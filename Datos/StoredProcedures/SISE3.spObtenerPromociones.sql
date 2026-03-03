-- =============================================
-- Autor:		Martín Tovar
-- Fecha:		16/08/2024
-- Objetivo:	Obtiene los datos necesarios para el dashboard de Oficilía,
/****** EXEC SISE3.spObtenerPromociones 147, '2024-07-01', '2024-08-15', NULL	*****/
-- =============================================

CREATE PROCEDURE [SISE3].[spObtenerPromociones] (
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	  
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE
	@pi_FechaPresentacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE
	@pi_FechaPresentacionFin DATE = NULL,
	-- REPRESENTA EL IDENTIFICADOR DE EMPLEADO - PUEDE LLEGAR NULA
	@pi_EmpleadoId INT = 0
	)
AS
BEGIN
SET NOCOUNT ON

--Variables para fechas de inicio de año anterior y año actual
DECLARE @pi_FechaPresentacionCicloAnual DATE = CAST(DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -11, GETDATE()), -1)) AS DATETIME)
DECLARE @pi_FechaPresentacionPeriodoAnual DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

DROP TABLE IF EXISTS #Promociones

--Crear tabla temporal
CREATE TABLE #Promociones (
	[NO]							INT				NULL
	,AsuntoNeunId					BIGINT			NULL
	,Expediente						VARCHAR(50)		NULL
	,CatTipoAsunto					VARCHAR(100)	NULL
	,CatTipoAsuntoId				INT				NULL
	,TipoProcedimiento				VARCHAR(500)	NULL
	,Cuaderno						VARCHAR(250)	NULL
	,NumeroRegistro					INT				NULL
	,OrigenPromocion				VARCHAR(50)		NULL
	,IdSecretario					INT				NULL
	,SecretarioUserName				VARCHAR(550)	NULL
	,Mesa							VARCHAR(50)		NULL
	,FechaPresentacion				DATETIME		NULL
	,FechaActualiza					DATETIME		NULL
	,Registrada						BIT				NULL
	,ConArchivo						BIT				NULL
	,EsDemanda						BIT				NULL
	,OrigenPromocionId				INT				NULL
	,Folio							INT				NULL
	,EsPromocionE					BIT				NULL
	,CatAutorizacionDocumentosId	INT				NULL
	,NombreArchivo					VARCHAR(300)	NULL
	,Origen							INT				NULL
	,NombreOrigen					VARCHAR(250)	NULL
	,NumeroOrden					INT				NULL
	,IdUsuarioCaptura				INT				NULL
	,UsuarioCaptura					VARCHAR(550)	NULL
	,CatOrganismoId					INT				NULL
	,YearPromocion					INT				NULL
	,kIdElectronica					BIGINT			NULL
	,FechaCaptura					DATETIME		NULL
	,TiempoAsignacion				INT				NULL
	,NumeroAlias					INT				NULL
	,EstadoAcuerdo					INT				NULL
	,CuadernoId						INT				NULL
	,AsuntoDocumentoId				INT				NULL
)

Insert into #Promociones
SELECT *
FROM (
SELECT
	RN = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion)
	,p.AsuntoNeunId
	,a.AsuntoAlias	AS Expediente
	,a.CatTipoAsunto
	,a.CatTipoAsuntoId
	,a.TipoProcedimiento
	,dbo.funRecuperaCatalogoDependienteDescripcion(527,p.TipoCuaderno)	AS Cuaderno
	,p.NumeroRegistro
	,o.sNombreOrigenPromocion OrigenPromocion
	,SecretarioId = p.Secretario
	,s.UserName
	,Mesa = p.Mesa
	,p.FechaPresentacion + p.HoraPresentacion	AS FechaPresentacion
	,p.FechaActualiza	AS FechaActualiza
	,Registrada = 1
	,ConArchivo = IIF(pa.AsuntoNeunId IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0),1)
	,EsDemanda = 0
	,OrigenPromocionId = p.OrigenPromocion
	,Folio = 0
	,EsPromocionE = IIF(p.OrigenPromocion IN (6,14,22,5,15,29,31),1,0)
	,ad.CatAutorizacionDocumentosId
	,pa.NombreArchivo
	,Origen = IIF(p.OrigenPromocion IN (6,14,22,5,15,29),p.OrigenPromocion,0)
	,NombreOrigen = CASE ISNULL(p.OrigenPromocion,0) 
		WHEN 0	THEN 'Promoción Física'
		WHEN 6	THEN 'Promoción Electrónica'
		WHEN 5	THEN 'Demanda Electrónica'
		WHEN 29	THEN 'Comunicación Oficial'
		WHEN 14	THEN 'Promoción Electrónica de Interconexión'
		WHEN 22	THEN 'Promoción Electrónica de Interconexión entre Órganos Jurisdiccionales'				
		WHEN 15	THEN 'Demanda Electrónica Interconexión'
		WHEN 31	THEN 'Demanda Electrónica'
		ELSE ''
		END
	,p.NumeroOrden
	,p.RegistroEmpleadoId
	,un.UserName	AS UsuarioCaptura
	,p.CatOrganismoId
	,p.YearPromocion
	,NULL 			AS kIdElectronica
	,p.fechaAlta	AS FechaCaptura
	,DATEDIFF(MINUTE, p.FechaPresentacion + p.HoraPresentacion, p.FechaAlta)	AS TiempoAsignacion
	,a.NumeroAlias
	,SISE3.fnEstadoAutorizacion(ad.AsuntoDocumentoId, ad.CatAutorizacionDocumentosId)	AS EstadoAutorizacion
    ,p.TipoCuaderno CuadernoId
	,p.AsuntoDocumentoId
FROM Promociones p WITH(NOLOCK) 
CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
LEFT JOIN tbx_CatTiposAsunto tac WITH(NOLOCK) ON p.TipoCuaderno = tac.CuadernoId AND p.AsuntoId = tac.CatTipoAsuntoId
LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON p.OrigenPromocion = o.kIdOrigenPromocion	
LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId AND pa.CatOrganismoId = p.CatOrganismoId AND pa.NumeroOrden = p.NumeroOrden
	AND pa.Origen = p.OrigenPromocion AND pa.YearPromocion = p.YearPromocion AND pa.StatusArchivo IN (1) AND pa.ClaseAnexo = 0 AND pa.EstatusArchivo = 1
LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario and s.StatusRegistro=1
LEFT JOIN CatPromocion cp WITH(NOLOCK) ON cp.CatalogoPromocionId = p.TipoContenido and cp.StatusReg =1
LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId and ad.StatusReg=1
LEFT JOIN CatEmpleados un WITH(NOLOCK) ON un.EmpleadoId = p.RegistroEmpleadoId and un.StatusRegistro=1
WHERE  p.StatusReg = 1
	AND p.CatOrganismoId = @pi_CatOrganismoId
	AND (CONVERT(DATE,p.FechaPresentacion) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)
	AND (p.RegistroEmpleadoId = @pi_EmpleadoId OR @pi_EmpleadoId = 0)
) p 
WHERE p.RN = 1


----Obtener Promociones electrónicas
--PROMOCIONES ELECTRÓNICAS 
INSERT INTO #Promociones(AsuntoNeunId				,Expediente				,CatTipoAsunto		,CatTipoAsuntoId	,TipoProcedimiento		,OrigenPromocion			,FechaPresentacion
						,Registrada					,ConArchivo				,EsDemanda			,OrigenPromocionId	,Folio					,EsPromocionE
						,Origen						,kIdElectronica			,NombreOrigen)
SELECT					p.fkIdAsuntoNeun			,a.AsuntoAlias			,a.CatTipoAsunto	,a.CatTipoAsuntoId	,a.TipoProcedimiento	,o.sNombreOrigenPromocion,	p.fFechaAlta
						,0							,1						,0					,p.fkIdOrigen		,p.kIdPromocion 		,1
						,6							,p.kIdPromocion			,'Promoción Electrónica'
FROM JL_MOV_Promocion p WITH (nolock) 
CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a				
LEFT JOIN JL_REL_PromocionSISE ps WITH(NOLOCK) ON p.kIdPromocion = ps.fkIdPromocion and p.fkIdAsuntoNeun = ps.AsuntoNeunId and p.fkIdOrgano = ps.CatOrganismoId
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON o.kIdOrigenPromocion = IIF(p.fkIdOrigen = 30, 29, IIF(p.fkIdOrigen = 22,22,5))
INNER JOIN JL_REL_PromocionArchivo pa WITH(NOLOCK) ON p.kIdPromocion = pa.fkIdPromocion and pa.fkIdEstatus = 1
WHERE ps.kIdPromocionSISE IS NULL
    AND P.fkIdOrigen != 22
	AND a.AsuntoNeunId = p.fkIdAsuntoNeun
	AND a.CatOrganismoId = p.fkIdOrgano
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

--PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN 
INSERT INTO #Promociones(AsuntoNeunId				,Expediente				,CatTipoAsunto		,CatTipoAsuntoId	,TipoProcedimiento		,OrigenPromocion			,FechaPresentacion
						,Registrada					,ConArchivo				,EsDemanda			,OrigenPromocionId	,Folio					,EsPromocionE
						,Origen						,kIdElectronica			,NombreOrigen)
SELECT					p.fkIdAsuntoNeun			,a.AsuntoAlias			,a.CatTipoAsunto	,a.CatTipoAsuntoId	,a.TipoProcedimiento	,o.sNombreOrigenPromocion	,p.fFechaAlta
						,0							,1						,0					,p.fkIdOrigen		,p.kIdPromocion			,1
						,14							,p.kiIdFolio			,'Promoción Electrónica de Interconexión'
FROM ICOIJ_MOV_Promocion p WITH (nolock) 
CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
LEFT JOIN ICOIJ_REL_PromocionSISE ps WITH(NOLOCK) ON p.kIdPromocion = ps.fkIdPromocion AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON o.kIdOrigenPromocion	= 14
LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON ad.AsuntoNeunId = p.fkIdAsuntoNeun and ad.StatusReg=1
LEFT JOIN ICOIJ_REL_DemandaPromocionSolicitud dps WITH(NOLOCK) ON dps.fkiIdFolio = p.kiIdFolio and dps.iEstatus=1
WHERE ps.kIdPromocionSISE IS NULL
	AND a.AsuntoNeunId = p.fkIdAsuntoNeun
	AND a.CatOrganismoId = p.fkIdOrgano 
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

--PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES SIN EXPEDIENTE 
INSERT INTO #Promociones(AsuntoNeunId				,OrigenPromocion		,FechaPresentacion	,Registrada			,ConArchivo				,EsDemanda
						,OrigenPromocionId			,Folio					,EsPromocionE		,Origen				,kIdElectronica			,NombreOrigen)
SELECT					p.fkIdAsuntoNeun		,o.sNombreOrigenPromocion	,p.fFechaAlta		,0					,1						,0
						,p.fkIdOrigen				,p.kIdPromocion			,1					,22					,p.kiIdFolio			,'Promoción Electrónica de Interconexión entre Órganos JurisdiccionalesSE'
FROM IOJ_MOV_PromocionOJ p WITH(NOLOCK)
LEFT JOIN IOJ_REL_PromocionSISE ps WITH(NOLOCK) ON p.kiIdFolio = ps.fkIdPromocion 
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON o.kIdOrigenPromocion = 22
WHERE ps.fkIdPromocion IS NULL
    AND P.fkIdOrigen = 22
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

--PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES CON EXPEDIENTE 
INSERT INTO #Promociones(AsuntoNeunId				,Expediente				,CatTipoAsunto		,CatTipoAsuntoId	,TipoProcedimiento		,OrigenPromocion			,FechaPresentacion
						,Registrada					,ConArchivo				,EsDemanda			,OrigenPromocionId	,Folio					,EsPromocionE
						,Origen						,kIdElectronica			,NombreOrigen)
SELECT					p.fkIdAsuntoNeun			,a.AsuntoAlias			,a.CatTipoAsunto	,a.CatTipoAsuntoId	,a.TipoProcedimiento	,o.sNombreOrigenPromocion	,p.fFechaAlta
						,0							,1						,0					,p.fkIdOrigen 		,p.kIdPromocion 		,1
						,22							,p.kIdPromocion			, 'Promoción Electrónica de Interconexión entre Órganos JurisdiccionalesCE'
FROM JL_MOV_Promocion p WITH(NOLOCK)
CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
LEFT JOIN  JL_REL_PromocionSISE ps WITH(NOLOCK) ON p.kIdPromocion = ps.fkIdPromocion 
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON o.kIdOrigenPromocion	= 22
WHERE ps.fkIdPromocion IS NULL
    AND p.fkIdOrigen = 22
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

--DEMANDAS ELECTRÓNICAS	
INSERT INTO #Promociones(OrigenPromocion			,FechaPresentacion		,Registrada			,ConArchivo			,EsDemanda
						,OrigenPromocionId			,Folio					,EsPromocionE		,Origen				,kIdElectronica			,NombreOrigen)
SELECT DISTINCT			o.sNombreOrigenPromocion	,p.fFechaAlta			,0					,1					,1
						,p.fkIdOrigen				,p.kIdDemanda			,1					,5					,p.kIdDemanda			,'Demanda Electrónica'
FROM JL_MOV_Demanda p WITH (nolock) 
INNER JOIN JLOCCSISE_MOV_EnLinea e WITH(NOLOCK) ON e.fkIdDemandaJL = p.kIdDemanda
INNER JOIN JL_REL_DemandaArchivo da WITH(NOLOCK) on p.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1	
LEFT JOIN JL_REL_DemandaSISE rdem WITH(NOLOCK) on rdem.fkIdDemanda = p.kIdDemanda
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON o.kIdOrigenPromocion = IIF(p.fkIdOrigen = 29, 29,5)
LEFT JOIN ComunicacionesOficialesEnviadas coe WITH(NOLOCK) ON p.kIdDemanda = coe.fkIdDemanda 
WHERE coe.fkIdDemanda IS NULL
	AND rdem.fkIdDemanda IS NULL
	AND p.fkIdEstatus = 1 and e.fkIdEstatus=1
	AND e.fkIdNeunSISE IS NULL
	AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

--DEMANDAS ELECTRÓNICAS INTERCONEXIÓN
INSERT INTO #Promociones(OrigenPromocion			,FechaPresentacion		,Registrada			,ConArchivo			,EsDemanda
						,OrigenPromocionId			,Folio					,EsPromocionE		,Origen				,kIdElectronica			,NombreOrigen)
SELECT DISTINCT			o.sNombreOrigenPromocion	,p.fFechaAlta			,0					,1					,1
						,p.fkIdOrigen				,p.kiIdFolio			,1					,15					,p.kiIdFolio			,'Demanda Electrónica Interconexión'
FROM ICOIJ_MOV_Demanda p WITH(NOLOCK) 
INNER JOIN ICOIJOCCSISE_MOV_EnLinea e WITH(NOLOCK) ON e.fkiIdFolio = p.kIdDemanda 
LEFT JOIN ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = p.kIdDemanda 
LEFT JOIN SISE3.CAT_OrigenPromocion o WITH(NOLOCK) ON o.kIdOrigenPromocion	= 5
LEFT JOIN ComunicacionesOficialesEnviadas coe WITH(NOLOCK) ON p.kIdDemanda = coe.fkIdDemanda 
WHERE coe.fkIdDemanda IS NULL
	AND irdem.fkIdDemanda IS NULL
	AND p.fkIdEstatus = 1  
	AND e.fkIdNeunSISE IS NULL
	AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	AND p.fkIdOrigen = 37
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

--COMUNICACIONES OFICIALES
INSERT INTO #Promociones(OrigenPromocion			,FechaPresentacion		,Registrada			,ConArchivo			,EsDemanda
						,OrigenPromocionId			,Folio					,EsPromocionE		,Origen				,kIdElectronica			,NombreOrigen)
SELECT DISTINCT			ori.sNombreOrigenPromocion	,dem.fFechaAlta			,0					,1					,1
						,dem.fkIdOrigen				,dem.kIdDemanda			,1					,29					,dem.kIdDemanda			,'Comunicación Oficial'
FROM JLOCCSISE_MOV_EnLinea p WITH(NOLOCK) 
LEFT JOIN JL_MOV_Demanda dem WITH(NOLOCK) ON p.fkIdDemandaJL = dem.kIdDemanda and dem.fkIdEstatus = 1
LEFT JOIN ComunicacionesOficialesEnviadas coe WITH(NOLOCK) ON dem.kIdDemanda = coe.fkIdDemanda
LEFT JOIN JL_REL_DemandaSISE ps WITH(NOLOCK) ON p.fkIdDemandaJL = ps.fkIdDemanda 
LEFT JOIN SISE3.CAT_OrigenPromocion ori WITH(NOLOCK) ON ori.kIdOrigenPromocion = 29
WHERE coe.fkIdDemanda IS NOT NULL
	AND p.fkIdEstatus = 1 
	AND ps.fkIdDemanda IS NULL
	AND p.fkIdOrganoOCC = @pi_CatOrganismoId
	AND (@pi_FechaPresentacionIni IS NULL OR CAST( dem.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin)

	
--Consulta principal
SELECT 
	*
	,SUM(CASE WHEN EsCicloAnual = 1 THEN 1 ELSE 0 END) OVER() 									AS Total
	,SUM(CASE WHEN EstatusPromocion IN (1) AND EsCicloAnual = 1 THEN 1 ELSE 0 END) OVER() 		AS SinCaptura
	,SUM(CASE WHEN EstatusPromocion IN (2) AND EsCicloAnual = 1 THEN 1 ELSE 0 END) OVER() 		AS Capturadas
	,SUM(CASE WHEN EstatusPromocion IN (4) AND EsCicloAnual = 1 THEN 1 ELSE 0 END) OVER() 		AS Asignadas
FROM (
	SELECT DISTINCT 
		Cuaderno
		,CuadernoId
		,AsuntoNeunId
		,Expediente
		,CatTipoAsunto
		,CatTipoAsuntoId
		,TipoProcedimiento
		,NumeroRegistro
		,OrigenPromocion
		,Origen
		,NombreOrigen
		,OrigenPromocionId
		,IdSecretario
		,SecretarioUserName
		,Mesa
		,FechaPresentacion
		,FechaActualiza
		,Registrada
		,ConArchivo
		,EsDemanda
		,Folio
		,EsPromocionE
		,EsCicloAnual		= CAST(CASE WHEN (CONVERT(DATE,[FechaPresentacion]) BETWEEN @pi_FechaPresentacionCicloAnual AND @pi_FechaPresentacionFin) THEN 1 ELSE 0 END AS BIT)
		,EsPeriodoAnual		= CAST(CASE WHEN (CONVERT(DATE,[FechaPresentacion]) BETWEEN @pi_FechaPresentacionPeriodoAnual AND @pi_FechaPresentacionFin) THEN 1 ELSE 0 END AS BIT)
		,EsPeriodoReporte	= CAST(CASE WHEN (CONVERT(DATE,[FechaPresentacion]) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin) THEN 1 ELSE 0 END AS BIT)
		,CatAutorizacionDocumentosId
		,NumeroOrden
		,[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) AS EstatusPromocion
		,IdUsuarioCaptura
		,UsuarioCaptura
		,YearPromocion
		,kIdElectronica
		,FechaCaptura
		,TiempoAsignacion
		,IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) AS NumeroAlias
		,EstadoAcuerdo
		,AsuntoDocumentoId
	FROM  #Promociones
) t

DROP TABLE IF EXISTS #Promociones

SET NOCOUNT OFF
END
