USE SISE_NEW;
GO

-- =============================================
-- Author:       Martín Tovar
-- Create date:  17/05/2024
-- Alter date:  06/01/2025 - MTS - Se optimiza consulta
-- Alter date:  19/12/2024 - MTS - Se filtran sólo las Turnadas
-- Description:  Obtiene el conteo de promociones en un rango de fechas determinado,
--               ligadas a un oficial y su OrganismoId, y cuenta cuántas de esas 
--               promociones han sido turnadas, así como el total de promociones
--               del año actual por oficial, teniendo en cuenta NumeroOrden y AsuntoNeunId.
-- EXEC [SISE3].[spObtenerTiposAsuntoPorMes] 6712, 148, '2024-01-01', '2024-08-15'
-- =============================================

ALTER PROCEDURE [SISE3].[spObtenerTiposAsuntoPorMes]
    @pi_EmpleadoId BIGINT,
    @pi_CatOrganismoId INT,
    @pi_FechaInicio DATE,
    @pi_FechaFin DATE
    
AS
BEGIN
	
SET NOCOUNT ON;

--Variables para fechas de inicio de año anterior y año actual
DECLARE @FechaPresentacionCicloAnual DATE = CAST(DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -11, GETDATE()), -1)) AS DATETIME)
DECLARE @FechaPresentacionPeriodoAnual DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

--Eliminar tabla temporal
DROP TABLE IF EXISTS #Proms

--Obtener promociones en tabla temporal
SELECT 
	AsuntoNeunId
	,Expediente
	,CatTipoAsunto
	,FechaPresentacion
	,IdUsuarioCaptura
	,EstatusPromocion	= [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,NULL, ConArchivo, SecretarioUserName) 
INTO #Proms
FROM (
	SELECT
		rn = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId, p.NumeroOrden, p.OrigenPromocion, p.YearPromocion ORDER BY p.FechaPresentacion)
		,p.AsuntoNeunId
		,Expediente			= a.AsuntoAlias
		,a.CatTipoAsunto
		,FechaPresentacion	= p.FechaPresentacion + p.HoraPresentacion
		,EsPromocionE		= IIF(p.OrigenPromocion IN (6,14,22,5,15,29,31),1,0)
		,ad.CatAutorizacionDocumentosId
		,pa.NombreArchivo
		,Origen				= IIF(p.OrigenPromocion IN (6,14,22,5,15,29),p.OrigenPromocion,0)
		,IdUsuarioCaptura	= p.RegistroEmpleadoId
		,ConArchivo = IIF(pa.AsuntoNeunId IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29,30,31),1,0),1)
		,SecretarioUserName = ce.UserName
	FROM Promociones p WITH(NOLOCK) 
	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
	LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId AND pa.CatOrganismoId = p.CatOrganismoId AND pa.NumeroOrden = p.NumeroOrden
		AND pa.Origen = p.OrigenPromocion AND pa.YearPromocion = p.YearPromocion AND pa.StatusArchivo IN (1) AND pa.ClaseAnexo = 0 AND pa.EstatusArchivo = 1
	LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId and ad.StatusReg = 1
	LEFT JOIN CatEmpleados ce WITH(NOLOCK) ON ce.EmpleadoId = p.Secretario and ce.StatusRegistro=1
	WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.FechaPresentacion >= @FechaPresentacionCicloAnual AND p.FechaPresentacion < DATEADD(DAY, 1, @pi_FechaFin)
		AND (p.RegistroEmpleadoId = @pi_EmpleadoId)
		AND p.FechaPresentacion + p.HoraPresentacion <= p.FechaAlta
    	AND p.RegistroEmpleadoId = @pi_EmpleadoId
		AND p.FechaPresentacion + p.HoraPresentacion >= @pi_FechaInicio AND p.FechaPresentacion + p.HoraPresentacion <= @pi_FechaFin
) p 
WHERE p.rn = 1

--Crear indice
CREATE INDEX ix_01 ON #Proms(FechaPresentacion)

--Obtener tabla con Meses
SET LANGUAGE Spanish
DECLARE @meses TABLE (
	NoMes	INT,
    Mes		VARCHAR(20),
    Orden	INT
)
-- Insertar meses en orden descendente desde el mes actual
DECLARE @mesActual INT = MONTH(GETDATE())
DECLARE @contador INT = 1
WHILE @contador <= 12
BEGIN
    INSERT INTO @meses (NoMes, Mes, Orden)
    VALUES (MONTH(DATEFROMPARTS(YEAR(GETDATE()),@mesActual,1)), DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()),@mesActual,1)), @contador)
    SET @mesActual = @mesActual - 1;
    IF @mesActual = 0 
        SET @mesActual = 12
    SET @contador = @contador + 1
END  


--Main
SELECT 
    m.Mes
    ,CatTipoAsunto				AS TipoAsunto
    ,COUNT(EstatusPromocion)	AS Total
FROM @meses m
INNER JOIN #Proms p ON MONTH(p.FechaPresentacion) = m.NoMes  
	AND EstatusPromocion = 4
GROUP BY 
    m.Mes
	,CatTipoAsunto
	,m.Orden
ORDER BY Orden

--Eliminar tabla temporal
DROP TABLE IF EXISTS #Proms

SET NOCOUNT OFF;

END