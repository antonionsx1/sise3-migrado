SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 11/23/23
-- Objetivo: Obtienen el detalle de los filtros del tablero de tramite
-- EXEC  [SISE3].[pcObtieneFiltrosTramite]  180
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneFiltrosTramite] 
(
@pi_catIdOrganismo INT
)


AS
BEGIN


	---Obtener Secretarios
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
    ORDER BY 1;


	---Obtener Origen
	SELECT  DISTINCT sNombreOrigenPromocion--, kIdOrigenPromocion as Origen
	FROM SISE3.CAT_OrigenPromocion
	WHERE kIdOrigenPromocion IN (14, 15, 22, 5,6,29,30,4,7,0)
	UNION 
	SELECT 'SIN ORIGEN'
	ORDER BY 1;
										

	---Obtener Tipo Asunto 
	EXEC [SISE3].[pcListadoCatTiposAsunto] @pi_catIdOrganismo,1;

	---Obtener Capturo
	--SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
	--FROM CatEmpleados e WITH (NOLOCK) 
	--INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
	--LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	--WHERE e.StatusRegistro = 1 
	--	AND eo.StatusRegistro = 1 
	--	AND eo.cargoId IN (14,18,19) 
	--	AND eo.CatOrganismoId = @pi_catIdOrganismo
	--ORDER BY 1


	--Obtener Capturo de tabla AsuntosDocumentos
    with
        tmp
        as
        (
            Select distinct ad.CreadorId as Secretario
            from dbo.Asuntosdocumentos ad WITH (NOLOCK)
            CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
            where a.CatOrganismoId = @pi_catIdOrganismo
            and ad.StatusReg = 1
        )
        --Obtiene secretarios de tabla areas con tipo area 2
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        FROM CatEmpleados e WITH (NOLOCK)
            LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        WHERE e.StatusRegistro = 1
            AND a.CatOrganismoId = @pi_catIdOrganismo
            AND a.fkIdTipoArea = 2
    UNION
    -- Obtiene secretarios de promociones
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from tmp
            inner join dbo.CatEmpleados e on e.EmpleadoId = tmp.Secretario
--            left join dbo.Areas a on e.EmpleadoId = a.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        where Secretario is not null and Secretario<>0
    ORDER BY 1;


	---Obtener Preautorizo
--	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Preautorizo,  ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
--	FROM CatEmpleados e WITH (NOLOCK) 
--	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
--	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
--	WHERE e.StatusRegistro = 1 
--		AND eo.StatusRegistro = 1 
--		AND eo.cargoId IN (14,18,19) 
--		AND eo.CatOrganismoId = @pi_catIdOrganismo
--	ORDER BY 1

	--Obtener Preautorizo de tabla AsuntosDocumentos
    with
        tmp
        as
        (
            Select distinct ad.EmpleadoIdPreautoriza as Secretario
            from dbo.Asuntosdocumentos ad WITH (NOLOCK)
            CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
            where a.CatOrganismoId = @pi_catIdOrganismo
            and ad.StatusReg = 1
        )
        --Obtiene secretarios de tabla areas con tipo area 2
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Preautorizo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        FROM CatEmpleados e WITH (NOLOCK)
            LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        WHERE e.StatusRegistro = 1
            AND a.CatOrganismoId = @pi_catIdOrganismo
            AND a.fkIdTipoArea = 2
    UNION
    -- Obtiene secretarios de promociones
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Preautorizo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from tmp
            inner join dbo.CatEmpleados e on e.EmpleadoId = tmp.Secretario
--            left join dbo.Areas a on e.EmpleadoId = a.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        where Secretario is not null and Secretario<>0
    ORDER BY 1;




	---Obtener Autorizo
--	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Autorizo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
--	FROM CatEmpleados e WITH (NOLOCK) 
--	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
--	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
--	WHERE e.StatusRegistro = 1 
--		AND eo.StatusRegistro = 1 
--		AND eo.cargoId IN (14,18,19) 
--		AND eo.CatOrganismoId = @pi_catIdOrganismo
--	ORDER BY 1
	--Obtener Preautorizo de tabla AsuntosDocumentos
    with
        tmp
        as
        (
            Select distinct ad.EmpleadoIdAutoriza as Secretario
            from dbo.Asuntosdocumentos ad WITH (NOLOCK)
            CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
            where a.CatOrganismoId = @pi_catIdOrganismo
            and ad.StatusReg = 1
        )
        --Obtiene secretarios de tabla areas con tipo area 2
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Autorizo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        FROM CatEmpleados e WITH (NOLOCK)
            LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        WHERE e.StatusRegistro = 1
            AND a.CatOrganismoId = @pi_catIdOrganismo
            AND a.fkIdTipoArea = 2
    UNION
    -- Obtiene secretarios de promociones
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Autorizo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from tmp
            inner join dbo.CatEmpleados e on e.EmpleadoId = tmp.Secretario
--            left join dbo.Areas a on e.EmpleadoId = a.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        where Secretario is not null and Secretario<>0
    ORDER BY 1;




	---Obtener Cancelo
--	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Cancelo,  ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
--	FROM CatEmpleados e WITH (NOLOCK) 
--	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
--	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
--	WHERE e.StatusRegistro = 1 
--		AND eo.StatusRegistro = 1 
--		AND eo.cargoId IN (14,18,19) 
--		AND eo.CatOrganismoId = @pi_catIdOrganismo
--	ORDER BY 1

	-- Obtener Cancelo de tabla AsuntosDocumentos
	with
        tmp
        as
        (
            Select distinct ad.EmpleadoIdCancela as Secretario
            from dbo.Asuntosdocumentos ad WITH (NOLOCK)
            CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
            where a.CatOrganismoId = @pi_catIdOrganismo
            and ad.StatusReg = 1
        )
        --Obtiene secretarios de tabla areas con tipo area 2
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Cancelo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        FROM CatEmpleados e WITH (NOLOCK)
            LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        WHERE e.StatusRegistro = 1
            AND a.CatOrganismoId = @pi_catIdOrganismo
            AND a.fkIdTipoArea = 2
    UNION
    -- Obtiene secretarios de promociones
    SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Cancelo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
        from tmp
            inner join dbo.CatEmpleados e on e.EmpleadoId = tmp.Secretario
--            left join dbo.Areas a on e.EmpleadoId = a.EmpleadoId and a.CatOrganismoId = @pi_catIdOrganismo
        where Secretario is not null and Secretario<>0
    ORDER BY 1




END
