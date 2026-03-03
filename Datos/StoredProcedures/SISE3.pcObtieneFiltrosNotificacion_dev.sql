SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Sergio Orozco - MS
-- Alter date: 10/01/2024
-- Objetivo: Obtienen el detalle de los filtros del tablero de detalle notificaciones
-- EXEC  [SISE3].[pcObtieneFiltrosNotificacion] 180
-- @pi_catIdOrganismo = 180 INT
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneFiltrosNotificacion_dev] 
(
    -- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
    @pi_catIdOrganismo INT
)


AS
BEGIN
-- Retorna 3 tablas Tipo de parte, Tipo de notificación, Actuario

-- Tipo de parte retorna [ 'Partes', 'Promoventes', 'Autoridades Judiciales' ]
Select 1 as ID, 'Partes' as sDescripcion
UNION
Select 2 as ID, 'Promoventes' as sDescripcion
UNION
Select 3 as ID, 'Autoridades Judiciales' as sDescripcion

--Tipo de notificacion de catalogo de notificaciones
Select 
    kIdCatNotificaciones
    ,sDescripcion 
from dbo.CatNotificaciones
where fkIdEstatus = 1 
order by kIdCatNotificaciones asc

--Actuarios
--Obtiene todos los actuarios de area 
select 
    a.AreaId, a.EmpleadoId, CONCAT(ce.Nombre, ' ', ce.ApellidoPaterno, ' ', ce.ApellidoMaterno) as NombreActuario 
from dbo.Areas a 
    inner join dbo.CatEmpleados ce on ce.EmpleadoId = a.EmpleadoId
    where a.fkIdTipoArea = 3 AND a.CatOrganismoId = @pi_catIdOrganismo
UNION
-- Une con los hijos de los actuarios de areas
Select a.AreaId, a.EmpleadoId,  CONCAT(ce.Nombre, ' ', ce.ApellidoPaterno, ' ', ce.ApellidoMaterno) as NombreActuario
from dbo.Areas a
    inner join dbo.CatEmpleados ce on ce.EmpleadoId = a.EmpleadoId
    where a.AreaIdPadre in (select a.AreaId from dbo.Areas a 
                            where a.fkIdTipoArea = 3 and a.CatOrganismoId = @pi_catIdOrganismo)
UNION 
-- Une con los actuarios de areaEmpleado ligados a un area de actuario
Select ae.AreaId
        , ae.EmpleadoId
        , CONCAT(ce.Nombre, ' ', ce.ApellidoPaterno, ' ', ce.ApellidoMaterno) as NombreActuario
from dbo.AreasEmpleados ae
    inner join dbo.CatEmpleados ce on ce.EmpleadoId = ae.EmpleadoId
    -- Filtra areas de actuario 
    where AreaId in (
        Select AreaId 
        from dbo.Areas a
        where (a.fkIdTipoArea = 3 and a.CatOrganismoId = @pi_catIdOrganismo)
            OR a.AreaIdPadre in (select a.AreaId
                                from dbo.Areas a
                                where a.fkIdTipoArea = 3 AND a.CatOrganismoId = @pi_catIdOrganismo)
        )


END

