SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 25/09/2024
-- Description: Obtiene los campos para los catalogos especiales
-- ================================
ALTER PROCEDURE [SISE3].[pcObtieneCamposCatalogos]  (
	@pc_CatTipoAsuntoId int)
AS  
BEGIN  

	SELECT 
	    vi.TipoAsuntoId iTipoAsuntoId
	    ,camposTbl.iPadreId iPadre
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
	 FROM viTiposAsunto vi WITH(NOLOCK) 
	 INNER JOIN [SISE3].[CatCamposEspeciales] camposTbl WITH(NOLOCK) ON vi.TipoAsuntoId = camposTbl.iTipoAsuntoId
	 JOIN CamposClase cc WITH(NOLOCK) ON cc.CampoClaseId = vi.Clase
	 JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vi.TipoAsuntoId
	 LEFT JOIN CamposPropiedades CP WITH(NOLOCK)  ON vi.TipoAsuntoId = CP.TipoAsuntoId
			AND CP.TipoPropiedadId IN(1,14,16) 
			AND CP.StatusReg = 1
	 WHERE vi.CatTipoAsuntoId = @pc_CatTipoAsuntoId
	 AND camposTbl.bStatusReg = 1

END