SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date:24/10/2023 
-- Description:	Obtiene el numero de Año, Anex, Folio bansandose en el ultimo registro con el folio  y el asuntoneunid
-- EXEC [SISE3].[uspx_getFolioOficio] 1808, 10
-- Nodiificacion: GGHH - 03/05/2013 - Se agrego el TipoAsunto
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getFolioOficio]
(
	@pi_asuntoNeun BIGINT,
	@pi_organismoId BIGINT
)
AS
BEGIN
	SELECT top 1 
	   Año AS Anio,
       AnexoTipoId AS TipoAnexo,
	   Folio
  FROM [SISE_NEW].[dbo].[Anexos]
  WHERE AsuntoNeunId = @pi_asuntoNeun
    AND CatOrganismoId = @pi_organismoId
  ORDER BY Folio DESC
	
END

