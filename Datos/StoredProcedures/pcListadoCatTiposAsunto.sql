USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcListadoCatTiposAsunto]    Script Date: 12/1/2023 6:18:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Diana Quiroga - MS
-- Create date: 24/11/2023 
-- Description: Listado Tipo Asunto
-- Basado en: uspx_getCatTiposAsunto
--  [SISE3].[pcListadoCatTiposAsunto] 180,1
-- ============================================= 

CREATE procedure [SISE3].[pcListadoCatTiposAsunto]
        @pi_CatOrganismoId INT, 
        @pi_Catalogo INT = NULL
AS
BEGIN
        DECLARE @TipoOrganismoId INT
        
        SELECT @TipoOrganismoId = CatTipoOrganismoId
        FROM CatOrganismos WITH(NOLOCK)
        WHERE   CatOrganismoId = @pi_CatOrganismoId
        
        IF(@pi_Catalogo = 1)
        BEGIN
                SELECT DISTINCT  
                        t.CatTipoAsuntoId,
                        ta.Descripcion TipoAsunto
                FROM 
                        tbx_CatTiposAsunto t WITH(NOLOCK)
                INNER JOIN 
                        CatTiposAsunto ta WITH(NOLOCK) ON t.CatTipoAsuntoId = ta.CatTipoAsuntoId
                LEFT JOIN 
                        tbx_CatCuadernos c WITH(NOLOCK) ON t.CuadernoId = c.CuadernoId
                WHERE
                        t.CatTipoAsuntoId IN (
                                        SELECT otam.CatTipoAsuntoId 
                                        FROM OrganismosTipoAsuntoMaterias otam WITH(NOLOCK) 
                                        WHERE otam.CatOrganismoId = @pi_CatOrganismoId)
                AND ta.StatusReg = 1
        END
        ELSE IF(@pi_Catalogo = 2)
        BEGIN
                IF OBJECT_ID('tempdb..#tmp') IS NOT NULL
                        DROP TABLE #tmp;
                CREATE TABLE #tmp (     CatTipoAsuntoId INT, 
                                                        TipoAsunto VARCHAR(100),
                                                        TipoAsuntoCorto VARCHAR(10) DEFAULT '',
                                                        Color VARCHAR(10) DEFAULT '',
                                                        CuadernoId INT DEFAULT 0,
                                                        Cuaderno VARCHAR(10) DEFAULT '') 
                
                INSERT INTO #tmp(CatTipoAsuntoId,TipoAsunto)
                EXEC usp_AgendaCatAsuntos @TipoOrganismoId
                
                SELECT *
                FROM #tmp
        END
        ELSE
        BEGIN
                SELECT  ta.CatTipoAsuntoId,
                                ta.Descripcion TipoAsunto,
                                '' TipoAsuntoCorto,
                                '' Color,
                                0 CuadernoId,
                                '' Cuaderno
                FROM CatTiposAsunto ta
                WHERE StatusReg = 1
                AND ta.CatTipoAsuntoId IN (
                                        SELECT otam.CatTipoAsuntoId 
                                        FROM OrganismosTipoAsuntoMaterias otam
                                        WHERE otam.CatOrganismoId = @pi_CatOrganismoId)
        END     
END
GO

