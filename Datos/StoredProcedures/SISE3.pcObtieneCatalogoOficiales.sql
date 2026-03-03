USE [SISE_NEW]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-----------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:  Erick Gonzalezs
-- Alter date:  09/05/2024
-- Description: Obtiene la información de los oficiales para un organismo y cargo específico
-- EXEC [SISE3].[pcObtieneCatalogoOficiales] 180, 17
-- =============================================
ALTER PROCEDURE [SISE3].[pcObtieneCatalogoOficiales]
    -- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
    @pi_CatOrganismoId INT,
    -- REPRESENTA LOS IDENTIFICADORES DEL CARGO COMO UNA LISTA SEPARADA POR COMAS
    @pi_CargoId NVARCHAR(MAX) = '22'
AS
BEGIN
    -- Selecciona información única de los empleados que tienen un cargo específico en un organismo específico
    WITH CombinedResults AS (
        -- Primera consulta: empleados relacionados a roles específicos en el organismo
        SELECT DISTINCT
            ce.EmpleadoId,
            nombreOficial = LTRIM(UPPER(ISNULL(ce.Nombre + ISNULL(' ' + ce.ApellidoPaterno, '') + ISNULL(' ' + ce.ApellidoMaterno, ''), ''))), 
            ce.UserName,
            1 AS isOther
        FROM sise3.REL_RolEmpleadoXOrganismo re
        JOIN CatEmpleados ce ON ce.EmpleadoId = re.IdCatEmpleado
        JOIN Promociones prom ON prom.RegistroEmpleadoId = re.IdCatEmpleado
        WHERE re.IdOrganismo = @pi_CatOrganismoId 
            AND re.bStatus = 1 
            AND ce.EstatusActivacion = 1
            AND YEAR(prom.FechaPresentacion) >= YEAR(GETDATE())
            AND prom.CatOrganismoId = @pi_CatOrganismoId
            AND prom.StatusReg = 1
        UNION
        -- Segunda consulta: empleados relacionados a un cargo específico en el organismo
        SELECT DISTINCT
            ce.EmpleadoId,
            nombreOficial = LTRIM(UPPER(ISNULL(ce.Nombre + ISNULL(' ' + ce.ApellidoPaterno, '') + ISNULL(' ' + ce.ApellidoMaterno, ''), ''))),
            ce.UserName,
            0 AS isOther
        FROM CatEmpleados ce
        INNER JOIN EmpleadoOrganismo eo ON ce.EmpleadoId = eo.EmpleadoId
        INNER JOIN [SISE3].SplitString(@pi_CargoId, ',') cargos ON eo.CargoId = CAST(cargos.Item AS INT)
        WHERE eo.CatOrganismoId = @pi_CatOrganismoId
            AND ce.FechaActivacion IS NOT NULL
    )
    , RankedResults AS (
        -- Asigna un número de fila para priorizar registros con isOther = 0
        SELECT 
            EmpleadoId,
            nombreOficial,
            UserName,
            isOther,
            ROW_NUMBER() OVER (PARTITION BY EmpleadoId, nombreOficial, UserName ORDER BY isOther) AS rn
        FROM CombinedResults
    )
    -- Selecciona los resultados únicos, prefiriendo isOther = 0
    SELECT
        EmpleadoId,
        nombreOficial,
        UserName,
        isOther
    FROM RankedResults
    WHERE rn = 1
    ORDER BY nombreOficial;
END;
