SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación: 09/10/2024
-- Descripción: Obtiene el tipoAsuntoId de documentos diferentes a las descripciones
-- 'Tipo (Descripción)','Fecha de exhibición','Número de registro','Carácter con que se exhibe'
-- Ejemplo : EXEC [SISE3].[pcObtenerTipoAsuntosDocumentosExcluidos] 2,1831
-- =============================================
CREATE PROCEDURE [SISE3].[pcObtenerTipoAsuntosDocumentosExcluidos]
@pc_CatTipoOrganismoId INT,
@pc_PadreId INT
AS
	BEGIN
	SET NOCOUNT ON
		BEGIN TRY
					
		SELECT TipoAsuntoId 
		FROM dbo.viTiposAsunto WITH(NOLOCK)
		WHERE @pc_CatTipoOrganismoId = @pc_CatTipoOrganismoId
		AND Padre = @pc_PadreId
		AND Descripcion NOT IN('Tipo (Descripción)','Fecha de exhibición','Número de registro','Carácter con que se exhibe')
		ORDER BY CatTipoAsuntoId ASC

		END TRY
		BEGIN CATCH
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
	SET NOCOUNT OFF
END