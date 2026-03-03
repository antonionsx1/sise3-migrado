USE [SISE_NEW]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		SBGE
-- Create date: 19/02/2025
-- Description:	Reporte por fecha de recepción de la DGAJ
-- exec [SISE3].[pcReporteDGAJRepresentacionContenciosaDetalle]  36070465
-- Modificción: 07052025 JRE Se realiza ajuste en la consulta del Nombre y Cargo Quejoso
-- Modificción: 08052025 JRE Cambio de identificador 4619 por 4628 del campo NumeroAmparoIndirectoRP
-- Modificción: 09052025 JRE Cambio de identificadores referentes a la tarea 22796
-- Modificción: 13052025 JRE Cambio de origen para el campo FechaNotificacionDGAJP referente a la tarea 23078
-- Modificción: 15052025 JRE Se retorna estado de la audiencia referente a la tarea 23048
-- Modificción: 19052025 JRE Se retorna fecha de de suspensión definitiva referente a la tarea 23079
-- Modificación: 21052025 JRE Se retorna fecha notificacion de cumplimiento referente a la tarea 23080
-- Modificación: 26062025 ALV Se toma en cuenta el AsuntoStatus y la FechaBaja al obtener Asunto Origen referente a la tarea 23897
-- Modificación: 03072025 ARS Se ajusta la consulta de órgano origen
-- =============================================
ALTER PROCEDURE [SISE3].[pcReporteDGAJRepresentacionContenciosaDetalle]  
	@pi_AsuntoNeunId BIGINT
	
AS

BEGIN

	BEGIN TRY

	DECLARE @ErrorMessage NVARCHAR(4000)
		   ,@ErrorSeverity INT
		   ,@ErrorState INT

	DECLARE @FechaRecepcionDGAJ DATETIME,
	@NombreQuejoso VARCHAR(500),
	@CargoQuejoso VARCHAR(500),
	@ActoReclamadoEspecifico VARCHAR(500),
	@PrecisionDelActo VARCHAR(500),
	@ResponsablePrincipal VARCHAR(500),
	@ResponsableIncidental VARCHAR(500),
	@FechaNotificacionDGAJP VARCHAR(10),
	@EstadoUltimaAudiencia VARCHAR(70),
	@FechaNotificacionSuspensionIsDGAJI VARCHAR(10),
	@FechaNotificacionI VARCHAR(10)
	
	--Nombre y Cargo del quejoso
	SELECT TOP 1 @NombreQuejoso=SQ.NombreQuejoso, @CargoQuejoso=SQ.Cargo FROM (
													SELECT  
														CASE
															WHEN   PA.CatCaracterPersonaAsuntoId IN(616) THEN PAU.ServidorPublico
															WHEN   PA.CatCaracterPersonaAsuntoId IN (12,13,48,54,60,71,87) THEN COALESCE( PA.Nombre, '')+ ' '
																    + COALESCE(PA.APaterno,'')+' '+COALESCE(PA.AMaterno,'')
														END as NombreQuejoso
														, PA.FechaAlta, PAU.Cargo 
													FROM PersonasAsunto PA WITH(NOLOCK)
													LEFT JOIN PersonasAsuntoUGIRA PAU WITH(NOLOCK) ON PAU.PersonaId=PA.PersonaId
													WHERE PA.AsuntoNeunId=@pi_AsuntoNeunId and PA.StatusReg=1  
													) AS SQ
	WHERE SQ.NombreQuejoso IS NOT NULL
	ORDER BY SQ.FechaAlta ASC

	--Fecha Notificacion resolución incidente cumplimiento
	SELECT TOP 1 @FechaNotificacionI = CONVERT(VARCHAR(10), ValorCampoAsunto, 103) FROM AsuntosDetalleFechas WITH(NOLOCK)
    WHERE asuntoneunid = @pi_AsuntoNeunId AND tipoasuntoid IN (27098) AND StatusReg =1
	--Fecha Notificacion en Suspensión definitiva
    SELECT TOP 1 @FechaNotificacionSuspensionIsDGAJI = CONVERT(VARCHAR(10), ValorCampoAsunto, 103) FROM AsuntosDetalleFechas WITH(NOLOCK)
    WHERE asuntoneunid = @pi_AsuntoNeunId AND tipoasuntoid IN (27095) AND StatusReg =1
	--Fecha Fecha Notificacion DGAJP
    SELECT TOP 1 @FechaNotificacionDGAJP = CONVERT(VARCHAR(10), ValorCampoAsunto, 103) FROM AsuntosDetalleFechas WITH(NOLOCK)
    WHERE asuntoneunid = @pi_AsuntoNeunId AND tipoasuntoid IN (27082) AND StatusReg =1
	--Fecha recepcion a la DGAJ
	SELECT @FechaRecepcionDGAJ =  ValorCampoAsunto FROM AsuntosDetalleFechas WITH(NOLOCK) WHERE TipoAsuntoId = 27057 And StatusReg = 1 and AsuntoNeunId = @pi_AsuntoNeunId		
	--Acto Reclamado especifico y Precisión del acta	
	SELECT @ActoReclamadoEspecifico=Contenido FROM AsuntosDetalleDescripcion WITH(NOLOCK) WHERE AsuntoNeunId=@pi_AsuntoNeunId and TipoAsuntoId=27102 and StatusReg=1
	SELECT @PrecisionDelActo=Contenido FROM AsuntosDetalleDescripcion  WITH(NOLOCK) WHERE AsuntoNeunId=@pi_AsuntoNeunId and TipoAsuntoId=27076 and StatusReg=1
	--Responsable
	SELECT @ResponsablePrincipal=concat(nombre,' ',ApellidoMaterno,' ',ApellidoPaterno) FROM CatEmpleados 
	WHERE EMPLEADOID IN (SELECT Top 1 Secretario FROM Promociones WITH(NOLOCK) WHERE AsuntoNeunId=@pi_AsuntoNeunId and TipoCuaderno=5645 order by FechaAlta asc)
	SELECT @ResponsableIncidental=concat(nombre,' ',ApellidoMaterno,' ',ApellidoPaterno) FROM CatEmpleados 
	WHERE EMPLEADOID IN (SELECT Top 1 Secretario FROM Promociones WITH(NOLOCK) WHERE AsuntoNeunId=@pi_AsuntoNeunId and TipoCuaderno=5647 order by FechaAlta asc)
	
	DECLARE @AsuntoNeunIdOrigen BIGINT
	DECLARE @AsuntoAliasOrigen VARCHAR(50)
	DECLARE @NombreOrganoOrigen VARCHAR(400)
	
	DECLARE @tbAD TABLE(
			AsuntoNeunId BIGINT not null,	
			TipoAsuntoId INT not null,	
			ValorCampoAsunto  VARCHAR(400) not null)

	--OBTENEMOS INFORMACION ASUNTO ORIGEN
	SELECT TOP(1) 
		@AsuntoNeunIdOrigen = ar.AsuntoNeunIdOrg,
		@AsuntoAliasOrigen = ao.AsuntoAlias,
		@NombreOrganoOrigen = co.NombreOficial
		FROM AsuntosRelacionados ar WITH(NOLOCK)
		LEFT JOIN Asuntos ao WITH(NOLOCK) ON ao.AsuntoNeunId=ar.AsuntoNeunIdOrg 
		LEFT JOIN CatOrganismos co WITH(NOLOCK) ON co.CatOrganismoId=ao.CatOrganismoId
		WHERE ar.AsuntoNeunIdDest=@pi_AsuntoNeunId
			AND ao.FechaBaja IS NULL
		ORDER BY ao.FechaAlta DESC

	--OBTENEMOS ESTADO DE LA ULTIMA AUDIENCIA DEL ASUNTO ORIGEN
        SELECT TOP 1  @EstadoUltimaAudiencia = acr.Descripcion FROM [AUD_AsuntosDetalleFechas] aadf
        INNER JOIN AsuntosDetalleFechas adf WITH(NOLOCK) ON aadf.ControlFecha=adf.TipoAsuntoId AND aadf.FechaId=adf.AsuntoDetalleFechasId AND aadf.AsuntoNeunId = adf.AsuntoNeunId AND aadf.AsuntoId = adf.AsuntoId
        INNER JOIN AUD_CatResultado acr ON acr.IdTipoAudiencia = aadf.AudienciaId and acr.IdResultado = aadf.ResultadoId
        WHERE aadf.AsuntoNeunId = @AsuntoNeunIdOrigen ORDER BY aadf.AgendaId DESC
	
	--INSERTAMOS UNIVERSO DE FECHAS POR NEUN DESTINO
	INSERT INTO @tbAD
	SELECT AsuntoNeunId ,TipoAsuntoId ,STRING_AGG(CONVERT(VARCHAR(10), ValorCampoAsunto, 103), '|')  AS ValorCampoAsunto
	FROM AsuntosDetalleFechas WITH(NOLOCK)
	WHERE asuntoneunid = @AsuntoNeunIdOrigen
	AND tipoasuntoid IN (27068, 27105, 27106,  -- Campos cuaderno principal
	27101, 27068,27112,27113)  --Campos cuaderno incidental
	AND StatusReg =1 group by AsuntoNeunId,TipoAsuntoId


	--INSERTAMOS UNIVERSO DE FECHAS POR NEUN ORIGEN
	INSERT INTO @tbAD
	SELECT AsuntoNeunId ,TipoAsuntoId, STRING_AGG(CONVERT(VARCHAR(10), ValorCampoAsunto, 103), '|')  AS ValorCampoAsunto
	FROM AsuntosDetalleFechas WITH(NOLOCK)
	WHERE asuntoneunid = @AsuntoNeunIdOrigen
	AND tipoasuntoid IN (8907, 4444, 4456, 4461, 4407, 4562, 4587, 4630, 8700, 4646, 4676, 4679, 4680, 4673, 4774,  -- Campos cuaderno principal
	4708, 4712,4716, 4720, 4741, 10412, 10413, 10419, 4756, 4759, 4760, 4774)  --Campos cuaderno incidental
	AND StatusReg =1 group by AsuntoNeunId,TipoAsuntoId


	---------INSERTAMOS UNIVERSO DE CATALOGO UNA OPCION 
	INSERT INTO @tbAD
	SELECT adc.AsuntosNeunId,adc.TipoAsuntoId, ced.CatalogoElementoDescripcion AS ValorCampoAsunto
	FROM AsuntosDetalleCatalogos adc 
	LEFT JOIN CatalogosElementosDescripcion ced with(nolock) on ced.CatalogoElementoDescripcionID =adc.CatCatalogoAsuntoId
	WHERE adc.TipoAsuntoId in(4457,10414,10420) and adc.AsuntosNeunId=@AsuntoNeunIdOrigen and adc.StatusReg=1 and ced.StatusRegistro=1
	-----------INSERTAMOS UNIVERSO DE CATALOGO UNA OPCION  ORGANOS
	INSERT INTO @tbAD
	SELECT adc.AsuntosNeunId,adc.TipoAsuntoId,co.NombreOficial AS ValorCampoAsunto
	FROM AsuntosDetalleCatalogos adc 
	LEFT JOIN CatOrganismos co WITH(NOLOCK) ON  co.CatOrganismoId=adc.CatCatalogoAsuntoId
	WHERE adc.TipoAsuntoId in(4459,4629,4677,4714,4739,10417) and adc.AsuntosNeunId=@AsuntoNeunIdOrigen and adc.StatusReg=1 

	----------------INSERTAMOS UNIVERSO DE CATALOGO VARIAS OPCIONES (Nota: Los campos 4445,4457 solo los usamos para validar si tiene Admisión y Queja para poder desplegar campos)
	INSERT INTO @tbAD
	SELECT adc.AsuntosNeunId, adc.TipoAsuntoId,STRING_AGG(ced.CatalogoElementoDescripcion, '|') AS ValorCampoAsunto
	FROM AsuntosDetalleCatalogos adc 
	LEFT JOIN CatalogosElementosDescripcion ced with(nolock) on ced.CatalogoElementoDescripcionID =adc.CatCatalogoAsuntoId
	WHERE adc.TipoAsuntoId in(4462, 4445, 4631, 4639, 4681, 4709, 4717, 4733, 4742, 4761) and adc.AsuntosNeunId=@AsuntoNeunIdOrigen and adc.StatusReg=1 and ced.StatusRegistro=1
	group by adc.AsuntosNeunId,adc.TipoAsuntoId


	---------------INSERTAMOS UNIVERSO DE CAMPO TEXTO
	INSERT INTO @tbAD
	SELECT ad.AsuntoNeunId,ad.TipoAsuntoId,ad.Contenido AS ValorCampoAsunto  FROM AsuntosDetalleDescripcion ad WHERE ad.TipoAsuntoId in(4628,10418,4740,4715,4678,4408,4460) 
	and ad.AsuntoNeunId=@AsuntoNeunIdOrigen and ad.StatusReg=1

	DECLARE @ContieneAdmision bit
	SET @ContieneAdmision =(SELECT 
								CASE 
								WHEN MAX(CHARINDEX('Admisión', ValorCampoAsunto)) > 0 THEN 1 
								ELSE 0 
								END AS ContieneAdmision
						FROM @tbAD 
						WHERE TipoAsuntoId = 4445)
	DECLARE @TipoRecursoEsQueja bit
	SET @TipoRecursoEsQueja =(SELECT 
								CASE 
								WHEN MAX(CHARINDEX('Queja', ValorCampoAsunto)) > 0 THEN 1 
								ELSE 0 
								END AS TipoRecursoEsQueja
						FROM @tbAD 
						WHERE TipoAsuntoId = 4457)
						
	DECLARE @EsResolucionInicial bit
	SET @EsResolucionInicial =(SELECT 
								CASE 
								WHEN 
									   MAX(CHARINDEX('Desechamiento', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('No interpuesta', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('No corresponde el asunto por turno', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('Impedimento', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('Incompetencia', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('Acumulación', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('Sobreseimiento por Desistimiento', ValorCampoAsunto)) > 0
									OR MAX(CHARINDEX('No Presentada', ValorCampoAsunto)) > 0
								THEN 1 
								ELSE 0 
								END AS TipoRecursoEsQueja
						FROM @tbAD 
						-- WHERE TipoAsuntoId = 4445 -- Revisar si es necesario filtrar por 4445 (Sentido resolución inicial)
						)
	   	    	  
	
	----------SELECT DISTINCT
	----------a.AsuntoNeunId
	----------,@pi_TipoCuadernoId as TipoCuadernoId
	----------,@AsuntoNeunIdOrigen AS AsuntoNeunIdOrigen
	----------,@AsuntoAliasOrigen AS AsuntoAliasOrigen 
	----------,[dbo].[fnDevuelveTipoAsunto](@AsuntoNeunIdOrigen) AS TipoAsuntoDesc
	----------,@FechaRecepcionDGAJ AS FechaRecepcionDGAJ
	----------,@NombreQuejoso AS NombreQuejoso
	----------,@CargoQuejoso AS CargoQuejoso
	----------,@NombreOrganoOrigen AS NombreOrganoOrigen
	----------,@ActoReclamadoEspecifico AS ActoReclamadoEspecifico
	----------,@PrecisionDelActo AS PrecisionDelActa
	----------,@Responsable AS Responsable
	----------,@ContieneAdmision AS ContieneAdmision
	----------,@TipoRecursoEsQueja as TipoRecursoEsQueja
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4444) AS FechaAdmisionOrigenP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4456) AS FechaInterposicionP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4459) AS TribunalColegiadoRecursoP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4460) AS NumeroTocaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4461) AS FechaResolucionP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4462) AS SentidoResolucionRecursoP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4407) AS FechaEgresoP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4408) AS NumeroAcuerdoP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4562) AS FechaResolucionAudienciaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4587) AS FechaSentenciaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4639) AS SentidoSentenciaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27082)AS FechaNotificacionDGAJP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4629) AS TribunalColegiadoSentenciaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4619) AS NumeroAmparoIndirectoRP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4630) AS FechaEjecutoriaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4631) AS SentidoTribunalP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4623) AS FechaCausaEjecutoriaP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4646) AS FechaRequerimientoP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4676) AS FechaRemisionP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4677) AS TribunalColegiadoIncidenteP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4678) AS ExpedienteIncidenteP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4679) AS FechaInconformidadP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4680) AS FechaEjecutoriaInconformidadP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4681) AS SentidoInconformidadP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4673) AS FechaCumplimientoP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4774) AS FechaRemisionArchivo-----
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27068) AS FechaRemisionDGAJ
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27105) AS FechaInnominadoDGAJP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27106) AS FechaVencimientoInnominadoDGAJP
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27107) AS DescripcionDGAJP

	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4708) AS FechaSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4709) AS SentidoSuspensionProvI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27089) AS EfectoDGAJI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4712) AS FechaInterposicionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4714) AS TribunalColegiadoRecursoI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4715) AS NumeroTocaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4716) AS FechaEjecutoriaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4717) AS SentidoQuejaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4720) AS FechaAudienciaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4733) AS SentidoSuspensionDefiI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27094) AS EfectosDGAJI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27095) AS FechaNotificacionSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4739) AS TribunalColegiadoSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4751) AS ExpedienteI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4752) AS FechaEjecutoriaRevisionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4753) AS SentidoSuspensionPlanoI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10412) AS FechaCelebracionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10413) AS FechaResolucionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10414) AS SentidoResolucionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27098) AS FechaNotificacionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10417) AS TribunalColegiadoQuejaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10418) AS ExpedienteQuejaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10419) AS FechaEjecutoriaQuejaI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=10420) AS SentidoQuejaSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4756) AS FechaInterposicionSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4759) AS FechaViolacionSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4760) AS FechaResolucionSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=4761) AS SentidoResolucionSuspensionI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27101) AS FechaNotificacionIncidenteI	
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27112) AS FechaInnominadoDGAJI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27113) AS FechaVencimientoInnominadoDGAJI
	----------,(SELECT ValorCampoAsunto FROM @tbAD WHERE TipoAsuntoId=27114) AS DescripcionDGAJI
	----------INTO #tmpReporte
	----------FROM Asuntos a WITH(NOLOCK)	WHERE a.AsuntoNeunId=@pi_AsuntoNeunId  AND a.StatusReg=1 


	--------------------Usamos un PIVOT para transformar los datos de la tabla tdAD en columnas para reducir la cantidad de subconsultas en el Select

	SELECT DISTINCT
     a.AsuntoNeunId										AS AsuntoNeunId
	,@AsuntoNeunIdOrigen								AS AsuntoNeunIdOrigen
	,@AsuntoAliasOrigen									AS AsuntoAliasOrigen 
	,[dbo].[fnDevuelveTipoAsunto](@AsuntoNeunIdOrigen)	AS TipoAsuntoDesc
	,@FechaRecepcionDGAJ								AS FechaRecepcionDGAJ
	,@NombreQuejoso										AS NombreQuejoso
	,@CargoQuejoso										AS CargoQuejoso
	,@NombreOrganoOrigen								AS NombreOrganoOrigen
	,@ActoReclamadoEspecifico							AS ActoReclamadoEspecifico
	,@PrecisionDelActo									AS PrecisionDelActo
	,@ResponsablePrincipal								AS ResponsablePrincipal
	,@ResponsableIncidental								AS ResponsableIncidental
	,@ContieneAdmision									AS ContieneAdmision
	,@TipoRecursoEsQueja								AS TipoRecursoEsQueja
	,@EsResolucionInicial								AS EsResolucionInicial
    -- Valores pivotados
	,p.[8907]											AS SobreseimientoP
	,p.[4444]											AS FechaAdmisionOrigenP
	,p.[4445]											AS SentidoResolucionP
	,p.[4457]											AS TipoRecursoP
	,p.[4456]											AS FechaInterposicionP
	,p.[4459]											AS TribunalColegiadoRecursoP
	,p.[4460]											AS NumeroTocaP
	,p.[4461]											AS FechaResolucionP
	,p.[4462]											AS SentidoResolucionRecursoP
	,p.[4407]											AS FechaEgresoP
	,p.[4408]											AS NumeroAcuerdoP
	,p.[4562]											AS FechaResolucionAudienciaP
	,p.[4587]											AS FechaSentenciaP
	,p.[4639]											AS SentidoSentenciaP
	,@FechaNotificacionDGAJP							AS FechaNotificacionDGAJP
	,p.[4629]											AS TribunalColegiadoSentenciaP
	,p.[4628]											AS NumeroAmparoIndirectoRP
	,p.[4630]											AS FechaEjecutoriaP
	,p.[4631]											AS SentidoTribunalP
	,p.[8700]											AS FechaCausaEjecutoriaP
	,p.[4646]											AS FechaRequerimientoP
	,p.[4676]											AS FechaRemisionP
	,p.[4677]											AS TribunalColegiadoIncidenteP
	,p.[4678]											AS ExpedienteIncidenteP
	,p.[4679]											AS FechaInconformidadP
	,p.[4680]											AS FechaEjecutoriaInconformidadP
	,p.[4681]											AS SentidoInconformidadP
	,p.[4673]											AS FechaCumplimientoP
	,p.[4774]											AS FechaRemisionArchivoP
	,p.[27068]											AS FechaRemisionDGAJ
	,p.[27105]											AS FechaInnominadoDGAJ
	,p.[27106]											AS FechaVencimientoInnominadoDGAJ
	,p.[27107]											AS DescripcionDGAJ
	,p.[4708]											AS FechaSuspensionI
	,p.[4709]											AS SentidoSuspensionProvI
	,p.[27089]											AS EfectoDGAJI
	,p.[4712]											AS FechaInterposicionI
	,p.[4714]											AS TribunalColegiadoRecursoI
	,p.[4715]											AS NumeroTocaI
	,p.[4716]											AS FechaEjecutoriaI
	,p.[4717]											AS SentidoQuejaI
	,p.[4720]											AS FechaAudienciaI
	,p.[4733]											AS SentidoSuspensionDefiI
	,p.[27094]											AS EfectosDGAJI
	,@FechaNotificacionSuspensionIsDGAJI				AS FechaNotificacionSuspensionIsDGAJI
	,p.[4739]											AS TribunalColegiadoSuspensionI
	,p.[4740]											AS ExpedienteI
	,p.[4741]											AS FechaEjecutoriaRevisionI
	,p.[4742]											AS SentidoSuspensionPlanoI
	,p.[10412]											AS FechaCelebracionI
	,p.[10413]											AS FechaResolucionI
	,p.[10414]											AS SentidoResolucionI
	,@FechaNotificacionI								AS FechaNotificacionI
	,p.[10417]											AS TribunalColegiadoQuejaI
	,p.[10418]											AS ExpedienteQuejaI
	,p.[10419]											AS FechaEjecutoriaQuejaI
	,p.[10420]											AS SentidoQuejaSuspensionI
	,p.[4756]											AS FechaInterposicionSuspensionI
	,p.[4759]											AS FechaViolacionSuspensionI
	,p.[4760]											AS FechaResolucionSuspensionI
	,p.[4761]											AS SentidoResolucionSuspensionI
	,p.[27101]											AS FechaNotificacionIncidenteI
	,p.[27112]											AS FechaInnominadoDGAJ
	,p.[27113]											AS FechaVencimientoInnominadoDGAJ
	,p.[27114]											AS DescripcionDGAJ
	,b.EstatusIJ										AS EstatusPrincipalIJ
	,b.FechaEtapaIJ										AS FechaEtapaPrincipalIJ
	,b.EstatusRR										AS EstatusPrincipalRR
	,b.FechaEtapaRR										AS FechaEtapaPrincipalRR
	,b.EstatusQ											AS EstatusPrincipalQ
	,b.FechaEtapaQ										AS FechaEtapaPrincipalQ
    ,b.EstatusI											AS EstatusPrincipalI
	,b.FechaEtapaI										AS FechaEtapaPrincipalI
	,c.EstatusIJ										AS EstatusIncidentalIJ
	,c.FechaEtapaIJ										AS FechaEtapaIncidentallIJ
	,c.EstatusRR										AS EstatusIncidentalRR
	,c.FechaEtapaRR										AS FechaEtapaIncidentalRR
	,c.EstatusQ											AS EstatusIncidentalQ
	,c.FechaEtapaQ										AS FechaEtapaIncidentalQ
    ,c.EstatusI											AS EstatusIncidentalI
	,c.FechaEtapaI										AS FechaEtapaIncidentalI
	,@EstadoUltimaAudiencia                             AS EstadoUltimaAudiencia
	FROM Asuntos a WITH(NOLOCK)
	LEFT JOIN (
		SELECT AsuntoNeunId, TipoAsuntoId, ValorCampoAsunto
		FROM @tbAD
	) src
	PIVOT (
		MAX(ValorCampoAsunto) 
		FOR TipoAsuntoId IN ([8907], [4444], [4445], [4457], [4456], [4459], [4460], [4461], [4462], [4407], [4408], [4562], [4587], [4639], [4629], [4628], [4630], [4631], [8700], [4646], [4676], [4677], [4678], [4679], [4680],[4681], [4673], [4774], [27068], [27105], [27106], [27107], 
							 [4708], [4709], [27089], [4712], [4714], [4715], [4716], [4717], [4720], [4733], [27094], [4739], [4740], [4741], [4742], [10412], [10413], [10414], [10417], [10418], [10419], [10420], [4756], [4759], [4760], [4761], [27101], [27112], [27113], [27114])
	) p ON a.AsuntoNeunId = @pi_AsuntoNeunId 
	--INTO #tmpReporte
	CROSS APPLY [SISE3].[fnObtieneEstadoTerminoPorEtapaDGAJ](a.AsuntoNeunId,5645) b
	CROSS APPLY [SISE3].[fnObtieneEstadoTerminoPorEtapaDGAJ](a.AsuntoNeunId,5647) c
	WHERE a.AsuntoNeunId = @pi_AsuntoNeunId AND a.StatusReg = 1;


	--select DISTINCT
	--tmp.AsuntoNeunId
	--,tmp.AsuntoNeunIdOrigen
	--,tmp.AsuntoAliasOrigen 
	--,tmp.TipoAsuntoDesc
	--,tmp.FechaRecepcionDGAJ
	--,tmp.NombreQuejoso
	--,tmp.CargoQuejoso
	--,tmp.NombreOrganoOrigen
	--,tmp.ActoReclamadoEspecifico
	--,tmp.PrecisionDelActa
	--,tmp.Responsable
	--,tmp.ContieneAdmision
	--,tmp.TipoRecursoEsQueja
	--,tmp.FechaAdmisionOrigenP
	--,tmp.FechaInterposicionP
	--,tmp.TribunalColegiadoRecursoP
	--,tmp.NumeroTocaP
	--,tmp.FechaResolucionP
	--,tmp.SentidoResolucionRecursoP
	--,tmp.FechaEgresoP
	--,tmp.NumeroAcuerdoP
	--,tmp.FechaResolucionAudienciaP
	--,tmp.FechaSentenciaP
	--,tmp.SentidoSentenciaP
	--,tmp.FechaNotificacionDGAJP
	--,tmp.TribunalColegiadoSentenciaP
	--,tmp.NumeroAmparoIndirectoRP
	--,tmp.FechaEjecutoriaP
	--,tmp.SentidoTribunalP
	--,tmp.FechaCausaEjecutoriaP
	--,tmp.FechaRequerimientoP
	--,tmp.FechaRemisionP
	--,tmp.TribunalColegiadoIncidenteP
	--,tmp.ExpedienteIncidenteP
	--,tmp.FechaInconformidadP
	--,tmp.FechaEjecutoriaInconformidadP
	--,tmp.SentidoInconformidadP
	--,tmp.FechaCumplimientoP
	--,tmp.FechaRemisionArchivo-----
	--,tmp.FechaRemisionDGAJ
	--,tmp.FechaInnominadoDGAJP
	--,tmp.FechaVencimientoInnominadoDGAJP
	--,tmp.DescripcionDGAJP
	--,tmp.FechaSuspensionI
	--,tmp.SentidoSuspensionProvI
	--,tmp.EfectoDGAJI
	--,tmp.FechaInterposicionI
	--,tmp.TribunalColegiadoRecursoI
	--,tmp.NumeroTocaI
	--,tmp.FechaEjecutoriaI
	--,tmp.SentidoQuejaI
	--,tmp.FechaAudienciaI
	--,tmp.SentidoSuspensionDefiI
	--,tmp.EfectosDGAJI
	--,tmp.FechaNotificacionSuspensionI
	--,tmp.TribunalColegiadoSuspensionI
	--,tmp.ExpedienteI
	--,tmp.FechaEjecutoriaRevisionI
	--,tmp.SentidoSuspensionPlanoI
	--,tmp.FechaCelebracionI
	--,tmp.FechaResolucionI
	--,tmp.SentidoResolucionI
	--,tmp.FechaNotificacionI
	--,tmp.TribunalColegiadoQuejaI
	--,tmp.ExpedienteQuejaI
	--,tmp.FechaEjecutoriaQuejaI
	--,tmp.SentidoQuejaSuspensionI
	--,tmp.FechaInterposicionSuspensionI
	--,tmp.FechaViolacionSuspensionI
	--,tmp.FechaResolucionSuspensionI
	--,tmp.SentidoResolucionSuspensionI
	--,tmp.FechaNotificacionIncidenteI	
	--,tmp.FechaInnominadoDGAJI
	--,tmp.FechaVencimientoInnominadoDGAJI
	--,tmp.DescripcionDGAJI
	--,b.EstatusIJ
	--,b.FechaEtapaIJ
	--,b.EstatusRR
	--,b.FechaEtapaRR
	--,b.EstatusQ
	--,b.FechaEtapaQ
 --   ,b.EstatusI
	--,b.FechaEtapaI
 --   from #tmpReporte tmp
	--CROSS APPLY [SISE3].[fnObtieneEstadoTerminoPorEtapaDGAJ](tmp.AsuntoNeunId,tmp.TipoCuadernoId) b

	

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END
