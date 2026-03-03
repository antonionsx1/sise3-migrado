SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación: 29 de julio 2024
-- Descripción: Consulta para obtener recordatorioId
-- Ejemplo : EXEC [SISE3].[pcObtenerRecordatorioId] 147457
-- =============================================
CREATE PROCEDURE [SISE3].[pcObtenerRecordatorioId]
@pcRecordatorioId INT
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
		SELECT 
			 CONVERT(INT,R.ObservacionDocumentoId) ObservacionDocumentoId
			,CONVERT(INT,R.EmpleadoId) EmpleadoId
			,CONVERT(INT,R.EmpleadoRecibe) EmpleadoRecibe
		FROM Word_ObservacionDocumento R WITH(NOLOCK)
			WHERE ObservacionDocumentoId = @pcRecordatorioId
		END TRY
		BEGIN CATCH
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
		SET NOCOUNT OFF
	END
