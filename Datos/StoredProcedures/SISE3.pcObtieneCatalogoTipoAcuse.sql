SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 13/12/2023
-- Description: Regresa la clasificación de Tipo de Acuse.  
-- ================================

CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneCatalogoTipoAcuse]   
AS  
BEGIN
	
    SELECT
         ID
        ,DESCRIPCION
    FROM  viCatalogos a with(nolock) 
    INNER JOIN Catalogos b with(nolock) 
        ON a.Catalogo = b.CatalogoId 
    WHERE CatalogoPadre = 6867 AND
    CatalogoPadre > 0

END
