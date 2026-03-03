USE [SISE_NEW]
GO

/****** Object:  View [SISE3].[viTiposAsuntoExpediente]    Script Date: 9/26/2024 6:44:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [SISE3].[viTiposAsuntoExpediente]
AS
	SELECT ta.TipoAsuntoId
	,c.Descripcion AS DescripcionXCat
	,ta.Descripcion
	,ct.CampoTipoDescripcion AS TipoCampo
	,ct.CampoTipoId AS TipoCampoId
	,ta.CatTipoAsuntoId
	,CASE CatTipoAsuntoId WHEN 1 THEN 2 WHEN 44 THEN 4 WHEN 45 THEN 4 ELSE CatTipoOrganismoId END AS CatTipoOrganismoId
	,ta.CatCampoAsuntoId
	,ta.Nivel
	,ta.Padre
	,dbo.fn_DevuelveNombreCampo(ta.Padre) AS PadreDescripcion
	,ta.Clase
	,ta.Tipo
	,ta.Catalogo
	,ta.Orden
	,ta.Normatividad
	,ta.CatCampoFormatoId
	,ta.FechaAlta
	,ta.FechaActualiza
	,ta.FechaBaja
	,ta.StatusReg
	,ta.TipoProcedimiento
FROM dbo.TiposAsunto ta WITH(NOLOCK)
INNER JOIN  dbo.CatCamposAsunto c WITH(NOLOCK) ON ta.CatCampoAsuntoId = c.CatCampoAsuntoId
INNER JOIN  dbo.CamposTipo ct WITH(NOLOCK) ON ta.Tipo = ct.CampoTipoId

GO


