SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: SGS
-- Create date: 06/03/2024
-- Description: Inserta acuse de notificacion
-- Ejemplo de llamada
-- exec [SISE3].[piInsertaArchivoAcuse] 566505173,'archivo','.pdf',1,1,1,2
-- ============================================= 

CREATE OR ALTER PROC [SISE3].[piInsertaArchivoAcuse]
@pi_NotElecId BIGINT,
@pi_NombreArchivo VARCHAR(100),
@pi_ExtensionDocumento VARCHAR(10),
@pi_Usuario BIGINT,
@pi_Origen INT = NULL,
@pi_TipoAcuse INT,
@pi_IdRuta INT

AS
BEGIN
       SET NOCOUNT ON
       BEGIN TRY
            BEGIN TRAN

            DECLARE @IdArchivo BIGINT

            INSERT INTO dbo.NotificacionElectronica_Archivos
            (NotElecId
            ,NombreArchivo
            ,NombreArchivoReal
            ,Observaciones
            ,FechaAlta
            ,EmpleadoId
            ,StatusReg
            ,Origen)
            VALUES
            (@pi_NotElecId
            ,@pi_NombreArchivo + '.' + @pi_ExtensionDocumento
            ,@pi_NombreArchivo + '.' + @pi_ExtensionDocumento
            ,'El archivo se guardó con éxito'
            ,GETDATE()
            ,@pi_Usuario
            ,1
            ,@pi_Origen)

            SET @IdArchivo = SCOPE_IDENTITY()

            INSERT INTO SISE3.REL_ArchivoTipoAcuse
            (IdArchivo
            ,TipoArchivo
            ,bEstatus
            ,fFechaAlta)
            VALUES
            (@IdArchivo
            ,@pi_TipoAcuse
            ,1
            ,GETDATE())
			  
       ------------------Termina Control PartesNotificacion------------------------------    
  END TRY
  BEGIN CATCH
    -- Ejecuto ROLLBACK solo en caso de error
       IF @@TRANCOUNT > 0
         ROLLBACK TRANSACTION;
             -- Ejecuta la rutina de recuperacion de errores.
             EXECUTE dbo.usp_GetErrorInfo;
  END CATCH;        
  -- Completo mi transaccion
  IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
  SET NOCOUNT OFF
END




