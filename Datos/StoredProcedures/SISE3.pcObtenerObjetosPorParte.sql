SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 03/04/2024
-- Description: Obtiene los objetos por parte para mostrarlos en un grid
-- Ejemplo: EXEC [SISE3].[pcObtenerObjetosPorParte]
-- ================================
ALTER PROCEDURE [SISE3].[pcObtenerObjetosPorParte]
(
 @pc_AsuntoNeunId BIGINT 
,@pc_CatTipoOrganismoId INT
,@pc_CatTipoAsuntoId INT
,@pc_PersonaId BIGINT
,@pc_CampoObjetoId INT
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CatalogoClaseId INT = 74;
	DECLARE @CatalogoTipoId INT = 75;
	DECLARE @CatalogoClaseTable TABLE (Id INT, Descripcion VARCHAR(200), Elementos INT);
	DECLARE @CatalogoTipoTable TABLE (Id INT, Descripcion VARCHAR(200), Elementos INT);

	INSERT INTO @CatalogoClaseTable
	EXEC usp_catalogosSel @CatalogoClaseId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId

	INSERT INTO @CatalogoTipoTable
	EXEC usp_catalogosSel @CatalogoTipoId,@pc_CatTipoOrganismoId,@pc_CatTipoAsuntoId

	SELECT * FROM 
	(
		SELECT CONVERT(INT,asuDetalle.NoBloque) NumeroBloqueFecha
			  ,asuDetalle.ValorCampoAsunto FechaAseguramiento
		FROM AsuntosDetalleFechas asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoObjetoId
		AND viAsu.Descripcion LIKE '%Fecha aseguramiento%'		
		AND asuDetalle.StatusReg = 1
		) T1
		FULL OUTER JOIN
		(
		SELECT CONVERT(INT,asuDetalle.NoBloque) NumeroBloqueClase 
		,(SELECT A.Descripcion FROM @CatalogoClaseTable A WHERE A.Id = asuDetalle.CatTipoCatalogoAsuntoId) Clase		
		FROM AsuntosDetalleCatalogos asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntosNeunId = @pc_AsuntoNeunId
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoObjetoId
		AND viAsu.Descripcion LIKE '%Clase objeto asegurado%'		
		AND asuDetalle.StatusReg = 1
		)T2 ON T1.NumeroBloqueFecha = T2.NumeroBloqueClase 
		FULL OUTER JOIN
		(
		SELECT CONVERT(INT,asuDetalle.NoBloque) NumeroBloqueTipo 
			,(SELECT A.Descripcion FROM @CatalogoTipoTable A WHERE A.Id = asuDetalle.CatTipoCatalogoAsuntoId) Tipo
		FROM AsuntosDetalleCatalogos asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntosNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoObjetoId
		AND viAsu.Descripcion LIKE '%Tipo genérico de objeto asegurado%'		
		AND asuDetalle.StatusReg = 1
		)T3 ON T1.NumeroBloqueFecha = T3.NumeroBloqueTipo
		OR T2.NumeroBloqueClase = T3.NumeroBloqueTipo
		FULL OUTER JOIN
		(
		SELECT DISTINCT(CONVERT(INT,asuDetalle.NoBloque)) NumeroBloqueTexto 
		FROM AsuntosDetalleDescripcion asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoObjetoId
		AND asuDetalle.StatusReg = 1
		)T4 ON T1.NumeroBloqueFecha = T4.NumeroBloqueTexto
		OR T2.NumeroBloqueClase = T4.NumeroBloqueTexto
		OR T3.NumeroBloqueTipo = T4.NumeroBloqueTexto
		FULL OUTER JOIN
		(
		SELECT DISTINCT(CONVERT(INT,asuDetalle.NoBloque)) NumeroBloqueAllFechas 
		FROM AsuntosDetalleFechas asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoObjetoId
		AND asuDetalle.StatusReg = 1
		)T5 ON T4.NumeroBloqueTexto = T5.NumeroBloqueAllFechas 
		OR T2.NumeroBloqueClase = T5.NumeroBloqueAllFechas
		OR T3.NumeroBloqueTipo = T5.NumeroBloqueAllFechas
		OR T1.NumeroBloqueFecha = T5.NumeroBloqueAllFechas
	ORDER BY T1.NumeroBloqueFecha, T2.NumeroBloqueClase,T3.NumeroBloqueTipo,T4.NumeroBloqueTexto,T5.NumeroBloqueAllFechas ASC
	   			
	SET NOCOUNT OFF
END