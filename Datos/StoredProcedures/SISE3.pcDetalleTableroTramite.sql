SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  09/11/2023
-- Description: Detalle asunto documento 
-- EXEC  [SISE3].pcDetalleTableroTramite 180, 30314120, 32, 32
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcDetalleTableroTramite] 
    -- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	@pi_AsuntoNeunId BIGINT ,
	@pi_SintesisOrden INT, 
	@pi_AsuntoDocumentoId INT
AS
BEGIN

	/*Dataset Cabecera Tramite*/
	SELECT a.CatOrganismoId, a.AsuntoId, a.AsuntoNeunId, sa.SintesisOrden, sa.FechaAlta as FechaCaptura
	,ad.AsuntoDocumentoId, ad.CatAutorizacionDocumentosId, ad.FechaAlta, ad.NombreArchivo, ad.NombreDocumento, ad.CatContenidoId, sa.Sintesis
	,ad.uGuidDocumento
	FROM Asuntos a 
	INNER JOIN SintesisAcuerdoAsunto sa ON a.CatOrganismoId = sa.CatOrganismoId AND a.AsuntoNeunId = sa.AsuntoNeunId
	INNER JOIN AsuntosDocumentos ad ON a.AsuntoID = ad.AsuntoID AND a.AsuntoNeunId = ad.AsuntoNeunId AND ad.SintesisOrden = sa.SintesisOrden
	WHERE a.CatOrganismoId = @pi_CatOrganismoId
          AND a.AsuntoNeunId = @pi_AsuntoNeunId
          AND sa.SintesisOrden = @pi_SintesisOrden
		  AND ad.AsuntoDocumentoId = @pi_AsuntoDocumentoId

	/*Dataset Promociones*/
	SELECT p.CatOrganismoId, p.AsuntoId, p.AsuntoNeunId, p.NumeroOrden, p.NumeroRegistro
	FROM Promociones p
	WHERE p.CatOrganismoId = @pi_CatOrganismoId
          AND p.AsuntoNeunId = @pi_AsuntoNeunId
		  AND p.AsuntoDocumentoId = @pi_AsuntoDocumentoId
		  AND statusReg = 1

	/*Dataset Partes*/
	SELECT AsuntoId, AsuntoNeunId, SintesisOrden, PersonaId, PromoventeId, NotElecId, NotificacionElectronicaJL, TipoNotificacion
	FROM NotificacionElectronica_Personas np  
	WHERE AsuntoNeunId = @pi_AsuntoNeunId 
		 AND SintesisOrden = @pi_SintesisOrden 
		 AND statusReg = 1

	/*Dataset Oficio*/
	SELECT AsuntoId, AsuntoNeunId, AsuntoDocumentoId, AnexoId, AnexoParteId, AnexoParteDescripcion, AnexoTipoId, Texto, NombreDocumento, RutaArchivoNAS, RutaAnexo, NombreArchivo
	FROM [SISE_NEW].[dbo].[Anexos]
	WHERE AsuntoNeunId = @pi_AsuntoNeunId 
		  AND AsuntoDocumentoId = @pi_AsuntoDocumentoId

END;