SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 15/08/2024 
-- Description: Se obtiene información por expediente (asuntoNeunId)
-- Ejemplo : EXEC [SISE3].[pcObtenerInformacionCampoExpediente] 30315014
-- ============================================= 
ALTER PROCEDURE [SISE3].[pcObtenerInformacionCampoExpediente]
@pc_AsuntoNeunId INT
AS
BEGIN
    BEGIN TRY	

	WITH DatosBase AS (
        SELECT asuDescipcion.TipoAsuntoId, asuDescipcion.AsuntoNeunId, V.TipoCampoId, asuDescipcion.Contenido AS ValorAux, asuDescipcion.NoBloque
        FROM AsuntosDetalleDescripcion asuDescipcion WITH(NOLOCK)
        INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuDescipcion.TipoAsuntoId = V.TipoAsuntoId
        WHERE asuDescipcion.AsuntoNeunId = @pc_AsuntoNeunId 
            AND asuDescipcion.FechaBaja IS NULL
            AND asuDescipcion.StatusReg = 1
        UNION ALL
        SELECT DISTINCT(asuCatalogos.TipoAsuntoId), asuCatalogos.AsuntosNeunId, V.TipoCampoId,
            CASE 
                WHEN descCatalogos.CatalogoDependienteDescripcion IS NULL 
                THEN dbo.fnValorCatalogo(asuCatalogos.CatCatalogoAsuntoId, asuCatalogos.CatTipoCatalogoAsuntoId)
                ELSE descCatalogos.CatalogoDependienteDescripcion
            END AS ValorAux,
            asuCatalogos.NoBloque
        FROM AsuntosDetalleCatalogos asuCatalogos WITH(NOLOCK) 
        LEFT JOIN CatalogosDependientes descCatalogos WITH(NOLOCK) ON descCatalogos.CatalogoDependienteElementoIDNew = asuCatalogos.CatTipoCatalogoAsuntoId
        INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuCatalogos.TipoAsuntoId = V.TipoAsuntoId
        WHERE asuCatalogos.AsuntosNeunId = @pc_AsuntoNeunId 
            AND asuCatalogos.FechaBaja IS NULL
            AND asuCatalogos.StatusReg = 1
        UNION ALL
        SELECT asuFechas.TipoAsuntoId, asuFechas.AsuntoNeunId, V.TipoCampoId, 
            IIF(V.TipoCampoId = 2, CONVERT(VARCHAR(10),asuFechas.ValorCampoAsunto,103),CONVERT(VARCHAR(5),CONVERT(TIME(5),asuFechas.ValorCampoAsunto)) ) AS ValorAux,      
            asuFechas.NoBloque
        FROM AsuntosDetalleFechas asuFechas WITH(NOLOCK)
        INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuFechas.TipoAsuntoId = V.TipoAsuntoId
        WHERE asuFechas.AsuntoNeunId = @pc_AsuntoNeunId
            AND asuFechas.FechaBaja IS NULL
            AND asuFechas.StatusReg = 1
            AND V.TipoCampoId IN(2,9)
        UNION ALL
        SELECT asuNumeros.TipoAsuntoId, asuNumeros.AsuntosNeunId, V.TipoCampoId, 
            CONVERT(VARCHAR(20),asuNumeros.NumeroCampoAsunto) AS ValorAux, 
            asuNumeros.NoBloque
        FROM AsuntosDetalleNumeros asuNumeros WITH(NOLOCK)
        INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuNumeros.TipoAsuntoId = V.TipoAsuntoId
        WHERE asuNumeros.AsuntosNeunId = @pc_AsuntoNeunId 
            AND asuNumeros.FechaBaja IS NULL
            AND asuNumeros.StatusReg = 1
        UNION ALL
        SELECT asuOpciones.TipoAsuntoId, asuOpciones.AsuntoNeunId, V.TipoCampoId,
            IIF(asuOpciones.OpcionCampoAsunto = 1,'true','false') AS ValorAux, 
            asuOpciones.NoBloque
        FROM AsuntosDetalleOpciones asuOpciones WITH(NOLOCK) 
        INNER JOIN viTiposAsunto V WITH(NOLOCK) ON asuOpciones.TipoAsuntoId = V.TipoAsuntoId
        WHERE asuOpciones.AsuntoNeunId = @pc_AsuntoNeunId 
            AND asuOpciones.FechaBaja IS NULL 
            AND asuOpciones.StatusReg = 1
    )

    -- 1. Primero seleccionamos los datos originales SIN ALTERARLOS
    SELECT DISTINCT 
        D.TipoAsuntoId, 
        D.AsuntoNeunId, 
        D.TipoCampoId, 
        D.ValorAux, 
        D.NoBloque
    FROM DatosBase D

    UNION ALL

    -- 2. Luego, agregamos las equivalencias SIN modificar los datos originales
    SELECT DISTINCT 
        E.IdAsuntoEquivalente AS TipoAsuntoId,
        D.AsuntoNeunId,
        D.TipoCampoId,
        D.ValorAux,
        D.NoBloque
    FROM DatosBase D
    INNER JOIN SISE3.EquivalenciasIDs E ON D.TipoAsuntoId = E.IdAsuntoBase;


    END TRY
    BEGIN CATCH

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;