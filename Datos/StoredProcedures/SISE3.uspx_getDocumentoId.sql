SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 11/11/2023
-- Description:	Obtiene el DocumentoId  a partir del AsuntoNeun
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getDocumentoId]
	(
	@pi_AsuntoNeunId INT  =NULL
	)
AS
BEGIN
	
	SELECT  TOP 1 DocumentoId  
	FROM Seguimiento 
	WHERE AsuntoNeun = @pi_AsuntoNeunId
	ORDER BY  FechaHora DESC

END
