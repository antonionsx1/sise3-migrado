USE [SISE_NEW]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 23/08/2024 
-- Description: Obtener validaciones de los esquemas 
-- Ejemplo : EXEC [SISE3].[pcObtenerValidacionesEsquemas] 4, 2
-- ============================================= 
ALTER PROCEDURE  [SISE3].[pcObtenerValidacionesEsquemas]
(
	@pc_CatTipoAsuntoId INT,
	@pc_CatTipoOrganismoId INT
)
AS
	BEGIN
		SET NOCOUNT ON
		
		  	SELECT xEsqValida 
		  	FROM [ESQ_ConfCatTipoAsunto] WITH(NOLOCK) 
			WHERE fkCatTipoAsuntoId=@pc_CatTipoAsuntoId 
			AND fkCatTipoOrganismoId=@pc_CatTipoOrganismoId 
			AND fkEstatusId=1				
		
		SET NOCOUNT OFF
	END

