SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GGHH
-- Create date: 23/02/2024
-- Description: pcDatosGenerales
-- [SISE3].[pcDatosGenerales] 30315607
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcDatosGenerales]
	--IDENTIFICADOR DEL ASUNTO
	@pi_AsuntoNeunId BIGINT
AS
BEGIN
	SELECT top 1
		FechaOCC = GETDATE(),
		FechaOrg = GETDATE(),
		Secretario = 'Juan Pérez',
		Mesa = 'Mesa 1'
	FROM Asuntos a WITH(NOLOCK)
	WHERE AsuntoNeunId = @pi_AsuntoNeunId
END
