SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:		Isidro Neri Silva 
-- Create date: 08/07/2024
-- Description:	Elimina recordatorios por Id.
-- ==========================================================================================
CREATE PROCEDURE [SISE3].[peEliminarRecordatorio](
    @pe_RecordatorioId INT
)
AS
BEGIN
	
	DECLARE 	   
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT;

	BEGIN TRY
	BEGIN TRAN TransRecordatorio
	BEGIN

        DELETE FROM Word_ObservacionDocumento WHERE ObservacionDocumentoId = @pe_RecordatorioId;
	    SELECT TOP 1 1 AS Resultado, 'Rol eliminado de manera exitosa' AS Mensaje FROM Word_ObservacionDocumento;

	END
	COMMIT TRAN TransRecordatorio
	END TRY 
	BEGIN CATCH
	ROLLBACK TRAN TransRecordatorio
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState =ERROR_STATE();

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
END