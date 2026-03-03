USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcObtenerDetallePartesCamposEspeciales]    Script Date: 16/05/2025 11:35:27 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 04/10/2024
-- Description: Obtiene el detalle de información por partes para los campos especiales
-- Ejemplo: EXEC [SISE3].[pcObtenerDetallePartesCamposEspeciales] 36068575,184167981,4506,180,1
/*	===== Cambios =====
	- Fecha: 16/05/2025
	- Se agrega el UNION con select para considerar los Billetes deposito
*/
-- ================================
ALTER PROCEDURE [SISE3].[pcObtenerDetallePartesCamposEspeciales]  (
	 @pc_AsuntoNeunId INT
	,@pc_PersonaId INT = NULL
	,@pc_PadreId INT
	,@pc_CatTipoOrganismoId INT
	,@pc_CatTipoAsuntoId INT)
AS  
BEGIN  

     DECLARE @CatalogoId INT = 17
	 DECLARE @CatCaracterId INT = 27
	 DECLARE @CatalogoTipoTable TABLE (Id INT, Descripcion VARCHAR(70), Elementos INT);
	 DECLARE @CatalogoCaracterTable TABLE (Id INT, Descripcion VARCHAR(70), Elementos INT);

	 DECLARE @IdDescripcion INT, @IdCatTipos INT, @IdFechas INT;
	 DECLARE @IdDescripcionBD INT, @IdCatTiposBD INT, @IdFechasBD INT;

	 INSERT INTO @CatalogoTipoTable
	 EXEC usp_catalogosSel @CatalogoId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId

	 INSERT INTO @CatalogoCaracterTable
	 EXEC usp_catalogosSel @CatCaracterId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId

	 SELECT @IdDescripcion = TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
	 WHERE Descripcion = 'Número de registro' AND Padre = @pc_PadreId;

	 SELECT @IdCatTipos = TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
	 WHERE Descripcion = 'Tipo (Descripción)' AND Padre = @pc_PadreId;

	 SELECT @IdFechas = TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
	 WHERE Descripcion = 'Fecha de exhibición' AND Padre = @pc_PadreId;

	 SELECT @IdDescripcionBD = TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
	 WHERE Descripcion = 'Número de documento' AND Padre = @pc_PadreId;

	 SELECT @IdCatTiposBD = TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
	 WHERE Descripcion = 'Carácter con que se exhibe' AND Padre = @pc_PadreId;

	 SELECT @IdFechasBD = TipoAsuntoId FROM dbo.viTiposAsunto WITH(NOLOCK)
	 WHERE Descripcion = 'Fecha de expedición' AND Padre = @pc_PadreId;

	 	
	SELECT *
	FROM (
	 	 
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
			,asuDoc.FechaAlta
		FROM [SISE_NEW].[dbo].[AsuntosApartadoDocumentos] asuDoc WITH(NOLOCK)
		INNER JOIN [dbo].[AsuntosApartadoDocumentosDescripcion] docDescripcion  WITH(NOLOCK) ON asuDoc.DocumentoId = docDescripcion.DocumentoId
		INNER JOIN [dbo].[AsuntosApartadoDocumentosCatalogos] docCatTipos WITH(NOLOCK) ON asuDoc.DocumentoId = docCatTipos.DocumentoId
		INNER JOIN [dbo].[AsuntosApartadoDocumentosFechas] docFechas WITH(NOLOCK) ON asuDoc.DocumentoId = docFechas.DocumentoId
		WHERE asuDoc.AsuntoNeunId = @pc_AsuntoNeunId
		--AND asuDoc.PersonaId = @pc_PersonaId
		AND ((@pc_PersonaId IS NULL) OR (@pc_PersonaId = asuDoc.PersonaId )) 
		AND docDescripcion.TipoAsuntoId = @IdDescripcion
		AND docCatTipos.TipoAsuntoId = @IdCatTipos 
		AND docFechas.TipoAsuntoId = @IdFechas		
		AND docDescripcion.StatusReg = 1
		AND docCatTipos.StatusReg = 1
		AND docFechas.StatusReg = 1
		AND docCatTipos.CatalogoId = @CatalogoId

		UNION

		SELECT 
			 CONVERT(INT,asuDoc.AsuntoNeunId) AsuntoNeunId
			,CONVERT(INT,asuDoc.PersonaId) PersonaId
			,CONVERT(INT,asuDoc.DocumentoId) DocumentoId
			,CONVERT(INT,asuDoc.NoBloque) NoBloque
			,docDescripcion.Valor NumeroRegistro
			,CASE WHEN docCatTipos.CatalogoElementoId = 1540 THEN 12683 ELSE docCatTipos.CatalogoElementoId END CatElementId
			,(SELECT A.Descripcion FROM @CatalogoTipoTable A WHERE A.Id = CASE WHEN docCatTipos.CatalogoElementoId = 1540 THEN 12683 ELSE docCatTipos.CatalogoElementoId END) CatTipo
			,(SELECT B.Descripcion FROM @CatalogoCaracterTable B WHERE B.Id = (SELECT CatalogoElementoId 
																		 FROM [dbo].[AsuntosApartadoDocumentosCatalogos] WITH(NOLOCK)
																		 WHERE DocumentoId IN(asuDoc.DocumentoId)
																		 AND TipoAsuntoId = 6639
																		 AND StatusReg = 1)) CatCaracter
			,docFechas.Valor FechaExhibicion 
			,asuDoc.FechaAlta
		FROM [SISE_NEW].[dbo].[AsuntosApartadoDocumentos] asuDoc WITH(NOLOCK)
		INNER JOIN [dbo].[AsuntosApartadoDocumentosDescripcion] docDescripcion  WITH(NOLOCK) ON asuDoc.DocumentoId = docDescripcion.DocumentoId
		INNER JOIN [dbo].[AsuntosApartadoDocumentosCatalogos] docCatTipos WITH(NOLOCK) ON asuDoc.DocumentoId = docCatTipos.DocumentoId
		INNER JOIN [dbo].[AsuntosApartadoDocumentosFechas] docFechas WITH(NOLOCK) ON asuDoc.DocumentoId = docFechas.DocumentoId
		WHERE asuDoc.AsuntoNeunId = @pc_AsuntoNeunId
		--AND asuDoc.PersonaId = @pc_PersonaId
		AND ((@pc_PersonaId IS NULL) OR (@pc_PersonaId = asuDoc.PersonaId )) 
		AND docDescripcion.TipoAsuntoId = @IdDescripcionBD
		AND docCatTipos.TipoAsuntoId = @IdCatTiposBD 
		AND docFechas.TipoAsuntoId = @IdFechasBD		
		AND docDescripcion.StatusReg = 1
		AND docCatTipos.StatusReg = 1
		AND docFechas.StatusReg = 1
		AND docCatTipos.CatalogoId = @CatCaracterId
	) Datos
	ORDER BY Datos.FechaAlta DESC
			

END
