SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [SISE3].[pcObtenerRecordatoriosXparametros]
    @pc_AsuntoNeunId BIGINT = NULL
	,@pc_catOrganismoId INT
    ,@pc_empleadoId INT = NULL
    ,@pc_expediente NVARCHAR(50) = NULL
    ,@pc_fechaInicio DATE = NULL
    ,@pc_fechaFin DATE = NULL
    ,@pc_empleadoRecibe INT = NULL
AS
BEGIN
DECLARE 
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT;

	BEGIN TRY
		SELECT od.ObservacionDocumentoId
			,od.AsuntoNeunId
			,od.CatOrganismoId
			,od.DocumentoId
			,od.Observacion Recordatorio
			,od.FechaNotificacion Fecha
			,od.EmpleadoId EmpleadoId
			,od.EmpleadoRecibe EmpleadoRecibeId
			,LTRIM(CatEmp.Nombre) + ' ' + ISNULL(CatEmp.ApellidoPaterno,'') +' ' + ISNULL(CatEmp.ApellidoMaterno,'') EmpleadoCaptura			
			,LTRIM(CatEmpRe.Nombre) + ' ' + ISNULL(CatEmpRe.ApellidoPaterno,'') +' ' + ISNULL(CatEmpRe.ApellidoMaterno,'') EmpleadoRecibe
			,a.AsuntoAlias Expediente
			,ct.Descripcion TipoAsunto			
			,cd.CatalogoDependienteDescripcion Procedimiento
		FROM dbo.Word_ObservacionDocumento od
		LEFT JOIN Asuntos a WITH(NOLOCK) ON od.AsuntoNeunId = a.AsuntoNeunId
		LEFT JOIN CatTiposAsunto ct WITH(NOLOCK) ON  a.CatTipoAsuntoId = ct.CatTipoAsuntoId		
		LEFT JOIN CatalogosDependientes cd WITH(NOLOCK) ON cd.CatalogoDependienteElementoIDNew = a.CatTipoProcedimiento AND cd.CatalogoDependienteIdPadre = 200	
		INNER JOIN CatEmpleados CatEmp WITH(NOLOCK) ON CatEmp.EmpleadoId = od.EmpleadoId 
		INNER JOIN CatEmpleados CatEmpRe WITH(NOLOCK) ON CatEmpRe.EmpleadoId = od.EmpleadoRecibe
		WHERE od.CatOrganismoId = @pc_catOrganismoId
		  AND (@pc_EmpleadoId IS NULL OR od.EmpleadoId = @pc_EmpleadoId) 
		  AND (@pc_expediente IS NULL OR a.AsuntoAlias = @pc_expediente)	
		  AND ((@pc_AsuntoNeunId IS NULL) OR (@pc_AsuntoNeunId = a.AsuntoNeunId ))
		  AND (@pc_FechaInicio IS NULL OR CONVERT(DATE,od.FechaNotificacion,103) >= CONVERT(DATE,@pc_FechaInicio,103) AND (@pc_FechaFin IS NULL OR CONVERT(DATE,od.FechaNotificacion,103) <= CONVERT(DATE,@pc_FechaFin,103)))
		  AND (@pc_EmpleadoRecibe IS NULL OR od.EmpleadoRecibe = @pc_EmpleadoRecibe)

END TRY
	BEGIN CATCH
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState =ERROR_STATE();

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
END