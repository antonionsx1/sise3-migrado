-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 25/10/2024
-- Description:	Obtiene los datos para el reporte de carga de trabajo de resoluciones en audiencia/Detalle
-- Ejemplo de ejecución: EXEC [SISE3].[pcReporteAgendaResCAudienciaDetalle] 1509, 60250, '2000-01-01', '2024-10-31'

-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcReporteAgendaResCAudienciaDetalle]
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
		tvigsf.idInformacionGeneralAudiencia	AS Id
		,tvigsf.idAudiencia						AS IdAudiencia
		,tvigsf.AsuntoAlias						AS AsuntoAlias
		,tvigsf.fkIdAsuntoNeun					AS Neun
		,tvigsf.DescripcionAsunto   			AS TipoAsunto
		,tvigsf.fkIdTipoAudiencia				AS IdTipoAudiencia
		,tvigsf.sDescripcionAudiencia			AS TipoAudiencia
		,ra.fkIdTipoResolucion					AS IdTipoResolucion
		,ra.sDescripcionResolucion				AS TipoResolucion
		,tvigsf.fechaInicio						AS FechaInicio
		,tvigsf.fechaFin						AS FechaFin
		,tvigsf.idEstatusAudiencia				AS IdEstatus
		,tvigsf.descripcionEstatusAudiencia		AS Estatus
		,tvigsf.idJuez							AS IdJuez
		,tvigsf.Juez							AS Juez
	FROM TAU_VIS_InformacionGeneralSinFiltros tvigsf WITH(NOLOCK)
	INNER JOIN InformacionGeneralAudiencia iga WITH(NOLOCK)
		ON tvigsf.idInformacionGeneralAudiencia = iga.idInformacionGeneralAudiencia
	INNER JOIN TAU_REL_ResolucionesAudiencia ra WITH(NOLOCK) ON ra.fkIdInformacionGeneralAudiencia = tvigsf.idInformacionGeneralAudiencia AND ra.iStatusReg = 1
	LEFT JOIN TAU_CAT_TipoResolucion c WITH (NOLOCK) ON c.kIdTipoResolucion = ra.fkIdTipoResolucion
	WHERE tvigsf.fkCatOrganismoId = @pi_OrganismoId
		AND tvigsf.idJuez = CASE WHEN @pi_IdJuez > 0 THEN @pi_IdJuez WHEN @pi_IdJuez = -1 THEN tvigsf.idJuez END
		AND (tvigsf.fechaInicio BETWEEN @pi_FechaInicial AND @pi_FechaFinal OR tvigsf.fechaFin BETWEEN @pi_FechaInicial AND @pi_FechaFinal)
		AND tvigsf.idEstatusAudiencia IN (4) --solo agendadas y celebradas
	ORDER BY AsuntoAlias
		,Neun
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