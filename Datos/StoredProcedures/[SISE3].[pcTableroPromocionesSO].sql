SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** 22/08/2023                 ******/
/****** Proyecto: SISE3       ******/
/****** Autor: Christian Araujo - MS  ******/
/****** Objetivo: Carga de pantalla promociones uniendo Promociones, Promociones electrónicas ******/
/****** Demandas electrónicas y Comunicaciones oficiales******/
/****** EXEC SISE3.[pcTableroPromocionesSO] 1494, 1000,1,0,  '2024-05-05', '2024-05-31' ,NULL,NULL,'','',0,0,NULL,NULL,NULL *****/
-- Modifiación:  13/06/2024 JSM Se optimiza sp
-- Modificación 01/06/2024 GGHH Se optimiza y se igualan los conteos de promociones electrónicas con SISE 2.0
-- Modificación JRE 11/06/2025 Se ajusta el ordenamiento para datos de expediente origen referente a la tarea 23689
ALTER PROCEDURE [SISE3].[pcTableroPromocionesSO]
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATE = NULL
	
AS
BEGIN
	DECLARE @Promociones SISE3.Promociones_TableType
	DECLARE @FechaIniciaOperaciones DATE 
	DECLARE @Pendientes BIT = 0
	/*********** VALIDACIÓN PARA ASUNTOS JURIDICOS ****************/
	DECLARE @TipoOrganoAsuntosJuridicos BIT =0 
	
	IF (
	(SELECT cto.CatTipoOrganismoId FROM CatOrganismos CO WITH(NOLOCK)
	INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK)
	ON CO.CatTipoOrganismoId =  CTO.CatTipoOrganismoId
	WHERE CO.CatOrganismoId =  @pi_CatOrganismoId) = 33
	)
	BEGIN
	SET @TipoOrganoAsuntosJuridicos = 1
	END
	/*********** VALIDACIÓN PARA ASUNTOS JURIDICOS ****************/
	
	
	IF(@pi_FechaPresentacionIni IS NULL AND @pi_FechaPresentacionFin IS NULL)
	BEGIN
		SELECT @FechaIniciaOperaciones = FechaAlta 
		FROM  SISE3.ConfiguracionOrganismo
		WHERE CatOrganismoId = @pi_CatOrganismoId

		SET @FechaIniciaOperaciones = ISNULL(@FechaIniciaOperaciones,GETDATE())

		SET @pi_FechaPresentacionIni = ISNULL(@pi_FechaPresentacionIni,@FechaIniciaOperaciones)
		SET @pi_FechaPresentacionFin = ISNULL(@pi_FechaPresentacionFin,GETDATE())
		SET @Pendientes = 1
	END
		SELECT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.CatOrganismoId,
			p.YearPromocion,
			p.NumeroOrden,
			p.AsuntoNeunId,
			p.OrigenPromocion,
			p.TipoCuaderno,
			p.NumeroRegistro,
			p.FechaPresentacion,
			p.HoraPresentacion,
			p.ClasePromocion,
			p.ClasePromovente,
			p.TipoPromovente,
			p.TipoContenido,
			p.Contenido,
			p.Secretario,
			p.FechaAlta,
			p.RegistroEmpleadoId,
			p.FechaAcuerdo,
			p.PromoIdentificador,
			p.AsuntoDocumentoId,
			p.Mesa,
			p.Observaciones,
			ConArchivo = IIF(pa.AsuntoNeunId IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29,30,31),1,0),1),
			pa.NombreArchivo,
			pa.Fojas,
			pa.Firmado,
			p.NumeroCopias, 
			p.NumeroAnexos,
			a.numeroOCC OCC
			INTO #CTEPromociones
		FROM Promociones p WITH(NOLOCK)
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId
														AND pa.CatOrganismoId = p.CatOrganismoId 
														AND pa.NumeroOrden = p.NumeroOrden
														AND pa.Origen = p.OrigenPromocion 
														AND pa.YearPromocion = p.YearPromocion
														AND pa.StatusArchivo IN (1)
														AND pa.ClaseAnexo = 0
		LEFT JOIN [SISE3].[Rel_PromocionArea] rpa WITH (NOLOCK) ON rpa.AsuntoNeunId = p.AsuntoNeunId
														AND rpa.CatOrganismoId = p.CatOrganismoId 
														AND rpa.NumeroOrden = p.NumeroOrden
														AND rpa.YearPromocion = p.YearPromocion
		LEFT JOIN Areas ar WITH (NOLOCK) ON ar.AreaId = rpa.AreaId
		WHERE p.catOrganismoId = @pi_CatOrganismoId 
		AND (
			(@Pendientes = 0 AND CONVERT(DATE,p.FechaPresentacion) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin) 
			OR
			(@Pendientes = 1 AND pa.AsuntoNeunId IS NULL AND CONVERT(DATE,p.FechaPresentacion) >= @FechaIniciaOperaciones))
		AND p.statusReg = 1
	
	INSERT INTO @Promociones
	SELECT	1, 
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,
			a.TipoProcedimiento,
			dbo.funRecuperaCatalogoDependienteDescripcion(527,p.TipoCuaderno) Cuaderno,
			p.NumeroRegistro, 
			OrigenPromocion = o.sNombreOrigenPromocion,
			SecretarioNombre = SISE3.ConcatenarNombres(s.Nombre,s.ApellidoPaterno,s.ApellidoMaterno),
			SecretarioId = p.Secretario,
			s.UserName,
			Mesa = p.Mesa,
			(CONVERT(DATETIME,p.FechaPresentacion+ CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END)) as FechaPresentacion,
			TipoPromociones = CASE p.ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END,
			Contenido = ISNULL(cp.CatalogoPromocionDescripcion,''),
			Promovente = ISNULL(
				CASE 
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid = 1 THEN SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid <> 1 THEN SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) =2 THEN SISE3.ConcatenarNombres(pr.Nombre, pr.APaterno,pr.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) =3 THEN SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 4 THEN ajo.AJONombre
					END,''),
			IdPromovente = ISNULL(
				CASE ISNULL(p.ClasePromovente,1) 
					WHEN 1 THEN pas.PersonaId
					WHEN 2 THEN pr.PromoventeId
					WHEN 3 THEN ea.EmpleadoId
					WHEN 4 THEN ajo.AJOId
					END,''),
			ClasePromoventeDescripcion = CASE ISNULL(ClasePromovente,1) 
				WHEN 1 THEN 'Partes'
				WHEN 2 THEN 'Promovente'
				WHEN 3 THEN 'Autoridad Judicial'
				WHEN 4 THEN  'Autoridad judicial'
				ELSE ''
				END,
			NumeroCopias = ISNULL(p.NumeroCopias,0),
			NumeroAnexos = ISNULL(p.NumeroAnexos,0),
			Registrada = 1,
			ConArchivo = IIF(p.NombreArchivo IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29,30,31),1,0),1),
			EsDemanda = 0,
			OrigenPromocionId = p.OrigenPromocion,
			Folio = 0,
			EsPromocionE = IIF(p.OrigenPromocion IN (6,14,22,5,15,29,30,31),1,0),
			ad.CatAutorizacionDocumentosId,
			p.NombreArchivo,
			Origen = IIF(p.OrigenPromocion IN (6,14,22,5,15,29,30,31),p.OrigenPromocion,0),
			NombreOrigen = o.sDescripcion,
			p.Fojas,
			p.NumeroOrden, 
			un.UserName as UsuarioCaptura,
			p.CatOrganismoId,
			p.YearPromocion,
			NULL kIdElectronica,
			p.fechaAlta as FechaCaptura,
			a.NumeroAlias, 
			SISE3.fnEstadoAutorizacion(ad.AsuntoDocumentoId, ad.CatAutorizacionDocumentosId) as EstadoAutorizacion,
			NULL NombreOficial,
			p.TipoCuaderno CuadernoId,
			p.Firmado,
			p.AsuntoDocumentoId,
			p.Observaciones,
			p.OCC,
			SISE3.ConcatenarNombres(ce.Nombre, ce.ApellidoPaterno, ce.ApellidoMaterno) as UsuarioCapturaCompleto
			,CASE WHEN ad.NombreDocumento IS NULL THEN 0 ELSE 1 END ConAcuerdo
	FROM #CTEPromociones p
	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a 
	LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK)  ON p.OrigenPromocion = o.kIdOrigenPromocion
	LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario and s.StatusRegistro=1
	LEFT JOIN CatPromocion cp WITH(NOLOCK) ON cp.CatalogoPromocionId = p.TipoContenido and cp.StatusReg =1
	LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1 and pas.StatusReg =1
	LEFT JOIN Promovente pr  WITH(NOLOCK) ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 and pr.AsuntoNeunId = p.AsuntoNeunId and pr.Estatus=1
	LEFT JOIN AutoridadJudicial aj WITH(NOLOCK) ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3 and aj.StatusReg=1
	LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId and ea.StatusRegistro=1
	LEFT JOIN AutoridadJudicial_Otros ajo  WITH(NOLOCK) ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4 and ajo.AJOEstatus=1
	LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId and ad.StatusReg=1
	LEFT JOIN CatEmpleados un  WITH(NOLOCK) ON un.EmpleadoId = p.RegistroEmpleadoId and un.StatusRegistro=1
	LEFT JOIN CatEmpleados ce WITH(NOLOCK) ON ce.EmpleadoId = p.RegistroEmpleadoId
	WHERE No = 1
	
	IF(@Pendientes = 1)
	BEGIN 
		DELETE @Promociones WHERE SISE3.fnEstatusPromocion (CatAutorizacionDocumentosId , EsPromocionE, NombreArchivo, Origen ,kIdElectronica, ConArchivo, SecretarioUserName) = 4
	END

	PRINT '1. ' +  CONVERT(VARCHAR(100), GETDATE(),9) 
	/***** PROMOCIONES ELECTRÓNICAS ****/

		SELECT	
			No = ROW_NUMBER() OVER (PARTITION BY p.kIdPromocion ORDER BY ISNULL(arc.bfirmado,0),arc.kIdArchivo),
			AsuntoNeunId = p.fkIdAsuntoNeun,			Expediente = a.AsuntoAlias,					CatTipoAsunto = a.CatTipoAsunto, 
			CatTipoAsuntoId = a.CatTipoAsuntoId,		TipoProcedimiento = a.TipoProcedimiento,	OrigenPromocion = o.sNombreOrigenPromocion ,		
			FechaPresentacion = p.fFechaAlta,			Registrada = 0,								ConArchivo = 1,
			EsDemanda = 0,								Promovente = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			OrigenPromocionId = p.fkIdOrigen,			Folio = p.kIdPromocion,						EsPromocionE = 1,
			Origen = IIF(p.fkIdOrigen = 30, 30,6),									kIdElectronica = p.kIdPromocion,			NombreOficial = '',
			NombreOrigen = 'Promoción Electrónica',		Firmado = arc.bFirmado
		INTO #CTEPromocionesElectronicas
		FROM dbo.JL_MOV_Promocion AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a				
		LEFT JOIN	JL_REL_PromocionSISE ps WITH(NOLOCK) ON p.kIdPromocion = ps.fkIdPromocion 
			AND p.fkIdAsuntoNeun = ps.AsuntoNeunId AND p.fkIdOrgano = ps.CatOrganismoId
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 30, 30, IIF(p.fkIdOrigen = 22,22,5))
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario and u.fkIdEstatus=1
		INNER JOIN JL_REL_PromocionArchivo pa WITH(NOLOCK) ON p.kIdPromocion = pa.fkIdPromocion --and pa.fkIdEstatus = 1
		INNER JOIN JL_MOV_Archivo arc ON arc.kIdArchivo = pa.fkIdArchivo --and arc.fkIdEstatus = 1
		WHERE ps.kIdPromocionSISE IS NULL
		AND P.fkIdOrigen != 22
		AND a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano
		AND p.fkIdEstatus = 1
		AND  p.fkIdUsuario  > 0 
		AND p.fkIdOrgano = @pi_CatOrganismoId
		AND CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin
		

	INSERT INTO @Promociones(
			AsuntoNeunId,		Expediente,			CatTipoAsunto,		CatTipoAsuntoId, 
			TipoProcedimiento,	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado)
	SELECT	AsuntoNeunId,		Expediente,			CatTipoAsunto,		CatTipoAsuntoId, 
			TipoProcedimiento,	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado
	FROM #CTEPromocionesElectronicas
	WHERE No = 1
	PRINT '2. ' +  CONVERT(VARCHAR(100), GETDATE(),9) 
	/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ****/

		SELECT	
			No = ROW_NUMBER() OVER (PARTITION BY p.kiIdFolio ORDER BY arc.kIdArchivo),
			AsuntoNeunId = p.fkIdAsuntoNeun,			Expediente = a.AsuntoAlias,					CatTipoAsunto = a.CatTipoAsunto, 
			CatTipoAsuntoId = a.CatTipoAsuntoId,		TipoProcedimiento = a.TipoProcedimiento,	OrigenPromocion = o.sNombreOrigenPromocion,		
			FechaPresentacion = p.fFechaAlta,			Registrada = 0,								ConArchivo = 1,
			EsDemanda = 0,								Promovente = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			OrigenPromocionId = p.fkIdOrigen,			Folio = p.kIdPromocion,						EsPromocionE = 1,
			Origen = 14,								kIdElectronica = p.kiIdFolio,				NombreOficial = co.NombreOficial,
			NombreOrigen = 'Promoción Electrónica de Interconexión',								Firmado = arc.bFirmado,
			CASE WHEN ad.NombreDocumento IS NULL THEN 0 ELSE 1 END ConAcuerdo
		INTO #CTEPromocionesElectronicasInterconexion
		FROM dbo.ICOIJ_MOV_Promocion AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
		LEFT JOIN ICOIJ_REL_PromocionSISE ps WITH(NOLOCK) ON p.kiIdFolio = ps.fkIdPromocion  AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= p.fkIdOrigen
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario and u.fkIdEstatus=1
		LEFT JOIN AsuntosDocumentos ad ON ad.AsuntoNeunId = p.fkIdAsuntoNeun and ad.StatusReg=1
		LEFT JOIN ICOIJ_REL_DemandaPromocionSolicitud dps ON dps.fkiIdFolio = p.kiIdFolio and dps.iEstatus=1
		INNER JOIN ICOIJ_MOV_Archivo arc ON arc.kiIdFolio = p.kiIdFolio 
		LEFT JOIN CatOrganismos co ON dps.iOIJ = co.CatOrganismoId and co.StatusReg=1
		WHERE ps.kIdPromocionSISE IS NULL
		AND a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano 
		AND p.fkIdEstatus = 1
		AND arc.fkIdEstatus = 1  
		AND p.fkIdOrgano = @pi_CatOrganismoId
		AND p.EsSinExpediente = 0 
		AND CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin

	INSERT INTO @Promociones(
			AsuntoNeunId,		Expediente,			CatTipoAsunto,		CatTipoAsuntoId, 
			TipoProcedimiento,	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado)
	SELECT	AsuntoNeunId,		Expediente,			CatTipoAsunto,		CatTipoAsuntoId, 
			TipoProcedimiento,	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado
	FROM #CTEPromocionesElectronicasInterconexion
	WHERE No = 1
	PRINT '3. ' +  CONVERT(VARCHAR(100), GETDATE(),9) 

	/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES SIN EXPEDIENTE (INTERCONEXIÓN OJ)****/

		SELECT	
			No = ROW_NUMBER() OVER (PARTITION BY p.kiIdFolio ORDER BY arc.kIdArchivo),
			AsuntoNeunId = p.fkIdAsuntoNeun,			OrigenPromocion = 'INTERCONEXIÓN OJ',			FechaPresentacion = p.fFechaAlta,		
			Registrada = 0,								ConArchivo = 1,									EsDemanda = 0,					
			Promovente = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			OrigenPromocionId = p.fkIdOrigen,			Folio = p.kIdPromocion,							EsPromocionE = 1, 
			Origen = P.fkIdOrigen,								kIdElectronica = p.kiIdFolio,			NombreOrigen = 'Promoción Electrónica de Interconexión entre Órganos Jurisdiccionales ' + CASE WHEN P.fkIdOrigen <> 22 THEN  o.sNombreOrigenPromocion ELSE '' END,
			NombreOficial = '',	Firmado = ISNULL(arc.bFirmado,0)
		INTO #CTEPromocionesElectronicasInterconexionOJ
		FROM IOJ_MOV_PromocionOJ AS p WITH (nolock) 
		LEFT JOIN  IOJ_REL_PromocionSISE ps WITH(NOLOCK) ON p.kiIdFolio = ps.fkIdPromocion 
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= P.fkIdOrigen
		--LEFT JOIN IOJ_MOV_SolicitudInterconexion si ON P.kiIdFolio = si.dFolioRespuesta --AND si.iStatusReg=1 
		--LEFT JOIN CatOrganismos c ON si.fkIdOrgano = c.CatOrganismoId AND c.statusreg =1
		LEFT JOIN IOJ_VIS_PromocionOJ arc ON arc.kIdPromocion = p.kiIdFolio AND arc.fkIdEstatusArchivo = 1
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario and u.fkIdEstatus =1
		WHERE ps.fkIdPromocion IS NULL
		--AND P.fkIdOrigen = 22
		AND p.fkIdEstatus = 1
		AND p.fkIdOrgano = @pi_CatOrganismoId
		AND CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin
	
	INSERT INTO @Promociones(
			AsuntoNeunId,		OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado)
	SELECT	AsuntoNeunId,		OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado
	FROM #CTEPromocionesElectronicasInterconexionOJ
	WHERE No = 1
	PRINT '4. ' +  CONVERT(VARCHAR(100), GETDATE(),9) 
	/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES CON EXPEDIENTE ****/
		SELECT	
			No = ROW_NUMBER() OVER (PARTITION BY p.kIdPromocion ORDER BY ISNULL(arc.bfirmado,0), arc.kIdArchivo),
			AsuntoNeunId = p.fkIdAsuntoNeun,			Expediente = a.AsuntoAlias,					CatTipoAsunto = a.CatTipoAsunto, 
			CatTipoAsuntoId = a.CatTipoAsuntoId,		TipoProcedimiento = a.TipoProcedimiento,	OrigenPromocion = o.sNombreOrigenPromocion,		
			FechaPresentacion = p.fFechaAlta,			Registrada = 0,								ConArchivo = 1,
			EsDemanda = 0,								Promovente = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			OrigenPromocionId = p.fkIdOrigen,			Folio = p.kIdPromocion,						EsPromocionE = 1,
			Origen = 22,									kIdElectronica = p.kIdPromocion,			NombreOficial = '',
			NombreOrigen = 'Promoción Electrónica de Interconexión entre Órganos Jurisdiccionales.',		Firmado = arc.bFirmado
		INTO #CTEPromocionesElectronicasOJExp
		FROM dbo.JL_MOV_Promocion AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a				
		LEFT JOIN	JL_REL_PromocionSISE ps WITH(NOLOCK) ON p.kIdPromocion = ps.fkIdPromocion 
			and p.fkIdAsuntoNeun = ps.AsuntoNeunId and p.fkIdOrgano = ps.CatOrganismoId
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= P.fkIdOrigen
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario and u.fkIdEstatus=1
		INNER JOIN JL_REL_PromocionArchivo pa WITH(NOLOCK) ON p.kIdPromocion = pa.fkIdPromocion --and pa.fkIdEstatus = 1
		INNER JOIN JL_MOV_Archivo arc ON arc.kIdArchivo = pa.fkIdArchivo --and arc.fkIdEstatus = 1
		WHERE ps.kIdPromocionSISE IS NULL
		AND P.fkIdOrigen = 22
		AND a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano
		AND p.fkIdEstatus = 1
		AND  p.fkIdUsuario  > 0 
		AND p.fkIdOrgano = @pi_CatOrganismoId
		AND CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin

	INSERT INTO @Promociones(
			AsuntoNeunId,		Expediente,			CatTipoAsunto,		CatTipoAsuntoId, 
			TipoProcedimiento,	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado)
	SELECT	AsuntoNeunId,		Expediente,			CatTipoAsunto,		CatTipoAsuntoId, 
			TipoProcedimiento,	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,			OrigenPromocionId, 
			Folio,				EsPromocionE,		Origen,				kIdElectronica, 
			NombreOficial,		NombreOrigen,		Firmado
	FROM #CTEPromocionesElectronicasOJExp
	WHERE No = 1
	PRINT '5. ' +  CONVERT(VARCHAR(100), GETDATE(),9)  
	/***** DEMANDAS ELECTRÓNICAS ****/
	
		SELECT 	
			No = ROW_NUMBER() OVER (PARTITION BY p.kIdDemanda ORDER BY ISNULL(arc.bfirmado,0), arc.kIdArchivo),
			OrigenPromocion = o.sNombreOrigenPromocion,			FechaPresentacion = p.fFechaAlta,			Registrada = 0,
			ConArchivo = 1,										EsDemanda = 1,								Promovente = SISE3.ConcatenarNombres(ISNULL(u.sNombre,p.sPromoventeNombre),ISNULL(u.sApellidoPaterno,''),ISNULL(u.sApellidoMaterno,'')),
			OrigenPromocionId = p.fkIdOrigen,					Folio = p.kIdDemanda,						EsPromocionE = 1,
			Origen = 5,											kIdElectronica = p.kIdDemanda,				NombreOrigen = 'Demanda Electrónica', 
			Firmado = arc.bFirmado,								OCC = CAST(ISNULL(e.fkIdNumeroRegistroOCC,0) AS VARCHAR(150))
		INTO #CTEDemandaElectronicas
		FROM JL_MOV_Demanda AS p WITH (nolock) 

		INNER JOIN JLOCCSISE_MOV_EnLinea AS e ON e.fkIdDemandaJL = p.kIdDemanda
		INNER JOIN JL_REL_DemandaArchivo da WITH(NOLOCK) ON p.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
		INNER JOIN  dbo.JL_MOV_Archivo AS arc ON arc.kIdArchivo = da.fkIdArchivo and arc.fkIdEstatus = 1	
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 29, 29,5)
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario and u.fkIdEstatus=1
		LEFT JOIN ComunicacionesOficialesEnviadas coe WITH(NOLOCK) ON p.kIdDemanda = coe.fkIdDemanda 

		WHERE coe.fkIdDemanda IS NULL
		AND p.fkIdEstatus = 1 and e.fkIdEstatus=1
		AND e.fkIdNeunSISE IS NULL
		AND e.fkIdOrganoOCC = @pi_CatOrganismoId
		AND CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin

	INSERT INTO @Promociones(
			OrigenPromocion,		FechaPresentacion,		Registrada,
			ConArchivo,				EsDemanda,				Promovente,
			OrigenPromocionId,		Folio,					EsPromocionE,
			Origen,					kIdElectronica,			NombreOrigen,
			Firmado, OCC			)
	SELECT	OrigenPromocion,		FechaPresentacion,		Registrada,
			ConArchivo,				EsDemanda,				Promovente,
			OrigenPromocionId,		Folio,					EsPromocionE,
			Origen,					kIdElectronica,			NombreOrigen,
			Firmado, OCC				
	FROM #CTEDemandaElectronicas
	WHERE No = 1
	PRINT '6. ' +  CONVERT(VARCHAR(100), GETDATE(),9)  

	/***** DEMANDAS ELECTRÓNICAS INTERCONEXIÓN ****/

		SELECT 
			No = ROW_NUMBER() OVER (PARTITION BY p.kIdDemanda ORDER BY ISNULL(arc.bfirmado,0), arc.kIdArchivo),
			OrigenPromocion = o.sNombreOrigenPromocion,		FechaPresentacion = p.fFechaAlta,			Registrada = 0,
			ConArchivo = 1,									EsDemanda = 1,								Promovente = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			OrigenPromocionId = p.fkIdOrigen,				Folio = p.kiIdFolio,						EsPromocionE = 1, 
			Origen = 15,									kIdElectronica = p.kiIdFolio,				NombreOrigen = 'Demanda Electrónica Interconexión', 
			Firmado = arc.bFirmado,							OCC = CAST(ISNULL(e.fkIdNumeroRegistroOCC,0) AS VARCHAR(150))
		INTO #CTEDemandaElectronicasI
		FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
		INNER JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
		INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
		LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = p.kIdDemanda 
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 5
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario and u.fkIdEstatus=1
		LEFT JOIN ComunicacionesOficialesEnviadas coe WITH(NOLOCK) ON p.kIdDemanda = coe.fkIdDemanda 
		WHERE coe.fkIdDemanda IS NULL
		AND irdem.fkIdDemanda IS NULL
		AND p.fkIdEstatus = 1  
		AND e.fkIdNeunSISE IS NULL
		AND e.fkIdOrganoOCC = @pi_CatOrganismoId
		AND CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin
		AND p.fkIdOrigen = 37
	
	INSERT INTO @Promociones(
			OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,
			OrigenPromocionId,	Folio,				EsPromocionE, 
			Origen,				kIdElectronica,		NombreOrigen,
			OCC)
	SELECT	OrigenPromocion,	FechaPresentacion,	Registrada,
			ConArchivo,			EsDemanda,			Promovente,
			OrigenPromocionId,	Folio,				EsPromocionE, 
			Origen,				kIdElectronica,		NombreOrigen,
			OCC
	FROM #CTEDemandaElectronicasI
	WHERE No = 1
	PRINT '7. ' +  CONVERT(VARCHAR(100), GETDATE(),9) 

	/***** COMUNICACIONES OFICIALES ****/

		SELECT 
			No = ROW_NUMBER() OVER (PARTITION BY dem.kIdDemanda ORDER BY ISNULL(moa.bfirmado,0), moa.kIdArchivo),
			OrigenPromocion = ori.sNombreOrigenPromocion,	FechaPresentacion = dem.fFechaAlta,			Registrada = 0,		
			ConArchivo = 1,									EsDemanda = 1,								Promovente = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			OrigenPromocionId = dem.fkIdOrigen,				Folio = dem.kIdDemanda,						EsPromocionE = 1, 
			Origen = 29,									kIdElectronica = dem.kIdDemanda,			NombreOficial =  co.NombreOficial, 
			NombreOrigen = 'Comunicación Oficial',			Firmado = ISNULL(moa.bFirmado,0),			OCC = CAST(ISNULL(e.fkIdNumeroRegistroOCC,0) AS VARCHAR(150))
		INTO #CTEDemandaElectronicasCOE
		FROM JLOCCSISE_MOV_EnLinea p with(nolock)
		LEFT JOIN JL_MOV_Demanda dem WITH(NOLOCK) ON p.fkIdDemandaJL = dem.kIdDemanda and dem.fkIdEstatus=1
		LEFT JOIN JLOCCSISE_MOV_EnLinea AS e ON e.fkIdDemandaJL = dem.kIdDemanda----------
		LEFT JOIN ComunicacionesOficialesEnviadas coe WITH(NOLOCK) ON  dem.kIdDemanda = coe.fkIdDemanda
		LEFT JOIN JL_REL_DemandaSISE ps WITH(NOLOCK) ON p.fkIdDemandaJL = ps.fkIdDemanda 
		LEFT JOIN SISE3.CAT_OrigenPromocion  ori ON  ori.kIdOrigenPromocion	= 29
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = dem.fkIdUsuario
		LEFT JOIN CatOrganismos co ON coe.OrigenCatOrganismoId = co.CatOrganismoId
		LEFT JOIN JL_REL_DemandaArchivo da WITH(NOLOCK) ON dem.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1	
		WHERE coe.fkIdDemanda IS NOT NULL
		AND p.fkIdEstatus = 1 
		AND ps.fkIdDemanda IS NULL
		AND p.fkIdNeunSISE IS NULL
		AND p.fkIdOrganoOCC = @pi_CatOrganismoId
		AND moa.fkIdOrigen != 7  
		AND CAST( dem.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin

	INSERT INTO @Promociones(
			OrigenPromocion,		FechaPresentacion,		Registrada,
			ConArchivo,				EsDemanda,				Promovente,
			OrigenPromocionId,		Folio,					EsPromocionE, 
			Origen,					kIdElectronica,			NombreOficial,	
			NombreOrigen,			Firmado,				OCC)
	SELECT	OrigenPromocion,		FechaPresentacion,		Registrada,
			ConArchivo,				EsDemanda,				Promovente,
			OrigenPromocionId,		Folio,					EsPromocionE, 
			Origen,					kIdElectronica,			NombreOficial,	
			NombreOrigen,			Firmado,				OCC
	FROM #CTEDemandaElectronicasCOE
	WHERE No = 1
	ORDER BY  Folio
	PRINT '8. ' +  CONVERT(VARCHAR(100), GETDATE(),9) 

	IF (@TipoOrganoAsuntosJuridicos = 1)
	BEGIN
	SELECT 
		P.CuadernoId,P.Cuaderno,P.No,P.AsuntoNeunId,P.Expediente,P.CatTipoAsunto,P.CatTipoAsuntoId,P.TipoProcedimiento,	
		P.NumeroRegistro,		
		(select  TOP 1 ISNULL(CO.NombreOficial ,'') 
            from AsuntosRelacionados AR WITH(NOLOCK)
            INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
            INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
            INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
        WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = p.AsuntoNeunId ORDER BY IdAsuntoRela DESC) as OrigenPromocion,	
		
		(select  TOP 1 isnull( (A.AsuntoAlias + ' - ' + (SELECT X.Descripcion FROM CatTiposAsunto X WHERE X.CatTipoAsuntoId = A.CatTipoAsuntoId)),'')
            from AsuntosRelacionados AR WITH(NOLOCK)
            INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
            INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
            INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
        WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = p.AsuntoNeunId ORDER BY IdAsuntoRela DESC) as expedienteOrigen,

		P.Secretario,P.IdSecretario,P.SecretarioUserName,P.Mesa,P.FechaPresentacion,P.TipoPromociones,P.TipoContenido,					
		P.Promovente,P.IdPromovente,P.ClasePromovente,P.NumeroCopias,P.NumeroAnexos,P.Registrada,P.ConArchivo,
		P.EsDemanda,P.OrigenPromocionId,P.Folio,P.EsPromocionE,P.CatAutorizacionDocumentosId,P.Origen,P.NombreOrigen,
		P.Fojas,P.NumeroOrden,P.CatOrganismoId,	P.YearPromocion,P.kIdElectronica,P.FechaCaptura,P.EstadoAcuerdo,		
		P.NombreOficial,P.Firmado,P.NombreArchivo,
		SISE3.fnEstatusPromocion (P.CatAutorizacionDocumentosId , P.EsPromocionE, P.NombreArchivo, P.Origen ,P.kIdElectronica, P.ConArchivo, P.SecretarioUserName) AS EstatusPromocion,
		P.UsuarioCaptura,
		IIF(P.NumeroAlias IS NULL, dbo.fnAliasaNumero (P.Expediente), P.NumeroAlias) AS NumeroAlias, P.Observaciones, P.OCC, P.UsuarioCapturaCompleto
	FROM @Promociones P
	END
	ELSE BEGIN
	SELECT 
		CuadernoId,			Cuaderno,			No,					AsuntoNeunId,			Expediente,						CatTipoAsunto, 
		CatTipoAsuntoId,	TipoProcedimiento,	NumeroRegistro,		OrigenPromocion,		Secretario,						IdSecretario, 
		SecretarioUserName,	Mesa,				FechaPresentacion,	TipoPromociones,		TipoContenido,					Promovente,
		IdPromovente,		ClasePromovente,	NumeroCopias,		NumeroAnexos,			Registrada,						ConArchivo,
		EsDemanda,			OrigenPromocionId,	Folio,				EsPromocionE,			CatAutorizacionDocumentosId,	Origen,NombreOrigen,
		Fojas,NumeroOrden,	CatOrganismoId,		YearPromocion,		kIdElectronica,			FechaCaptura,					EstadoAcuerdo,		
		NombreOficial,		Firmado,			NombreArchivo,
		SISE3.fnEstatusPromocion (CatAutorizacionDocumentosId , EsPromocionE, NombreArchivo, Origen ,kIdElectronica, ConArchivo, SecretarioUserName) AS EstatusPromocion,UsuarioCaptura,
		IIF(NumeroAlias IS NULL, dbo.fnAliasaNumero (Expediente), NumeroAlias) AS NumeroAlias, Observaciones, OCC, UsuarioCapturaCompleto,ConAcuerdo
	FROM @Promociones
	END
END
