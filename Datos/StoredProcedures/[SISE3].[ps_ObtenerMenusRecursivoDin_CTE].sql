SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author: Erick Gonzalez
-- Create date: 20/07/2024
-- Description:	Obtiene la estructura de menus y submenus para captura expediente 
-- Ejemplo : EXEC [SISE3].[ps_ObtenerMenusRecursivoDin] 4
-- ==========================================================================================
ALTER PROCEDURE [SISE3].[ps_ObtenerMenusRecursivoDin]
    @CatTipoAsuntoId INT
AS
BEGIN
    -- Tabla temporal para almacenar los resultados
    CREATE TABLE #Resultados (
        Padre INT
		,Nivel SMALLINT
        ,Orden INT
		,Clase SMALLINT
        ,NombreClase VARCHAR(255)
        ,TipoAsuntoId INT
        ,Descripcion VARCHAR(255) NULL
        ,TipoCampo VARCHAR(255) NOT NULL
        ,TipoCampoId SMALLINT
        ,CatTipoAsuntoId INT
		,NumeroCatalogo INT
		,EsMultiple BIT		
		,TipoIcono INT
        ,OrdenRecursivo VARCHAR(MAX) -- Nueva columna para el orden recursivo
    );

    -- Tabla temporal para almacenar los elementos a procesar
    CREATE TABLE #Pendientes (
        Padre INT
		,Nivel SMALLINT
        ,Orden INT
		,Clase SMALLINT
        ,NombreClase VARCHAR(255)
        ,TipoAsuntoId INT
        ,Descripcion VARCHAR(255) NULL
        ,TipoCampo VARCHAR(255) NOT NULL
        ,TipoCampoId SMALLINT
        ,CatTipoAsuntoId INT
		,NumeroCatalogo INT
		,EsMultiple BIT
		,TipoIcono INT
    );

    -- Insertar los elementos raíz del menú en la tabla de pendientes
    INSERT INTO #Pendientes
    SELECT 
        vta.Padre
		,vta.Nivel
        ,CONVERT(INT, vta.Orden)
		,vta.Clase
        ,cc.CampoClaseDescripcion
        ,vta.TipoAsuntoId
        ,vta.Descripcion
        ,vta.TipoCampo
        ,vta.TipoCampoId
        ,vta.CatTipoAsuntoId
		,vta.Catalogo
		,ta.EsMultiple
		,CP.TipoPropiedadId TipoIcono 
    FROM [SISE3].[viTiposAsuntoExpediente] vta WITH(NOLOCK)
        JOIN CamposClase cc WITH(NOLOCK) ON cc.CampoClaseId = vta.Clase
		JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
		LEFT JOIN CamposPropiedades CP WITH(NOLOCK)  ON vta.TipoAsuntoId = CP.TipoAsuntoId
			AND CP.TipoPropiedadId IN(1,14,16) 
			AND CP.StatusReg = 1
    WHERE 
        vta.CatTipoAsuntoId = @CatTipoAsuntoId
        AND vta.StatusReg = 1
        AND vta.Padre = 0
		AND vta.Clase = 0
     ORDER BY CONVERT(INT,vta.Orden) ASC;

    WHILE EXISTS (SELECT 1 FROM #Pendientes)
    BEGIN
        -- Insertar los pendientes en los resultados, calculando el orden recursivo
        INSERT INTO #Resultados
        SELECT *, SISE3.CalcularOrdenRecursivo(TipoAsuntoId) AS OrdenRecursivo
        FROM #Pendientes;

        -- Obtener los siguientes elementos
        INSERT INTO #Pendientes
        SELECT 
            vta.Padre
			,vta.Nivel
            ,CONVERT(INT, vta.Orden)
			,vta.Clase
            ,cc.CampoClaseDescripcion
            ,vta.TipoAsuntoId
            ,vta.Descripcion
            ,vta.TipoCampo
            ,vta.TipoCampoId
            ,vta.CatTipoAsuntoId
			,vta.Catalogo
		    ,ta.EsMultiple
			,CP.TipoPropiedadId TipoIcono
        FROM 
            [SISE3].[viTiposAsuntoExpediente] vta WITH(NOLOCK)
            JOIN CamposClase cc WITH(NOLOCK) ON cc.CampoClaseId = vta.Clase
            JOIN #Pendientes p WITH(NOLOCK) ON p.TipoAsuntoId = vta.Padre			
		    JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
			LEFT JOIN CamposPropiedades CP WITH(NOLOCK)  ON vta.TipoAsuntoId = CP.TipoAsuntoId
			AND CP.TipoPropiedadId IN(1,14,16) 
			AND CP.StatusReg = 1
        WHERE 
            vta.CatTipoAsuntoId = @CatTipoAsuntoId
            AND vta.StatusReg = 1
         ORDER BY CONVERT(INT,vta.Orden) ASC

        -- Eliminar los procesados de la tabla de pendientes
        DELETE p
        FROM #Pendientes p
        JOIN #Resultados r ON r.TipoAsuntoId = p.TipoAsuntoId;
    END;

    -- Seleccionar los resultados ordenados por el orden recursivo
    SELECT * 
    FROM #Resultados
    ORDER BY OrdenRecursivo;

    -- Limpiar las tablas temporales
    DROP TABLE #Pendientes;
    DROP TABLE #Resultados;
END;