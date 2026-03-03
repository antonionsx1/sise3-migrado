SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/10/2023
-- Description: Actualiza Estado tramite
-- Basado en:   [usp_AsuntosDocumentosTitularSecretario], usp_AsuntosDocumentosCambiaStatusUpd, 
-- Exec [SISE3].[paActualizaEstadoAcuerdo] 18939614, 5, 1, 62234, 'PRUEBA_3.docx'

-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[paActualizaEstadoAcuerdo]

(
       @pi_AsuntoNeunId BIGINT,  
	   @pi_AsuntoDocumentoId INT,  
       @pi_TipoUpdate INT,  -- 1 Preautorización , 2 Autorizados,  3 Cancelado
       @pi_EmpleadoId BIGINT,    -- EmpleadoId que preautoriza
	   @pi_NombreDocumento VARCHAR(MAX),   --Nombre del archivo mas la extensión
	   @pi_PreautorizadoSinFirma BIT -- True si el acuerdo fue preautorizado sin usar firma
)
AS
BEGIN
	BEGIN TRY

		DECLARE @IsOpcionActiva BIT, @pi_AsuntoId INT , @estadoActual INT, @ValidaNot INT, @pi_CatAutorizacionDocumentosId  INT
		DECLARE @CatAutorizacionId INT
		DECLARE @CatAutorizacionDocumentosId SMALLINT  --2 (pre-autorización), 1 (No autorizado)
		DECLARE @pi_SintesisOrden INT

		SET @pi_AsuntoId = 1

		SELECT TOP 1 @estadoActual = CatAutorizacionDocumentosId , @pi_SintesisOrden = SintesisOrden 
		FROM AsuntosDocumentos
		WHERE StatusReg <> 0
			  AND AsuntoNeunId = @pi_AsuntoNeunId 
			  AND AsuntoDocumentoId = @pi_AsuntoDocumentoId

		

		/*Validacion para cambiar a cancelado */
		IF @pi_TipoUpdate = 3
		BEGIN
			IF @estadoActual  NOT IN (2,3) 
			BEGIN 
				THROW 51000,'No es posible cancelar, no se cumple con los requisitos',1;
			END
			ELSE
			BEGIN
				--- Cancela Autorización -----
				IF @estadoActual = 3 
				BEGIN	

					/*SET @ValidaNot = (SELECT COUNT(1) 
									  FROM NotificacionElectronica_Personas WITH(NOLOCK) 
									  WHERE AsuntoNeunId = @pi_AsuntoNeunId 
									        AND SintesisOrden = @pi_SintesisOrden
									 )*/

					IF @ValidaNot > 0
					BEGIN 
						THROW 51000,'No es posible cancelar, porque tiene notificación',1;
					END
					ELSE 
					BEGIN 
						EXEC SISE3.paDesactivaAcuerdo
							@pi_AsuntoId 
							,@pi_AsuntoNeunId 
							,@pi_SintesisOrden 
							,@pi_AsuntoDocumentoId 
							,@pi_EmpleadoId
					END
				END
				---------- Calcelación ----------
				IF @estadoActual = 2
				BEGIN	
					SET @CatAutorizacionDocumentosId = 2

					EXEC usp_AsuntosDocumentosTitularSecretario 
						@pi_AsuntoNeunId ,
						@pi_AsuntoDocumentoId ,
						@pi_TipoUpdate ,
						@pi_EmpleadoId 

					UPDATE AsuntosDocumentos WITH(ROWLOCK) 
					SET catAutorizacionDocumentosId = 4, 
						FechaCancela = GETDATE(),
						EmpleadoIdCancela = @pi_EmpleadoId
					WHERE AsuntoNeunId = @pi_AsuntoNeunId 
						  AND AsuntoDocumentoId = @pi_AsuntoDocumentoId  
						  AND  SintesisOrden = @pi_SintesisOrden
						  AND StatusReg = 1
				END
			END
		END

		/*Validacion para cambiar a preautorizado */
		IF @pi_TipoUpdate = 1
		BEGIN
			IF @estadoActual  IN (2,3) 
			BEGIN 
				THROW 51000,'No es posible preautorizar, no se cumple con los requisitos',1;
			END
			ELSE 
			BEGIN
				EXEC usp_AsuntosDocumentosTitularSecretario 
						@pi_AsuntoNeunId ,
						@pi_AsuntoDocumentoId ,
						@pi_TipoUpdate ,
						@pi_EmpleadoId 

				UPDATE AsuntosDocumentos WITH(ROWLOCK) 
				SET CatAutorizacionDocumentosId = 2, 
					FechaPreautoriza = GETDATE(),
					EmpleadoIdPreautoriza = @pi_EmpleadoId
					--PreautorizadoSinFirma = @pi_PreautorizadoSinFirma
				WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					  AND AsuntoDocumentoId = @pi_AsuntoDocumentoId  
					  AND  SintesisOrden = @pi_SintesisOrden
					  AND StatusReg = 1

				UPDATE SISE3.AsuntosDocumentosAdicional WITH(ROWLOCK)
				SET PreautorizadoSinFirma = @pi_PreautorizadoSinFirma
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
					  AND AsuntoDocumentoId = @pi_AsuntoDocumentoId

				SET @pi_CatAutorizacionDocumentosId = 2; 
				--EXEC usp_AsuntosDocumentosCambiaStatusUpd
				--		@pi_AsuntoNeunId,
				--		@pi_AsuntoID,
				--		@pi_AsuntoDocumentoId ,
				--		2 
			END 
		END

		/*Validacion para cambiar a autorizado */
		IF @pi_TipoUpdate = 2
		BEGIN
			IF @estadoActual <> 2
			BEGIN 
				THROW 51000,'No es posible preautorizar, no se cumple con los requisitos',1;
			END
			ELSE 
			BEGIN 
				DECLARE @pi_NumeroOrden INT

				SET @pi_CatAutorizacionDocumentosId = 3
					
				SELECT @pi_NumeroOrden = MAX(NumeroOrden)
				FROM DeterminacionesJudiciales
				WHERE AsuntoNeunId = @pi_AsuntoNeunId 
				      AND SintesisOrden = @pi_SintesisOrden

				EXEC usp_AsuntosDocumentosTitularSecretario 
						@pi_AsuntoNeunId ,
						@pi_AsuntoDocumentoId ,
						@pi_TipoUpdate ,
						@pi_EmpleadoId 
 
				EXEC SISE_paDocCargaPanelDeterminacionAut
						@pi_AsuntoNeunId ,
						@pi_SintesisOrden ,
						@pi_NumeroOrden,
						1 ,--pa_statusReg
						@pi_NombreDocumento,  --pa_NombreArchivo = 
						@pi_EmpleadoId --pa_TitularId =   -- = EmpleadoId que Autoriza
							 
				--EXEC usp_AsuntosDocumentosCambiaStatusUpd
				--		@pi_AsuntoNeunId,
				--		@pi_AsuntoID,
				--		@pi_AsuntoDocumentoId ,
				--		3 
				UPDATE AsuntosDocumentos WITH(ROWLOCK) 
				SET CatAutorizacionDocumentosId = 3, 
					FechaAutoriza = GETDATE(),
					EmpleadoIdAutoriza = @pi_EmpleadoId
				WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					  AND AsuntoDocumentoId = @pi_AsuntoDocumentoId  
					  AND  SintesisOrden = @pi_SintesisOrden
					  AND StatusReg = 1
			END
			
			DECLARE @TipoRuta INT
			SET @TipoRuta = (SELECT TipoRuta
							 FROM AsuntosDocumentos WITH(NOLOCK) 
							 WHERE AsuntoNeunId = @pi_AsuntoNeunId 
								   AND AsuntoDocumentoId = @pi_AsuntoDocumentoId)

			DECLARE @UserId INT
			IF (@pi_CatAutorizacionDocumentosId = 2)
			BEGIN
				SET @UserId = (SELECT TOP 1 EmpleadoIdPreautoriza 
							   FROM AsuntosDocumentos WITH(NOLOCK) 
							   WHERE AsuntoNeunId = @pi_AsuntoNeunId 
									 AND AsuntoDocumentoId = @pi_AsuntoDocumentoId)
			END
			ELSE IF (@pi_CatAutorizacionDocumentosId = 3)
			BEGIN
				SET @UserId = (SELECT TOP 1 EmpleadoIdAutoriza 
							   FROM AsuntosDocumentos WITH(NOLOCK) 
							   WHERE AsuntoNeunId = @pi_AsuntoNeunId 
									 AND AsuntoDocumentoId = @pi_AsuntoDocumentoId)
			END
			ELSE IF (@pi_CatAutorizacionDocumentosId = 4)
			BEGIN
				SET @UserId = (SELECT TOP 1 EmpleadoIdCancela 
							   FROM AsuntosDocumentos WITH(NOLOCK) 
							   WHERE AsuntoNeunId = @pi_AsuntoNeunId 
									 AND AsuntoDocumentoId = @pi_AsuntoDocumentoId)
			END
			ELSE IF (@pi_CatAutorizacionDocumentosId = 1)
			BEGIN
				SET @UserId = (SELECT TOP 1 EmpleadoIdCancela 
							   FROM AsuntosDocumentos WITH(NOLOCK) 
							   WHERE AsuntoNeunId = @pi_AsuntoNeunId 
									 AND AsuntoDocumentoId = @pi_AsuntoDocumentoId)
			END

			DECLARE @dt DATETIME
			SET @dt = GETDATE() 
			DECLARE @CancelaPreAutorizacion INT 
			DECLARE @CancelaAutorizacion INT 

			IF (@TipoRuta = 7 AND @pi_CatAutorizacionDocumentosId = 4)
			BEGIN 
				SET @pi_CatAutorizacionDocumentosId = 1
				SET @CancelaAutorizacion = 9
			END 

			ELSE IF (@TipoRuta = 7 AND @pi_CatAutorizacionDocumentosId = 1)
			BEGIN 
				SET @pi_CatAutorizacionDocumentosId = 1
				SET @CancelaPreAutorizacion = 8
			END 

			IF (@TipoRuta = 7 AND @pi_CatAutorizacionDocumentosId = 1 AND @CancelaAutorizacion = 9)
			BEGIN 
				EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@CancelaAutorizacion,@dt,@UserId
			END
			ELSE IF (@TipoRuta = 7 AND @pi_CatAutorizacionDocumentosId = 1 and @CancelaPreAutorizacion = 8)
			BEGIN
				EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@CancelaPreAutorizacion,@dt,@UserId
			END
			ELSE 
			BEGIN
				EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@pi_CatAutorizacionDocumentosId,@dt,@UserId
			END
		END
	END TRY 
	BEGIN CATCH
			-- Ejecuta la rutina de recuperacion de errores.
			EXECUTE dbo.usp_GetErrorInfo;
	END CATCH;
END