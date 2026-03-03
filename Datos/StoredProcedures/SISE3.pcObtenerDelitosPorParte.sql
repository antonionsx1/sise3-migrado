SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 27/11/2024
-- Description: Obtiene los delitos por parte para mostrarlos en un grid
-- Ejemplo: EXEC [SISE3].[pcObtenerDelitosPorParte] 36069298,1462,74,184169256
-- ================================
ALTER PROCEDURE [SISE3].[pcObtenerDelitosPorParte]
(
 @pc_AsuntoNeunId BIGINT 
,@pc_CatTipoOrganismoId INT
,@pc_CatTipoAsuntoId INT
,@pc_PersonaId BIGINT
,@pc_CampoDelitoId INT
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CatalogoId INT = 48;
	DECLARE @CatalogoTipoTable TABLE (Id INT, Descripcion VARCHAR(200), Elementos INT);

	INSERT INTO @CatalogoTipoTable
	EXEC usp_catalogosSel @CatalogoId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId

	SELECT * FROM 
	(
		SELECT asuDetalle.NoBloque NumeroBloqueTexto 
		      ,asuDetalle.Contenido TipoDelitoEspecifico
		FROM AsuntosDetalleDescripcion asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoDelitoId
		AND viAsu.Descripcion LIKE '%Tipo de delito(s) específico(s)%'
		AND asuDetalle.StatusReg = 1
		) T1
	FULL OUTER JOIN
	(
		SELECT asuDetalle.NoBloque NumeroBloqueCatalogo 
			,(SELECT A.Descripcion FROM @CatalogoTipoTable A WHERE A.Id = asuDetalle.CatTipoCatalogoAsuntoId) CatDescripcion
		FROM AsuntosDetalleCatalogos asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntosNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoDelitoId
		AND viAsu.Descripcion LIKE '%Género(s) de delito(s) %'
		AND asuDetalle.StatusReg = 1
		)T2 ON T1.NumeroBloqueTexto = T2.NumeroBloqueCatalogo
	ORDER BY T1.NumeroBloqueTexto, T2.NumeroBloqueCatalogo ASC
	   			
	SET NOCOUNT OFF
END