SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Anabel Gonzalez Ayala 
-- Create date: 17/12/2024
-- Description: Realiza la baja de los campos que tienen valores vaciós por medio de un update en CapturaExpediente
-- ================================
CREATE PROCEDURE [SISE3].[paTipoAsuntoSIdVaciosUpd]
@pa_AsuntoNeunId INT
,@pa_TipoAsuntosIdVacios_type [SISE3].[TipoAsuntosIdVacios_type] READONLY 
AS
BEGIN
    BEGIN TRY
		 BEGIN TRAN

			DECLARE @ResultadoExpediente BIGINT = 0				
			DECLARE @RowConuntCamposVacios INT = 0
			DECLARE @IndexCamposFechas INT = 1,@IndexCamposTexto INT = 1,@IndexCamposCatalogos INT = 1,@IndexCamposNumeros INT = 1,@IndexCamposOpciones INT = 1
			
			SELECT @RowConuntCamposVacios = COUNT(*) FROM @pa_TipoAsuntosIdVacios_type;				
	
			DECLARE @CamposIdUpdTable TABLE (RowNum INT, TipoAsuntoId INT, NoBloque INT);
	
			INSERT INTO @CamposIdUpdTable
			SELECT  ROW_NUMBER() OVER (ORDER BY asuId.TipoAsuntoId) AS RowNum
			,asuId.TipoAsuntoId	
			,asuId.NoBloque
			FROM @pa_TipoAsuntosIdVacios_type asuId
			ORDER BY asuId.TipoAsuntoId ASC

	--------------
	 --FECHAS
	--------------	 
	 WHILE @IndexCamposFechas <= @RowConuntCamposVacios
		BEGIN		
			DECLARE @RowsAffected INT = 0
			DECLARE @TipoAsuntoId INT = 0
			DECLARE @RoWAsuId INT = 0
			DECLARE @NoBloqueFecha INT = 0
			
			SELECT 
			 @RoWAsuId = camposId.RowNum
			,@TipoAsuntoId = camposId.TipoAsuntoId
			,@NoBloqueFecha = camposId.NoBloque
			FROM @CamposIdUpdTable camposId
			WHERE camposId.RowNum = @IndexCamposFechas
			ORDER BY camposId.TipoAsuntoId ASC		       

			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleFechas adf WITH(NOLOCK)
				WHERE adf.AsuntoNeunId = @pa_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoId
				AND adf.NoBloque = @NoBloqueFecha
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
				BEGIN				
					UPDATE AsuntosDetalleFechas
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoId
					AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoId AND A.NoBloque = @NoBloqueFecha) 
					AND NoBloque = @NoBloqueFecha
					AND StatusReg = 1
					SET @RowsAffected = @@ROWCOUNT;				

					IF @RowsAffected > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
					BEGIN
						UPDATE PersonasAsuntosDetalleFechas
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pa_AsuntoNeunId
						AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoId AND A.NoBloque = @NoBloqueFecha) 
						AND StatusReg = 1	
					END
				END	

		 SET @IndexCamposFechas = @IndexCamposFechas + 1;
	END	-- FIN DE WHILE PRINCIPAL  

	--------------  	  
	-- TEXTO 
	--------------
	WHILE @IndexCamposTexto <= @RowConuntCamposVacios -- SE INICIA RECORRIDO
		BEGIN
		    DECLARE @RowsAffectedTexto INT = 0
			DECLARE @TipoAsuntoIdTexto INT = 0
			DECLARE @RoWTexto INT = 0
			DECLARE @NoBloqueTexto INT = 0
			
			--SE OBTIENEN VALORES POR CADA ROW 	
			SELECT 
			 @RoWTexto = camposId.RowNum
			,@TipoAsuntoIdTexto = camposId.TipoAsuntoId
			,@NoBloqueTexto = camposId.NoBloque
			FROM @CamposIdUpdTable camposId
			WHERE camposId.RowNum = @IndexCamposTexto
			ORDER BY camposId.TipoAsuntoId ASC
			
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleDescripcion adf WITH(NOLOCK)
				WHERE adf.AsuntoNeunId = @pa_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoIdTexto
				AND adf.NoBloque = @NoBloqueTexto
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
				BEGIN	
				    
					UPDATE AsuntosDetalleDescripcion
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdTexto
					AND AsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdTexto AND A.NoBloque = @NoBloqueTexto) 
					AND NoBloque = @NoBloqueTexto
					AND StatusReg = 1
					SET @RowsAffectedTexto = @@ROWCOUNT;				

					IF @RowsAffectedTexto > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
					BEGIN
						SET @ResultadoExpediente = 10
						UPDATE PersonasAsuntoDetalleDescripcion
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pa_AsuntoNeunId
						AND AsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdTexto AND A.NoBloque = @NoBloqueTexto) 
						AND StatusReg = 1	
					END
			END	
		 SET @IndexCamposTexto = @IndexCamposTexto + 1;
	END -- FIN DE WHILE PRINCIPAL

	
	--------------
	-- CATALOGOS
	--------------	
	WHILE @IndexCamposCatalogos <= @RowConuntCamposVacios
		BEGIN
		    DECLARE @RowsAffectedCatalogos INT = 0
			DECLARE @TipoAsuntoIdCatalogo INT = 0
			DECLARE @RoWCatalogo INT = 0
			DECLARE @NoBloqueCatalogo INT

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
			 @RoWCatalogo = camposId.RowNum
			,@TipoAsuntoIdCatalogo = camposId.TipoAsuntoId
			,@NoBloqueCatalogo = camposId.NoBloque
			FROM @CamposIdUpdTable camposId
			WHERE camposId.RowNum = @IndexCamposCatalogos
			ORDER BY camposId.TipoAsuntoId ASC

			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleCatalogos adf WITH(NOLOCK)
				WHERE adf.AsuntosNeunId = @pa_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoIdCatalogo
				AND adf.NoBloque = @NoBloqueCatalogo
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
				BEGIN
					UPDATE AsuntosDetalleCatalogos
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntosNeunId = @pa_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdCatalogo
					AND AsuntoDetalleCatalogosId = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdCatalogo AND A.NoBloque = @NoBloqueCatalogo) 
					AND NoBloque = @NoBloqueCatalogo
					AND StatusReg = 1
					SET @RowsAffectedCatalogos = @@ROWCOUNT;				

					IF @RowsAffectedCatalogos > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
					BEGIN
						UPDATE PersonasAsuntosDetalleCatalogos
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pa_AsuntoNeunId
						AND AsuntoDetalleCatalogosId = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdCatalogo AND A.NoBloque = @NoBloqueCatalogo) 
						AND StatusReg = 1	
					END
			END	
		 SET @IndexCamposCatalogos = @IndexCamposCatalogos + 1;
	END-- FIN DE WHILE PRINCIPAL

	-----------------
	--NUMEROS
	-----------------
	 WHILE @IndexCamposNumeros <= @RowConuntCamposVacios
		BEGIN
		    DECLARE @RowsAffectedNumero INT = 0
			DECLARE @TipoAsuntoIdNumero INT = 0
			DECLARE @RoWNumero INT = 0
			DECLARE @RowsAffectedNumeros INT = 0
			DECLARE @NoBloqueNumero INT

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
			 @RoWNumero = camposId.RowNum
			,@TipoAsuntoIdNumero = camposId.TipoAsuntoId
			,@NoBloqueNumero = camposId.NoBloque
			FROM @CamposIdUpdTable camposId
			WHERE camposId.RowNum = @IndexCamposNumeros
			ORDER BY camposId.TipoAsuntoId ASC
					   
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleNumeros adf WITH(NOLOCK)
				WHERE adf.AsuntosNeunId = @pa_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoIdNumero
				AND adf.NoBloque = @NoBloqueNumero
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
				BEGIN
					UPDATE AsuntosDetalleNumeros
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntosNeunId = @pa_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdNumero
					AND AsuntoDetalleNumerosId = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdNumero AND A.NoBloque = @NoBloqueNumero) 
					AND NoBloque = @NoBloqueNumero
					AND StatusReg = 1
					SET @RowsAffectedNumero = @@ROWCOUNT;				

					IF @RowsAffectedNumero > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
					BEGIN
						UPDATE PersonasAsuntosDetalleNumeros
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pa_AsuntoNeunId
						AND AsuntoDetalleNumerosId = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdNumero AND A.NoBloque = @NoBloqueNumero) 
						AND StatusReg = 1	
					END
			END	

		 SET @IndexCamposNumeros = @IndexCamposNumeros + 1;
	END -- FIN DE WHILE PRINCIPAL		
	

	-----------------
	--OPCIONES
	-----------------
	  WHILE @IndexCamposOpciones <= @RowConuntCamposVacios
		BEGIN
		    DECLARE @RowsAffectedOpciones INT = 0
			DECLARE @TipoAsuntoIdOpciones INT = 0
			DECLARE @RoWOpciones INT = 0
			DECLARE @NoBloqueOpciones INT

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
			 @RoWOpciones = camposId.RowNum
			,@TipoAsuntoIdOpciones = camposId.TipoAsuntoId
			,@NoBloqueOpciones = camposId.NoBloque
			FROM @CamposIdUpdTable camposId
			WHERE camposId.RowNum = @IndexCamposOpciones
			ORDER BY camposId.TipoAsuntoId ASC
			
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleOpciones adf WITH(NOLOCK)
				WHERE adf.AsuntoNeunId = @pa_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoIdOpciones
				AND adf.NoBloque = @NoBloqueOpciones
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
				BEGIN
					UPDATE AsuntosDetalleOpciones
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdOpciones
					AND AsuntoDetalleOpcionesId = (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdOpciones AND A.NoBloque = @NoBloqueOpciones) 
					AND NoBloque = @NoBloqueOpciones
					AND StatusReg = 1
					SET @RowsAffectedOpciones = @@ROWCOUNT;				

					IF @RowsAffectedOpciones > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
					BEGIN
						UPDATE PersonasAsuntosDetalleOpciones
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pa_AsuntoNeunId
						AND AsuntoDetalleOpcionesId = (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pa_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdOpciones AND A.NoBloque = @NoBloqueOpciones) 
						AND StatusReg = 1	
					END
			END	
		 SET @IndexCamposOpciones = @IndexCamposOpciones + 1;
	END	-- FIN DE WHILE PRINCIPAL 	

	COMMIT TRAN
	
	SELECT @ResultadoExpediente --- ES UN VALOR SOLO PARA PRUEBAS	    
			                           
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;