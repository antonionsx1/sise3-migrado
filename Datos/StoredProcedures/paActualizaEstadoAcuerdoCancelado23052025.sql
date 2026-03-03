USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[paActualizaEstadoAcuerdoCancelado]    Script Date: 19/05/2025 02:42:56 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/10/2023
-- Description: Actualiza Estado tramite a Cancelado
-- Basado en:   [usp_AsuntosDocumentosTitularSecretario], usp_AsuntosDocumentosCambiaStatusUpd, 
-- Exec [SISE3].[paActualizaEstadoAcuerdoCancelado] 30312293, 2, 62234
-- Modificación: JSM 21/11/24 Ajuste de notificaciones
-- Modificación: JARR 05/06/25 Ajuste de extensión del documento

-- =============================================

ALTER PROCEDURE [SISE3].[paActualizaEstadoAcuerdoCancelado]
    @pi_AsuntoNeunId BIGINT,  
	@pi_AsuntoDocumentoId INT,
    @pi_EmpleadoId BIGINT,    -- EmpleadoId que preautoriza
	@pi_NombreDocumento VARCHAR(MAX) = NULL,
	@pi_PreautorizadoSinFirma BIT, -- True si el acuerdo fue preautorizado sin usar firma
	@pi_TipoUpdate INT = NULL
AS
BEGIN
    BEGIN TRY
        DECLARE @EstadoActual INT
        DECLARE @SintesisOrden INT
		DECLARE @CatAutorizacionDocumentosId INT
		DECLARE @dt DATETIME = GETDATE() 
		DECLARE @Extension VARCHAR(20)

		SELECT TOP 1 @EstadoActual = CatAutorizacionDocumentosId
                    ,@SintesisOrden = SintesisOrden
        FROM dbo.AsuntosDocumentos
        WHERE StatusReg <> 0
            AND AsuntoNeunId = @pi_AsuntoNeunId 
            AND AsuntoDocumentoId = @pi_AsuntoDocumentoId;

		IF @EstadoActual NOT IN(2, 3)
		BEGIN
			;THROW 51000, 'No es posible cancelar, No se encuentra en estado para cancelar', 1;
		END
		
		SET @CatAutorizacionDocumentosId = 4

		SELECT @Extension = ExtensionDocumento
		FROM dbo.AsuntosDocumentos
		WHERE AsuntoNeunId = @pi_AsuntoNeunId 
			AND AsuntoDocumentoId = @pi_AsuntoDocumentoId 

		IF (@Extension <> '.doc' AND @Extension <> '.docx')
		BEGIN
			SELECT @Extension = ExtensionDocumentoOriginal 
			FROM SISE3.AsuntosDocumentosAdicional
			WHERE AsuntoNeunId = @pi_AsuntoNeunId 
				AND AsuntoDocumentoId = @pi_AsuntoDocumentoId
		END

		IF(@Extension IS NULL OR @Extension = '')
		BEGIN
			SET @Extension = '.doc'
		END
		
		UPDATE dbo.AsuntosDocumentos WITH(ROWLOCK) 
		SET catAutorizacionDocumentosId = @CatAutorizacionDocumentosId, 
			FechaCancela = GETDATE(),
            EmpleadoIdCancela = @pi_EmpleadoId,
			ExtensionDocumento = @Extension,
			uGuidDocumento = NEWID(),
			Firmado = NULL,
			NombreArchivo = REPLACE(NombreArchivo,SUBSTRING(NombreArchivo, LEN(NombreArchivo) - CHARINDEX('.',REVERSE(NombreArchivo)) + 1, 100),'')
		WHERE AsuntoNeunId = @pi_AsuntoNeunId 
			AND AsuntoDocumentoId = @pi_AsuntoDocumentoId  
			AND SintesisOrden = @SintesisOrden
			AND StatusReg = 1

		UPDATE dbo.SintesisAcuerdoAsunto
		SET StatusReg = 2
		WHERE AsuntoNeunId = @pi_AsuntoNeunId 
			AND SintesisOrden = @SintesisOrden

		UPDATE dbo.DeterminacionesJudiciales
		SET StatusReg = 2
		WHERE AsuntoNeunId = @pi_AsuntoNeunId 
			AND SintesisOrden = @SintesisOrden

		UPDATE dbo.NotificacionElectronica
		SET StatusReg = 2, FechaActualiza = GETDATE()
		WHERE AsuntoNeunId = @pi_AsuntoNeunId
			AND SintesisOrden = @SintesisOrden 
			
		UPDATE dbo.NotificacionElectronica_Personas
		SET StatusReg = 2	
		WHERE AsuntoNeunId = @pi_AsuntoNeunId
			AND SintesisOrden = @SintesisOrden
				
		EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@CatAutorizacionDocumentosId,@dt,@pi_EmpleadoId;

    END TRY
    BEGIN CATCH
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH
END