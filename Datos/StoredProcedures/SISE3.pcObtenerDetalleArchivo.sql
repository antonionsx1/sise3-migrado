SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 24/10/2024
-- Description: Obtiene el detalle del archivo en documentos
-- Ejemplo: EXEC [SISE3].[pcObtenerDetalleArchivo] 30315745,171521472
-- ================================
ALTER PROCEDURE [SISE3].[pcObtenerDetalleArchivo]
@pc_AsuntoNeunId BIGINT
,@pc_PersonaId BIGINT
,@pc_NoBloque INT
,@pc_TipoDocumentoId INT
AS
BEGIN
    BEGIN TRY	

	    DECLARE @CatClase INT = 502;
		DECLARE @CatTipoDescripcion INT = 17;
		DECLARE @CatCarater INT = 27;
	
		SELECT 
		archCatalogos.AsuntoNeunId AsuntoNeunId
		,archCatalogos.PersonaId PersonaId
		,archCatalogos.Clase ClaseId
		,dbo.fnValorCatalogo(@CatClase,archCatalogos.Clase) DescripcionClase  
		,archCatalogos.Descripcion DescripcionId
		,dbo.fnValorCatalogo(@CatTipoDescripcion,archCatalogos.Descripcion) DescripcionTipo
		,archCatalogos.CaracterExhibe CaracterExhibeId
		,dbo.fnValorCatalogo(@CatCarater,archCatalogos.CaracterExhibe) DescripcionCaracterExhibe		
		,archCatalogos.NoBloque NoBloque
		,archCatalogos.Orden Orden
		,archCatalogos.NombreArchivo NombreArchivo
        ,archCatalogos.NombreArchivoUsuario NombreArchivoUsuario
		FROM DocumentoArchivos archCatalogos WITH(NOLOCK) 
		LEFT JOIN CatalogosDependientes descCatalogos WITH(NOLOCK) ON descCatalogos.CatalogoDependienteElementoIDNew = archCatalogos.Clase
		AND descCatalogos.CatalogoDependienteElementoIDNew = archCatalogos.Descripcion
		AND descCatalogos.CatalogoDependienteElementoIDNew = archCatalogos.CaracterExhibe
		WHERE 
		archCatalogos.AsuntoNeunId = @pc_AsuntoNeunId 
		AND archCatalogos.PersonaId = @pc_PersonaId
		AND archCatalogos.NoBloque=@pc_NoBloque
        AND archCatalogos.TipoDocumentoId=@pc_TipoDocumentoId
		AND archCatalogos.StatusReg = 1	
	
	END TRY
    BEGIN CATCH
       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;