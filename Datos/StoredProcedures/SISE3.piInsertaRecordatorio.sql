-- =============================================
-- Author: FJSR
-- Create date: 27/06/2024
-- Description: Agrega un recordatorio
-- Basado en: [dbo].[uspx_rec_addRecordatorio]
-- EXEC 
-- Example:
/*      
  DECLARE @RecordatorioId BIGINT
  EXEC [SISE3].[piInsertaRecordatorio] 11318444,523, 'Insertando desde base sise3', '2024-06-27',49841, 49841,@RecordatorioId OUTPUT 
  SELECT @RecordatorioId     
*/
-- =============================================
CREATE PROCEDURE [SISE3].[piInsertaRecordatorio]
	@pi_AsuntoNeunId BIGINT, 
    @pi_DocumentoId INT, 
    @pi_Observacion VARCHAR(300),
	@pi_FechaNotificacion DATE,
    @pi_EmpleadoId BIGINT,
	@pi_EmpleadoRecibe BIGINT
AS
BEGIN
    BEGIN TRY
		SET NOCOUNT ON;
		DECLARE @pi_CatOrganismoId INT 
                
        SELECT @pi_CatOrganismoId = CatOrganismoId
        FROM Asuntos
        WHERE AsuntoNeunId = @pi_AsuntoNeunId
                        
        INSERT INTO dbo.Word_ObservacionDocumento (AsuntoNeunId, CatOrganismoId, DocumentoId, Observacion, FechaNotificacion, EmpleadoId, Revisado, EmpleadoRecibe) 
		VALUES (@pi_AsuntoNeunId, @pi_CatOrganismoId, @pi_DocumentoId, @pi_Observacion, @pi_FechaNotificacion, @pi_EmpleadoId, 0, @pi_EmpleadoRecibe)

		SELECT @@IDENTITY
        END TRY
     BEGIN CATCH
		EXECUTE usp_GetErrorInfo; 
     END CATCH
END