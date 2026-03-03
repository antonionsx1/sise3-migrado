SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date:25/10/2023 
-- Description:	Obtiene el numero de Año, Anex, orden bansandose en el ultimo registro con catOrganismoId  y el asuntoneunid
-- EXEC [SISE3].[uspx_getPromocion] 8357752, 4
-- Modificación
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getPromocion]
(
	@pi_asuntoNeun BIGINT,
	@pi_organismoId BIGINT
)
AS
BEGIN
     SELECT TOP 1 
	       YearPromocion,
		   NumeroOrden AS Orden 
	FROM Promociones 
	WHERE AsuntoNeunId = @pi_asuntoNeun
	  AND CatOrganismoId =  @pi_organismoId
	ORDER BY NumeroOrden DESC
	
	
END



