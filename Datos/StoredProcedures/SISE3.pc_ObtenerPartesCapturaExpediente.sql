SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Autor: Anabel Gonzalez
-- Creado: 23/08/2024
-- Objetivo: Obtener las partes en Captura Expediente
-- Ejemplo: EXEC [SISE3].[pc_ObtenerPartesCapturaExpediente] 30315745
-- =============================================

CREATE PROCEDURE [SISE3].[pc_ObtenerPartesCapturaExpediente]
    @pc_AsuntoNeunId INT
AS
BEGIN
	 SELECT DISTINCT PersonaId
		FROM (
			SELECT PF.PersonaId FROM PersonasAsuntosDetalleFechas PF WITH(NOLOCK) WHERE AsuntoNeunId = @pc_AsuntoNeunId
			UNION ALL
			SELECT PD.PersonaId FROM PersonasAsuntoDetalleDescripcion PD WITH(NOLOCK) WHERE AsuntoNeunId = @pc_AsuntoNeunId 
			UNION ALL
			SELECT  PC.PersonaId FROM PersonasAsuntosDetalleCatalogos PC WITH(NOLOCK) WHERE AsuntoNeunId = @pc_AsuntoNeunId 
			UNION ALL
			SELECT  PN.PersonaId FROM PersonasAsuntosDetalleNumeros PN WITH(NOLOCK) WHERE AsuntoNeunId = @pc_AsuntoNeunId 
			UNION ALL
			SELECT  PO.PersonaId FROM PersonasAsuntosDetalleOpciones PO WITH(NOLOCK) WHERE AsuntoNeunId = @pc_AsuntoNeunId 
		) AS CombinedResults;
END;