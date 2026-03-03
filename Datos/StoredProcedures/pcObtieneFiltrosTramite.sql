USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcObtieneFiltrosTramite]    Script Date: 12/1/2023 6:19:57 PM ******/
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
CREATE PROCEDURE [SISE3].[pcObtieneFiltrosTramite] 
(
@pi_catIdOrganismo INT
)


AS
BEGIN
	
	---Obtener Secretarios
	
	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Secretario, e.UserName , ISNULL(a.Descripcion ,'') AS Mesa , e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
	FROM CatEmpleados e WITH (NOLOCK) 
	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	WHERE e.StatusRegistro = 1 
		AND eo.StatusRegistro = 1 
		AND eo.cargoId IN (14,18,19) 
		AND eo.CatOrganismoId = @pi_catIdOrganismo
	ORDER BY a.Descripcion 

	---Obtener Origen
	SELECT  sNombreOrigenPromocion, kIdOrigenPromocion as Origen
	FROM SISE3.CAT_OrigenPromocion​
	WHERE kIdOrigenPromocion IN (0,4,5,14,22,29)
	ORDER BY 1
										

	---Obtener Tipo Asunto 
	EXEC [SISE3].[pcListadoCatTiposAsunto] @pi_catIdOrganismo,1

	---Obtener Capturo
	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Capturo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
	FROM CatEmpleados e WITH (NOLOCK) 
	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	WHERE e.StatusRegistro = 1 
		AND eo.StatusRegistro = 1 
		AND eo.cargoId IN (14,18,19) 
		AND eo.CatOrganismoId = @pi_catIdOrganismo
	ORDER BY 1

	---Obtener Preautorizo
	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Preautorizo,  ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
	FROM CatEmpleados e WITH (NOLOCK) 
	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	WHERE e.StatusRegistro = 1 
		AND eo.StatusRegistro = 1 
		AND eo.cargoId IN (14,18,19) 
		AND eo.CatOrganismoId = @pi_catIdOrganismo
	ORDER BY 1

	---Obtener Autorizo
	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Autorizo, ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
	FROM CatEmpleados e WITH (NOLOCK) 
	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	WHERE e.StatusRegistro = 1 
		AND eo.StatusRegistro = 1 
		AND eo.cargoId IN (14,18,19) 
		AND eo.CatOrganismoId = @pi_catIdOrganismo
	ORDER BY 1

	---Obtener Cancelo
	SELECT SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno) AS Cancelo,  ISNULL(e.UserName,'') AS UserName, e.EmpleadoId, @pi_catIdOrganismo AS CatOrganismoId
	FROM CatEmpleados e WITH (NOLOCK) 
	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	WHERE e.StatusRegistro = 1 
		AND eo.StatusRegistro = 1 
		AND eo.cargoId IN (14,18,19) 
		AND eo.CatOrganismoId = @pi_catIdOrganismo
	ORDER BY 1
END
GO

