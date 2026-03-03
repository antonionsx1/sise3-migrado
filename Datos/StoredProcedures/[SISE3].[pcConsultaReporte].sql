SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:		Erick Garcia de la Rosa
-- Create date: 17/01/2025
-- Description:	Permite ejecutar una consulta 
-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcConsultaReporte] 
	@pc_cadena VARCHAR(MAX)
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(4000)
		   ,@ErrorSeverity INT
		   ,@ErrorState INT

	BEGIN TRY

		EXEC (@pc_cadena);
	
	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END