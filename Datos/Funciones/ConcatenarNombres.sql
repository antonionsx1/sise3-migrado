USE [SISE_NEW]
GO

/****** Object:  UserDefinedFunction [SISE3].[ConcatenarNombres]    Script Date: 10/12/2023 1:43:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		GGHH
-- Create date: 24/07/2023
-- Description:	Concatena varios valores para el nombre
-- Example: SELECT SISE3.ConcatenarNombres( 'Gemma', '', '')
-- =============================================
CREATE FUNCTION [SISE3].[ConcatenarNombres]
(
	@pi_Primero VARCHAR(100), 
	@pi_Segundo VARCHAR(100), 
	@pi_Tercero VARCHAR(100)
)
RETURNS VARCHAR(300)
AS
BEGIN

	DECLARE @ps_Nombre VARCHAR(300)
	
	SET @pi_Primero = LTRIM(RTRIM(REPLACE(@pi_Primero, '.', ' ')))
	SET @pi_Segundo = LTRIM(RTRIM(REPLACE(@pi_Segundo, '.', ' ')))
	SET @pi_Tercero = LTRIM(RTRIM(REPLACE(@pi_Tercero, '.', ' ')))
	SET @ps_Nombre = RTRIM(CONCAT(
		IIF((@pi_Primero IS NOT NULL AND LEN(@pi_Primero) > 0 AND @pi_Primero <> 'Sin valor'), @pi_Primero, ''),
		IIF((@pi_Segundo IS NOT NULL AND LEN(@pi_Segundo) > 0 AND @pi_Segundo <> 'Sin valor'), ' ' + @pi_Segundo, ''),
		IIF((@pi_Tercero IS NOT NULL AND LEN(@pi_Tercero) > 0 AND @pi_Tercero <> 'Sin valor'), ' ' + @pi_Tercero, '')
		))

	RETURN @ps_Nombre

END
GO

