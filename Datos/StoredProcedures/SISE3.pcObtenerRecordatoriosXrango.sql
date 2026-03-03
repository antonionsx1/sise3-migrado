SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:		Isidro Neri Silva 
-- Create date: 09/07/2024
-- Description:	Obtiene recordatorios por rango de fechas.
-- EXEC [SISE3].[pcObtenerRecordatoriosXrango]
-- ==========================================================================================
CREATE PROCEDURE [SISE3].[pcObtenerRecordatoriosXrango](
@pc_catOrganismoId INT,
@pc_fechaInicio DATETIME,
@pc_fechaFin DATETIME
)
AS
BEGIN
DECLARE 
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT;

	BEGIN TRY
	SELECT 
			od.ObservacionDocumentoId
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
        FROM dbo.Word_ObservacionDocumento od WITH(NOLOCK)
	    LEFT JOIN Asuntos a WITH(NOLOCK) ON od.AsuntoNeunId = a.AsuntoNeunId
	    LEFT JOIN CatTiposAsunto ct WITH(NOLOCK) ON a.CatTipoAsuntoId = ct.CatTipoAsuntoId		
		LEFT JOIN CatalogosDependientes cd WITH(NOLOCK) ON cd.CatalogoDependienteElementoIDNew = a.CatTipoProcedimiento AND cd.CatalogoDependienteIdPadre = 200	
		INNER JOIN CatEmpleados CatEmp WITH(NOLOCK) ON CatEmp.EmpleadoId = od.EmpleadoId 
	    INNER JOIN CatEmpleados CatEmpRe WITH(NOLOCK) ON CatEmpRe.EmpleadoId = od.EmpleadoRecibe
		WHERE od.CatOrganismoId =  @pc_catOrganismoId
		AND od.FechaNotificacion BETWEEN @pc_fechaInicio AND @pc_fechaFin
		ORDER BY od.FechaNotificacion ASC

END TRY
	BEGIN CATCH
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState =ERROR_STATE();

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
END