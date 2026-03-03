USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[paActualizaEstadoAcuerdoAutorizado]    Script Date: 12/1/2023 6:11:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/10/2013
-- Description: Actualiza Estado tramite a Cancelado
-- Basado en:   [usp_AsuntosDocumentosTitularSecretario], usp_AsuntosDocumentosCambiaStatusUpd, 
-- Exec [SISE3].[paActualizaEstadoAcuerdoAutorizado] 18939614, 5, 62234, 'PRUEBA_3.docx'
-- =============================================

CREATE PROCEDURE [SISE3].[paActualizaEstadoAcuerdoAutorizado]
    @pi_AsuntoNeunId BIGINT,  
	@pi_AsuntoDocumentoId INT,
    @pi_EmpleadoId BIGINT,    -- EmpleadoId que autoriza
	@pi_NombreDocumento VARCHAR(MAX)   --Nombre del archivo mas la extensión 
AS
BEGIN
    BEGIN TRY

            DECLARE @pi_SintesisOrden INT
            DECLARE @pi_TipoUpdate INT = 2 -- 2 AUTORIZADO
            DECLARE @pi_CatAutorizacionDocumentosId SMALLINT = 3  --2 (pre-autorización), 1 (No autorizado), 3 (autorización)
            DECLARE @pi_NumeroOrden INT
			DECLARE @dt DATETIME = GETDATE() 
		
			SELECT TOP 1 @pi_SintesisOrden = SintesisOrden
			FROM AsuntosDocumentos
			WHERE StatusReg <> 0
				AND AsuntoNeunId = @pi_AsuntoNeunId 
				AND AsuntoDocumentoId = @pi_AsuntoDocumentoId

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

			--EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@pi_AsuntoDocumentoId,@pi_CatAutorizacionDocumentosId,@dt,@pi_EmpleadoId
    END TRY
    BEGIN CATCH
    -- Ejecuta la rutina de recuperacion de errores.
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH
END
GO

