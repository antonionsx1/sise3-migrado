-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 25/10/2024
-- Description:	Obtiene los datos para el reporte de carga de trabajo de resoluciones sin audiencia/Resumen
-- Ejemplo de ejecución: EXEC [SISE3].[pcReporteAgendaResSAudienciaResumen] 1500, '2024-01-01', '2024-10-31'

-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcReporteAgendaResSAudienciaResumen] 
(
	@pi_OrganismoId INT,
	@pi_IdJuez BIGINT,
    @pi_FechaInicial DATETIME,
    @pi_FechaFinal DATETIME
)
AS
BEGIN

	BEGIN TRY

	DECLARE @ErrorMessage NVARCHAR(4000)
		   ,@ErrorSeverity INT
		   ,@ErrorState INT
	
	SELECT
		info.fkIdTipoResolucion					AS IdTipoResolucion
		,c.sTipoResolucion						AS TipoResolucion
		,COUNT(*)								AS TotalAudiencias
	FROM TAU_MOV_ResolucionSolicitudes info WITH (NOLOCK) 
	LEFT JOIN TAU_CAT_TipoResolucion c WITH (NOLOCK) ON c.kIdTipoResolucion = info.fkIdTipoResolucion
	WHERE info.fkCatOrganismoId = @pi_OrganismoId
		AND info.idJuez = CASE WHEN @pi_IdJuez > 0 THEN @pi_IdJuez WHEN @pi_IdJuez = -1 THEN info.idJuez END
		AND (ISNULL(info.fechaInicio, info.fechaInicioCelebrada) BETWEEN @pi_FechaInicial AND @pi_FechaFinal OR ISNULL(info.fechaFin, info.fechaFinCelebrada) BETWEEN @pi_FechaInicial AND @pi_FechaFinal)
		AND c.bEstatusRegistro = 1
		AND info.fkIdEstatusResolucion IN (1,2,3) --solo agendadas y celebradas
	GROUP BY info.fkIdTipoResolucion
		,c.sTipoResolucion
	ORDER BY TipoResolucion

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END
