SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación: 18 de Julio 2024
-- Descripción: Obtiene las horas disponibles respecto a una fecha de audiencia o día
-- Ejemplo : EXEC [SISE3].[pcAgendaHorariosDisponibles] 147,30315724,1,1,'2024-08-16'
-- SPOriginal : EXEC [dbo].[usp_AgendaHorasDisponibles]
-- ============================================= 

ALTER PROCEDURE [SISE3].[pcAgendaHorariosDisponibles]
@pc_CatOrganismoId INT,
@pc_AsuntoNeunId INT,
@pc_IdTipoAudiencia INT,
@pc_TipoAsuntoId INT,
@pc_FechaAudiencia DATETIME
AS
	BEGIN
		SET NOCOUNT ON
			BEGIN TRY
		
					SELECT
						 CONVERT(DATE,hora.ValorCampoAsunto,103) Fecha
						,CONVERT(VARCHAR(10),CONVERT(TIME,hora.ValorCampoAsunto,103),8) DescripcionHora
					FROM [AUD_AsuntosDetalleFechas] aud WITH(NOLOCK)					
					INNER JOIN Asuntos asu WITH(NOLOCK)	ON asu.AsuntoNeunId = aud.AsuntoNeunId
					JOIN AsuntosDetalleFechas hora WITH(NOLOCK) ON aud.ControlHora=hora.TipoAsuntoId 
						AND aud.HoraId=hora.AsuntoDetalleFechasId 
						AND aud.AsuntoNeunId = hora.AsuntoNeunId
						AND aud.AsuntoId = hora.AsuntoId
					JOIN AsuntosDetalleFechas fecha WITH(NOLOCK) ON aud.ControlFecha=fecha.TipoAsuntoId 
						AND aud.FechaId=fecha.AsuntoDetalleFechasId 
						AND aud.AsuntoNeunId = fecha.AsuntoNeunId
						AND aud.AsuntoId = fecha.AsuntoId
					WHERE CONVERT(DATE,fecha.ValorCampoAsunto,103) = @pc_FechaAudiencia
						AND aud.OrganoId = @pc_CatOrganismoId
						AND asu.AsuntoNeunId = @pc_AsuntoNeunId
						AND aud.AudienciaId = @pc_IdTipoAudiencia 
						AND asu.CatTipoAsuntoId = @pc_TipoAsuntoId
						AND aud.StatusReg=1 
					ORDER BY hora.ValorCampoAsunto DESC

			END TRY
		BEGIN CATCH
			--EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
		SET NOCOUNT OFF
	END
