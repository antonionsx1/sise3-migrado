SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 23/09/2024 
-- Description: Se encarga de realizar la inserción y edición de partes para campos tipo fecha.	
--              Este sp es ejecutado dentro del sp [SISE3].[piUpInsertCapturaExpediente]
-- Ejemplo : EXEC [SISE3].[piUpInsertaPartesFechas] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdF,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloqueFecha							
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsertaPartesFechas]
@pi_PersonasAsuntosSel_type [PersonasAsuntosSel_type] READONLY 
,@pi_AsuntoNeunId INT
,@pi_AsuntoId INT
,@TipoAsuntoIdF INT
,@IdAsuDetalles INT
,@TotalPersonas INT
,@RowCountPersonas INT
,@NoBloqueFecha INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

		DECLARE @IndexPersonasFechas INT = 1
		DECLARE @RoWF INT = 0
		DECLARE @RoWPF INT = 0	
		DECLARE @PersonaIdF INT = 0
		DECLARE @RowsAffectedPF INT = 0

		DECLARE @PersonasTable TABLE (RowNum INT,PersonaId INT);
		
		INSERT INTO @PersonasTable
		SELECT ROW_NUMBER() OVER (ORDER BY PT.PersonaId ASC) AS RowNum
		,PT.PersonaId
		FROM @pi_PersonasAsuntosSel_type PT


		IF(@TotalPersonas = @RowCountPersonas) -- IF SI EL NUMERO DE PERSONAS ES IGUAL
		BEGIN
			DECLARE @AsuDetalleId TABLE (AsuDetalleFechaId INT);
			DECLARE @TotalAsuDetalleId INT = 0

			INSERT INTO @AsuDetalleId
			SELECT ADF1.AsuntoDetalleFechasId 
			FROM AsuntosDetalleFechas ADF1 WITH(NOLOCK) 
			WHERE ADF1.AsuntoNeunId = @pi_AsuntoNeunId 
			AND ADF1.TipoAsuntoId = @TipoAsuntoIdF 
			AND ADF1.AsuntoDetalleFechasId <> @IdAsuDetalles

			SET @TotalAsuDetalleId = (SELECT COUNT(*) AS AsuCount FROM @AsuDetalleId)
											
			IF(@TotalAsuDetalleId > 0)
			BEGIN	
				UPDATE PersonasAsuntosDetalleFechas
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId	
				AND StatusReg = 1	
				AND AsuntoDetalleFechasId IN (SELECT AsuDetalleFechaId FROM @AsuDetalleId)

				UPDATE AsuntosDetalleFechas
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdF
				AND AsuntoDetalleFechasId IN (SELECT AsuDetalleFechaId FROM @AsuDetalleId)
				AND StatusReg = 1	
			END
			WHILE @IndexPersonasFechas <= @TotalPersonas
			BEGIN														
				SELECT 
				@RoWPF = PT.RowNum
				,@PersonaIdF = PT.PersonaId
				FROM @PersonasTable PT
				WHERE PT.RowNum = @IndexPersonasFechas
				ORDER BY PT.PersonaId ASC	

				INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF)
				SET @IndexPersonasFechas = @IndexPersonasFechas + 1;
			END											
		END-- IF SI EL NUMERO DE PERSONAS ES IGUAL
		ELSE -- ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
		BEGIN
			WHILE @IndexPersonasFechas <= @RowCountPersonas
			BEGIN				
					SELECT 
					@RoWPF = PT.RowNum
					,@PersonaIdF = PT.PersonaId
					FROM @PersonasTable PT
					WHERE PT.RowNum = @IndexPersonasFechas
					ORDER BY PT.PersonaId ASC

					UPDATE PersonasAsuntosDetalleFechas
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId	
					AND StatusReg = 1
					AND PersonaId = @PersonaIdF		
					AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId)-1,0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF AND A.NoBloque = @NoBloqueFecha)											
					SET @RowsAffectedPF = @@ROWCOUNT;	
					
					IF(@RowsAffectedPF > 0)
					BEGIN 
						INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF)

						UPDATE AsuntosDetalleFechas
						SET FechaBaja = NULL,
						StatusReg = 1
						WHERE AsuntoNeunId = @pi_AsuntoNeunId
						AND TipoAsuntoId = @TipoAsuntoIdF
						AND AsuntoDetalleFechasId =  (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId)-1,0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF AND A.NoBloque = @NoBloqueFecha)
						AND NoBloque = @NoBloqueFecha
						AND StatusReg = 0
					END
				SET @IndexPersonasFechas = @IndexPersonasFechas + 1;
			END	--FIN DEL WHILE
		END-- FIN ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
	
	COMMIT TRAN		
	
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;