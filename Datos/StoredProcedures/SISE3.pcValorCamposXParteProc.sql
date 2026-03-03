USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcValorCamposXParteProc]    Script Date: 11/28/2024 6:35:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 27/11/2024
-- Description: Obtiene valores de los campos para organismos Centro de Justicia Penal Federal
-- Ejemplo: EXEC [SISE3].[pcValorCamposXParteProc] 36069298,184169256,1
-- ================================
ALTER PROCEDURE [SISE3].[pcValorCamposXParteProc]
@pc_AsuntoNeunId BIGINT
,@pc_PersonaId BIGINT
AS
BEGIN
    BEGIN TRY	

	SELECT asuDescipcion.TipoAsuntoId, asuDescipcion.AsuntoNeunId, V.TipoCampoId, asuDescipcion.Contenido ValorAux, asuDescipcion.NoBloque
	FROM AsuntosDetalleDescripcion asuDescipcion WITH(NOLOCK)
	INNER JOIN PersonasAsuntoDetalleDescripcion perAsu WITH(NOLOCK) ON asuDescipcion.AsuntoDetalleDescripcionId = perAsu.AsuntoDetalleDescripcionId
	INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuDescipcion.TipoAsuntoId = V.TipoAsuntoId
	WHERE asuDescipcion.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perAsu.PersonaId = @pc_PersonaId
		AND asuDescipcion.StatusReg = 1
	UNION ALL

	SELECT DISTINCT(asuCatalogos.TipoAsuntoId), asuCatalogos.AsuntosNeunId, V.TipoCampoId,
    CASE 
        WHEN descCatalogos.CatalogoDependienteDescripcion IS NULL 
        THEN dbo.fnValorCatalogo(asuCatalogos.CatCatalogoAsuntoId, asuCatalogos.CatTipoCatalogoAsuntoId)
        ELSE descCatalogos.CatalogoDependienteDescripcion
    END AS ValorAux
	,asuCatalogos.NoBloque
    FROM  AsuntosDetalleCatalogos asuCatalogos WITH(NOLOCK) 
	INNER JOIN PersonasAsuntosDetalleCatalogos perAsu WITH(NOLOCK) ON asuCatalogos.AsuntoDetalleCatalogosId = perAsu.AsuntoDetalleCatalogosId
    LEFT JOIN CatalogosDependientes descCatalogos WITH(NOLOCK) ON descCatalogos.CatalogoDependienteElementoIDNew = asuCatalogos.CatTipoCatalogoAsuntoId
    INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuCatalogos.TipoAsuntoId = V.TipoAsuntoId
	WHERE 
    asuCatalogos.AsuntosNeunId = @pc_AsuntoNeunId 
    AND perAsu.PersonaId = @pc_PersonaId
    AND asuCatalogos.StatusReg = 1

	UNION ALL
	SELECT asuFechas.TipoAsuntoId
		   ,asuFechas.AsuntoNeunId		   
		   ,V.TipoCampoId		  
		   ,IIF(V.TipoCampoId = 2, CONVERT(VARCHAR(10),asuFechas.ValorCampoAsunto,103),CONVERT(VARCHAR(5),CONVERT(TIME(5),asuFechas.ValorCampoAsunto)) ) ValorAux      
		   ,asuFechas.NoBloque
	FROM AsuntosDetalleFechas asuFechas WITH(NOLOCK)
	INNER JOIN PersonasAsuntosDetalleFechas perAsu WITH(NOLOCK) ON asuFechas.AsuntoDetalleFechasId = perAsu.AsuntoDetalleFechasId
	INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuFechas.TipoAsuntoId = V.TipoAsuntoId
	WHERE asuFechas.AsuntoNeunId = @pc_AsuntoNeunId
	AND perAsu.PersonaId = @pc_PersonaId
	AND asuFechas.StatusReg = 1
	AND V.TipoCampoId IN(2,9)

	UNION ALL
	SELECT asuNumeros.TipoAsuntoId, asuNumeros.AsuntosNeunId, V.TipoCampoId, CONVERT(VARCHAR(20),asuNumeros.NumeroCampoAsunto) ValorAux, asuNumeros.NoBloque
	FROM AsuntosDetalleNumeros asuNumeros WITH(NOLOCK)
	INNER JOIN PersonasAsuntosDetalleNumeros perAsu WITH(NOLOCK) ON asuNumeros.AsuntoDetalleNumerosId = perAsu.AsuntoDetalleNumerosId
	INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuNumeros.TipoAsuntoId = V.TipoAsuntoId
	WHERE asuNumeros.AsuntosNeunId = @pc_AsuntoNeunId 
		AND perAsu.PersonaId = @pc_PersonaId
		AND asuNumeros.StatusReg = 1

	UNION ALL
	SELECT asuOpciones.TipoAsuntoId, asuOpciones.AsuntoNeunId, V.TipoCampoId,IIF(asuOpciones.OpcionCampoAsunto = 1,'true','false') ValorAux, asuOpciones.NoBloque
	FROM AsuntosDetalleOpciones asuOpciones WITH(NOLOCK) 
	INNER JOIN PersonasAsuntosDetalleOpciones perAsu WITH(NOLOCK) ON asuOpciones.AsuntoDetalleOpcionesId = perAsu.AsuntoDetalleOpcionesId
	INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuOpciones.TipoAsuntoId = V.TipoAsuntoId
	WHERE asuOpciones.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perAsu.PersonaId = @pc_PersonaId
		AND asuOpciones.StatusReg = 1                          
    END TRY
    BEGIN CATCH

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;