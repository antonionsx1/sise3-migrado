SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:    Christian Araujo - MS
-- Create date: 22/01/2024
-- Description: Obtiene los secretarios de un organismo
-- Basado en uspx_getSecretariosPorOrganismo
-- EXEC [SISE3].[pcConsultaSecretariosPorOrganismo] 148
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcConsultaSecretariosPorOrganismo]
        @pi_CatOrganismoId INT
AS
BEGIN
        SELECT DISTINCT 
                e.EmpleadoId 
                , SISE3.ConcatenarNombres(e.Nombre, e.ApellidoPaterno, e.ApellidoMaterno) AS Completo 
				, ISNULL(a.Descripcion, 'Sin mesa/área asignada') Area
				,a.fkIdTipoArea
        FROM CatEmpleados e WITH (NOLOCK) 
        --INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
		INNER JOIN SISE3.REL_RolEmpleadoXOrganismo eo ON e.EmpleadoId = eo.IdCatEmpleado
		LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.IdOrganismo
        WHERE e.StatusRegistro = 1 
        --AND eo.StatusRegistro = 1 
        --AND eo.cargoId IN (14,18,19) 
		AND a.fkIdTipoArea = 2
        AND (eo.IdOrganismo=@pi_CatOrganismoId OR e.EmpleadoId= 0) 
        AND e.EmpleadoId NOT IN (SELECT EmpleadoId FROM EmpleadoOrganismo WHERE CatOrganismoId in (3,1580) AND StatusRegistro=1) 
		AND a.fkIdTipoArea IS NOT NULL
        ORDER BY Completo 
END