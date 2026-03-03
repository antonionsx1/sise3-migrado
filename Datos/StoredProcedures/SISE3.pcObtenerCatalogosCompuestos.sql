SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 14/01/2025
-- Description: Se encarga de obtener los catalogos compuestos es decir los que se generan por medio de otro sp
-- Ejemplo : EXEC [SISE3].[pcObtenerCatalogosCompuestos] 522,36069632,1,180,2,0,0,0						
-- ============================================= 
ALTER PROCEDURE [SISE3].[pcObtenerCatalogosCompuestos]
  @pc_NumeroCatalogo INT 
 ,@pc_AsuntoNeunId BIGINT
 ,@pc_AsuntoId INT
 ,@pc_CatOrganismoId INT
 ,@pc_CatTipoOrganismoId INT
 ,@pc_CatCircuitoId INT NULL
 ,@pc_CatCargoId INT NULL
 ,@pc_EstatusAudienciaId INT NULL
AS
BEGIN
	BEGIN TRY
	
		DECLARE @sqlCommand NVARCHAR(MAX);

		IF(@pc_NumeroCatalogo = 389)
			BEGIN 				
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatCircuitoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|DBO.FNOBTIENEORGANISMO',CAST(@pc_AsuntoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 391)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatOrganismoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOCATALOGOASUNTOID_IN|DBO.FNOBTIENEEMPLEADO',CAST(@pc_NumeroCatalogo AS NVARCHAR));
			END	
		ELSE IF(@pc_NumeroCatalogo = 475)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatOrganismoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOCATALOGOASUNTOID_IN|DBO.FNOBTIENEEMPLEADO',CAST(@pc_NumeroCatalogo AS NVARCHAR));
			END	
		ELSE IF(@pc_NumeroCatalogo = 480)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|DBO.FNOBTIENEEMPLEADO',CAST(@pc_CatOrganismoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 482)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|DBO.FNOBTIENEEMPLEADO',CAST(@pc_CatCircuitoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 488)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatTipoOrganismoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 489) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 494) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)
			END
		ELSE IF(@pc_NumeroCatalogo = 499)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatTipoOrganismoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 514)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatTipoOrganismoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 522)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 523)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 540)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 584)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 624)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatCircuitoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|dbo.fnObtieneOrganismo( @pi_ElementoId )',CAST(@pc_AsuntoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 711)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 733) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 735) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 744) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatOrganismoId AS NVARCHAR));
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_CatCargoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 820) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_EstatusAudienciaId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 883) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)
			END
		ELSE IF(@pc_NumeroCatalogo = 1030) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@piCatSalaId_IN |',CAST(@pc_CatOrganismoId AS NVARCHAR)); --PENDIENTE DE PARAMETRO
			END
		ELSE IF(@pc_NumeroCatalogo = 1031)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@piCatSalaId_IN |',CAST(@pc_CatOrganismoId AS NVARCHAR)); --PENDIENTE DE PARAMETRO
			END
		ELSE IF(@pc_NumeroCatalogo = 1032)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@piCatSalaId_IN |',CAST(@pc_CatOrganismoId AS NVARCHAR)); --PENDIENTE DE PARAMETRO
			END			
		ELSE IF(@pc_NumeroCatalogo = 1055)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1056)--AQUI VOY
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
			END	
		ELSE IF(@pc_NumeroCatalogo = 1065) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1066) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_AsuntoId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1145)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_AsuntoId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1396)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatOrganismoId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOCATALOGOASUNTOID_IN|',CAST(@pc_NumeroCatalogo AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1397)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatOrganismoId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOCATALOGOASUNTOID_IN|',CAST(@pc_NumeroCatalogo AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1398)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@piCatTipoAsuntoId_IN|',CAST(@pc_AsuntoNeunId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1409)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1466)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 1473) 
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR)); 
			END
		ELSE IF(@pc_NumeroCatalogo = 2232)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN',CAST(@pc_CatCircuitoId AS NVARCHAR)); 
				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATTIPOASUNTOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR));
			END
		ELSE IF(@pc_NumeroCatalogo = 2233)
			BEGIN 
				SELECT @sqlCommand = (SELECT DESCRIPCION FROM viCatalogos WITH(NOLOCK) WHERE Catalogo = @pc_NumeroCatalogo AND CatalogoPadre <> 0)

				SET @sqlCommand = REPLACE(@sqlCommand,'@PICATORGANISMOID_IN|',CAST(@pc_CatOrganismoId AS NVARCHAR)); 
			END
			

		EXEC sp_executesql @sqlCommand;	
	
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;