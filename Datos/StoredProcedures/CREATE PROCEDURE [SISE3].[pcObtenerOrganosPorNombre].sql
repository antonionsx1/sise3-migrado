USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcObtenerOrganosPorNombre]    Script Date: 14/04/2025 03:16:16 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Edgar Vargas
-- Create date: 11/04/2025
-- Description:	Obtiene los organos por nombre de organo, Estado y/o ciudad
-- Ejemplo: EXEC [SISE3].[pcObtenerOrganosPorNombre] 'Sonora'
-- =============================================
CREATE PROCEDURE [SISE3].[pcObtenerOrganosPorNombre]
	-- Add the parameters for the stored procedure here
	@pi_Nombre VARCHAR(150)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT 
		co.CatOrganismoId
		,co.NombreOficial AS NombreOrganismo
		,co.CatTipoOrganismoId
		,ce.Nombre AS NombreEstado
		,cc.CiudadNombre AS NombreCiudad
	FROM CatOrganismos co
	INNER JOIN CatEstados ce ON co.CatEstadosId = ce.CatEstadoId
	INNER JOIN CatCiudades cc ON co.CatCiudadId = cc.CatCiudadId
		AND cc.CatEstadoId = ce.CatEstadoId
	WHERE co.NombreOficial LIKE '%'+@pi_Nombre+'%'
		OR ce.Nombre LIKE '%'+@pi_Nombre+'%'
		OR cc.CiudadNombre LIKE '%'+@pi_Nombre+'%'
		AND co.StatusReg = 1
		AND co.FechaBaja IS NULL
	ORDER BY co.NombreOficial
END
GO


