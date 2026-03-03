-- ==========================================================================================
-- Author:		Martín Tovar
-- Create date: 25/10/2024
-- Description:	Se genera SP [SISE3].[pcConsultaJuezControl] a partir del sp original [dbo].[TAU_pcConsultaJuezControl], se agrega Juez último/primero.
-- Ejemplo de ejecución: EXEC [SISE3].[pcConsultaJuezControl] 1462, '2000-01-01', '2024-10-31'

-- ==========================================================================================

CREATE PROCEDURE [SISE3].[pcConsultaJuezControl]
(
@fcatorganismoid INT,
@fFechaInicio DATETIME,
@fFechaFin DATETIME
)  
AS

BEGIN

	DECLARE 
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT

	SET NOCOUNT ON;
	BEGIN TRY 		
		DECLARE @FechaFinHora DATETIME 
		SET @FechaFinHora = CONVERT(DATETIME, @fFechaFin + ' 23:59')

		SELECT a.AsuntoAlias
			,a.AsuntoNeunId
			,ta.Descripcion AS TipoAsunto
			,cd.CatalogoDependienteDescripcion AS TipoProcedimiento	
			,ISNULL(cs.DESCRIPCION, '') AS TipoSolicitud
			,c.DESCRIPCION AS TipoDelito
			,UPPER((SELECT TOP 1 ot.Nombre + ' ' + ot.ApellidoPaterno + ' ' + ot.ApellidoMaterno FROM TAU_Mov_ReservacionJuezControl jc WITH(NOLOCK)
				LEFT JOIN CatEmpleados ot WITH(NOLOCK) ON ot.EmpleadoId = jc.idJuez
				WHERE jc.fAsuntoNeunId = a.AsuntoNeunId  AND idJuez != 0 ORDER BY jc.fFechaRegistro DESC)) AS JuezAsignado
			,UPPER((SELECT TOP 1 ot.Nombre + ' ' + ot.ApellidoPaterno + ' ' + ot.ApellidoMaterno FROM TAU_Mov_ReservacionJuezControl jc WITH(NOLOCK)
				LEFT JOIN CatEmpleados ot WITH(NOLOCK) ON ot.EmpleadoId = jc.idJuez
				WHERE jc.fAsuntoNeunId = a.AsuntoNeunId  AND idJuez != 0 ORDER BY jc.fFechaRegistro ASC)) AS JuezPrimeraAudiencia
		FROM Asuntos a WITH(NOLOCK)
		INNER JOIN CatTiposAsunto ta WITH(NOLOCK)
			ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
			AND ta.StatusReg = 1
		INNER JOIN CatalogosDependientes cd WITH(NOLOCK)
			ON cd.CatalogoDependienteId= 734
			AND cd.catalogoDependienteElementoIDNew = a.CatTipoProcedimiento
			AND cd.CatalogoDependienteIdPadre <> 0
			AND cd.StatusRegistro = 1
		INNER JOIN REL_NoCarpInvetAsuntosSISE ci WITH(NOLOCK)
			ON a.AsuntoNeunId = ci.iAsuntoNeunId
			AND ci.iEstatus > 0
		LEFT JOIN viCatalogos c
			ON ci.iTipoDelito = c.ID
			AND c.Catalogo = 1496
		LEFT JOIN viCatalogos cs
			ON ci.iTipoSolicitud = cs.ID
			AND cs.Catalogo = 1495
		WHERE a.CatOrganismoId = @fcatorganismoid
			AND a.FechaAlta BETWEEN @fFechaInicio AND @FechaFinHora		
			AND a.CatTipoAsuntoId = 74
			AND a.StatusReg = 1
		ORDER BY a.FechaAlta

	END TRY
	BEGIN CATCH
	
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState =ERROR_STATE();

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
   
END
