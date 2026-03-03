SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:  Sergio Orozco MSFT
-- Alter date:  12/03/2024
-- Description: Obtiene los organos de tipo OCC
-- Ejecutar como : EXEC [SISE3].[pcOrganismosOCC] 
-- =============================================
CREATE OR ALTER PROCEDURE  [SISE3].[pcOrganismosOCC]
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
      



      BEGIN

                  --se crean las tablas temporales. 
                  CREATE TABLE #TmpOrgs
				  (CircuitoOrden int,
				   CatOrganismoId int,
				   NombreOficial  varchar(300), 
				   CatTipoOrganismoId INT)


                  INSERT INTO #TmpOrgs 
				  SELECT cc.CircuitoOrden, co.CatOrganismoId, co.NombreOficial, co.CatTipoOrganismoId 
                  FROM 
                    CatOrganismos AS co WITH (nolock) 
					INNER JOIN CatCircuitos AS cc WITH (nolock) ON co.CatCircuitoId = cc.CatCircuitoId
                  where co.statusreg=1 and CatTipoOrganismoId in (7,8,9,31,58)
                    

				  select * from #TmpOrgs 
                  order by CatOrganismoId asc 
      END

		IF OBJECT_ID('tempdb..#TmpOrgs') IS NOT NULL
		DROP TABLE #TmpOrgs;


END
