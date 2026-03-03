USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[EliminarArchivoDocumento]    Script Date: 10/31/2024 12:13:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Autor: Anabel Gonzalez
-- Fecha de creación : 31/10/2024
-- Descripción:	Se realiza eliminación del archivo realizando un update en el estatus y fecha de baja
-- =============================================
ALTER PROCEDURE [SISE3].[EliminarArchivoDocumento]
(
 @pe_AsuntoNeunId INT 
,@pe_PersonaId INT
,@pe_NoBloque INT
,@pe_TipoDocumentoId INT
,@pe_NombreArchivo NVARCHAR(50)
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ResultRow INT
	
		BEGIN TRY
			BEGIN TRAN		

			UPDATE DocumentoArchivos
			SET FechaBaja = GETDATE(),
			StatusReg = 0
			WHERE AsuntoNeunId = @pe_AsuntoNeunId
			AND PersonaId = @pe_PersonaId
			AND NoBloque = @pe_NoBloque
			AND TipoDocumentoId = @pe_TipoDocumentoId
			AND NombreArchivo = @pe_NombreArchivo
			SET @ResultRow = @@ROWCOUNT

		SELECT @ResultRow
					
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



