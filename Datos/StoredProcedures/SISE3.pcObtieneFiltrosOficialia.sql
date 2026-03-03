SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Christian Araujo - MS
-- Alter date: 24/01/2024
-- Objetivo: Obtienen el detalle de los filtros del tablero de Oficialía de partes
-- EXEC  [SISE3].[pcObtieneFiltrosOficialia]  147
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneFiltrosOficialia]
    (
    @pi_catIdOrganismo INT
)


AS
BEGIN

-- Crea tabla temporal para obtener secrearios de promociones
    with
        tmp
        as
        (
            Select distinct secretario as Secretario
            from
                dbo.Promociones p WITH(NOLOCK)
            Where p.StatusReg = 1
                AND p.CatOrganismoId = @pi_catIdOrganismo
        )
    --Obtiene secretarios de tabla areas con tipo area 2
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Secretario, ISNULL(e.UserName,'') AS UserName, ISNULL(a.Descripcion ,'') AS Mesa, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        FROM CatEmpleados e WITH (NOLOCK)
            LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        WHERE e.StatusRegistro = 1
            AND a.CatOrganismoId = @pi_catIdOrganismo
            AND a.fkIdTipoArea = 2
    UNION
    -- Obtiene secretarios de promociones
    Select SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Secretario,
            ISNULL(e.UserName,'') AS UserName, ISNULL(a.Descripcion ,'') AS Mesa , e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from tmp
            inner join dbo.CatEmpleados e on e.EmpleadoId = tmp.Secretario
            left join dbo.Areas a on e.EmpleadoId = a.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        where Secretario is not null and Secretario<>0
    ORDER BY 1


    ---Obtener Origen
    SELECT DISTINCT sNombreOrigenPromocion--, kIdOrigenPromocion as Origen
    FROM SISE3.CAT_OrigenPromocion
    ​
	WHERE kIdOrigenPromocion IN
    (14, 15, 22, 5,6,29,30,4,7,0)
	UNION
    SELECT 'SIN ORIGEN'
    ORDER BY 1;

    -- Crea tabla temporal para obtener usuarios que han capturado promociones
    with
        tmp
        as
        (
            Select distinct RegistroEmpleadoId as UsuarioCaptura
            from
                dbo.Promociones p WITH(NOLOCK)
            Where p.StatusReg = 1
                AND p.CatOrganismoId = @pi_catIdOrganismo
        )
    -- Obiene empleado asignado a area con tipodearea = 1
                SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        FROM CatEmpleados e WITH (NOLOCK)
            LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId
        WHERE e.StatusRegistro = 1
            AND a.CatOrganismoId = @pi_catIdOrganismo
            AND a.fkIdTipoArea = 1
    UNION
        --Obtiene hijos de empleado asignado a area con tipodearea = 1 de areasempleados
        (Select SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from dbo.CatEmpleados e
            inner join dbo.AreasEmpleados ae on e.EmpleadoId = ae.EmpleadoId
        where ae.AreaId in (Select a.AreaId
        from dbo.Areas a
        where a.CatOrganismoId = @pi_catIdOrganismo and a.fkIdTipoArea = 1)
)
    UNION
        -- Obtiene usuarios que han capturado promociones
        Select SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo,
            ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from tmp
            inner join dbo.CatEmpleados e on e.EmpleadoId = tmp.UsuarioCaptura
        where UsuarioCaptura is not null
    ORDER BY 1
END
