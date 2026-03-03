SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:  Saul Garcia
-- Create date:  29/01/2024
-- Description: Devuelve el oficio por el folio
-- EXEC [SISE3].[pcConsultaAcuerdoYOficios] '95387ff2-6add-4ede-90ec-4ebe4b2d4a5a'
-- =============================================

CREATE OR ALTER PROC [SISE3].[pcConsultaAcuerdoYOficios]
(
	 @pi_GuidAcuerdo UNIQUEIDENTIFIER
)
AS
BEGIN

    DECLARE @AsuntoNeunId BIGINT
    DECLARE @AsuntoDocumentoId INT

    SELECT @AsuntoNeunId = AsuntoNeunId, @AsuntoDocumentoId = AsuntoDocumentoId
    FROM AsuntosDocumentos ad
    WHERE ad.uGuidDocumento = @pi_GuidAcuerdo

    SELECT 
         Firmado
        ,EsAcuerdo = 1
        ,CONCAT(rc.sRuta,'\',a.CatorganismoId,'\', dj.NombreArchivo) Ruta
        ,ad.NombreArchivo
        ,RIGHT(dj.NombreArchivo, LEN(dj.NombreArchivo) - CHARINDEX('.', dj.NombreArchivo)) ExtensionDocumento
        ,ad.uGuidDocumento uGuid
        -- ,IIF(Firmado = 1, LEFT(dj.NombreArchivo, CHARINDEX('.', dj.NombreArchivo))+'.p7m', NULL) ArchivoFirma
    FROM AsuntosDocumentos ad
    JOIN Asuntos a WITH(NOLOCK) 
		ON a.AsuntoNeunId= ad.AsuntoNeunId
    JOIN DeterminacionesJudiciales dj WITH(NOLOCK)
        ON dj.AsuntoNeunId = ad.AsuntoNeunId
        AND dj.SintesisOrden = ad.SintesisOrden
        AND dj.CatOrganismoId = a.CatOrganismoId
    LEFT JOIN CAT_RutasChunk rc 
        ON rc.iGrupo = 1 AND rc.iEscritura = 1
    WHERE ad.uGuidDocumento = @pi_GuidAcuerdo

    UNION

    SELECT 
         Firmado
        ,EsAcuerdo = 0
        ,CONCAT(rc.sRuta,'\',eo.CatOrganismoId,'\', CONCAT(eo.NombreArchivo, eo.ExtensionDocumento)) Ruta
        ,NombreArchivo
        ,ExtensionDocumento
        ,eo.uGuid
        -- ,IIF(Firmado = 1, eo.NombreArchivo+'.p7m', NULL) ArchivoFirma
    FROM EstadoOficio eo
    LEFT JOIN CAT_RutasChunk rc 
        ON rc.kId = eo.kIdRuta
    WHERE AsuntoNeunId = @AsuntoNeunId
    AND AsuntoDocumentoId = @AsuntoDocumentoId
	
END

