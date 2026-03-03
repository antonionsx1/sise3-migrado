SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GGHH
-- Create date: 21/02/2024
-- Description:	Obtienen el estado general de un expediente
-- [SISE3].[pcEstadoSentencia] 30315607
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcEstadoSentencia]
	--IDENTIFICADOR DEL ASUNTO
	@pi_AsuntoNeunId BIGINT
AS
BEGIN

	SELECT TOP 1 FechaSentencia,Estado,Ejecucion
	FROM (
		SELECT TOP 1
			Id = 1,
			FechaSentencia = CONVERT(VARCHAR(10),f.ValorCampoAsunto,103),
			Estado = CASE WHEN f.ValorCampoAsunto IS NULL THEN 'En proyecto' ELSE 'Aprobada' END,
			Ejecucion = CASE WHEN f.ValorCampoAsunto > GETDATE() THEN 'En vías' ELSE '' END
		FROM AsuntosDetalleFechas f WITH(NOLOCK)
		INNER JOIN TiposAsunto ta WITH(NOLOCK) ON f.TipoAsuntoId = ta.tipoAsuntoId
		WHERE f.AsuntoNeunId = @pi_AsuntoNeunId
		AND f.StatusReg = 1
		AND ta.Descripcion LIKE '%Sentencia%'
		AND ta.CatCampoFormatoId = 5
		ORDER BY f.ValorCampoAsunto DESC
		UNION 
		SELECT 2, 'Sin fecha', 'En proyecto', ''
	)tbl
	ORDER BY tbl.Id
END
