USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[paActualizaEstadoAcuerdoCancelado]    Script Date: 12/1/2023 6:11:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/10/2013
-- Description: Actualiza Estado tramite a Cancelado
-- Basado en:   [usp_AsuntosDocumentosTitularSecretario], usp_AsuntosDocumentosCambiaStatusUpd, 
-- Exec [SISE3].[paActualizaEstadoAcuerdoCancelado] 18939614, 5, 62234
-- =============================================

CREATE PROCEDURE [SISE3].[paActualizaEstadoAcuerdoCancelado]
    @pi_AsuntoNeunId BIGINT,  
	@pi_AsuntoDocumentoId INT,
    @pi_EmpleadoId BIGINT,    -- EmpleadoId que preautoriza
	@pi_NombreDocumento VARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY

        DECLARE @estadoActual INT
        DECLARE @pi_SintesisOrden INT
        DECLARE @pi_AsuntoId INT = 1
        DECLARE @pi_TipoUpdate INT = 3 -- 3 CANCELACION
        DECLARE @CatAutorizacionDocumentosId SMALLINT  --2 (pre-autorización), 1 (No autorizado)
		DECLARE @pi_CatAutorizacionDocumentosId INT
		DECLARE @dt DATETIME = GETDATE() 

        SELECT TOP 1 @estadoActual = CatAutorizacionDocumentosId
                    ,@pi_SintesisOrden = SintesisOrden
        FROM AsuntosDocumentos
        WHERE StatusReg <> 0
            AND AsuntoNeunId = @pi_AsuntoNeunId 
            AND AsuntoDocumentoId = @pi_AsuntoDocumentoId
           
        IF @estadoActual = 3  --- Cancela Autorización ---
        BEGIN
			SET @pi_CatAutorizacionDocumentosId = 9
            -- Valida que no tenga notificación
            IF EXISTS ( 
                SELECT 1 
                FROM NotificacionElectronica_Personas WITH(NOLOCK) 
                WHERE AsuntoNeunId = @pi_AsuntoNeunId 
                    AND SintesisOrden = @pi_SintesisOrden
                )
            BEGIN 
                THROW 51000, 'No es posible cancelar, porque tiene notificación', 1;
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
        ELSE IF @estadoActual = 2 ---------- Calcelación ----------
        BEGIN
			SET @pi_CatAutorizacionDocumentosId = 8

            EXEC usp_AsuntosDocumentosTitularSecretario 
                @pi_AsuntoNeunId,
                @pi_AsuntoDocumentoId,
                @pi_TipoUpdate,
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

		--EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@pi_CatAutorizacionDocumentosId,@dt,@pi_EmpleadoId

    END TRY
    BEGIN CATCH
    -- Ejecuta la rutina de recuperacion de errores.
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH
END

GO

