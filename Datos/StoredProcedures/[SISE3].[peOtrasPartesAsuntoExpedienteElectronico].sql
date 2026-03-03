USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[peOtrasPartesAsuntoExpedienteElectronico]    Script Date: 11/06/2025 04:08:01 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--=============================================
-- Author:		Oliver A. Martinez Estudillo
-- Create date: 03/06/2025
-- Description:	Elimina otra parte de un asunto.
-- =============================================
CREATE PROCEDURE [SISE3].[peOtrasPartesAsuntoExpedienteElectronico]
(
	@pi_PersonaId BIGINT,
	@pi_UsuarioElimna BIGINT
)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY		
		DECLARE @AsuntoNeunId BIGINT,
				@AsuntoId INT

		SELECT	@AsuntoNeunId = AsuntoNeunId,
				@AsuntoId = @AsuntoId
		FROM  [SISE3].[OtrasPartesAsunto]
		WHERE iPersonaId = @pi_PersonaId

		BEGIN TRANSACTION
			IF EXISTS (SELECT 1 FROM NotificacionElectronica_Personas WITH(NOLOCK) WHERE PersonaId = @pi_PersonaId AND  StatusReg = 1)
				THROW 51000,'No es posible eliminar una parte cuando ya ha sido notificada',1;

			UPDATE [SISE3].[OtrasPartesAsunto] with(rowlock) 
			SET fFechaBaja = GETDATE(),
				iUsuarioCaptura = @pi_UsuarioElimna,
				StatusReg = 0		
			WHERE iPersonaId = @pi_PersonaId
			EXEC SISE_NEWLOG.DBO.usp_BitacoraOtrasPartesAsuntoIns @AsuntoNeunId,@pi_PersonaId,@pi_UsuarioElimna,'Baja'
		COMMIT TRANSACTION																			
	END TRY
	BEGIN CATCH
		-- Ejecuto ROLLBACK solo en caso de error
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		-- Ejecuta la rutina de recuperacion de errores.
		EXECUTE dbo.usp_GetErrorInfo;
	END CATCH;
END

GO


