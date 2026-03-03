SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date:23/10/2023 
-- Description:	Obtiene el numero de orden bansandose en el ultimo registro en la tabla
-- EXEC [SISE3].[uspx_getOrdenAcuerdo] 23070844,	4
-- Nodiificacion: GGHH - 03/05/2013 - Se agrego el TipoAsunto
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getOrdenAcuerdo]
(
	@pi_asuntoNeun BIGINT,
	@pi_organismoId BIGINT
)
AS
BEGIN
	SELECT 	TOP 1
	SintesisOrden AS Orden
	
	FROM sintesisacuerdoasunto
	WHERE AsuntoNeunId=@pi_asuntoNeun
	AND CatOrganismoId = @pi_organismoId
	ORDER BY SintesisOrden DESC
	
END