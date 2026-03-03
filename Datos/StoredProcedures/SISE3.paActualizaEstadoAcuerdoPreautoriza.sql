SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/10/2023
-- Description: Actualiza Estado tramite a Cancelado
-- Basado en:   [usp_AsuntosDocumentosTitularSecretario], usp_AsuntosDocumentosCambiaStatusUpd, 
-- Exec [SISE3].[paActualizaEstadoAcuerdoPreautoriza] 18939614, 5, 62234
-- =============================================

CREATE OR ALTER PROCEDURE [SISE3].[paActualizaEstadoAcuerdoPreautoriza]
    @pi_AsuntoNeunId BIGINT,  
	@pi_AsuntoDocumentoId INT,
    @pi_EmpleadoId BIGINT,    -- EmpleadoId que preautoriza
	@pi_NombreDocumento VARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY

        DECLARE @pi_SintesisOrden INT
        DECLARE @pi_TipoUpdate INT = 1 -- 1 PREAUTORIZA
		DECLARE @pi_CatAutorizacionDocumentosId INT = 2
		DECLARE @dt DATETIME = GETDATE() 

		SELECT TOP 1 @pi_SintesisOrden = SintesisOrden
        FROM AsuntosDocumentos
        WHERE StatusReg <> 0
            AND AsuntoNeunId = @pi_AsuntoNeunId 
            AND AsuntoDocumentoId = @pi_AsuntoDocumentoId

		EXEC usp_AsuntosDocumentosTitularSecretario 
				@pi_AsuntoNeunId ,
				@pi_AsuntoDocumentoId ,
				@pi_TipoUpdate ,
				@pi_EmpleadoId 

		UPDATE AsuntosDocumentos WITH(ROWLOCK) 
		SET CatAutorizacionDocumentosId = 2, 
			FechaPreautoriza = GETDATE(),
			EmpleadoIdPreautoriza = @pi_EmpleadoId
		WHERE AsuntoNeunId = @pi_AsuntoNeunId 
				AND AsuntoDocumentoId = @pi_AsuntoDocumentoId  
				AND  SintesisOrden = @pi_SintesisOrden
				AND StatusReg = 1

		--EXEC usp_AsuntosDocumentosCambiaStatusUpd
		--		@pi_AsuntoNeunId,
		--		@pi_AsuntoID,
		--		@pi_AsuntoDocumentoId ,
		--		2 

		EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@pi_CatAutorizacionDocumentosId,@dt,@pi_EmpleadoId

    END TRY
    BEGIN CATCH
    -- Ejecuta la rutina de recuperacion de errores.
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH
END