SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** 06/12/2023                 ******/
/****** Proyecto: SISE3       ******/
/****** Autor: Christian Araujo - MS  ******/
/****** Objetivo: Devuelve el detalle de una promoción para generación de alerta por garga masiva de archivos******/
/****** EXEC SISE3.[pcGeneraDetalleAlertaPromocion] 2023, 617,180*****/

CREATE OR ALTER PROCEDURE [SISE3].[pcGeneraDetalleAlertaPromocion]
	(@pi_YearPromocion INT,
	@pi_NumeroRegistro INT,
	@pi_CatOrganismoId INT
	)
AS
BEGIN
	SELECT p.NumeroRegistro, a.AsuntoAlias as NumeroExpediente, a.CatTipoAsunto as TipoAsunto, a.TipoProcedimiento, p.Mesa, p.Secretario as SecretarioId
	FROM 
	Promociones p
	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
	WHERE p.YearPromocion = @pi_YearPromocion
	AND p.NumeroRegistro = @pi_NumeroRegistro
	AND p.CatOrganismoId = @pi_CatOrganismoId
END

