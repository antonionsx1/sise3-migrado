USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[paDesactivaAcuerdo]    Script Date: 12/1/2023 6:13:16 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/10/2013
-- Description: Actualiza Estado tramite
-- Basado en:   [usp_DeterminacionJudicialDesactivaAcuerdo]
-- Exec [SISE3].[paDesactivaAcuerdo]  1, 23035825, 2

-- =============================================
CREATE procedure [SISE3].[paDesactivaAcuerdo]
(
@pi_AsuntoId [int] ,
@pi_AsuntoNeunId [bigint],
@pi_SintesisOrden int,
@pi_AsuntoDocumentoId int,
@pi_Valor int
)
AS

	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
			BEGIN TRAN
			
			DECLARE @CatOrganismoId INT
			DECLARE @TipoOrigen INT
			DECLARE @ValidaNot INT

			
			SELECT @CatOrganismoId = CatOrganismoId FROM Asuntos with(nolock) WHERE AsuntoNeunId = @pi_AsuntoNeunId
			
		
			SELECT @TipoOrigen = TipoOrigen FROM DeterminacionesJudiciales with(nolock) 
			WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @pi_SintesisOrden

			DECLARE @IsOpcionActiva Bit
			SELECT @IsOpcionActiva=Activa FROM ConfiguracionSISE with(nolock) WHERE ConfiguracionOpcionSISEId = 5 AND CatOrganismoId = @CatOrganismoId
			
			IF @IsOpcionActiva IS NULL
			BEGIN
			SET @IsOpcionActiva = 0
			END
					
			IF @IsOpcionActiva = 1
			BEGIN
		
			UPDATE SintesisAcuerdoAsunto with(rowlock) 
				SET FechaPublicacion = null
				WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @pi_SintesisOrden
				AND CatOrganismoId = CatOrganismoId AND StatusReg = 1
			
			END
		
			UPDATE SintesisAcuerdoAsunto with(rowlock) 
				SET StatusReg = 2
				WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @pi_SintesisOrden
				AND CatOrganismoId = CatOrganismoId AND StatusReg = 1
			

			IF @TipoOrigen = 7
			BEGIN 
				UPDATE DeterminacionesJudiciales with(rowlock) 
				SET StatusReg = 2 
				WHERE AsuntoNeunId = @pi_AsuntoNeunId  AND SintesisOrden = @pi_SintesisOrden

				SET @ValidaNot = (SELECT COUNT(1) FROM NotificacionElectronica_Personas with(nolock) where AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @pi_SintesisOrden)
				IF @ValidaNot > 0
				BEGIN
					UPDATE NotificacionElectronica_Personas set StatusReg = 0, FechaBaja = getdate() where AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @pi_SintesisOrden
					AND StatusReg = 1
				END
			END
			ELSE
				BEGIN
					UPDATE DeterminacionesJudiciales with(rowlock) 
					SET StatusReg = 0, FechaBaja = GETDATE()
					WHERE AsuntoNeunId = @pi_AsuntoNeunId AND  SintesisOrden = @pi_SintesisOrden
					AND StatusReg = 1
				END
			

			UPDATE AsuntosDocumentos with(rowlock) 
			SET CatAutorizacionDocumentosId = 4, 
			FechaCancela = GETDATE(),
			EmpleadoIdCancela = @pi_Valor
			WHERE AsuntoNeunId = @pi_AsuntoNeunId and AsuntoDocumentoId = @pi_AsuntoDocumentoId  AND  SintesisOrden = @pi_SintesisOrden
			AND StatusReg = 1
		

			
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
GO

