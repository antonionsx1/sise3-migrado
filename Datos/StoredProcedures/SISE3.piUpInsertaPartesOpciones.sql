SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 23/09/2024 
-- Description: Se encarga de realizar la inserción y edición de partes para campos tipo opción.	
--              Este sp es ejecutado dentro del sp [SISE3].[piUpInsertCapturaExpediente]
-- Ejemplo : EXEC [SISE3].[piUpInsertaPartesOpciones] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdO,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloque							
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsertaPartesOpciones]
@pi_PersonasAsuntosSel_type [PersonasAsuntosSel_type] READONLY 
,@pi_AsuntoNeunId INT
,@pi_AsuntoId INT
,@TipoAsuntoIdO INT
,@IdAsuDetalles INT
,@TotalPersonas INT
,@RowCountPersonas INT
,@NoBloque INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

		DECLARE @IndexPersonasOpciones INT = 1
		DECLARE @RoWO INT = 0
		DECLARE @RoWPO INT = 0	
		DECLARE @PersonaIdPO INT = 0
		DECLARE @RowsAffectedPO INT = 0

		DECLARE @PersonasTable TABLE (RowNum INT,PersonaId INT);
		
		INSERT INTO @PersonasTable
		SELECT ROW_NUMBER() OVER (ORDER BY PT.PersonaId ASC) AS RowNum
		,PT.PersonaId
		FROM @pi_PersonasAsuntosSel_type PT


		IF(@TotalPersonas = @RowCountPersonas) -- IF SI EL NUMERO DE PERSONAS ES IGUAL
		BEGIN
			DECLARE @AsuDetalleId TABLE (AsuDetalleOpcionesId INT);
			DECLARE @TotalAsuDetalleId INT = 0

			INSERT INTO @AsuDetalleId
			SELECT ADO1.AsuntoDetalleOpcionesId 
			FROM AsuntosDetalleOpciones ADO1 WITH(NOLOCK) 
			WHERE ADO1.AsuntoNeunId = @pi_AsuntoNeunId 
			AND ADO1.TipoAsuntoId = @TipoAsuntoIdO
			AND ADO1.AsuntoDetalleOpcionesId <> @IdAsuDetalles

			SET @TotalAsuDetalleId = (SELECT COUNT(*) AS AsuCount FROM @AsuDetalleId)
											
			IF(@TotalAsuDetalleId > 0)
			BEGIN	
				UPDATE PersonasAsuntosDetalleOpciones
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId	
				AND StatusReg = 1	
				AND AsuntoDetalleOpcionesId IN (SELECT AsuDetalleOpcionesId FROM @AsuDetalleId)

				UPDATE AsuntosDetalleOpciones
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdO
				AND AsuntoDetalleOpcionesId IN (SELECT AsuDetalleOpcionesId FROM @AsuDetalleId)
				AND StatusReg = 1	
			END
			WHILE @IndexPersonasOpciones <= @TotalPersonas
			BEGIN														
				SELECT 
				@RoWPO = PT.RowNum
				,@PersonaIdPO = PT.PersonaId
				FROM @PersonasTable PT
				WHERE PT.RowNum = @IndexPersonasOpciones
				ORDER BY PT.PersonaId ASC	

				INSERT INTO PersonasAsuntosDetalleOpciones WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPO)
				SET @IndexPersonasOpciones = @IndexPersonasOpciones + 1;
			END											
		END-- IF SI EL NUMERO DE PERSONAS ES IGUAL
		ELSE -- ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
		BEGIN
			WHILE @IndexPersonasOpciones <= @RowCountPersonas
			BEGIN				
					SELECT 
					@RoWPO = PT.RowNum
					,@PersonaIdPO = PT.PersonaId
					FROM @PersonasTable PT
					WHERE PT.RowNum = @IndexPersonasOpciones
					ORDER BY PT.PersonaId ASC

					UPDATE PersonasAsuntosDetalleOpciones
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId	
					AND StatusReg = 1
					AND PersonaId = @PersonaIdPO		
					AND AsuntoDetalleOpcionesId = (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId)-1,0) FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdO AND A.NoBloque = @NoBloque)											
					SET @RowsAffectedPO = @@ROWCOUNT;	
					
					IF(@RowsAffectedPO > 0)
					BEGIN 
						INSERT INTO PersonasAsuntosDetalleOpciones WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId,PersonaId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPO)

						UPDATE AsuntosDetalleOpciones
						SET FechaBaja = NULL,
						StatusReg = 1
						WHERE AsuntoNeunId = @pi_AsuntoNeunId
						AND TipoAsuntoId = @TipoAsuntoIdO
						AND AsuntoDetalleOpcionesId =  (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId)-1,0) FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdO AND A.NoBloque = @NoBloque)
						AND NoBloque = @NoBloque
						AND StatusReg = 0
					END
				SET @IndexPersonasOpciones = @IndexPersonasOpciones + 1;
			END	--FIN DEL WHILE
		END-- FIN ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
	
	COMMIT TRAN		
	
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;