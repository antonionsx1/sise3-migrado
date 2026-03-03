-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 25/10/2024
-- Description:	Obtiene los datos para el reporte de carga de trabajo Audiencias/Detalle
-- Ejemplo de ejecución: EXEC [SISE3].[pcReporteAgendaDetalle] 1462, 17919, '2024-01-01', '2024-10-31'

-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcReporteAgendaDetalle] 
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
		tvigsf.idInformacionGeneralAudiencia
		,tvigsf.idAudiencia
		,tvigsf.AsuntoAlias
		,tvigsf.fkIdAsuntoNeun
		,tvigsf.DescripcionAsunto
		,tvigsf.fkIdTipoAudiencia
		,tvigsf.sDescripcionAudiencia
		,tvigsf.fechaInicio
		,tvigsf.fechaFin
		,tvigsf.idEstatusAudiencia
		,CASE WHEN iga.bDiferida = 1 THEN 'Diferida' ELSE tvigsf.descripcionEstatusAudiencia END AS descripcionEstatusAudiencia
		,tvigsf.idJuez
		,tvigsf.Juez
		,iga.bDiferida
	FROM TAU_VIS_InformacionGeneralSinFiltros tvigsf WITH(NOLOCK)
	INNER JOIN InformacionGeneralAudiencia iga WITH(NOLOCK)
		ON tvigsf.idInformacionGeneralAudiencia = iga.idInformacionGeneralAudiencia
	WHERE tvigsf.fkCatOrganismoId = @pi_OrganismoId
		AND tvigsf.idJuez = CASE WHEN @pi_IdJuez > 0 THEN @pi_IdJuez WHEN @pi_IdJuez = -1 THEN tvigsf.idJuez END 
		AND (tvigsf.fechaInicio BETWEEN @pi_FechaInicial AND @pi_FechaFinal OR tvigsf.fechaFin BETWEEN @pi_FechaInicial AND @pi_FechaFinal)
	ORDER BY AsuntoAlias
		,fkIdAsuntoNeun
		,idAudiencia

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END