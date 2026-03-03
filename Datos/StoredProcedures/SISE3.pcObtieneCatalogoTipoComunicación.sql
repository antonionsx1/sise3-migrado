SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Sergio Orozco - MS 
-- Create date: 05/03/2024
-- Description: Obtiene el catalogo de Tipo de Comunicación para C.O.E.
-- EXEC [SISE3].[pcObtieneCatalogoTipoComunicación]
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneCatalogoTipoComunicación] 
AS
BEGIN
CREATE TABLE #TempCatTipoComunicacion (ID INT, Descripcion VARCHAR(100), Elementos INT)

INSERT INTO #TempCatTipoComunicacion
EXEC usp_catalogosSel 79, 0, 4

SELECT ID, Descripcion FROM #TempCatTipoComunicacion
order by Descripcion asc

drop table #TempCatTipoComunicacion

END;
