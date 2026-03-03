SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 13/12/2023
-- Description: Regresa la clasificación de cuaderno de acuerdo al Tipo de Asunto dado.  
-- Basado en:	[dbo].[uspx_getCatCuaderno]
-- Ejemplo:	[SISE3].[pcObtieneCatCuaderno]   null ,5647
--			[SISE3].[pcObtieneCatCuaderno]  1
-- ================================

CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneCatCuaderno]   
	@pi_TipoAsuntoId INT = NULL,
	@pi_CuadernoId INT = NULL
AS  
BEGIN
	DECLARE @Cuaderno TABLE (CuadernoId INT, Cuaderno VARCHAR(255)) 
	
	INSERT INTO @Cuaderno
	EXEC usp_TipoCuadernoXTipoAsunto @pi_TipoAsuntoId
	
	SELECT DISTINCT cc.CuadernoId ,
		cc.Cuaderno,
		ISNULL(c.Color,'#FFFFFF') as Color,
		CuadernoCorto = c.nombreCorto
	FROM @Cuaderno cc   
	LEFT JOIN tbx_CatTiposAsunto c ON cc.CuadernoId = c.CuadernoId AND c.CatTipoAsuntoId = @pi_TipoAsuntoId
	WHERE cc.CuadernoId = ISNULL(@pi_CuadernoId,cc.CuadernoId) 

END