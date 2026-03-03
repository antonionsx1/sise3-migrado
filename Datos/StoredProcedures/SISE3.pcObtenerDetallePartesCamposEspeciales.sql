USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcObtenerDetallePartesCamposEspeciales]    Script Date: 10/18/2024 5:48:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 04/10/2024
-- Description: Obtiene el detalle de información por partes para los campos especiales
-- Ejemplo: EXEC [SISE3].[pcObtenerDetallePartesCamposEspeciales] 36068575,184167981,4506,180,1
-- ================================
ALTER PROCEDURE [SISE3].[pcObtenerDetallePartesCamposEspeciales]  (
	 @pc_AsuntoNeunId INT
	,@pc_PersonaId INT
	,@pc_PadreId INT
	,@pc_CatTipoOrganismoId INT
	,@pc_CatTipoAsuntoId INT)
AS  
BEGIN  

     DECLARE @CatalogoId INT = 17
	 DECLARE @CatCaracterId INT = 27
	 DECLARE @CatalogoTipoTable TABLE (Id INT, Descripcion VARCHAR(70), Elementos INT);
	 DECLARE @CatalogoCaracterTable TABLE (Id INT, Descripcion VARCHAR(70), Elementos INT);

	 INSERT INTO @CatalogoTipoTable
	 EXEC usp_catalogosSel @CatalogoId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId

	 INSERT INTO @CatalogoCaracterTable
	 EXEC usp_catalogosSel @CatCaracterId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId
	 	
	 	 
		SELECT 
			 CONVERT(INT,asuDoc.AsuntoNeunId) AsuntoNeunId
			,CONVERT(INT,asuDoc.PersonaId) PersonaId
			,CONVERT(INT,asuDoc.DocumentoId) DocumentoId
			,CONVERT(INT,asuDoc.NoBloque) NoBloque
			,docDescripcion.Valor NumeroRegistro
			,docCatTipos.CatalogoElementoId CatElementId
			,(SELECT A.Descripcion FROM @CatalogoTipoTable A WHERE A.Id = docCatTipos.CatalogoElementoId) CatTipo
			,(SELECT B.Descripcion FROM @CatalogoCaracterTable B WHERE B.Id = (SELECT CatalogoElementoId 
																		 FROM [dbo].[AsuntosApartadoDocumentosCatalogos] WITH(NOLOCK)
																		 WHERE DocumentoId IN(asuDoc.DocumentoId)
																		 AND TipoAsuntoId = 6639
																		 AND StatusReg = 1)) CatCaracter
			,docFechas.Valor FechaExhibicion 
		FROM [SISE_NEW].[dbo].[AsuntosApartadoDocumentos] asuDoc WITH(NOLOCK)
		INNER JOIN [dbo].[AsuntosApartadoDocumentosDescripcion] docDescripcion  WITH(NOLOCK) ON asuDoc.DocumentoId = docDescripcion.DocumentoId
		INNER JOIN [dbo].[AsuntosApartadoDocumentosCatalogos] docCatTipos WITH(NOLOCK) ON asuDoc.DocumentoId = docCatTipos.DocumentoId
		INNER JOIN [dbo].[AsuntosApartadoDocumentosFechas] docFechas WITH(NOLOCK) ON asuDoc.DocumentoId = docFechas.DocumentoId
		WHERE asuDoc.AsuntoNeunId = @pc_AsuntoNeunId
		AND asuDoc.PersonaId = @pc_PersonaId
		AND docDescripcion.TipoAsuntoId = (SELECT TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
											WHERE Descripcion = 'Número de registro' AND Padre = @pc_PadreId)
		AND docCatTipos.TipoAsuntoId = (SELECT TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
											WHERE Descripcion = 'Tipo (Descripción)' AND Padre = @pc_PadreId) 
		AND docFechas.TipoAsuntoId = (SELECT TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
										WHERE Descripcion = 'Fecha de exhibición' AND Padre = @pc_PadreId)		
		AND docDescripcion.StatusReg = 1
		AND docCatTipos.StatusReg = 1
		AND docFechas.StatusReg = 1
		AND docCatTipos.CatalogoId = @CatalogoId
		ORDER BY asuDoc.FechaAlta DESC

		

END
