USE [SISE_NEW]
GO

-- =============================================
-- Author:       Martín Tovar
-- Alter date:  19/12/2024 - MTS - Se filtran cuya duración sea mayor a cero.
-- Alter date:  06/01/2025 - MTS - Se optimiza consulta
-- Description:  Obtiene el conteo de promociones en un rango de fechas determinado,
--               ligadas a un oficial y su OrganismoId, y cuenta cuántas de esas 
--               promociones han sido turnadas, así como el total de promociones
--               del año actual por oficial, teniendo en cuenta NumeroOrden y AsuntoNeunId.
-- EXEC [SISE3].[spObtenerConteoPromociones] '2024-01-01', '2024-08-15', 148, 122
-- =============================================

ALTER PROCEDURE [SISE3].[spObtenerConteoPromociones]
    @pi_FechaInicio DATETIME,
    @pi_FechaFin DATETIME,
    @pi_CatOrganismoId INT,
    @pi_CargoId INT = 22
AS
BEGIN
SET NOCOUNT ON;

--Variables para fechas de inicio de año anterior y año actual
DECLARE @FechaPresentacionCicloAnual DATE = CAST(DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -11, GETDATE()), -1)) AS DATETIME)
DECLARE @FechaPresentacionPeriodoAnual DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

--Eliminar tabla temporal
DROP TABLE IF EXISTS #Proms
DROP TABLE IF EXISTS #Oficiales

--Obtener promociones en tabla temporal
SELECT 
	AsuntoNeunId
	,Expediente
	,CatTipoAsunto
	,NumeroRegistro
	,FechaPresentacion
	,FechaActualiza
	,IdUsuarioCaptura
	,TiempoAsignacion	= CASE WHEN ISNULL(TiempoAsignacion,0) < 60 THEN 1 ELSE ISNULL(TiempoAsignacion,0) / 60 END			--Convertir a minutos
	,EstatusPromocion	= [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,NULL, ConArchivo, SecretarioUserName) 
	,EsCicloAnual		= CAST(CASE WHEN FechaPresentacion >= @FechaPresentacionCicloAnual AND FechaPresentacion <= @pi_FechaFin THEN 1 ELSE 0 END AS BIT)
	,EsPeriodoAnual		= CAST(CASE WHEN FechaPresentacion >= @FechaPresentacionPeriodoAnual AND FechaPresentacion <= @pi_FechaFin THEN 1 ELSE 0  END AS BIT)
	,EsPeriodoReporte	= CAST(CASE WHEN FechaPresentacion >= @pi_FechaInicio AND FechaPresentacion <= @pi_FechaFin THEN 1 ELSE 0 END AS BIT)
INTO #Proms
FROM (
	SELECT
		rn = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId, p.NumeroOrden, p.OrigenPromocion, p.YearPromocion ORDER BY p.FechaPresentacion)
		,p.AsuntoNeunId
		,Expediente			= a.AsuntoAlias
		,a.CatTipoAsunto
		,p.NumeroRegistro
		,FechaPresentacion	= p.FechaPresentacion + p.HoraPresentacion
		,FechaActualiza		= p.FechaActualiza
		,ConArchivo 		= IIF(pa.NombreArchivo IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0),1)
		,SecretarioUserName	= s.UserName
		,EsPromocionE		= IIF(p.OrigenPromocion IN (6,14,22,5,15,29,31),1,0)
		,ad.CatAutorizacionDocumentosId
		,pa.NombreArchivo
		,Origen				= IIF(p.OrigenPromocion IN (6,14,22,5,15,29),p.OrigenPromocion,0)
		,IdUsuarioCaptura	= p.RegistroEmpleadoId
		,TiempoAsignacion	= DATEDIFF(SECOND, p.FechaPresentacion + p.HoraPresentacion, p.FechaAlta)
	FROM Promociones p WITH(NOLOCK) 
	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
	LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId AND pa.CatOrganismoId = p.CatOrganismoId AND pa.NumeroOrden = p.NumeroOrden
		AND pa.Origen = p.OrigenPromocion AND pa.YearPromocion = p.YearPromocion AND pa.StatusArchivo IN (1) AND pa.ClaseAnexo = 0 AND pa.EstatusArchivo = 1
	LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId and ad.StatusReg = 1
	LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario and s.StatusRegistro=1
	WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.FechaPresentacion >= @FechaPresentacionCicloAnual AND p.FechaPresentacion < DATEADD(DAY, 1, @pi_FechaFin)
		AND p.RegistroEmpleadoId IS NOT NULL
		AND p.FechaPresentacion + p.HoraPresentacion <= p.FechaAlta
	) p 
WHERE p.rn = 1


--Crear indice
CREATE INDEX ix_01 ON #Proms(IdUsuarioCaptura)

-- Crear una tabla temporal para almacenar los oficiales
CREATE TABLE #Oficiales (
    EmpleadoId BIGINT,
    NombreOficial VARCHAR(255),
    UserName VARCHAR(255),
	isOther BIT
)
-- Insertar los oficiales en la tabla temporal
INSERT INTO #Oficiales (EmpleadoId, NombreOficial, UserName, isOther)
EXEC [SISE3].[pcObtieneCatalogoOficiales] @pi_CatOrganismoId, @pi_CargoId

--Crear indice
CREATE INDEX ix_01 ON #Oficiales(EmpleadoId)


--Main
SELECT
	o.EmpleadoId
	,MAX(o.NombreOficial)				AS NombreOficial
	,MAX(o.UserName)					AS UserName
	,o.isOther							AS isOther
	,TotalPromociones					= SUM(CASE WHEN EsPeriodoReporte = 1 AND EstatusPromocion IN (2, 4) THEN 1 ELSE 0 END)
	,PromocionesTurnadas				= SUM(CASE WHEN EsPeriodoReporte = 1 AND EstatusPromocion = 4 THEN 1 ELSE 0 END)
	,TotalPromocionesAnoActual			= SUM(CASE WHEN EsPeriodoAnual = 1 AND EstatusPromocion = 4 THEN 1 ELSE 0 END)
	,PromedioPromocionesTurnadasPorDia	= ISNULL(SUM(CASE WHEN EsPeriodoAnual = 1 AND EstatusPromocion = 4 THEN 1 end),0) /
											CASE WHEN COUNT(DISTINCT CASE WHEN EsPeriodoAnual = 1 AND EstatusPromocion = 4 THEN FechaActualiza END) > 0 THEN COUNT(DISTINCT CASE WHEN EsPeriodoAnual = 1 AND EstatusPromocion = 4 THEN FechaActualiza END)
												ELSE 1
											END
	,TiempoPromedioMins					= ISNULL(AVG(CASE WHEN EsPeriodoAnual = 1 AND EstatusPromocion = 4 THEN TiempoAsignacion end),0)
FROM #Proms p 
INNER JOIN #Oficiales o
	ON o.EmpleadoId = p.IdUsuarioCaptura
GROUP BY o.EmpleadoId
	,o.isOther
ORDER BY NombreOficial

--Eliminar tabla temporal
DROP TABLE IF EXISTS #Proms
DROP TABLE IF EXISTS #Oficiales

SET NOCOUNT OFF;

END
