-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 23/10/2024
-- Description:	Obtiene los datos para el reporte de Audiencias/Origen
-- Ejemplo de ejecución: EXEC [SISE3].[pcReporteAudiencias] 1500, '2024-01-01', '2024-10-31'
-- Actualización: Martin Tovar, 25/10/2024: Se actualizan Fechas Inici/Fin y se actualiza fecha/hora de parámetros

-- ==========================================================================================
ALTER PROCEDURE [SISE3].[pcReporteAudiencias] 
(
	@pi_CatOrganismoId INT,
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
		,tvigsf.fkIdAsuntoNeun
		,tvigsf.idAudiencia
		,tvigsf.AsuntoAlias
		,tvigsf.fkIdTipoAudiencia
		,tvigsf.DescripcionAsunto
		,CASE 
		    WHEN ISNULL(sub3.CatalogoDependienteDescripcion, 
		                ISNULL(ti.CatalogoDependienteDescripcion, 
		                       ISNULL(pe.CatalogoDependienteDescripcion, ''))) = 'INCIDENTES'
		         OR ISNULL(sub3.CatalogoDependienteDescripcion, '') = 'Solicitud de inicio de Procedimiento de Ejecución (SIPE)'
		         OR ISNULL(sub3.CatalogoDependienteDescripcion, '') = 'Solicitud de Traslado'
		         OR ISNULL(sub3.CatalogoDependienteDescripcion, '') = 'Controversia'
		         OR ISNULL(sub3.CatalogoDependienteDescripcion, '') = 'Ejecución Medida Cautelar'
		    THEN 'Proceso de Ejecución'
		    ELSE ISNULL(sub2.CatalogoDependienteDescripcion, ISNULL(tp.CatalogoDependienteDescripcion, '')) 
		END 							AS TipoProcedimiento
		,dbo.TAU_fnObtieneProcedimiento (tvigsf.fkIdAsuntoNeun,1)	AS Nivel1
		,dbo.TAU_fnObtieneProcedimiento (tvigsf.fkIdAsuntoNeun,2)	AS Nivel2
	    ,ISNULL(sub3.CatalogoDependienteDescripcion, 
	           ISNULL(ti.CatalogoDependienteDescripcion, 
	                  ISNULL(pe.CatalogoDependienteDescripcion, ''))
		)								AS Nivel3
	    ,ISNULL(sub4.CatalogoDependienteDescripcion, ISNULL(inc.CatalogoDependienteDescripcion, '')) AS Nivel4				
		,tvigsf.sDescripcionAudiencia
		,tvigsf.idJuez
		,tvigsf.Juez
		,tvigsf.fechaInicio
		,CAST(FORMAT(iga.fechaInicio, 'HH:mm:ss') AS VARCHAR(8))	AS horaInicio
		,tvigsf.fechaFin
		,CAST(FORMAT(iga.fechaFin, 'HH:mm:ss') AS VARCHAR(8))		AS HoraFin
		,ISNULL(iga.fechaInicioCelebrada, tvigsf.fechaInicio)		AS fechaInicioReal
		,ISNULL(iga.fechaFinCelebrada, tvigsf.fechaFin)				AS fechaFinReal
		,CASE WHEN ob.iUsuario = 0 THEN 'OralTis' ELSE 'SISE' END AS Origen
		,tvigsf.idEstatusAudiencia
		,CASE WHEN iga.BDIFERIDA = 1 THEN 'Diferida' ELSE tvigsf.descripcionEstatusAudiencia END 	AS descripcionEstatusAudiencia
		,ob.sObservacion  		
		,ISNULL(e.USERNAME,ce.USERNAME)								AS UsuarioModifica
		,iga.BDIFERIDA
	FROM TAU_VIS_InformacionGeneralSinFiltros tvigsf
	INNER JOIN InformacionGeneralAudiencia iga
		ON tvigsf.idInformacionGeneralAudiencia = iga.idInformacionGeneralAudiencia
	INNER JOIN Asuntos a WITH (NOLOCK)
		ON tvigsf.fkIdAsuntoNeun = a.AsuntoNeunId
	LEFT JOIN CatalogosDependientes tp 
		ON tp.CatalogoDependienteIdPadre = 13298 
	    AND tp.CatalogoDependienteElementoIDNew = a.CatTipoProcedimiento
	    AND tp.CatalogoDependienteId = 734
	    AND tp.CatalogoDependienteNivel = 2
	LEFT JOIN CatalogosDependientes ti 
		ON ti.CatalogoDependienteIdPadre = 13300 
	    AND ti.CatalogoDependienteElementoIDNew = a.CatTipoProcedimiento
	    AND ti.CatalogoDependienteId = 734
	    AND ti.CatalogoDependienteNivel = 3
	LEFT JOIN CatalogosDependientes pe 
		ON pe.CatalogoDependienteIdPadre = 13482
	    AND pe.CatalogoDependienteElementoIDNew = a.CatTipoProcedimiento
	    AND pe.CatalogoDependienteId = 734
	    AND pe.CatalogoDependienteNivel = 3
	LEFT JOIN CatalogosDependientes inc 
		ON inc.CatalogoDependienteIdPadre IN 
	    (SELECT ID FROM viCatalogos WHERE CatalogoPadre = 13488 AND Catalogo = 734)
	    AND inc.CatalogoDependienteElementoIDNew = a.CatTipoProcedimiento
	    AND inc.CatalogoDependienteId = 734
	    AND inc.CatalogoDependienteNivel = 4
	LEFT JOIN REL_NoCarpInvetAsuntosSISE rel2 ON rel2.iAsuntoNeunId = a.AsuntoNeunId
	LEFT JOIN CatalogosDependientes sub2
		ON sub2.CatalogoDependienteElementoIDNew = rel2.iTipoSubNivel
	    AND sub2.CatalogoDependienteId = 734
	    AND sub2.CatalogoDependienteNivel = 2
	LEFT JOIN CatalogosDependientes sub3 
		ON sub3.CatalogoDependienteElementoIDNew = rel2.iTipoSubNivel
	    AND sub3.CatalogoDependienteId = 734
	    AND sub3.CatalogoDependienteNivel = 3
	LEFT JOIN CatalogosDependientes sub4 
		ON sub4.CatalogoDependienteElementoIDNew = rel2.iTipoSubNivel
	    AND sub4.CatalogoDependienteId = 734
	    AND sub4.CatalogoDependienteNivel = 4
	LEFT JOIN TAU_Mov_Observaciones ob WITH(NOLOCK) ON iga.fkIdAsuntoNeun = ob.fAsuntoNeunId and iga.idAudiencia = ob.iAudiencia
	LEFT JOIN CatEmpleados e WITH(NOLOCK) ON e.empleadoid = ob.iUsuario
	LEFT JOIN CatEmpleados ce WITH (NOLOCK) ON iga.idUsuarioAlta = ce.EmpleadoId
	WHERE tvigsf.fkCatOrganismoId = @pi_CatOrganismoId 
		AND (tvigsf.fechaInicio BETWEEN @pi_FechaInicial AND @pi_FechaFinal OR tvigsf.fechaFin BETWEEN @pi_FechaInicial AND @pi_FechaFinal)
	ORDER BY tvigsf.idAudiencia;

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END