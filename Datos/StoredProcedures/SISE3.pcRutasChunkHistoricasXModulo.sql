SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 09/10/2023 
-- Description: Se utiliza para devolver las rutas de los archivos que se van a generar en el sistema
-- Según el tipo de archivo que se requiera generar
-- Basado en: pcWSRutasChunk
--execute [SISE3].[pcRutasChunkHistoricasXModulo] 'Oficialia'
-- ============================================= 
CREATE OR ALTER PROCEDURE [SISE3].[pcRutasChunkHistoricasXModulo] 
(                                            
@pi_Modulo  VARCHAR(50)
)						
AS
DECLARE 
@ErrorMessage  NVARCHAR(4000),
@ErrorSeverity INT,
@ErrorState    INT,
@Grupo        INT=NULL

			--IF @pi_Modulo = 'Oficialia'
            BEGIN TRY 
					IF @pi_Modulo = 'Oficialia'
					BEGIN
						select KId,iGrupo,sDescripcion,iTipoArchivo,sTipoArchivoDesc,sRuta,iEscritura from CAT_RutasChunk rc with(nolock) where rc.iGrupo IN (2, 9, 16) and rc.iEscritura = 0  order by fFechaAlta desc
					End

					ELSE IF @pi_Modulo = 'Tramite'
					BEGIN
						select KId,iGrupo,sDescripcion,iTipoArchivo,sTipoArchivoDesc,sRuta,iEscritura from CAT_RutasChunk rc with(nolock) where rc.iGrupo = 1 and rc.iEscritura = 0 order by fFechaAlta desc
					End
					ELSE
					BEGIN
						THROW 51000,'Error módulo no configurado',1;
					END

			END TRY
            ------Manejo de Errores.
			BEGIN CATCH
			  
			   SELECT 
					  @ErrorMessage = ERROR_MESSAGE(),
                      @ErrorSeverity = ERROR_SEVERITY(),                 
                      @ErrorState =ERROR_STATE();

			 --RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
			 THROW 51000,@ErrorMessage,1;

			END CATCH

