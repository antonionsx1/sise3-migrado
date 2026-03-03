SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GGHH
-- Create date: 21/02/2024
-- Description:	Obtienen la información de la audiencia
-- EXEC SISE3.pcAudiencia 30315607,1
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcAudiencia]
	--IDENTIFICADOR DEL ASUNTO
	@pi_AsuntoNeunId BIGINT,
	--IDENTIFICADOR DEL CUADERNO
	@pi_CuadernoId INT
AS
BEGIN
	SELECT TOP 1
			Fecha = ISNULL(CONVERT(VARCHAR(10), f.ValorCampoAsunto,103) ,''),
			Hora = ISNULL(CONVERT(CHAR(5),h.ValorCampoAsunto,108),''),
			Resultado = ISNULL(r.Descripcion,''),
			TipoAudiencia = ISNULL(t.Descripcion,'')
	FROM AUD_AsuntosDetalleFechas a WITH(NOLOCK) 
	LEFT JOIN AsuntosDetalleFechas f WITH(NOLOCK) ON a.AsuntoNeunId = f.AsuntoNeunId AND a.FechaId = f.AsuntoDetalleFechasId AND f.StatusReg = 1
	LEFT JOIN AsuntosDetalleFechas h WITH(NOLOCK)  ON a.AsuntoNeunId = h.AsuntoNeunId AND a.HoraId = h.AsuntoDetalleFechasId AND f.StatusReg = 1
	LEFT JOIN AUD_CatResultado r WITH(NOLOCK)  ON a.ResultadoId = r.IdResultado
	LEFT JOIN AUD_CatTipoAudiencia t WITH(NOLOCK)  ON a.AudienciaId = t.IdTipoAudiencia
	WHERE a.AsuntoNeunId = @pi_AsuntoNeunId
	AND a.AudienciaId = 1
	AND a.StatusReg = 1
	ORDER BY a.AgendaId DESC
END
