SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 11/23/23
-- Objetivo: Obtienen el detalle de los filtros del tablero de tramite
-- EXEC  [SISE3].[pcObtieneFiltrosTramite]  180
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneFiltrosActuaria] 
(
@pi_catIdOrganismo INT
)


AS
BEGIN

	SELECT 1 AS ID, 'Sin asignar' AS Estado​ 
	UNION
	SELECT 2 AS ID, 'Pendiente' AS Estado​ 
	UNION
	SELECT 3 AS ID, 'Notificados' AS Estado​ 
​

	exec usp_CatalogosSel  496,0,0

END
