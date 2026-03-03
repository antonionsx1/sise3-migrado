IF OBJECT_ID('tempdb.dbo.#tblPadrePadre') IS NOT NULL
	DROP TABLE #tblPadrePadre
GO

IF OBJECT_ID('tempdb.dbo.#tblPadreHijo') IS NOT NULL
	DROP TABLE #tblPadreHijo
GO



WITH CTE_MenuHierarchy AS (
    -- Nivel 0 (Padre ra�z)
    SELECT 
        TipoAsuntoId, 
        DescripcionXCat, 
        Descripcion, 
        TipoCampo, 
        TipoCampoId, 
        CatTipoAsuntoId, 
        CatTipoOrganismoId, 
        CatCampoAsuntoId, 
        Nivel, 
        Padre, 
        PadreDescripcion,
        CAST(TipoAsuntoId AS NVARCHAR(MAX)) AS RutaJerarquica
    FROM viTiposAsunto
    WHERE CatTipoAsuntoId = 2 
      AND CatTipoOrganismoId = 2
      AND Padre IN (1848)  -- Aqu� defines el padre ra�z
     
    UNION ALL

    -- Recursividad: busca los hijos de los registros ya encontrados
    SELECT 
        t.TipoAsuntoId, 
        t.DescripcionXCat, 
        t.Descripcion, 
        t.TipoCampo, 
        t.TipoCampoId, 
        t.CatTipoAsuntoId, 
        t.CatTipoOrganismoId, 
        t.CatCampoAsuntoId, 
        t.Nivel, 
        t.Padre, 
        t.PadreDescripcion,
        CAST(c.RutaJerarquica + ' > ' + CAST(t.TipoAsuntoId AS NVARCHAR(MAX)) AS NVARCHAR(MAX))
    FROM viTiposAsunto t
    INNER JOIN CTE_MenuHierarchy c ON t.Padre = c.TipoAsuntoId
)

SELECT 
TipoAsuntoId	
,DescripcionXCat	
,TipoCampo	
,CatTipoAsuntoId	
,CatTipoOrganismoId	
,Nivel	
,Padre	
,PadreDescripcion	
INTO #tblPadrePadre
FROM CTE_MenuHierarchy
ORDER BY Padre, TipoAsuntoId, Nivel asc;

WITH CTE_MenuHierarchy2 AS (
    -- Nivel 0 (Padre ra�z)
    SELECT 
        TipoAsuntoId, 
        DescripcionXCat, 
        Descripcion, 
        TipoCampo, 
        TipoCampoId, 
        CatTipoAsuntoId, 
        CatTipoOrganismoId, 
        CatCampoAsuntoId, 
        Nivel, 
        Padre, 
        PadreDescripcion,
        CAST(TipoAsuntoId AS NVARCHAR(MAX)) AS RutaJerarquica
    FROM viTiposAsunto
    WHERE CatTipoAsuntoId = 2 
      AND CatTipoOrganismoId = 2
      AND Padre IN (1883,2082,2259)  -- Aqu� defines el padre ra�z
     
    UNION ALL

    -- Recursividad: busca los hijos de los registros ya encontrados
    SELECT 
        t.TipoAsuntoId, 
        t.DescripcionXCat, 
        t.Descripcion, 
        t.TipoCampo, 
        t.TipoCampoId, 
        t.CatTipoAsuntoId, 
        t.CatTipoOrganismoId, 
        t.CatCampoAsuntoId, 
        t.Nivel, 
        t.Padre, 
        t.PadreDescripcion,
        CAST(c.RutaJerarquica + ' > ' + CAST(t.TipoAsuntoId AS NVARCHAR(MAX)) AS NVARCHAR(MAX))
    FROM viTiposAsunto t
    INNER JOIN CTE_MenuHierarchy2 c ON t.Padre = c.TipoAsuntoId
)

SELECT 
TipoAsuntoId	
,DescripcionXCat	
,TipoCampo	
,CatTipoAsuntoId	
,CatTipoOrganismoId	
,Nivel	
,Padre	
,PadreDescripcion	
INTO #tblPadreHijo
FROM CTE_MenuHierarchy2
ORDER BY Padre, TipoAsuntoId, Nivel asc;


-- SELECT
-- *
-- FROM [#tblPadrePadre] pp
-- INNER JOIN [#tblPadreHijo] ph
-- ON pp.DescripcionXCat = ph.DescripcionXCat
-- ORDER BY pp.TipoAsuntoId, pp.Padre, pp.Nivel ASC


INsert INTO SISE3.EquivalenciasIDs(CatTipoAsuntoId, CatTipoOrganismoId, IdBuscar, IdRemplazar)
SELECT 
t.CatTipoAsuntoId
,t.CatTipoOrganismoId
,t.TipoAsuntoId
,t.reemplazo
FROM (
	SELECT
	pp.CatTipoAsuntoId
	,pp.CatTipoOrganismoId
	,pp.TipoAsuntoId
	,ph.TipoAsuntoId AS reemplazo
	FROM [#tblPadrePadre] pp
	INNER JOIN [#tblPadreHijo] ph
	ON pp.DescripcionXCat = ph.DescripcionXCat
	--ORDER BY pp.TipoAsuntoId, pp.Padre, pp.Nivel ASC
) AS t

SELECT * FROM SISE3.EquivalenciasIDs ORDER BY IdBuscar