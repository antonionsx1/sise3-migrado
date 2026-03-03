SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Saul Garcia
-- Alter date:  13/02/2024 (Sergio O.)
-- Description: Detalle asunto documento 
-- Modificacion ContenidoAcuerdo
-- EXEC  [SISE3].pcDetalleAcuerdo 1494, 30313725, 2, 0
-- =============================================
-- EXEC  [SISE3].pcDetalleAcuerdo 147, 30316103, 2, 2

CREATE OR ALTER PROCEDURE [SISE3].[pcDetalleAcuerdo] 
    -- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	@pi_AsuntoNeunId BIGINT ,
	@pi_SintesisOrden INT, 
	@pi_AsuntoDocumentoId INT
AS
BEGIN
	
	DECLARE @FechaNotificacion DATETIME

	SELECT @FechaNotificacion = CASE 
		   WHEN COUNT(FechaNotificacion) = COUNT(1) THEN MAX(FechaNotificacion)
		   ELSE NULL END
	FROM NotificacionElectronica_Personas np  
	WHERE AsuntoNeunId = @pi_AsuntoNeunId 
			AND SintesisOrden = @pi_SintesisOrden
			AND statusReg = 1

	SELECT ex.AsuntoAlias AS Expediente
		   ,ex.CatTipoAsunto AS TipoAsuntoDescripcion
		   ,dbo.funRecuperaCatalogoDependienteDescripcion(527,saa.TipoCuaderno) as NombreTipoCuaderno
		   ,saa.TipoCuaderno
--		   ,cp.CatalogoPromocionDescripcion ContenidoAcuerdo
           ,ced.CatalogoElementoDescripcion ContenidoAcuerdo
		   ,saa.FechaAlta FechaRecepcionAcuerdo
		   ,DATEDIFF(DAY,ISNULL(saa.fechaActualizacion,saa.FechaAlta),ISNULL(@FechaNotificacion,GETDATE())) DiasTranscurridos
		   ,saa.Sintesis
	FROM SintesisAcuerdoAsunto saa
	CROSS APPLY SISE3.fnExpediente(saa.AsuntoNeunId) ex
	LEFT JOIN AsuntosDocumentos ad 
		ON saa.AsuntoID = ad.AsuntoID 
		AND saa.AsuntoNeunId = ad.AsuntoNeunId 
		AND ad.SintesisOrden = saa.SintesisOrden
--	LEFT JOIN CatPromocion cp
--		ON cp.CatalogoPromocionId = ad.CatContenidoId
    LEFT JOIN CatalogosElementosDescripcion ced 
        ON ced.CatalogoElementoDescripcionID = ad.CatContenidoId
	WHERE saa.AsuntoNeunId= @pi_AsuntoNeunId
	AND saa.CatOrganismoId = @pi_CatOrganismoId
	AND saa.SintesisOrden = @pi_SintesisOrden
	AND saa.EstatusSintesis = 1

	SELECT 'Promoción ' + CONVERT(VARCHAR(20),p.NumeroRegistro) Promocion
	FROM Promociones p
	WHERE p.CatOrganismoId = @pi_CatOrganismoId
	AND p.AsuntoNeunId = @pi_AsuntoNeunId
	AND p.AsuntoDocumentoId = @pi_AsuntoDocumentoId
	AND statusReg = 1
END
