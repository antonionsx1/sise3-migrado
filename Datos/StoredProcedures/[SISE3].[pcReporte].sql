SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:		Erick Garcia de la Rosa
-- Create date: 17/01/2025
-- Description:	Permite obtener la informacion de un reporte
-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcReporte]
	@pc_IdReporte BIGINT
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(4000)
		   ,@ErrorSeverity INT
		   ,@ErrorState INT

	BEGIN TRY

		SELECT 
			R.IdReporte,
			R.CatTipoOrganismoId,
			R.CatTipoAsuntoId,
			R.sNombre,
			R.sDescripcion,
			RP.IdReporteProcedimiento,
			RP.sProcedimientoAlmacenado
		FROM SISE3.Reportes R
		INNER JOIN SISE3.ReportesProcedimientos RP ON RP.IdReporte=R.IdReporte
		WHERE R.IdReporte=@pc_IdReporte AND R.bActivo=1 AND RP.bActivo=1;
	
	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END