SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación: 9 de enero del 2025
-- Descripción: Es un catalogo que contiene la combinación de campos por cada opción del catalogo Tipo(Descripción) dentro de Documentos
-- Ejemplo: EXEC [SISE3].[pcObtieneCamposDocumentos] 1,2
-- ============================================= 
ALTER PROCEDURE [SISE3].[pcObtieneCamposDocumentos]  (
	 @pc_CatTipoAsuntoId INT
	,@pc_CatTipoOrganismoId INT)
AS  
BEGIN  

	SELECT 
	    vi.TipoAsuntoId iTipoAsuntoId
	    ,catTipo.iPadreId iPadre
		,vi.Nivel iNivel
		,CONVERT(INT, vi.Orden) iOrden
		,CONVERT(INT,vi.Clase) iClase
		,cc.CampoClaseDescripcion sNombreClase		
		,vi.Descripcion sDescripcion
		,vi.TipoCampo sTipoCampo
		,CONVERT(INT,vi.TipoCampoId) iTipoCampoId
		,CONVERT(INT,vi.Catalogo) iNumeroCatalogo
		,vi.CatTipoAsuntoId iCatTipoAsuntoId
		,CP.TipoPropiedadId iTipoIcono 	 
		,ta.EsMultiple bEsMultiple
		,vi.FechaAlta fFechaAlta
		,vi.FechaBaja fFechaBaja
		,vi.StatusReg bStatusReg
		,catDocumentos.bIsBajaBillete IsBajaBillete
	 FROM viTiposAsunto vi WITH(NOLOCK) 
	 INNER JOIN [SISE3].[CatCamposDocumentos] catDocumentos WITH(NOLOCK) ON vi.TipoAsuntoId = catDocumentos.iTipoAsuntoId
     INNER JOIN [SISE3].[CatTipoCampos] catTipo WITH(NOLOCK) ON catDocumentos.iTipoCampoId = catTipo.iTipoCampoId
	 JOIN CamposClase cc WITH(NOLOCK) ON cc.CampoClaseId = vi.Clase
	 JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vi.TipoAsuntoId
	 LEFT JOIN CamposPropiedades CP WITH(NOLOCK)  ON vi.TipoAsuntoId = CP.TipoAsuntoId
			AND CP.TipoPropiedadId IN(1,14,16) 
			AND CP.StatusReg = 1
	 WHERE catDocumentos.iCatTipoAsunto = @pc_CatTipoAsuntoId
	 AND catDocumentos.iCatTipoOrganismoId = @pc_CatTipoOrganismoId
	 AND vi.StatusReg = 1
	 ORDER BY CONVERT(INT,vi.Orden) ASC

END
