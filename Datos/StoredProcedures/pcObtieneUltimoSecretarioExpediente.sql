USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcObtieneUltimoSecretarioExpediente]    Script Date: 12/1/2023 6:21:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author: Diana Quiroga 
-- Create date: 28/11/2023
-- Description:	Busca el ultimo secretario asignado a la ultima promocion por expediente
-- EXEC [SISE3].[pcObtieneUltimoSecretarioExpediente] '3232/2023',1494
-- =============================================
CREATE PROCEDURE [SISE3].[pcObtieneUltimoSecretarioExpediente]
	-- REPRESENTA EL ASUNTO ALIAS POR EL CUAL SE DESEA OBTENER
	@pi_AsuntoNeunId BIGINT, 
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT
AS
BEGIN


		/*Cargar Asuntos Documentos que no tienen promoción*/
		CREATE TABLE #MaxSec
		(AsuntoNeunId BIGINT, 
			Expediente VARCHAR(50) collate SQL_Latin1_General_CP850_CI_AI, 
			Secretario BIGINT,
			Id int 
		)


		INSERT INTO #MaxSec
		SELECT p.AsuntoNeunId, 
		aa.AsuntoAlias ,
		p.Secretario,
		ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, aa.AsuntoAlias ORDER BY CAST(CONCAT(CONVERT(VARCHAR,p.FechaPresentacion,112),' ',p.HoraPresentacion) AS DATETIME) DESC) AS id
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) aa
		INNER JOIN CatTiposAsunto ta ON aa.CatTipoAsuntoId = ta.CatTipoAsuntoId
		INNER  JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId
													AND pa.CatOrganismoId = p.CatOrganismoId 
													AND pa.NumeroOrden = p.NumeroOrden
													AND pa.Origen = p.OrigenPromocion 
													AND pa.YearPromocion = p.YearPromocion
													AND pa.StatusArchivo = 1
													AND pa.ClaseAnexo = 0
		WHERE p.StatusReg = 1 
		AND aa.AsuntoNeunId = @pi_AsuntoNeunId
		AND aa.CatOrganismoId = @pi_CatOrganismoId
		AND aa.CatTipoAsuntoId = ta.CatTipoAsuntoId


		SELECT	
			 Secretario
		FROM #MaxSec a 
		WHERE id = 1
		
	

END
GO

