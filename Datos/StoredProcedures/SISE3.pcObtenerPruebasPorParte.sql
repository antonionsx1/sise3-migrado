SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 05/12/2024
-- Description: Obtiene las pruebas por parte para mostrarlos en un grid
-- Ejemplo: EXEC [SISE3].[pcObtenerPruebasPorParte] 36069436,1462,74,184169426,12601,12601
-- ================================
ALTER PROCEDURE [SISE3].[pcObtenerPruebasPorParte]
(
 @pc_AsuntoNeunId BIGINT 
,@pc_CatTipoOrganismoId INT
,@pc_CatTipoAsuntoId INT
,@pc_PersonaId BIGINT
,@pc_CampoPruebaId INT
,@pc_CampoPadreId INT
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * FROM 
	(
		SELECT CONVERT(INT,asuDetalle.NoBloque) NumeroBloqueFecha
			  ,CONVERT(VARCHAR(10),CONVERT(DATE, asuDetalle.ValorCampoAsunto)) FechaDesahogo
		FROM AsuntosDetalleFechas asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoPruebaId
		AND viAsu.Descripcion LIKE '%Fecha en que se desahogó la prueba confesional%'		
		AND asuDetalle.StatusReg = 1
		) T1
		FULL OUTER JOIN
		(
		SELECT CONVERT(INT,asuDetalle.NoBloque) NumeroBloqueHora
			  ,CONVERT(VARCHAR(5),CONVERT(TIME, asuDetalle.ValorCampoAsunto)) HoraDesahogo
		FROM AsuntosDetalleFechas asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre = @pc_CampoPruebaId
		AND viAsu.Descripcion LIKE '%Hora señalada para desahogo de la prueba confesional%'		
		AND asuDetalle.StatusReg = 1
		)T2 ON T1.NumeroBloqueFecha = T2.NumeroBloqueHora
		FULL OUTER JOIN
		(
		SELECT DISTINCT(CONVERT(INT,asuDetalle.NoBloque)) NumeroBloqueTexto 
		FROM AsuntosDetalleDescripcion asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.Padre IN( SELECT TipoAsuntoId FROM viTiposAsunto 
							WHERE Padre IN(SELECT TipoAsuntoId FROM viTiposAsunto 
										   WHERE Padre = @pc_CampoPadreId))
		AND asuDetalle.StatusReg = 1
		)T3 ON T1.NumeroBloqueFecha = T3.NumeroBloqueTexto
		OR T2.NumeroBloqueHora = T3.NumeroBloqueTexto
		FULL OUTER JOIN
		(
		SELECT DISTINCT(CONVERT(INT,asuDetalle.NoBloque)) NumeroBloqueAllFechas 
		FROM AsuntosDetalleFechas asuDetalle WITH(NOLOCK) 
		INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON asuDetalle.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId
		INNER JOIN viTiposAsunto viAsu WITH(NOLOCK) ON asuDetalle.TipoAsuntoId = viAsu.TipoAsuntoId
		WHERE asuDetalle.AsuntoNeunId = @pc_AsuntoNeunId 
		AND perDetalle.PersonaId = @pc_PersonaId
		AND viAsu.TipoAsuntoId IN( SELECT TipoAsuntoId FROM viTiposAsunto 
							WHERE Padre IN(SELECT TipoAsuntoId FROM viTiposAsunto 
										   WHERE Padre = @pc_CampoPadreId))
		AND viAsu.Descripcion NOT LIKE '%Fecha en que se desahogó la prueba confesional%'	
		AND viAsu.Descripcion NOT LIKE '%Hora señalada para desahogo de la prueba confesional%'	
		AND asuDetalle.StatusReg = 1
		)T4 ON  T1.NumeroBloqueFecha = T4.NumeroBloqueAllFechas
		OR T2.NumeroBloqueHora = T4.NumeroBloqueAllFechas
		OR T3.NumeroBloqueTexto = T4.NumeroBloqueAllFechas
	ORDER BY T1.NumeroBloqueFecha, T2.NumeroBloqueHora,T3.NumeroBloqueTexto,T4.NumeroBloqueAllFechas ASC
	   			
	SET NOCOUNT OFF
END