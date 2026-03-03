USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcListaPromocionesXExpediente]    Script Date: 12/1/2023 6:18:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ============================================= 
-- Author: Diana Quiroga - MS
-- Alter date: 28/09/2023 
-- Description: Se uliliza para listar las promociones por expediente 
--execute [SISE3].[pcListaPromocionesXExpediente] 30314352, '548/2023'
-- ============================================= 

CREATE PROCEDURE [SISE3].[pcListaPromocionesXExpediente]
@pi_AsuntoNeunId [bigint],
@pi_NoExpediente Varchar(50)
AS

BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT pr.NumeroRegistro, pr.NumeroOrden, pr.YearPromocion, 
	[SISE3].[fnEstatusPromocion] (ad.CatAutorizacionDocumentosId , 0, pa.[NombreArchivo]) as EstadoPromocion
	FROM Promociones pr
	INNER JOIN Asuntos Ex on ex.AsuntoNeunId = pr.AsuntoNeunId
	LEFT JOIN AsuntosDocumentos ad on ad.AsuntoNeunId = pr.AsuntoNeunId and pr.AsuntoDocumentoId = ad.AsuntoDocumentoId
	LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = pr.AsuntoNeunId
												AND pa.CatOrganismoId = pr.CatOrganismoId 
												AND pa.NumeroOrden = pr.NumeroOrden
												AND pa.Origen = pr.OrigenPromocion 
												AND pa.YearPromocion = pr.YearPromocion
												AND pa.StatusArchivo = 1
												AND pa.ClaseAnexo = 0
	WHERE pr.AsuntoNeunId = @pi_AsuntoNeunId 
	AND pr.StatusReg = 1
	AND ex.AsuntoAlias = @pi_NoExpediente
	AND  [SISE3].[fnEstatusPromocion] (ad.CatAutorizacionDocumentosId , 0, pa.[NombreArchivo]) <> 2 
	AND (ad.CatAutorizacionDocumentosId  IN (2,3) OR (ad.AsuntoDocumentoId = 0 OR ad.AsuntoDocumentoId IS NULL) OR (ad.CatAutorizacionDocumentosId NOT IN (2,3,4,8,9)))
	AND ((pr.AsuntoDocumentoId IS  NULL OR pr.AsuntoDocumentoId=0) AND (ad.AsuntoDocumentoId = 0 OR ad.AsuntoDocumentoId IS NULL))
		SET NOCOUNT OFF
END
GO

