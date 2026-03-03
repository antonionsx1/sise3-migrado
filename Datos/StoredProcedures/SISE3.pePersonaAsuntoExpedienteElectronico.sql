SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		GGHH
-- Create date: 07/02/2024
-- Description:	Elimina una parte de un asunto.
-- Basado en usp_PersonasAsuntoDel
-- =============================================
CREATE OR ALTER PROCEDURE SISE3.pePersonaAsuntoExpedienteElectronico
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
		FROM  PersonasAsunto
		WHERE PersonaId = @pi_PersonaId

		BEGIN TRANSACTION
			UPDATE PersonasAsunto with(rowlock) 
			SET FechaBaja = GETDATE(),
				UsuarioCaptura = @pi_UsuarioElimna,
				StatusReg = 0		
			WHERE PersonaId = @pi_PersonaId
						
			EXEC SISE_NEWLOG.DBO.usp_BitacoraPersonasAsuntoIns @AsuntoNeunId,@pi_PersonaId,@pi_UsuarioElimna,'Baja'
						
			--Manda llamar a store que elimina de las tablas AsuntosDetalle relacionados a la parte eliminada			
			EXEC usp_PersonasAsuntoDetallesDel  @AsuntoNeunId,@AsuntoId,@pi_PersonaId,@pi_UsuarioElimna	
			
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

