USE [SISE_NEW]
GO

/****** Object:  UserDefinedFunction [SISE3].[fnExpediente]    Script Date: 12/1/2023 6:33:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [SISE3].[fnExpediente] (
  @pi_AsuntoNeunId BIGINT
)
RETURNS TABLE
AS
  RETURN
	SELECT 
		AsuntoNeunId 
		,AsuntoAlias
		,NumeroAlias
		,cto.CatTipoOrganismoId
		,CatTipoOrganismo = cto.Nombre 
		,ct.CatOrganismoId
		,CatOrganismo = ct.NombreOficial
		,a.CatMateriaId 
		,CatMateria = m.Nombre
		,a.CatTipoAsuntoId
		,CatTipoAsunto = cta.Descripcion
		,a.CatTipoProcedimiento
		,TipoProcedimiento = ISNULL(ctp.TipoProcedimiento,'')
		,ta.NombreCorto
		,TipoProcedimientoId = ISNULL(ctp.TipoProcedimientoId,'')
		,a.NumeroOCC
		,a.AsuntoId
	FROM Asuntos a WITH(NOLOCK) 
	INNER JOIN CatOrganismos  ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId  
	INNER JOIN CatTiposAsunto cta WITH (NOLOCK) on a.CatTipoAsuntoId = cta.CatTipoAsuntoId  
	INNER JOIN CatTipoOrganismos cto  WITH (NOLOCK) on ct.CatTipoOrganismoId = cto.CatTipoOrganismoId  
	INNER JOIN CatMaterias m ON m.CatMateriaId = a.CatMateriaId
	LEFT JOIN (
			SELECT 
				nombreCorto
				,CatTipoAsuntoId
				,row = ROW_NUMBER() OVER(PARTITION BY CatTipoAsuntoId ORDER BY nombreCorto) 
			FROM dbo.tbx_CatTiposAsunto
	) ta ON cta.CatTipoAsuntoId = ta.CatTipoAsuntoId AND row  = 1
	LEFT JOIN (
		SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew,ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew) 
			,TipoProcedimiento = ced.CatalogoElementoDescripcion, 
			CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew, 
			ceta.CatTipoAsuntoId,TipoProcedimientoId = ced.CatalogoElementoDescripcionID 
		FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
		INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)  ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
		INNER JOIN CatalogosElementosTiposAsunto ceta with(nolock) on cd.CatalogoDependienteId=ceta.CatalogoId and cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
		WHERE cd.CatalogoDependienteId  IN (464,124,208,1207,734,1933,1892)
	) ctp ON a.CatTipoProcedimiento = ctp.CatTipoProcedimiento AND a.CatTipoAsuntoId = ctp.CatTipoAsuntoId AND ctp.row = 1
	WHERE a.StatusReg = 1
	AND a.AsuntoNeunId = @pi_AsuntoNeunId;

GO

