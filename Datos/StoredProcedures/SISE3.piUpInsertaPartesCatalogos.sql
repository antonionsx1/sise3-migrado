SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 23/09/2024 
-- Description: Se encarga de realizar la inserción y edición de partes para campos tipo catalogo.	
--              Este sp es ejecutado dentro del sp [SISE3].[piUpInsertCapturaExpediente]
-- Ejemplo : EXEC [SISE3].[piUpInsertaPartesCatalogos] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@@TipoAsuntoIdC,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloque						
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsertaPartesCatalogos]
@pi_PersonasAsuntosSel_type [PersonasAsuntosSel_type] READONLY 
,@pi_AsuntoNeunId INT
,@pi_AsuntoId INT
,@TipoAsuntoIdC INT
,@IdAsuDetalles INT
,@TotalPersonas INT
,@RowCountPersonas INT
,@NoBloque INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

		DECLARE @IndexPersonasCatalogos INT = 1
		DECLARE @RoWC INT = 0
		DECLARE @RoWPC INT = 0	
		DECLARE @PersonaIdPC INT = 0
		DECLARE @RowsAffectedPF INT = 0

		DECLARE @PersonasTable TABLE (RowNum INT,PersonaId INT);
		
		INSERT INTO @PersonasTable
		SELECT ROW_NUMBER() OVER (ORDER BY PT.PersonaId ASC) AS RowNum
		,PT.PersonaId
		FROM @pi_PersonasAsuntosSel_type PT


		IF(@TotalPersonas = @RowCountPersonas) -- IF SI EL NUMERO DE PERSONAS ES IGUAL
		BEGIN
			DECLARE @AsuDetalleId TABLE (AsuDetalleCatalogosId INT);
			DECLARE @TotalAsuDetalleId INT = 0

			INSERT INTO @AsuDetalleId
			SELECT ADC1.AsuntoDetalleCatalogosId 
			FROM AsuntosDetalleCatalogos ADC1 WITH(NOLOCK) 
			WHERE ADC1.AsuntosNeunId = @pi_AsuntoNeunId 
			AND ADC1.TipoAsuntoId = @TipoAsuntoIdC 
			AND ADC1.AsuntoDetalleCatalogosId <> @IdAsuDetalles

			SET @TotalAsuDetalleId = (SELECT COUNT(*) AS AsuCount FROM @AsuDetalleId)
											
			IF(@TotalAsuDetalleId > 0)
			BEGIN	
				UPDATE PersonasAsuntosDetalleCatalogos
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId	
				AND StatusReg = 1	
				AND AsuntoDetalleCatalogosId IN (SELECT AsuDetalleCatalogosId FROM @AsuDetalleId)

				UPDATE AsuntosDetalleCatalogos
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntosNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdC
				AND AsuntoDetalleCatalogosId IN (SELECT AsuDetalleCatalogosId FROM @AsuDetalleId)
				AND StatusReg = 1	
			END
			WHILE @IndexPersonasCatalogos <= @TotalPersonas
			BEGIN														
				SELECT 
				@RoWPC = PT.RowNum
				,@PersonaIdPC = PT.PersonaId
				FROM @PersonasTable PT
				WHERE PT.RowNum = @IndexPersonasCatalogos
				ORDER BY PT.PersonaId ASC	

				INSERT INTO PersonasAsuntosDetalleCatalogos WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleCatalogosId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPC)
				SET @IndexPersonasCatalogos = @IndexPersonasCatalogos + 1;
			END											
		END-- IF SI EL NUMERO DE PERSONAS ES IGUAL
		ELSE -- ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
		BEGIN
			WHILE @IndexPersonasCatalogos <= @RowCountPersonas
			BEGIN				
					SELECT 
					@RoWPC = PT.RowNum
					,@PersonaIdPC = PT.PersonaId
					FROM @PersonasTable PT
					WHERE PT.RowNum = @IndexPersonasCatalogos
					ORDER BY PT.PersonaId ASC

					UPDATE PersonasAsuntosDetalleCatalogos
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId	
					AND StatusReg = 1
					AND PersonaId = @PersonaIdPC		
					AND AsuntoDetalleCatalogosId = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId)-1,0) FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdC AND A.NoBloque = @NoBloque)											
					SET @RowsAffectedPF = @@ROWCOUNT;	
					
					IF(@RowsAffectedPF > 0)
					BEGIN 
						INSERT INTO PersonasAsuntosDetalleCatalogos WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleCatalogosId,PersonaId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPC)

						UPDATE AsuntosDetalleCatalogos
						SET FechaBaja = NULL,
						StatusReg = 1
						WHERE AsuntosNeunId = @pi_AsuntoNeunId
						AND TipoAsuntoId = @TipoAsuntoIdC
						AND AsuntoDetalleCatalogosId =  (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId)-1,0) FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdC AND A.NoBloque = @NoBloque)
						AND NoBloque = @NoBloque
						AND StatusReg = 0
					END
				SET @IndexPersonasCatalogos = @IndexPersonasCatalogos + 1;
			END	--FIN DEL WHILE
		END-- FIN ELSE SI EL NUMERO DE PERSONAS NO ES IGUAL
	
	COMMIT TRAN		
	
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;