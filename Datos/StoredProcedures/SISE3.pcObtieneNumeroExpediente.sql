SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GGHH
-- Create date: 31/08/2023
-- Description:	Obtiene el siguiente número de expediente para un año y un tipo de asunto especifico.
-- EXEC SISE3.pcObtieneNumeroExpediente 180,67,16822
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneNumeroExpediente]
	@pi_CatOrganismoId INT,
	@pi_CatTipoAsunto INT,
	@pi_CatTipoProcedimiento INT
AS
BEGIN
	/*SET NOCOUNT ON;
	DECLARE @Anio INT = YEAR(GETDATE())
	SELECT CONCAT(ISNULL(MAX(Substring (asuntoAlias,0, Charindex( '/', asuntoAlias ))),0)+1,'/',@Anio)
	FROM Asuntos
	WHERE  StatusReg = 1 
	AND CatOrganismoId = @pi_CatOrganismoId
	AND CatTipoAsuntoId = @pi_CatTipoAsunto
	AND Substring (asuntoAlias, Charindex( '/', asuntoAlias ) + 1,LEN(AsuntoAlias)) = @Anio
	*/
	DECLARE @NumeroAsuntoSiguiente INT
	DECLARE @NumeroExpedienteNuevo VARCHAR(50)
	DECLARE @YEAR INT = YEAR(GETDATE())
	SELECT @NumeroAsuntoSiguiente=(ISNULL(Max(right(NumeroAlias, LEN(NumeroAlias) - 4)),0)+1)
	FROM dbo.Asuntos
	where StatusReg = 1
    AND CatOrganismoId = @pi_CatOrganismoId
    AND CatTipoAsuntoId = @pi_CatTipoAsunto
	AND CatTipoProcedimiento = @pi_CatTipoProcedimiento
    AND left(NumeroAlias,4) = @YEAR
 
	SET @NumeroExpedienteNuevo = CONCAT(@NumeroAsuntoSiguiente,'/',@YEAR)
	SELECT @NumeroExpedienteNuevo as AsuntoAlias
END
