SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 21/01/2025
-- Description: Se encarga de obtener los catalogos dependientes
-- Original: EXEC usp_CatalogosDependientes 4267, 356
-- Ejemplo : [SISE3].[pc_ObtenerCatalogosDependientes] 4267, 356				
-- ============================================= 
CREATE PROCEDURE [SISE3].[pc_ObtenerCatalogosDependientes]
 @pc_CatalogoElementoId INT	-- Se recibe el ID del elemento
,@pc_CatalogoId	INT			-- Se recibe el ID del Catalogo original
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
			IF (@pc_CatalogoId = 249)
				BEGIN
					SET @pc_CatalogoElementoId = 
						CASE @pc_CatalogoElementoId
							WHEN 12715 THEN 13721
							WHEN 12740 THEN 13754					
							WHEN 12741 THEN 13771					
							WHEN 12765 THEN 13813					
							WHEN 13716 THEN 13834
							ELSE 0
						END															
				END
			-- Obtengo la llave Subrrugada
			SET @pc_CatalogoId = (
				SELECT	
					KS 
				FROM viCatalogos WITH(NOLOCK)
				WHERE ID = @pc_CatalogoElementoId 
				AND	Catalogo = @pc_CatalogoId 
				AND	Elementos > 0 )
			
			SELECT	ID 
					,DESCRIPCION
					,Elementos
			FROM	viCatalogos WITH(NOLOCK)
			WHERE	CatalogoPadre = @pc_CatalogoId
					ORDER BY Orden 

			RETURN (0)
		END TRY
		BEGIN CATCH
			--EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
		SET NOCOUNT OFF
	END
