SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: FJSR
-- Create date: 25/06/2024
-- Description: Actualiza un recordatorio
-- Basado en: usp_Word_ObservacionDocumento_Ins
-- EXEC [SISE3].[paActualizaRecordatorio] 147295,11318444,'Actualizando desde base','2024-06-25',52936,@RecordatorioId OUTPUT 
-- EXEC 
-- Example:
/*      
  DECLARE @RecordatorioId BIGINT
  EXEC [SISE3].[paActualizaRecordatorio] 147295,11318444, 523,'Actualizando desde base 2','2024-06-25', 49841, 49841, @RecordatorioId OUTPUT 
  SELECT @RecordatorioId     
*/
-- =============================================
CREATE PROCEDURE [SISE3].[paActualizaRecordatorio]
	@pa_CatOrganismoId INT,
	@pa_RecordatorioId BIGINT, 
	@pa_AsuntoNeunId BIGINT, 
    @pa_DocumentoId INT, 
    @pa_Observacion VARCHAR(300),
	@pa_FechaNotificacion DATE,
    @pa_EmpleadoId BIGINT,
	@pa_EmpleadoRecibe BIGINT
AS
BEGIN
    BEGIN TRY
		SET NOCOUNT ON;

		UPDATE dbo.Word_ObservacionDocumento
		SET AsuntoNeunId = @pa_AsuntoNeunId
		,CatOrganismoId = @pa_CatOrganismoId
		,DocumentoId = @pa_DocumentoId
		,Observacion = @pa_Observacion
		,FechaNotificacion = @pa_FechaNotificacion
		,EmpleadoId = @pa_EmpleadoId
		,Revisado = 0
		,EmpleadoRecibe = @pa_EmpleadoRecibe
		WHERE ObservacionDocumentoId = @pa_RecordatorioId

		SELECT @pa_RecordatorioId
        END TRY
     BEGIN CATCH
		EXECUTE usp_GetErrorInfo; 
     END CATCH
END