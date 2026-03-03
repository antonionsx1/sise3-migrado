USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcObtieneNumeroExpediente]    Script Date: 12/1/2023 6:20:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		GGHH
-- Create date: 31/08/2023
-- Description:	Obtiene el siguiente número de expediente para un año y un tipo de asunto especifico.
-- EXEC SISE3.pcObtieneNumeroExpediente 772,1
-- =============================================
CREATE PROCEDURE [SISE3].[pcObtieneNumeroExpediente]
	@pi_CatOrganismoId INT,
	@pi_CatTipoAsunto INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Anio INT = YEAR(GETDATE())
	SELECT ISNULL(MAX(Substring (asuntoAlias,0, Charindex( '/', asuntoAlias ))),0)+1
	FROM Asuntos
	WHERE  StatusReg = 1 
	AND CatOrganismoId = @pi_CatOrganismoId
	AND CatTipoAsuntoId = @pi_CatTipoAsunto
	AND Substring (asuntoAlias, Charindex( '/', asuntoAlias ) + 1,LEN(AsuntoAlias)) = @Anio
END
GO

