USE [SISE_NEW]
GO

-- =============================================
-- Author:       Martín Tovar
-- Create date:  17/05/2024
-- Alter date:  19/12/2024 - MTS - Se filtran cuya duración sea mayor a cero.
-- Alter date:  06/01/2025 - MTS - Se optimiza consulta
-- Description:  Obtiene el conteo de promociones en un rango de fechas determinado,
--               ligadas a un oficial y su OrganismoId, y cuenta cuántas de esas 
--               promociones han sido turnadas, así como el total de promociones
--               del año actual por oficial, teniendo en cuenta NumeroOrden y AsuntoNeunId.
--EXEC [SISE3].[spDiferenciaTiemposPromocion] 6712, 148, '2024-01-01', '2024-08-15'
-- =============================================

ALTER PROCEDURE [SISE3].[spDiferenciaTiemposPromocion]
    @pi_EmpleadoId BIGINT,
	@pi_CatOrganismoId INT,
    @pi_FechaInicio DATETIME,
    @pi_FechaFin DATETIME
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
	,NumeroRegistro
	,NombreCorto
	,FechaPresentacion
	,FechaActualiza
	,IdUsuarioCaptura
	,FechaCaptura
	,EstatusPromocion	= [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,NULL, ConArchivo, SecretarioUserName) 
INTO #Proms
FROM (
	SELECT
		rn = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId, p.NumeroOrden, p.OrigenPromocion, p.YearPromocion ORDER BY p.FechaPresentacion)
		,p.AsuntoNeunId
		,Expediente			= a.AsuntoAlias
		,p.NumeroRegistro
		,NombreCorto		= cd.NombreCorto	
		,FechaPresentacion	= p.FechaPresentacion + p.HoraPresentacion
		,FechaActualiza		= p.FechaActualiza
		,ConArchivo 		= IIF(pa.NombreArchivo IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0),1)
		,SecretarioUserName	= s.UserName
		,EsPromocionE		= IIF(p.OrigenPromocion IN (6,14,22,5,15,29,31),1,0)
		,ad.CatAutorizacionDocumentosId
		,pa.NombreArchivo
		,Origen				= IIF(p.OrigenPromocion IN (6,14,22,5,15,29),p.OrigenPromocion,0)
		,IdUsuarioCaptura	= p.RegistroEmpleadoId
		,FechaCaptura		= p.fechaAlta
	FROM Promociones p WITH(NOLOCK) 
	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
	LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId AND pa.CatOrganismoId = p.CatOrganismoId AND pa.NumeroOrden = p.NumeroOrden
		AND pa.Origen = p.OrigenPromocion AND pa.YearPromocion = p.YearPromocion AND pa.StatusArchivo = 1 AND pa.ClaseAnexo = 0 AND pa.EstatusArchivo = 1
	LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId and ad.StatusReg = 1
	LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario and s.StatusRegistro=1
	LEFT JOIN (			
		SELECT 
			a.AsuntoNeunId 
			,ta.NombreCorto
		FROM Asuntos a WITH(NOLOCK)
		INNER JOIN CatTiposAsunto cta WITH (NOLOCK) on a.CatTipoAsuntoId = cta.CatTipoAsuntoId
		LEFT JOIN (
				SELECT 
					nombreCorto
					,CatTipoAsuntoId
					,row = ROW_NUMBER() OVER(PARTITION BY CatTipoAsuntoId ORDER BY nombreCorto) 
				FROM dbo.tbx_CatTiposAsunto WITH (NOLOCK)
		) ta ON cta.CatTipoAsuntoId = ta.CatTipoAsuntoId AND row = 1
	) cd
		ON cd.AsuntoNeunId = p.AsuntoNeunId
	WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.FechaPresentacion >= @FechaPresentacionCicloAnual AND p.FechaPresentacion < DATEADD(DAY, 1, @pi_FechaFin)
		AND (p.RegistroEmpleadoId = @pi_EmpleadoId)
		AND p.FechaPresentacion + p.HoraPresentacion <= p.FechaAlta
		AND p.RegistroEmpleadoId = @pi_EmpleadoId
		AND p.FechaPresentacion + p.HoraPresentacion >= @pi_FechaInicio AND p.FechaPresentacion + p.HoraPresentacion <= @pi_FechaFin
) p 
WHERE p.rn = 1
 

--Main
SELECT
    p.IdUsuarioCaptura		AS RegistroEmpleadoId
    ,p.NumeroRegistro		AS NumeroRegistro
    ,p.NombreCorto			AS NombreCorto
    ,HoraMinutoAlta			= FORMAT(CAST(p.FechaPresentacion AS DATETIME), 'HH:mm')
	,HoraMinutoTurnado		= FORMAT(ISNULL(p.FechaActualiza, p.FechaCaptura), 'HH:mm')
    ,Dias					= DATEDIFF(D, p.FechaPresentacion, ISNULL(p.FechaActualiza, p.FechaCaptura))
FROM #Proms p
WHERE EstatusPromocion = 4
ORDER BY NumeroRegistro
	
--Eliminar tabla temporal
DROP TABLE IF EXISTS #Proms

SET NOCOUNT OFF;

END
