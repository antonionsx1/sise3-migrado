-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 26/12/2024
-- Description:	SP original [dbo].[TAU_piObservaciones], para guardar diferimiento de Audiencia de Alzada
-- Ejemplo de ejecución: EXEC [SISE3].[piDiferimientoAudienciaAlzada] 203161, 24, 19, 'Prueba de Diferimiento';

-- ==========================================================================================

CREATE PROCEDURE [SISE3].[piDiferimientoAudienciaAlzada]
	@fidinformaciongeneralaudiencia BIGINT
	,@fkidtipomovimiento INT
	,@fkidmotivo INT
	,@smotivo VARCHAR (500) = NULL
   WITH
   EXEC AS CALLER
AS

BEGIN
	DECLARE 
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT

	SET NOCOUNT ON;
	BEGIN TRY 
	
		DECLARE @ID BIGINT = 0
				,@fcatorganismoid INT
				,@fasuntoneunid BIGINT
				,@iaudiencia INT
				,@sobservacion VARCHAR (500) = NULL
				,@iusuario INT = 0							--Default		
				,@fkIdObservacion INT = 4					--Otros
				,@nombreUsuarioOraltis VARCHAR(150)
				
		--Obtener Neun y ID
		BEGIN
			SELECT
				@fcatorganismoid = fkCatOrganismoId
				,@fasuntoneunid = fkIdAsuntoNeun
				,@iaudiencia = idAudiencia
			FROM InformacionGeneralAudiencia a 
			WHERE idInformacionGeneralAudiencia = @fidinformaciongeneralaudiencia
		END

		
		MERGE dbo.TAU_Mov_Observaciones AS tgt
		USING (
			SELECT 
				@fidinformaciongeneralaudiencia	AS fidInformacionGeneralAudiencia 
				,@fkidtipomovimiento			AS fkIdTipoMovimiento 
		) AS src
		ON (tgt.fidInformacionGeneralAudiencia = src.fidInformacionGeneralAudiencia
			AND tgt.iEstatus = 1
		)

		WHEN MATCHED THEN
			UPDATE SET 
				tgt.fkIdObservacion = @fkIdObservacion
				,tgt.fkIdTipoMovimiento = @fkidtipomovimiento				

		WHEN NOT MATCHED THEN
			INSERT (fCatOrganismoId, fidInformacionGeneralAudiencia, fAsuntoNeunId, iAudiencia, sObservacion, fkIdTipoMovimiento, fFechaRegistro, iUsuario, iEstatus, fkIdObservacion, NombreUsuarioOraltis)
			VALUES (@fcatorganismoid, @fidinformaciongeneralaudiencia, @fasuntoneunid, @iaudiencia, @sobservacion, @fkidtipomovimiento, GETDATE(), @iusuario, 1, @fkIdObservacion, @nombreUsuarioOraltis)
		--OUTPUT inserted.kIdObservacion INTO @ID
		;
		SET @ID = SCOPE_IDENTITY()
		
		
		UPDATE InformacionGeneralAudiencia 
		SET bDiferida = 1
			,sMotivoDiferimiento = @smotivo
			,fkIdMotivoDiferimiento = @fkidmotivo
			,idEstatusAudiencia = 5							--Cancelada
		WHERE idInformacionGeneralAudiencia = @fidinformaciongeneralaudiencia;

				
		SELECT kIdObservacion, fCatOrganismoId, fidInformacionGeneralAudiencia, fAsuntoNeunId, iAudiencia, sObservacion, fkIdTipoMovimiento, fFechaRegistro, iUsuario, iEstatus, fkIdObservacion
		FROM TAU_Mov_Observaciones WITH (NOLOCK) 
		WHERE kIdObservacion = @ID;
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN TAUpiObservaciones
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
   
END