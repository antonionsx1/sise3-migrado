SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Saul Garcia
-- Create date:  11/01/2024
-- Description: Devuelve el folio de los oficios
-- EXEC [SISE3].[pcObtieneOficio] 180,30315077,8,171520992
-- =============================================

CREATE OR ALTER PROC [SISE3].[pcObtieneOficio]
(
	 @pi_CatOrganismo INT,
	 @pi_AsuntoNeunId BIGINT,
	 @pi_AsuntoDocumentoId INT,
	 @pi_AnexoParteId INT
)
AS
BEGIN
	SELECT  CONVERT(VARCHAR(100),ax.Folio)+'/'+CONVERT(VARCHAR(100),ax.Año) Folio
	FROM AsuntosDocumentos ad WITH(NOLOCK) 
	INNER JOIN Anexos ax 
		ON ax.AsuntoNeunId = ad.AsuntoNeunId 
		AND ax.AsuntoDocumentoId = ad.AsuntoDocumentoId
	WHERE ad.AsuntoNeunId = @pi_AsuntoNeunId
	AND ad.AsuntoDocumentoId = @pi_AsuntoDocumentoId
	AND ax.CatOrganismoId = @pi_CatOrganismo
	AND ax.AnexoParteId = @pi_AnexoParteId
END
