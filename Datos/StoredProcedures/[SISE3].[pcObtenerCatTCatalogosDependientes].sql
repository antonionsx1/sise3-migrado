USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcObtenerCatalogosDinamicos]    Script Date: 20/03/2025 05:12:37 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author: Edgar Vargas
-- Create date: 20/03/2024
-- Description:	Obtiene equivalencias de los catalogos 
-- Ejemplo: EXEC [SISE3].[pcObtenerCatalogosDinamicos] 1
-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcObtenerCatTCatalogosDependientes]
(
	@piCatOrganismoId int
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		[iCatalogoPadreId] ,
		[iCatalogoHijoId] 
	FROM [SISE3].[CatTCatalogosDependientes]
	WHERE [bStatusReg] = 1;
    
END
GO

