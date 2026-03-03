SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación: 08/10/2024
-- Descripción: Obtiene el tipoAsuntoId de documentos por catTipoAsunto
-- Ejemplo : EXEC [SISE3].[pcObtenerTipoAsuntoIdDocumentos] 1,2
-- =============================================
ALTER PROCEDURE [SISE3].[pcObtenerTipoAsuntoIdDocumentos]
@pc_CatTipoOrganismoId INT
AS
	BEGIN
	SET NOCOUNT ON
		BEGIN TRY
					
		SELECT 
		CatTipoAsuntoId
		,TipoAsuntoId 
		FROM dbo.viTiposAsunto WITH(NOLOCK)
		WHERE CatTipoOrganismoId = @pc_CatTipoOrganismoId
		AND Descripcion = 'Documentos'
		AND TipoCampoId = 1 
		AND Nivel = 0
		ORDER BY CatTipoAsuntoId ASC

		END TRY
		BEGIN CATCH
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
	SET NOCOUNT OFF
END
