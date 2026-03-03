SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 23/09/2024 
-- Description: Se encarga de realizar la inserción y edición de partes para campos tipo número.	
--              Este sp es ejecutado dentro del sp [SISE3].[piUpInsertCapturaExpediente]
-- Ejemplo : EXEC [SISE3].[piUpInsertaPartesNumeros] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdN,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloque							
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsertaPartesNumeros]
@pi_PersonasAsuntosSel_type [PersonasAsuntosSel_type] READONLY 
,@pi_AsuntoNeunId INT
,@pi_AsuntoId INT
,@TipoAsuntoIdN INT
,@IdAsuDetalles INT
,@TotalPersonas INT
,@RowCountPersonas INT
,@NoBloque INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

		DECLARE @IndexPersonasNumeros INT = 1
		DECLARE @RoWN INT = 0
		DECLARE @RoWPN INT = 0	
		DECLARE @PersonaIdPN INT = 0
		DECLARE @RowsAffectedPN INT = 0

		DECLARE @PersonasTable TABLE (RowNum INT,PersonaId INT);
		
		INSERT INTO @PersonasTable
		SELECT ROW_NUMBER() OVER (ORDER BY PT.PersonaId ASC) AS RowNum
		,PT.PersonaId
		FROM @pi_PersonasAsuntosSel_type PT


		IF(@TotalPersonas = @RowCountPersonas) -- IF SI EL NUMERO DE PERSONAS ES IGUAL
		BEGIN
			DECLARE @AsuDetalleId TABLE (AsuDetalleNumerosId INT);
			DECLARE @TotalAsuDetalleId INT = 0

			INSERT INTO @AsuDetalleId
			SELECT ADN1.AsuntoDetalleNumerosId 
			FROM AsuntosDetalleNumeros ADN1 WITH(NOLOCK) 
			WHERE ADN1.AsuntosNeunId = @pi_AsuntoNeunId 
			AND ADN1.TipoAsuntoId = @TipoAsuntoIdN 
			AND ADN1.AsuntoDetalleNumerosId <> @IdAsuDetalles

			SET @TotalAsuDetalleId = (SELECT COUNT(*) AS AsuCount FROM @AsuDetalleId)
											
			IF(@TotalAsuDetalleId > 0)
			BEGIN	
				UPDATE PersonasAsuntosDetalleNumeros
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId	
				AND StatusReg = 1	
				AND AsuntoDetalleNumerosId IN (SELECT AsuDetalleNumerosId FROM @AsuDetalleId)

				UPDATE AsuntosDetalleNumeros
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntosNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdN
				AND AsuntoDetalleNumerosId IN (SELECT AsuDetalleNumerosId FROM @AsuDetalleId)
				AND StatusReg = 1	
			END

			WHILE @IndexPersonasNumeros <= @TotalPersonas
			BEGIN														
				SELECT 
				@RoWPN = PT.RowNum
				,@PersonaIdPN = PT.PersonaId
				FROM @PersonasTable PT
				WHERE PT.RowNum = @IndexPersonasNumeros
				ORDER BY PT.PersonaId ASC	

				INSERT INTO PersonasAsuntosDetalleNumeros WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleNumerosId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPN)
				SET @IndexPersonasNumeros = @IndexPersonasNumeros + 1;
			END											
		END-- IF SI EL NUMERO DE PERSONAS ES IGUAL
		ELSE -- ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
		BEGIN
			WHILE @IndexPersonasNumeros <= @RowCountPersonas
			BEGIN				
					SELECT 
					@RoWPN = PT.RowNum
					,@PersonaIdPN = PT.PersonaId
					FROM @PersonasTable PT
					WHERE PT.RowNum = @IndexPersonasNumeros
					ORDER BY PT.PersonaId ASC

					UPDATE PersonasAsuntosDetalleNumeros
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId	
					AND StatusReg = 1
					AND PersonaId = @PersonaIdPN		
					AND AsuntoDetalleNumerosId = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId)-1,0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdN AND A.NoBloque = @NoBloque)											
					SET @RowsAffectedPN = @@ROWCOUNT;	
					
					IF(@RowsAffectedPN > 0)
					BEGIN 
						INSERT INTO PersonasAsuntosDetalleNumeros WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleNumerosId,PersonaId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPN)

						UPDATE AsuntosDetalleNumeros
						SET FechaBaja = NULL,
						StatusReg = 1
						WHERE AsuntosNeunId = @pi_AsuntoNeunId
						AND TipoAsuntoId = @TipoAsuntoIdN
						AND AsuntoDetalleNumerosId =  (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId)-1,0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdN AND A.NoBloque = @NoBloque)
						AND NoBloque = @NoBloque
						AND StatusReg = 0
					END
				SET @IndexPersonasNumeros = @IndexPersonasNumeros + 1;
			END	--FIN DEL WHILE
		END-- FIN ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
	
	COMMIT TRAN		
	
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;