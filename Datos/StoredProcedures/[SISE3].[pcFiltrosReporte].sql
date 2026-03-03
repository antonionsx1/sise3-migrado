SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:		Erick Garcia de la Rosa
-- Create date: 24/01/2025
-- Description:	Permite obtener la configuración de filtros de un reporte
-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcFiltrosReporte]
	@pc_IdReporte BIGINT
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(4000)
		   ,@ErrorSeverity INT
		   ,@ErrorState INT

	BEGIN TRY

		SELECT 
			FR.IdReporteFiltro,
			FR.sNombreParametro,
			FR.sEtiqueta,
			FR.sTipoDato,
			FR.Orden,
			RP.IdReporteProcedimiento
		FROM [SISE3].[ReporteFiltros] FR
		INNER JOIN SISE3.ReportesProcedimientos RP ON RP.IdReporteProcedimiento=FR.IdReporteProcedimiento
		INNER JOIN SISE3.Reportes R ON R.IdReporte=RP.IdReporte
		WHERE R.IdReporte=@pc_IdReporte AND R.bActivo=1 AND FR.bActivo=1 AND RP.bActivo=1;
	
	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END