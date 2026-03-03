SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 20/09/2024 
-- Description: Se encarga de realizar la inserción y edición de partes para campos tipo texto.	
--              Este sp es ejecutado dentro del sp [SISE3].[piUpInsertCapturaExpediente]
-- Ejemplo : EXEC [SISE3].[piUpInsertaPartesDescripcion] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdD,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloqueDesc										
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsertaPartesDescripcion]
@pi_PersonasAsuntosSel_type [PersonasAsuntosSel_type] READONLY 
,@pi_AsuntoNeunId INT
,@pi_AsuntoId INT
,@TipoAsuntoIdD INT
,@IdAsuDetalles INT
,@TotalPersonas INT
,@RowCountPersonas INT
,@NoBloqueDesc INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

		DECLARE @IndexPersonasDescripcion INT = 1
		DECLARE @RoWD INT = 0
		DECLARE @RoWPD INT = 0	
		DECLARE @PersonaIdPD INT = 0
		DECLARE @RowsAffectedPD INT = 0

		DECLARE @PersonasTable TABLE (RowNum INT,PersonaId INT);
		
		INSERT INTO @PersonasTable
		SELECT ROW_NUMBER() OVER (ORDER BY PT.PersonaId ASC) AS RowNum
		,PT.PersonaId
		FROM @pi_PersonasAsuntosSel_type PT


		IF(@TotalPersonas = @RowCountPersonas) -- IF SI EL NUMERO DE PERSONAS ES IGUAL
		BEGIN
			DECLARE @AsuDetalleId TABLE (AsuDetalleDescripcionId INT);
			DECLARE @TotalAsuDetalleId INT = 0

			INSERT INTO @AsuDetalleId
			SELECT ADD1.AsuntoDetalleDescripcionId 
			FROM AsuntosDetalleDescripcion ADD1 WITH(NOLOCK) 
			WHERE ADD1.AsuntoNeunId = @pi_AsuntoNeunId 
			AND ADD1.TipoAsuntoId = @TipoAsuntoIdD 
			AND ADD1.AsuntoDetalleDescripcionId <> @IdAsuDetalles

			SET @TotalAsuDetalleId = (SELECT COUNT(*) AS AsuCount FROM @AsuDetalleId)
											
			IF(@TotalAsuDetalleId > 0)
			BEGIN	
				UPDATE PersonasAsuntoDetalleDescripcion
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId	
				AND StatusReg = 1	
				AND AsuntoDetalleDescripcionId IN (SELECT AsuDetalleDescripcionId FROM @AsuDetalleId)

				UPDATE AsuntosDetalleDescripcion
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdD
				AND AsuntoDetalleDescripcionId IN (SELECT AsuDetalleDescripcionId FROM @AsuDetalleId)
				AND StatusReg = 1	
			END
			WHILE @IndexPersonasDescripcion <= @TotalPersonas
			BEGIN														
				SELECT 
				@RoWPD = PT.RowNum
				,@PersonaIdPD = PT.PersonaId
				FROM @PersonasTable PT
				WHERE PT.RowNum = @IndexPersonasDescripcion
				ORDER BY PT.PersonaId ASC	

				INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPD)
				SET @IndexPersonasDescripcion = @IndexPersonasDescripcion + 1;
			END											
		END-- IF SI EL NUMERO DE PERSONAS ES IGUAL
		ELSE -- ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
		BEGIN
			WHILE @IndexPersonasDescripcion <= @RowCountPersonas
			BEGIN				
					SELECT 
					@RoWPD = PT.RowNum
					,@PersonaIdPD = PT.PersonaId
					FROM @PersonasTable PT
					WHERE PT.RowNum = @IndexPersonasDescripcion
					ORDER BY PT.PersonaId ASC

					UPDATE PersonasAsuntoDetalleDescripcion
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId	
					AND StatusReg = 1
					AND PersonaId = @PersonaIdPD		
					AND AsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId)-1,0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdD AND A.NoBloque = @NoBloqueDesc)											
					SET @RowsAffectedPD = @@ROWCOUNT;	
					
					IF(@RowsAffectedPD > 0)
					BEGIN 
						INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPD)

						UPDATE AsuntosDetalleDescripcion
						SET FechaBaja = NULL,
						StatusReg = 1
						WHERE AsuntoNeunId = @pi_AsuntoNeunId
						AND TipoAsuntoId = @TipoAsuntoIdD
						AND AsuntoDetalleDescripcionId =  (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId)-1,0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdD AND A.NoBloque = @NoBloqueDesc)
						AND NoBloque = @NoBloqueDesc
						AND StatusReg = 0
					END
				SET @IndexPersonasDescripcion = @IndexPersonasDescripcion + 1;
			END	--FIN DEL WHILE
		END-- FIN ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
	
	COMMIT TRAN		
	
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;