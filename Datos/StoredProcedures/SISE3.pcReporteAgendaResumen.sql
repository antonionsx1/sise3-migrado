-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 25/10/2024
-- Description:	Obtiene los datos para el reporte de carga de trabajo Audiencias/Resumen
-- Ejemplo de ejecución: EXEC [SISE3].[pcReporteAgendaResumen] 1462, 17919, '2024-01-01', '2024-10-31'

-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcReporteAgendaResumen] 
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

	DROP TABLE IF EXISTS #tmp
	
	SELECT
		tvigsf.idInformacionGeneralAudiencia
		,tvigsf.idAudiencia
		,tvigsf.AsuntoAlias
		,tvigsf.fkIdAsuntoNeun
		,tvigsf.fkIdTipoAudiencia
		,tvigsf.sDescripcionAudiencia
		,CASE WHEN iga.bDiferida = 1 THEN 'Diferida' ELSE tvigsf.descripcionEstatusAudiencia END AS descripcionEstatusAudiencia
		,iga.bDiferida
	INTO #tmp
	FROM TAU_VIS_InformacionGeneralSinFiltros tvigsf WITH(NOLOCK)
	INNER JOIN InformacionGeneralAudiencia iga WITH(NOLOCK)
		ON tvigsf.idInformacionGeneralAudiencia = iga.idInformacionGeneralAudiencia
	WHERE tvigsf.fkCatOrganismoId = @pi_OrganismoId
		AND tvigsf.idJuez = CASE WHEN @pi_IdJuez > 0 THEN @pi_IdJuez WHEN @pi_IdJuez = -1 THEN tvigsf.idJuez END  
		AND (tvigsf.fechaInicio BETWEEN @pi_FechaInicial AND @pi_FechaFinal OR tvigsf.fechaFin BETWEEN @pi_FechaInicial AND @pi_FechaFinal)
	ORDER BY tvigsf.idAudiencia;
	
	--Resumen
	SELECT
		fkIdTipoAudiencia,
		sDescripcionAudiencia
		,COUNT(*)							AS TotalAudiencias
		,SUM(CASE WHEN descripcionEstatusAudiencia = 'Agendada' THEN 1 ELSE 0 END)							AS TotalAudienciasAgendadas
		,SUM(CASE WHEN descripcionEstatusAudiencia = 'Celebrada' THEN 1 ELSE 0 END)							AS TotalAudienciasCelebradas
		,SUM(CASE WHEN descripcionEstatusAudiencia = 'Cancelada' AND bDiferida = 0 THEN 1 ELSE 0 END)		AS TotalAudienciasCanceladas
		,SUM(CASE WHEN bDiferida = 1 THEN 1 ELSE 0 END)														AS TotalAudienciasDiferidas
	FROM #tmp
	GROUP BY fkIdTipoAudiencia
		,sDescripcionAudiencia
	ORDER BY sDescripcionAudiencia
	
	DROP TABLE IF EXISTS #tmp

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END