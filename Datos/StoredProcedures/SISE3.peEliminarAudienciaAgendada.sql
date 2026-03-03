SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación: 31 de Julio 2024
-- Descripción: Se elimina la audiencia agendada 
-- SPOriginal : EXEC [SISE3].[peEliminarAudienciaAgendada] 180,'2024-08-14','2024-08-12',30315620,3,9172970
-- ============================================= 
ALTER PROCEDURE [SISE3].[peEliminarAudienciaAgendada]
(
    @pe_CatOrganismoId INT,	
	@pe_FechaAudiencia DATETIME,
	@pe_FechaAlta DATETIME,
	@pe_HoraAlta VARCHAR(8),
	@pe_AsuntoNeunId INT,
	@pe_AudienciaId INT,	
	@pe_AgendaId INT
)
AS
BEGIN

	 DECLARE @Deleted_Rows INT;
	 SET @Deleted_Rows = 1;

    BEGIN TRY
	 BEGIN TRAN
		BEGIN
	 
		 CREATE TABLE #AsuntoFechasId (id INT)

		 IF(@pe_AudienciaId <> 3)
			BEGIN
		
		    INSERT INTO #AsuntoFechasId (id)		
			SELECT FechaId AS Id FROM AUD_AsuntosDetalleFechas WITH(NOLOCK) 
			WHERE AgendaId = @pe_AgendaId AND AsuntoNeunId = @pe_AsuntoNeunId 
			UNION ALL 
			SELECT HoraId  FROM AUD_AsuntosDetalleFechas WITH(NOLOCK) 
			WHERE AgendaId = @pe_AgendaId AND AsuntoNeunId = @pe_AsuntoNeunId 


			--INICIAN DELETE

			DELETE FROM AUD_AsuntosDetalleFechas
			WHERE AgendaId = @pe_AgendaId
			SET @Deleted_Rows = @@ROWCOUNT;
						
			DELETE FROM PersonasAsuntosDetalleFechas
			WHERE AsuntoNeunId = @pe_AsuntoNeunId 
		    AND AsuntoDetalleFechasId IN(SELECT id FROM #AsuntoFechasId) 
			SET @Deleted_Rows = @@ROWCOUNT;
					   			 
			DELETE FROM AsuntosDetalleFechas
			WHERE AsuntoNeunId = @pe_AsuntoNeunId 
			AND AsuntoDetalleFechasId IN (SELECT id FROM #AsuntoFechasId) 
			SET @Deleted_Rows = @@ROWCOUNT;

		END
		ELSE
		BEGIN

			INSERT INTO #AsuntoFechasId (id)
			SELECT FechaId AS Id FROM AUD_AsuntosDetalleFechas WITH(NOLOCK)
			WHERE  AsuntoNeunId = @pe_AsuntoNeunId AND AgendaId = @pe_AgendaId
			UNION ALL
			SELECT HoraID FROM AUD_AsuntosDetalleFechas WITH(NOLOCK)
			WHERE  AsuntoNeunId = @pe_AsuntoNeunId AND AgendaId = @pe_AgendaId
			UNION ALL 
			SELECT AsuntoDetalleFechasId 
			FROM AsuntosDetalleFechas A WITH(NOLOCK) 
			WHERE  A.AsuntoNeunId = @pe_AsuntoNeunId 
			AND CONVERT(DATE,FechaAlta) = CONVERT(DATE,@pe_FechaAlta)
			AND CONVERT(VARCHAR,FechaAlta,8) = @pe_HoraAlta
			AND A.TipoAsuntoId in(23903,23904)
					   			
			DECLARE @AsuntoDetalleDescripcionId INT = (SELECT AsuntoDetalleDescripcionId FROM AsuntosDetalleDescripcion 
											   WHERE AsuntoNeunId = @pe_AsuntoNeunId 
											   AND TipoAsuntoId IN(21845)
											   AND CONVERT(DATE,FechaAlta) = CONVERT(DATE,@pe_FechaAlta)
											   AND CONVERT(VARCHAR,FechaAlta,8) = @pe_HoraAlta)

			--INICIAN DELETE

			DELETE FROM AUD_AsuntosDetalleFechas
			WHERE AgendaId = @pe_AgendaId
			SET @Deleted_Rows = @@ROWCOUNT;
			
			DELETE FROM PersonasAsuntosDetalleFechas
			WHERE AsuntoNeunId = @pe_AsuntoNeunId 
		    AND AsuntoDetalleFechasId IN(SELECT id FROM #AsuntoFechasId) 
			SET @Deleted_Rows = @@ROWCOUNT;

			DELETE FROM AsuntosDetalleFechas
			WHERE AsuntoNeunId = @pe_AsuntoNeunId 
			AND AsuntoDetalleFechasId IN (SELECT id FROM #AsuntoFechasId)
			SET @Deleted_Rows = @@ROWCOUNT;

			DELETE FROM AsuntosDetalleDescripcion 
			WHERE AsuntoNeunId = @pe_AsuntoNeunId 
			AND TipoAsuntoId IN(21845)
			AND AsuntoDetalleDescripcionId = @AsuntoDetalleDescripcionId
			SET @Deleted_Rows = @@ROWCOUNT;
		
			DELETE FROM PersonasAsuntoDetalleDescripcion 
			WHERE AsuntoNeunId = @pe_AsuntoNeunId 
			AND AsuntoDetalleDescripcionId = @AsuntoDetalleDescripcionId
			SET @Deleted_Rows = @@ROWCOUNT;
		END	
	END

	 COMMIT TRAN

	 DROP TABLE #AsuntoFechasId
	 
	 SELECT @Deleted_Rows

    END TRY
    BEGIN CATCH
		ROLLBACK TRAN		
	    --DROP TABLE #AsuntoFechasId
        --EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;