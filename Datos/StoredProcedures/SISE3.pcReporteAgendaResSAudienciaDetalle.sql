-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 25/10/2024
-- Description:	Obtiene los datos para el reporte de carga de trabajo de resoluciones en audiencia/Detalle
-- Ejemplo de ejecución: EXEC [SISE3].[pcReporteAgendaResSAudienciaDetalle] 1500, '2024-01-01', '2024-10-31'

-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcReporteAgendaResSAudienciaDetalle]
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
		info.kIdResolucionSolicitudes			AS Id
		,info.idResolucion						AS IdResolucion
		,info.AsuntoAlias						AS AsuntoAlias
		,info.kIdResolucionSolicitudes			AS Neun
		,dbo.TAU_fnObtieneProcedimiento(info.fkIdAsuntoNeun,0)		AS TipoAsunto
		,info.fkIdTipoResolucion				AS IdTipoResolucion
		,c.sTipoResolucion						AS TipoResolucion
		,info.fechaInicio						AS FechaInicio
		,info.fechaFin							AS FechaFin
		,info.fkIdEstatusResolucion				AS IdEstatus
		,er.sEstatusResolucion					AS Estatus
		,info.idJuez							AS IdJuez
		,CONCAT(e.Nombre,' ', e.ApellidoPaterno, ' ', e.ApellidoMaterno)	AS Juez
	FROM TAU_MOV_ResolucionSolicitudes info WITH (NOLOCK) 
	LEFT JOIN TAU_CAT_TipoResolucion c WITH (NOLOCK) ON c.kIdTipoResolucion = info.fkIdTipoResolucion
	LEFT JOIN TAU_CAT_EstatusResolucion er WITH(NOLOCK)
		ON er.kIdEstatusResolucion = info.fkIdEstatusResolucion
	LEFT JOIN Catempleados e WITH(NOLOCK) ON e.EmpleadoId = info.idJuez
	WHERE info.fkCatOrganismoId = @pi_OrganismoId
		AND info.idJuez = CASE WHEN @pi_IdJuez > 0 THEN @pi_IdJuez WHEN @pi_IdJuez = -1 THEN info.idJuez END
		AND (ISNULL(info.fechaInicio, info.fechaInicioCelebrada) BETWEEN @pi_FechaInicial AND @pi_FechaFinal OR ISNULL(info.fechaFin, info.fechaFinCelebrada) BETWEEN @pi_FechaInicial AND @pi_FechaFinal)
		AND c.bEstatusRegistro = 1
		AND info.fkIdEstatusResolucion IN (1,2,3) --solo agendadas y celebradas
	ORDER BY AsuntoAlias
		,Neun
		,IdResolucion

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END
