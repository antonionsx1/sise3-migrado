USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[paActualizarSolicitudFirmaDG]    Script Date: 11/04/2025 01:38:23 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:		Aaron Rodríguez Santiago
-- Create date: 08/04/2025
-- Description:	Actualiza dato de Solicitud Firma DG de la pantalla de trámite
-- EXEC [SISE3].[paActualizarSolicitudFirmaDG] 36071460, 1, 0
-- ==========================================================================================
CREATE OR ALTER PROCEDURE [SISE3].[paActualizarSolicitudFirmaDG](
    @pa_AsuntoNeunId BIGINT,
	@pa_AsuntoDocumentoId BIGINT,
	@pa_Estatus BIT
)
AS
BEGIN

	DECLARE 
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT,
		@Result INT;

	BEGIN TRY
		UPDATE [SISE_NEW].[SISE3].[AsuntosDocumentosAdicional] SET
			SolicitaFirmaDG = @pa_Estatus
		WHERE AsuntoNeunId = @pa_AsuntoNeunId
		AND AsuntoDocumentoId = @pa_AsuntoDocumentoId;

		SELECT COUNT(*) FROM [SISE_NEW].[SISE3].[AsuntosDocumentosAdicional] 
		WHERE AsuntoNeunId = @pa_AsuntoNeunId
		AND AsuntoDocumentoId = @pa_AsuntoDocumentoId

	END TRY
	BEGIN CATCH
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState =ERROR_STATE();

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
END