SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author: Anabel Gonzalez
-- Create date: 02/08/2024
-- Description:	Obtiene las lista de catalogos
-- Ejemplo: EXEC [SISE3].[pcObtenerCatalogosDinamicos] 391,180,4
-- SPOriginal : EXEC usp_catalogosSel 22,148,4
-- ==========================================================================================
ALTER PROCEDURE [SISE3].[pcObtenerCatalogosDinamicos]
(
@piCatTipoCatalogoAsuntoId smallint,     -- Id del Catalogo
@piCatOrganismoId int,                         -- Id del Organismo (Para el Catalogo de Organismos, pasan el ID del Circuito)
@piCatTipoAsuntoId int                         -- Id del Tipo de Asunto
)
AS
/****** 18/06/2009                 ******/
/****** Proyecto: SISE       ******/
/****** Autor: Isaias Islas  ******/
/****** Objetivo: Cosulta la lista de catalogos por Tipo Asunto ******/
/****** 200090709 IIslas: Se cambio por modificacion en todo el esquema de Catalogos ******/
      BEGIN
            SET NOCOUNT ON
            BEGIN TRY

            -- Pregunto si se desea desplegar todos los catalogos existentes
            IF @piCatTipoCatalogoAsuntoId = 0
                  BEGIN
                        SELECT 
                                   a.CatalogoId AS ID
                                   ,a.CatalogoDescripcion as DESCRIPCION
                                   ,b.Elementos
                        FROM Catalogos a with(nolock) INNER JOIN viCatalogos b with(nolock) ON a.CatalogoId = b.Catalogo
                        WHERE CatalogoPadre = 0
                        RETURN(0)
                  END

            -- Valido, si existe el catalogo
            IF NOT EXISTS(SELECT CatalogoId FROM Catalogos with(nolock) WHERE CatalogoId = @piCatTipoCatalogoAsuntoId AND StatusRegistro = 1) OR
               NOT EXISTS(SELECT CatalogoPadre FROM viCatalogos with(nolock) WHERE Catalogo = @piCatTipoCatalogoAsuntoId and CatalogoPadre = 0)
                  BEGIN
             
                      DECLARE @message varchar(255)
                      SET @message = 'Error: No existe el catalogo ' +  cast(@piCatTipoCatalogoAsuntoId as varchar)
                        EXEC usp_GetErrorCustomInfo @message
                        RETURN(0)
                  END

            -- Valida si es un catalogo Externo, ejecucion de PROCEDIMIENTO ALMACENADO (Tipo 2)
            IF (SELECT TOP 1 LEFT(DESCRIPCION, 1)
                  FROM viCatalogos
                  WHERE Catalogo = @piCatTipoCatalogoAsuntoId AND CatalogoPadre > 0) = '['
                  BEGIN 
                        DECLARE @SQLString NVARCHAR(500);
                        DECLARE @ParmDefinition NVARCHAR(500);
                        /* Construyo la ejecucion del store */
                        SELECT TOP 1 @SQLString = N'EXEC SISE_NEW.' + SUBSTRING(DESCRIPCION, 1, CHARINDEX('|', DESCRIPCION, 10)-1)
                        FROM viCatalogos with(nolock)
                        WHERE Catalogo = @piCatTipoCatalogoAsuntoId AND
                               CatalogoPadre > 0  
                                                    
                        /* Especifia la declaracion de parametros */
                        SET @ParmDefinition = N'@piCatTipoCatalogoAsuntoId_IN smallint, @piCatOrganismoId_IN int, @piCatTipoAsuntoId_IN int ';
                        /* Ejecuto el resultado del armado */
                        EXECUTE sp_executesql @SQLString, @ParmDefinition,
                                                 @piCatTipoCatalogoAsuntoId_IN = @piCatTipoCatalogoAsuntoId ,
                                                 @piCatOrganismoId_IN =  @piCatOrganismoId ,
                                                 @piCatTipoAsuntoId_IN = @piCatTipoAsuntoId ;
                        RETURN(0)
                  END
            PRINT @piCatTipoCatalogoAsuntoId
          -- Catalogo que aplica para todos los TIPOS DE ASUNTO, la condicion es que el Catalogo no exista en CatalogosElementosTiposAsunto
          
          
          
        IF NOT EXISTS(SELECT distinct CatalogoId FROM CatalogosElementosTiposAsunto with(nolock) WHERE CatalogoId = @piCatTipoCatalogoAsuntoId)
                  BEGIN 
						IF(@piCatTipoAsuntoId = 74 AND @piCatTipoCatalogoAsuntoId IN (677, 877))
						BEGIN
							SELECT @piCatTipoCatalogoAsuntoId = KS FROM viCatalogos with(nolock) WHERE Catalogo = @piCatTipoCatalogoAsuntoId AND CatalogoPadre = 0
							SELECT ID
								,DESCRIPCION
								,Elementos
							FROM  viCatalogos a with(nolock) INNER JOIN Catalogos b with(nolock) ON a.Catalogo = b.CatalogoId 
							WHERE CatalogoPadre = @piCatTipoCatalogoAsuntoId AND
									   CatalogoPadre > 0
								ORDER BY a.Orden
						END
						ELSE IF (@piCatTipoCatalogoAsuntoId in (2024,2025)) --HDMM 24/11/22 Ordena Catalogo Alfabéticamente
						BEGIN
						SELECT @piCatTipoCatalogoAsuntoId = KS FROM viCatalogos with(nolock) WHERE Catalogo = @piCatTipoCatalogoAsuntoId AND CatalogoPadre = 0
							SELECT ID
								,DESCRIPCION
								,Elementos
							FROM  viCatalogos a with(nolock) INNER JOIN Catalogos b with(nolock) ON a.Catalogo = b.CatalogoId 
							WHERE CatalogoPadre = @piCatTipoCatalogoAsuntoId AND
									   CatalogoPadre > 0
								ORDER BY a.DESCRIPCION
						END
						ELSE IF (@piCatTipoCatalogoAsuntoId in (587)) --HDMM 04/11/24 Ordena Catalogo Ordén Númerico
						BEGIN
						SELECT @piCatTipoCatalogoAsuntoId = KS FROM viCatalogos with(nolock) WHERE Catalogo = @piCatTipoCatalogoAsuntoId AND CatalogoPadre = 0
							SELECT ID
								,DESCRIPCION
								,Elementos
							FROM  viCatalogos a with(nolock) INNER JOIN Catalogos b with(nolock) ON a.Catalogo = b.CatalogoId 
							WHERE CatalogoPadre = @piCatTipoCatalogoAsuntoId AND
									   CatalogoPadre > 0
								ORDER BY a.Orden
						END
						ELSE
						BEGIN
							SELECT @piCatTipoCatalogoAsuntoId = KS FROM viCatalogos with(nolock) WHERE Catalogo = @piCatTipoCatalogoAsuntoId AND CatalogoPadre = 0
							SELECT      ID
									   ,DESCRIPCION
									   ,Elementos
							FROM  viCatalogos a with(nolock) INNER JOIN Catalogos b with(nolock) ON a.Catalogo = b.CatalogoId 
							WHERE CatalogoPadre = @piCatTipoCatalogoAsuntoId AND
									   CatalogoPadre > 0
									   PRINT 'HOLA'
						END
                        RETURN (0)

                  END   
            PRINT 'Paso 1'    
            -- De lo contrario es un Catalogo normal, si tiene elementos dependientes, se ejecuta el procedimiento usp_CatalogosDependientes   
            IF EXISTS(SELECT CatalogoId FROM CatalogosElementosTiposAsunto with(nolock) WHERE CatalogoId = @piCatTipoCatalogoAsuntoId) 
                  BEGIN
                        -- RCG, 31Oct2013. Incorporación de IF para validar cuando el catálogo es 17, se obtenga el listado de opción con un
                        --                         Ordenamiento específico. Como requerimiento derivado de la nueva captura de documentos.
                        IF (@piCatTipoCatalogoAsuntoId = 17)
                             Begin
                                        exec dbo.usp_ObtieneCatalogoTipoDocumento_NuevoOrden @piCatTipoCatalogoAsuntoId, @piCatTipoAsuntoId,@piCatOrganismoId   
                             End
                        ELSE IF (@piCatTipoAsuntoId = 126 and @piCatTipoCatalogoAsuntoId = 263) ---HDMM 29/10/2022 se agrega condición para eliminar opción repetida
						BEGIN

						 SELECT ID,DESCRIPCION,Elementos
                                                      FROM  viCatalogos a with(nolock) INNER JOIN
                                                                          CatalogosElementosTiposAsunto b  with(nolock)
                                                                          ON a.Catalogo = b.CatalogoId AND
                                                                          a.ID = b.CatalogoElementoIdNew 
                                                      WHERE a.Catalogo = @piCatTipoCatalogoAsuntoId AND
                                                                          b.CatTipoAsuntoId = @piCatTipoAsuntoId AND
                                                                          (b.StatusRegistro = 1                                               
                                                                          ) AND
                                                                          a.CatalogoPadre > 0
																		  and a.Nivel = 2 order by b.CatalogoElementoId 

						END
                        -- ABP 14/08/2015 se agrega opción para ordenamiento de catálogos para el esquema de PPA     
                        ELSE IF ((@piCatTipoAsuntoId = 74 AND  (@piCatTipoCatalogoAsuntoId = 476 
                        OR @piCatTipoCatalogoAsuntoId = 481 OR @piCatTipoCatalogoAsuntoId = 477
                        OR @piCatTipoCatalogoAsuntoId = 437 OR @piCatTipoCatalogoAsuntoId = 822 OR @piCatTipoCatalogoAsuntoId = 823))--PPA
						OR(@piCatTipoAsuntoId = 10 AND @piCatTipoCatalogoAsuntoId = 107) --SENTENCIA AD
						OR(@piCatTipoAsuntoId = 11 AND @piCatTipoCatalogoAsuntoId = 108) --SENTENCIA AR
						OR(@piCatTipoAsuntoId = 55 AND @piCatTipoCatalogoAsuntoId = 454) --SENTENCIA TCA
						OR(@piCatTipoAsuntoId = 56 AND @piCatTipoCatalogoAsuntoId = 463) --SENTENCIA TUA
						OR(@piCatTipoAsuntoId = 9 AND @piCatTipoCatalogoAsuntoId = 125) --SENTENCIA TCA
						OR(@piCatTipoAsuntoId = 6 AND @piCatTipoCatalogoAsuntoId = 125) --SENTENCIA TUA
					 

						) 
                        BEGIN 
                       
                                               SELECT ID,DESCRIPCION,Elementos
                                                      FROM  viCatalogos a with(nolock) INNER JOIN
                                                                          CatalogosElementosTiposAsunto b  with(nolock)
                                                                          ON a.Catalogo = b.CatalogoId AND
                                                                          a.ID = b.CatalogoElementoIdNew 
                                                      WHERE a.Catalogo = @piCatTipoCatalogoAsuntoId AND
                                                                          b.CatTipoAsuntoId = @piCatTipoAsuntoId AND
                                                                          (b.StatusRegistro = 1                                               
                                                                          ) AND
                                                                          a.CatalogoPadre > 0  order by b.CatalogoElementoId 
                        END
                        -- ABP 14/08/2015 se agrega opción para el catálogo de nacionalidad del modulo de personal 
                        ELSE IF (@piCatTipoAsuntoId = 0 AND @piCatTipoCatalogoAsuntoId = 481) --Personal
                        BEGIN 
                         
                                               SELECT      ID
                                               ,DESCRIPCION
                                               ,Elementos
                                   FROM  viCatalogos a with(nolock) INNER JOIN
                                               CatalogosElementosTiposAsunto b  with(nolock)
                                               ON a.Catalogo = b.CatalogoId AND
                                               a.ID = b.CatalogoElementoIdNew 
                                   WHERE a.Catalogo = @piCatTipoCatalogoAsuntoId AND
                                               b.CatTipoAsuntoId = 19 AND
                                               (b.StatusRegistro = 1                                               
                                               ) AND
                                               a.CatalogoPadre > 0  order by b.CatalogoElementoId 
                        END						
                        ELSE
                             Begin print '11'
                                   SELECT      ID
                                               ,DESCRIPCION
                                               ,Elementos
                                   FROM  viCatalogos a with(nolock) INNER JOIN
                                               CatalogosElementosTiposAsunto b  with(nolock)
                                               ON a.Catalogo = b.CatalogoId AND
                                               a.ID = b.CatalogoElementoIdNew 
                                   WHERE a.Catalogo = @piCatTipoCatalogoAsuntoId AND
                                               b.CatTipoAsuntoId = @piCatTipoAsuntoId AND
                                               (b.StatusRegistro = 1 
                                               --or b.StatusRegistro = 2
                                               ) AND
                                               a.CatalogoPadre > 0     order by a.Orden        
                                   RETURN (0)  
                             End
                  END
            END TRY 
            BEGIN CATCH
                  -- Ejecuta la rutina de recuperacion de errores.     
                  --EXECUTE dbo.usp_GetErrorInfo;
            END CATCH;
            SET NOCOUNT OFF
      END