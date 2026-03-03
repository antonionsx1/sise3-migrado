SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 07/10/2024 
-- Description: Se obtiene el valor de los campos para campos especiales por partes
-- Ejemplo : EXEC [SISE3].[pcObtenerValorCamposPartes] 30315014,302376,5
-- ============================================= 
ALTER PROCEDURE [SISE3].[pcObtenerValorCamposPartes]
@pc_AsuntoNeunId INT,
@pc_DocumentoId INT,
@pc_NoBloque INT
AS
BEGIN
    BEGIN TRY	

	SELECT asuDescipcion.TipoAsuntoId, asuDescipcion.AsuntoNeunId, V.TipoCampoId, asuDescipcion.Contenido ValorAux, asuDescipcion.NoBloque
	FROM AsuntosDetalleDescripcion asuDescipcion WITH(NOLOCK)
	INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuDescipcion.TipoAsuntoId = V.TipoAsuntoId
	WHERE asuDescipcion.AsuntoNeunId = @pc_AsuntoNeunId 
		AND asuDescipcion.FechaBaja IS NULL
		AND asuDescipcion.StatusReg = 1
		AND asuDescipcion.TipoAsuntoId IN (SELECT docDesc.TipoAsuntoId 
										   FROM [dbo].[AsuntosApartadoDocumentosDescripcion] docDesc
										   WHERE docDesc.DocumentoId = @pc_DocumentoId)
		AND asuDescipcion.NoBloque = @pc_NoBloque
	UNION ALL

	SELECT DISTINCT(asuCatalogos.TipoAsuntoId), asuCatalogos.AsuntosNeunId, V.TipoCampoId,
	dbo.fnValorCatalogo(asuCatalogos.CatTipoCatalogoAsuntoId,asuCatalogos.CatCatalogoAsuntoId) ValorAux  
	,asuCatalogos.NoBloque
    FROM 
    AsuntosDetalleCatalogos asuCatalogos WITH(NOLOCK) 
    LEFT JOIN CatalogosDependientes descCatalogos WITH(NOLOCK) ON descCatalogos.CatalogoDependienteElementoIDNew = asuCatalogos.CatTipoCatalogoAsuntoId
    INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuCatalogos.TipoAsuntoId = V.TipoAsuntoId
	WHERE 
    asuCatalogos.AsuntosNeunId = @pc_AsuntoNeunId 
    AND asuCatalogos.FechaBaja IS NULL
    AND asuCatalogos.StatusReg = 1
	AND asuCatalogos.TipoAsuntoId IN (SELECT docCatalogos.TipoAsuntoId 
									  FROM [dbo].[AsuntosApartadoDocumentosCatalogos] docCatalogos 
									  WHERE docCatalogos.DocumentoId = @pc_DocumentoId)
    AND asuCatalogos.NoBloque = @pc_NoBloque

	UNION ALL
	SELECT asuFechas.TipoAsuntoId
		   ,asuFechas.AsuntoNeunId		   
		   ,V.TipoCampoId		  
		   ,IIF(V.TipoCampoId = 2, CONVERT(VARCHAR(10),asuFechas.ValorCampoAsunto,103),CONVERT(VARCHAR(5),CONVERT(TIME(5),asuFechas.ValorCampoAsunto)) ) ValorAux      
		   ,asuFechas.NoBloque
	FROM AsuntosDetalleFechas asuFechas WITH(NOLOCK)
	INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuFechas.TipoAsuntoId = V.TipoAsuntoId
	WHERE asuFechas.AsuntoNeunId = @pc_AsuntoNeunId
	AND asuFechas.FechaBaja IS NULL
	AND asuFechas.StatusReg = 1
	AND V.TipoCampoId IN(2,9)
	AND asuFechas.TipoAsuntoId IN (SELECT docFechas.TipoAsuntoId 
								   FROM [dbo].[AsuntosApartadoDocumentosFechas] docFechas 
								   WHERE docFechas.DocumentoId = @pc_DocumentoId)
	AND asuFechas.NoBloque = @pc_NoBloque


    END TRY
    BEGIN CATCH

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;