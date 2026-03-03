USE SISE_NEW
GO

-- ====================================================================================
-- Author:        Erick Gonzalez
-- Create date:   06/06/2024
-- Description:   Este procedimiento almacenado obtiene una lista de empleados junto con 
--                su información asociada a un organismo específico y cargo(s) específico(s).
-- ====================================================================================

ALTER PROCEDURE [SISE3].[sp_ObtenerEmpleadosPorOrganismoYCargo]
    @pi_CatOrganismoId INT,        		-- Identificador del organismo
    @pi_CargoId NVARCHAR(MAX) = '15'	-- Lista de identificadores de cargos separados por comas
AS
BEGIN
    SET NOCOUNT ON;
WITH usuarios AS (
	SELECT DISTINCT
		e.EmpleadoId				AS EmpleadoId
		,0							AS CargoId
		,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS nombreOficial
		,e.USERNAME					AS UserName
		,a.Nombre					AS NombreArea
		,CASE WHEN fkIdTipoArea  IN (3) THEN 1 ELSE 0 END		AS EsCoordinador
		,0														AS EsOtrosUsaurios
		,2							AS Orden
	FROM AreasEmpleados ae WITH (NOLOCK)
	INNER JOIN Areas a WITH (NOLOCK)
		ON a.AreaId = ae.AreaId
		AND a.STATUSREG = 1
	INNER JOIN uvix_Empleados e WITH (NOLOCK)
		ON e.EmpleadoId = ae.EmpleadoId
    INNER JOIN EmpleadoOrganismo eo 
    	ON eo.EmpleadoId = e.EmpleadoId
    	AND eo.STATUSREGISTRO = 1
	WHERE a.CatOrganismoId = @pi_CatOrganismoId
		AND a.fkIdTipoArea  IN (3,5) 
	UNION ALL
	SELECT DISTINCT
		a.EmpleadoId				AS EmpleadoId
		,0							AS CargoId
		,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS nombreOficial
		,e.USERNAME					AS UserName
		,a.Nombre					AS NombreArea
		,CASE WHEN fkIdTipoArea  IN (3) THEN 1 ELSE 0 END		AS EsCoordinador
		,0														AS EsOtrosUsaurios
		,1							AS Orden
	FROM areas a WITH (NOLOCK)
	INNER JOIN uvix_Empleados e WITH (NOLOCK)
		ON e.EmpleadoId = a.EmpleadoId
	INNER JOIN EmpleadoOrganismo eo 
    	ON e.EmpleadoId = eo.EmpleadoId 
    	AND eo.STATUSREGISTRO = 1
	WHERE a.fkIdTipoArea IN (3,5)
		and a.CatOrganismoId = @pi_CatOrganismoId
		AND a.STATUSREG = 1
)
SELECT * 
FROM usuarios
UNION ALL
SELECT DISTINCT
	e.EmpleadoId					AS EmpleadoId
	,0								AS CargoId
	,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)			AS nombreOficial
	,e.USERNAME						AS UserName
	,'Otra Area'					AS NombreArea
	,0															AS EsCoordinador
	,1															AS EsOtrosUsaurios
	,3							AS Orden
FROM AsuntosDocumentos ad WITH (NOLOCK)
CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
INNER JOIN NotificacionElectronica_Personas nep ON ad.AsuntoID = nep.AsuntoId AND ad.AsuntoNeunId = nep.AsuntoNeunId AND ad.SintesisOrden = nep.SintesisOrden
LEFT JOIN NotificacionElectronica_AsignaActuario neaa WITH (NOLOCK) ON nep.AsuntoNeunId = neaa.AsuntoNeunId AND nep.SintesisOrden = neaa.SintesisOrden AND nep.NotElecId = neaa.NotElecId AND neaa.IESTATUSREG = 1
INNER JOIN dbo.CatEmpleados e ON e.EmpleadoId = neaa.IdUsuarioAsigno
LEFT JOIN usuarios U ON u.EmpleadoId = e.EmpleadoId
WHERE 1=1
	AND nep.StatusReg = 1 AND ad.StatusReg = 1
	AND nep.TipoNotificacion IN (1, 3, 5, 6, 11, 12)
	AND a.CatOrganismoId = @pi_CatOrganismoId
	AND nep.StatusReg = 1 
	AND ad.StatusReg = 1
	AND u.EmpleadoId IS NULL
ORDER BY
	EsCoordinador DESC
	,Orden
	,nombreOficial

END
