SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 10/01/2024
-- Description: Obtiene el catalogo de zonas y actuario por organismo
-- EXEC [SISE3].[pcCatalogoZonas]  180
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[pcCatalogoZonas] (@pi_CatOrganismoId int)
AS
SELECT ar.AreaId, ar.Nombre, ar.EmpleadoId, SISE3.ConcatenarNombres(ce.Nombre, ce.ApellidoPaterno, ce.ApellidoMaterno) as NombreEmpleado
from Areas ar
left join CatEmpleados ce on ce.EmpleadoId = ar.EmpleadoId
where /*ar.Nombre like '%zona%'
and*/ ar.CatOrganismoId = @pi_CatOrganismoId
AND ar.fkIdTipoArea = 5
order by ar.Nombre