USE [SISE_NEW]
GO
/****** Object:  UserDefinedFunction [SISE3].[fnEstatusPromocion]    Script Date: 12/14/2023 11:35:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Diana Quiroga Microsoft
-- Create date: 06/09/2023
-- Description:	Retorna el Estatus de la promoción
-- Example: SELECT [SISE3].[fnEstatusPromocion] (NULL , 2, NULL)
-- =============================================
ALTER FUNCTION [SISE3].[fnEstatusPromocion]
(
	@pi_catAutorizacionDocumentosId INT NULL, 
	@pi_EsPromocionE INT, 
	@pi_NombreArchivo NVARCHAR(300),
	@pi_Origen INT = 0
)
RETURNS INT
AS
BEGIN

	DECLARE @ps_Estatus VARCHAR(300)
	SET @ps_Estatus  = (CASE WHEN @pi_EsPromocionE = 1 THEN 1 
							WHEN @pi_EsPromocionE = 0 AND @pi_Origen IN (6,16,22,5,15,29) THEN 4
							WHEN  @pi_EsPromocionE = 0 AND @pi_catAutorizacionDocumentosId IS NULL 	AND @pi_NombreArchivo IS NULL THEN 2
							WHEN  @pi_EsPromocionE = 0 AND @pi_NombreArchivo IS NOT NULL THEN 4							
							ELSE 0
						END )
	
	
	RETURN @ps_Estatus

END
