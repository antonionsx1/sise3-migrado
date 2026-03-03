SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 14/08/2024 
-- Description: Se realiza la inserción y edición de informacion de campos no multiples para captura expediente
			-- Se realiza la inserción, edición y eliminación de campos multiples 
-- Ejemplo : [SISE3].[piInsertarCapturaExpediente]
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsertCapturaExpediente]
 @pi_EmpleadoId INT 
,@pi_AsuntoId INT
,@pi_AsuntoNeunId INT
,@pi_AsuntoDetalleFechas_type [SISE3].[AsuntosDetalleFechas_type] READONLY 
,@pi_AsuntoDetalleDescripcion_type [SISE3].[AsuntoDetalleDescripcion_type] READONLY 
,@pi_AsuntoDetalleCatalogos_type [SISE3].[AsuntosDetalleCatalogos_type] READONLY 
,@pi_AsuntoDetalleNumeros_type [SISE3].[AsuntosDetalleNumeros_type] READONLY 
,@pi_AsuntoDetalleOpciones_type [SISE3].[AsuntosDetalleOpciones_type] READONLY 
,@pi_PersonasAsuntosSel_type [PersonasAsuntosSel_type] READONLY 
AS
BEGIN
    BEGIN TRY
		 BEGIN TRAN

	 DECLARE @ResultadoExpediente BIGINT = 0		
	
	  DECLARE @NoCaptura INT = 0
	  DECLARE @NoBloque INT = 0
	  DECLARE @NoBloquePadre INT = 0
	  DECLARE @RowConuntFechas INT = 0, @RowCountDescripcion INT = 0 ,@RowCountCatalogos INT = 0, @RowCountNumeros INT = 0, @RowCountOpciones INT = 0,@RowCountPersonas INT = 0
	  DECLARE @IndexFecha INT = 1,@IndexDescripcion INT = 1,@IndexCatalogos INT = 1,@IndexNumeros INT = 1,@IndexOpciones INT = 1
	  	  
	  SELECT @RowConuntFechas = COUNT(*) FROM @pi_AsuntoDetalleFechas_type;
	  SELECT @RowCountDescripcion = COUNT(*) FROM @pi_AsuntoDetalleDescripcion_type;
	  SELECT @RowCountCatalogos = COUNT(*) FROM @pi_AsuntoDetalleCatalogos_type;
	  SELECT @RowCountNumeros = COUNT(*) FROM @pi_AsuntoDetalleNumeros_type;
	  SELECT @RowCountOpciones = COUNT(*) FROM @pi_AsuntoDetalleOpciones_type;
	  SELECT @RowCountPersonas = COUNT(*) FROM @pi_PersonasAsuntosSel_type;
		
	  DECLARE @FechasTable TABLE (RowNum INT,TipoAsuntoId INT,ValorCampoAsunto DATETIME,NoCaptura INT, NoBloque INT, NoBloquePadre INT,CamposComunes BIT);
	  DECLARE @DescripcionTable TABLE (RowNum INT,TipoAsuntoId INT,Contenido NVARCHAR(MAX),NoCaptura INT,NoBloque INT, NoBloquePadre INT,CamposComunes BIT);
	  DECLARE @CatalogosTable TABLE (RowNum INT,TipoAsuntoId INT,NumeroCatalogo INT, CatalogoElementoId INT,NoCaptura INT,NoBloque INT,NoBloquePadre INT,CamposComunes BIT);
	  DECLARE @NumerosTable TABLE (RowNum INT,TipoAsuntoId INT,NumeroCampoAsunto INT,NoCaptura INT,NoBloque INT, NoBloquePadre INT,CamposComunes BIT);
	  DECLARE @OpcionesTable TABLE (RowNum INT,TipoAsuntoId INT,OpcionCampoAsunto BIT,NoCaptura INT,NoBloque INT, NoBloquePadre INT,CamposComunes BIT);
	  DECLARE @PersonasTable TABLE (RowNum INT,PersonaId INT);
	  DECLARE @PersonasInsTable TABLE (PersonaId BIGINT);

	  INSERT INTO @PersonasInsTable
	  SELECT PA1.PersonaId FROM PersonasAsunto PA1 WITH(NOLOCK) WHERE AsuntoNeunId =  @pi_AsuntoNeunId 

	  DECLARE @TotalPersonas INT = (SELECT COUNT(*) AS PersonasCount FROM @PersonasInsTable)

	  INSERT INTO @PersonasTable
	  SELECT ROW_NUMBER() OVER (ORDER BY PT.PersonaId ASC) AS RowNum
	  ,PT.PersonaId
	  FROM @pi_PersonasAsuntosSel_type PT

	  INSERT INTO @FechasTable
	  SELECT  ROW_NUMBER() OVER (ORDER BY F.TipoAsuntoId) AS RowNum
	  ,F.TipoAsuntoId, F.ValorCampoAsunto
	  ,F.NoCaptura, F.NoBloque
	  ,F.NoBloquePadre
	  ,CASE WHEN CP.TipoAsuntoId IS NULL THEN CASE WHEN asuMAP.TipoAsuntoId IS NULL THEN 0 ELSE 1 END ELSE 1 END CamposComunes			
	  FROM @pi_AsuntoDetalleFechas_type F 
	  INNER JOIN viTiposAsunto V ON F.TipoAsuntoId = V.TipoAsuntoId 
	  LEFT JOIN (SELECT DISTINCT mta.TipoAsuntoId FROM MapeoTiposAsunto mta WITH(NOLOCK)) asuMAP ON V.TipoAsuntoId= asuMAP.TipoAsuntoId 
	  LEFT JOIN CamposPropiedades cp WITH(NOLOCK)  ON V.TipoAsuntoId = cp.TipoAsuntoId AND cp.TipoPropiedadId=2 AND cp.StatusReg=1 
	  ORDER BY V.Orden ASC
	  
	  INSERT INTO @DescripcionTable
	  SELECT  ROW_NUMBER() OVER (ORDER BY D.TipoAsuntoId) AS RowNum
	  ,D.TipoAsuntoId
	  ,D.Contenido,D.NoCaptura
	  ,D.NoBloque
	  ,D.NoBloquePadre
	  ,CASE WHEN CP.TipoAsuntoId IS NULL THEN CASE WHEN asuMAP.TipoAsuntoId IS NULL THEN 0 ELSE 1 END ELSE 1 END CamposComunes	
	  FROM @pi_AsuntoDetalleDescripcion_type D
	  INNER JOIN viTiposAsunto V ON D.TipoAsuntoId = V.TipoAsuntoId 
	  LEFT JOIN (SELECT DISTINCT mta.TipoAsuntoId FROM MapeoTiposAsunto mta WITH(NOLOCK)) asuMAP ON V.TipoAsuntoId= asuMAP.TipoAsuntoId 
	  LEFT JOIN CamposPropiedades cp WITH(NOLOCK)  ON V.TipoAsuntoId = cp.TipoAsuntoId AND cp.TipoPropiedadId=2 AND cp.StatusReg=1 
	  ORDER BY V.Orden ASC

	  INSERT INTO @CatalogosTable
	  SELECT  ROW_NUMBER() OVER (ORDER BY C.TipoAsuntoId) AS RowNum
	  ,C.TipoAsuntoId
	  ,C.CatalogoId
	  ,C.CatalogoElementoId
	  ,C.NoCaptura
	  ,C.NoBloque
	  ,C.NoBloquePadre
	  ,CASE WHEN CP.TipoAsuntoId IS NULL THEN CASE WHEN asuMAP.TipoAsuntoId IS NULL THEN 0 ELSE 1 END ELSE 1 END CamposComunes	
	  FROM @pi_AsuntoDetalleCatalogos_type C
	  INNER JOIN viTiposAsunto V ON C.TipoAsuntoId = V.TipoAsuntoId 
	  LEFT JOIN (SELECT DISTINCT mta.TipoAsuntoId FROM MapeoTiposAsunto mta WITH(NOLOCK)) asuMAP ON V.TipoAsuntoId= asuMAP.TipoAsuntoId 
	  LEFT JOIN CamposPropiedades cp WITH(NOLOCK)  ON V.TipoAsuntoId = cp.TipoAsuntoId AND cp.TipoPropiedadId=2 AND cp.StatusReg=1 
	  ORDER BY V.Orden ASC

	  INSERT INTO @NumerosTable
	  SELECT  ROW_NUMBER() OVER (ORDER BY N.TipoAsuntoId) AS RowNum
	  ,N.TipoAsuntoId
	  ,N.NumeroCampoAsunto
	  ,N.NoCaptura
	  ,N.NoBloque
	  ,N.NoBloquePadre
	  ,CASE WHEN CP.TipoAsuntoId IS NULL THEN CASE WHEN asuMAP.TipoAsuntoId IS NULL THEN 0 ELSE 1 END ELSE 1 END CamposComunes	  
	  FROM @pi_AsuntoDetalleNumeros_type N
	  INNER JOIN viTiposAsunto V ON N.TipoAsuntoId = V.TipoAsuntoId 
	  LEFT JOIN (SELECT DISTINCT mta.TipoAsuntoId FROM MapeoTiposAsunto mta WITH(NOLOCK)) asuMAP ON V.TipoAsuntoId= asuMAP.TipoAsuntoId 
	  LEFT JOIN CamposPropiedades cp WITH(NOLOCK)  ON V.TipoAsuntoId = cp.TipoAsuntoId AND cp.TipoPropiedadId=2 AND cp.StatusReg=1 
	  ORDER BY V.Orden ASC

	  INSERT INTO @OpcionesTable
	  SELECT  ROW_NUMBER() OVER (ORDER BY O.TipoAsuntoId) AS RowNum
	  ,O.TipoAsuntoId
	  ,O.OpcionCampoAsunto
	  ,O.NoCaptura
	  ,O.NoBloque
	  ,O.NoBloquePadre
	  ,CASE WHEN CP.TipoAsuntoId IS NULL THEN CASE WHEN asuMAP.TipoAsuntoId IS NULL THEN 0 ELSE 1 END ELSE 1 END CamposComunes	 	  
	  FROM @pi_AsuntoDetalleOpciones_type O
	  INNER JOIN viTiposAsunto V ON O.TipoAsuntoId = V.TipoAsuntoId 
	  LEFT JOIN (SELECT DISTINCT mta.TipoAsuntoId FROM MapeoTiposAsunto mta WITH(NOLOCK)) asuMAP ON V.TipoAsuntoId= asuMAP.TipoAsuntoId 
	  LEFT JOIN CamposPropiedades cp WITH(NOLOCK)  ON V.TipoAsuntoId = cp.TipoAsuntoId AND cp.TipoPropiedadId=2 AND cp.StatusReg=1 
	  ORDER BY V.Orden ASC

	 DECLARE @IdAsuDetalles INT = 0
	 DECLARE @ConseAsuDetalles INT = 0	
	--------------
	 --FECHAS
	--------------	 
	 WHILE @IndexFecha <= @RowConuntFechas
		BEGIN		
			DECLARE @RowsAffected INT = 0
			DECLARE @TipoAsuntoIdF INT = 0
		    DECLARE @ValorCampoAsuntoF DATETIME = NULL;
			DECLARE @RoWF INT = 0
			DECLARE @CamposComunesF BIT
			DECLARE @NoBloqueFecha INT = 0
			DECLARE @RowsAffectedPF INT = 0
		    DECLARE @PersonaIdF INT = 0
			DECLARE @RoWPF INT = 0				
			DECLARE @EsMultipleF BIT = 0
			DECLARE @NoBloqueDescF INT
			DECLARE @IndexPersonasFechas INT = 1
			DECLARE @NoCapturaMultiFecha INT = 0
			
			SELECT 
			 @RoWF = FT.RowNum
			,@TipoAsuntoIdF = FT.TipoAsuntoId
			,@ValorCampoAsuntoF = FT.ValorCampoAsunto
			,@NoCaptura = FT.NoCaptura
			,@NoBloqueFecha = FT.NoBloque
			,@NoBloquePadre = FT.NoBloquePadre
			,@CamposComunesF = FT.CamposComunes
			FROM @FechasTable FT
			WHERE FT.RowNum = @IndexFecha
			ORDER BY FT.TipoAsuntoId ASC
			
		---VALIDACION PARA ELIMINACION
				DECLARE @countParamsF INT = (SELECT COUNT(*) FROM @FechasTable FTDel WHERE FTDel.TipoAsuntoId = @TipoAsuntoIdF) 
				DECLARE @countOrigenF INT = (SELECT COUNT(*) FROM AsuntosDetalleFechas asuDel WITH(NOLOCK) WHERE asuDel.AsuntoNeunId = @pi_AsuntoNeunId AND asuDel.TipoAsuntoId = @TipoAsuntoIdF AND asuDel.StatusReg = 1)
				DECLARE @ValorNoExistenteFecha INT = 0
				
				IF(@countParamsF < @countOrigenF)
					BEGIN 	
						SELECT @ValorNoExistenteFecha = asuDel.AsuntoDetalleFechasId
						FROM AsuntosDetalleFechas asuDel
						WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdF AND  NOT EXISTS (
										 SELECT 1
										 FROM @FechasTable ftDel
										 WHERE asuDel.tipoAsuntoId = ftDel.tipoAsuntoId
										 AND asuDel.NoBloque = ftDel.NoBloque
										);						
						IF @ValorNoExistenteFecha > 0
							BEGIN
								UPDATE AsuntosDetalleFechas
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND TipoAsuntoId = @TipoAsuntoIdF
								AND AsuntoDetalleFechasId = @ValorNoExistenteFecha 
								AND FechaBaja IS NULL
								AND StatusReg = 1

								UPDATE PersonasAsuntosDetalleFechas
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND AsuntoDetalleFechasId = @ValorNoExistenteFecha 
								AND FechaBaja IS NULL
								AND StatusReg = 1
							END
				END
			---VALIDACION PARA ELIMINACION

		   -- OBTNER EL VALOR DE LA PROPIEDAD ESMULTIPLE DEL CAMPO

		    SELECT @EsMultipleF = ta.EsMultiple
				FROM viTiposAsunto vta WITH(NOLOCK)
				JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
            WHERE vta.StatusReg = 1
			AND vta.TipoCampoId = 16
		    AND vta.TipoAsuntoId = (SELECT vtaP.Padre FROM  viTiposAsunto vtaP WITH(NOLOCK) 
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdF)

			 IF @EsMultipleF = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDescF = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdF AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDescF = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdF AND StatusReg = 1)
				END

			--- DECLARACION DE VARIABLES ID´S MAXIMOS	
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) + 1 FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloqueFecha)
		  
			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDesF BIGINT = (SELECT ISNULL(MAX(A.PersonaAsuntoDetallesFechasId),0) FROM PersonasAsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF AND A.NoBloque = @NoBloqueFecha)) 
			IF @RowCountPersonas = @TotalPersonas
				BEGIN 
					SET @NoCapturaMultiFecha = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdF AND C.NoBloque = @NoBloque)
				END
			ELSE
				BEGIN
					SET @NoCapturaMultiFecha = 1
				END 

			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleFechas adf WITH(NOLOCK)
				WHERE adf.AsuntoNeunId = @pi_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoIdF
				AND adf.NoBloque = @NoBloqueFecha
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
			 BEGIN	--UPDATE
				UPDATE AsuntosDetalleFechas
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdF
				AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF AND A.NoBloque = @NoBloqueFecha) 
				AND NoBloque = @NoBloqueFecha
				AND FechaBaja IS NULL
				AND StatusReg = 1
				AND CONVERT(VARCHAR,ValorCampoAsunto,120) <> CONVERT(VARCHAR,@ValorCampoAsuntoF,120)
				SET @RowsAffected = @@ROWCOUNT;				

				IF @RowsAffected > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
				BEGIN
					INSERT INTO AsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId ,TipoAsuntoId ,ValorCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
					VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@TipoAsuntoIdF,@ValorCampoAsuntoF,@NoCapturaMultiFecha,@NoBloqueFecha,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)	
						
						IF(@IdMultiPerDesF > 0) ---VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS
						BEGIN 
							IF(@CamposComunesF = 0) -- ACTUALIZACION/INSERCION CON PARTES
							BEGIN
							--INSERCION DE PARTES 
								EXEC [SISE3].[piUpInsertaPartesFechas] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdF,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloqueFecha		
								
							 END --FIN ACTUALIZACION/INSERCION CON PARTES
						END--FIN VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS 
						ELSE --- NO EXISTE REGISTRO EN PERSONAS DETALLES PERO SI EN ASUNTOS
						BEGIN 							
							IF(@CamposComunesF = 0) -- INSERCION CON PARTES
							BEGIN
								WHILE @IndexPersonasFechas <= @RowCountPersonas
								BEGIN				
									SELECT 
									@RoWPF = PT.RowNum
									,@PersonaIdF = PT.PersonaId
									FROM @PersonasTable PT
									WHERE PT.RowNum = @IndexPersonasFechas
									ORDER BY PT.PersonaId ASC	

									INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId,EmpleadoId)	 
									VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF,@pi_EmpleadoId)										

								SET @IndexPersonasFechas = @IndexPersonasFechas + 1;
								END	--FIN DE WHILE
							END -- FIN INSERCION CON PARTES
						END --FIN DEL ELSE

				END--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES	
			END --FIN DE IF SI EXIST
			ELSE  -- SI NO EXISTE SE REALIZA INSERCION
			BEGIN
			   
				INSERT INTO AsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId ,TipoAsuntoId ,ValorCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@TipoAsuntoIdF,@ValorCampoAsuntoF,@NoCaptura,@NoBloqueDescF,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
				
				IF(@CamposComunesF = 0) -- INSERCION CON PARTES
					BEGIN
						
						WHILE @IndexPersonasFechas <= @RowCountPersonas
							BEGIN				
							SELECT 
							@RoWPF = PT.RowNum
							,@PersonaIdF = PT.PersonaId
							FROM @PersonasTable PT
							WHERE PT.RowNum = @IndexPersonasFechas
							ORDER BY PT.PersonaId ASC	

							INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId,EmpleadoId)	 
							VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF,@pi_EmpleadoId)										
												

							SET @IndexPersonasFechas = @IndexPersonasFechas + 1;
						END	--FIN DEL WHILE
					END-- FIN DE INSERCION CON PARTES
			END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION

		 SET @IndexFecha = @IndexFecha + 1;
	END	-- FIN DE WHILE PRINCIPAL  

	
	--------------  	  
	-- TEXTO 
	--------------
	WHILE @IndexDescripcion <= @RowCountDescripcion -- SE INICIA RECORRIDO
		BEGIN
		    DECLARE @RowsAffectedD INT = 0
			DECLARE @TipoAsuntoIdD INT = 0
		    DECLARE @ContenidoD VARCHAR(MAX)
			DECLARE @RoWD INT = 0
			DECLARE @CamposComunesPD BIT
			DECLARE @NoBloqueDesc INT = 0
			DECLARE @RowsAffectedPD INT = 0
		    DECLARE @PersonaIdPD INT = 0
			DECLARE @RoWPD INT = 0	
			DECLARE @EsMultipleD BIT = 0
			DECLARE @NoBloqueDescD INT	
			DECLARE @IndexPersonasDescripcion INT = 1
			DECLARE @NoCapturaMultiD INT = 0

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
				 @RoWD = DT.RowNum
				,@TipoAsuntoIdD = DT.TipoAsuntoId
				,@ContenidoD = DT.Contenido
				,@NoCaptura = DT.NoCaptura
				,@NoBloqueDesc = DT.NoBloque
				,@NoBloquePadre = DT.NoBloquePadre
				,@CamposComunesPD = DT.CamposComunes
			FROM @DescripcionTable DT
			WHERE DT.RowNum = @IndexDescripcion
			ORDER BY DT.TipoAsuntoId ASC

			---VALIDACION PARA ELIMINACION
				DECLARE @countParamsD INT = (SELECT COUNT(*) FROM @DescripcionTable DTDel WHERE DTDel.TipoAsuntoId = @TipoAsuntoIdD) 
				DECLARE @countOrigenD INT = (SELECT COUNT(*) FROM AsuntosDetalleDescripcion asuDel WITH(NOLOCK) WHERE asuDel.AsuntoNeunId = @pi_AsuntoNeunId AND asuDel.TipoAsuntoId = @TipoAsuntoIdD AND asuDel.StatusReg = 1)
				DECLARE @ValorNoExistenteDescripcion INT = 0			

				IF(@countParamsD < @countOrigenD)
					BEGIN 

						SELECT @ValorNoExistenteDescripcion = asuDel.AsuntoDetalleDescripcionId
						FROM AsuntosDetalleDescripcion asuDel
						WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdD AND  NOT EXISTS (
										 SELECT 1
										 FROM @DescripcionTable dtDel
										 WHERE asuDel.tipoAsuntoId = dtDel.tipoAsuntoId
										 AND asuDel.NoBloque = dtDel.NoBloque
										);						
						IF @ValorNoExistenteDescripcion > 0
							BEGIN
								--SET @ResultadoExpediente = @ValorNoExistenteD
								
								UPDATE AsuntosDetalleDescripcion
								SET FechaBaja = GETDATE(),
								StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND TipoAsuntoId = @TipoAsuntoIdD
								AND AsuntoDetalleDescripcionId = @ValorNoExistenteDescripcion 
								AND FechaBaja IS NULL
								AND StatusReg = 1

								UPDATE PersonasAsuntoDetalleDescripcion
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND AsuntoDetalleDescripcionId = @ValorNoExistenteDescripcion 
								AND FechaBaja IS NULL
								AND StatusReg = 1								
								
							END
				END
			---VALIDACION PARA ELIMINACION

			-- OBTNER EL VALOR DE LA PROPIEDAD ESMULTIPLE DEL CAMPO

		    SELECT @EsMultipleD = ta.EsMultiple
				FROM viTiposAsunto vta WITH(NOLOCK)
				JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
            WHERE vta.StatusReg = 1
			AND vta.TipoCampoId = 16
		    AND vta.TipoAsuntoId = (SELECT vtaP.Padre FROM  viTiposAsunto vtaP WITH(NOLOCK) 
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdD)

			 IF @EsMultipleD = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDescD = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdD AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDescD = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdD AND StatusReg = 1)
				END

			--- DECLARACION DE VARIABLES ID´S MAXIMOS
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) + 1 FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloqueDesc)
				
			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDesD BIGINT = (SELECT ISNULL(MAX(A.PersonaAsuntoDetalleDescripcionId),0) FROM PersonasAsuntoDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdD AND A.NoBloque = @NoBloqueDesc)) 

			IF @RowCountPersonas = @TotalPersonas
				BEGIN 
					SET @NoCapturaMultiD = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdD AND C.NoBloque = @NoBloqueDesc)
				END
			ELSE
				BEGIN
					SET @NoCapturaMultiD = 1
				END 
			
			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleDescripcion asdd WITH(NOLOCK)
				WHERE asdd.AsuntoNeunId = @pi_AsuntoNeunId
					AND asdd.TipoAsuntoId = @TipoAsuntoIdD
					AND asdd.NoBloque = @NoBloqueDesc
					AND asdd.FechaBaja IS NULL
					AND asdd.StatusReg = 1
				)
				BEGIN --UPDATE
					  UPDATE AsuntosDetalleDescripcion
						SET FechaBaja = GETDATE(),
						StatusReg = 0
					  WHERE AsuntoNeunId = @pi_AsuntoNeunId
					  AND TipoAsuntoId = @TipoAsuntoIdD
					  AND AsuntoDetalleDescripcionId =  (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdD AND A.NoBloque = @NoBloqueDesc)
					  AND NoBloque = @NoBloqueDesc
					  AND FechaBaja IS NULL
					  AND StatusReg = 1
					  AND Contenido <> @ContenidoD
					  SET @RowsAffectedD = @@ROWCOUNT;						  

					IF @RowsAffectedD > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
						BEGIN
							INSERT INTO AsuntosDetalleDescripcion WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId,Contenido,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
							VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdD ,@ContenidoD,@NoCapturaMultiD,@NoBloqueDesc,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)								
																
							IF(@CamposComunesPD = 0) -- ACTUALIZACION/INSERCION CON PARTES
								BEGIN
								--INSERCION DE PARTES

									EXEC [SISE3].[piUpInsertaPartesDescripcion] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdD,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloqueDesc										

								END--FIN ACTUALIZACION/INSERCION CON PARTES
						END--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES	
					END --FIN DE IF SI EXIST
					ELSE    -- SI NO EXISTE SE REALIZA INSERCION
						BEGIN						 
						INSERT INTO AsuntosDetalleDescripcion WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId,Contenido,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdD ,@ContenidoD,@NoCaptura,@NoBloqueDescD,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)								
						
						IF(@CamposComunesPD = 0) -- INSERCION CON PARTES
						BEGIN
							WHILE @IndexPersonasDescripcion <= @RowCountPersonas
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
							END	--FIN DEL WHILE
					   END -- FIN DE INSERCION CON PARTES
					END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION
		 SET @IndexDescripcion = @IndexDescripcion + 1;
	END -- FIN DE WHILE PRINCIPAL

	
	--------------
	-- CATALOGOS
	--------------	
	WHILE @IndexCatalogos <= @RowCountCatalogos
		BEGIN
		    DECLARE @RowsAffectedC INT = 0
			DECLARE @TipoAsuntoIdC INT = 0
		    DECLARE @CatalogoElementoIdC INT = 0
			DECLARE @NumeroCatalogoC INT = 0
			DECLARE @RoWC INT = 0
			DECLARE @CamposComunesPC BIT
			DECLARE @RowsAffectedPC INT = 0
		    DECLARE @PersonaIdPC INT = 0
			DECLARE @RoWPC INT = 0	
			DECLARE @EsMultipleC BIT = 0
			DECLARE @NoBloqueDescC INT
			DECLARE @IndexPersonasCatalogos INT = 1
			DECLARE @NoCapturaMultiC INT = 0

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
			 @RoWC = CT.RowNum
			,@TipoAsuntoIdC = CT.TipoAsuntoId
			,@NumeroCatalogoC = CT.NumeroCatalogo
			,@CatalogoElementoIdC = CT.CatalogoElementoId
			,@NoCaptura = NoCaptura
			,@NoBloque = NoBloque
			,@NoBloquePadre = NoBloquePadre
			,@CamposComunesPC = CT.CamposComunes
			FROM @CatalogosTable CT
			WHERE CT.RowNum = @IndexCatalogos
			ORDER BY CT.TipoAsuntoId ASC

			---VALIDACION PARA ELIMINACION
				DECLARE @countParamsC INT = (SELECT COUNT(*) FROM @CatalogosTable CTDel WHERE CTDel.TipoAsuntoId = @TipoAsuntoIdC) 
				DECLARE @countOrigenC INT = (SELECT COUNT(*) FROM AsuntosDetalleCatalogos asuDel WITH(NOLOCK) WHERE asuDel.AsuntosNeunId = @pi_AsuntoNeunId AND asuDel.TipoAsuntoId = @TipoAsuntoIdC AND asuDel.StatusReg = 1)
				DECLARE @ValorNoExistenteCatalogos INT = 0

				IF(@countParamsC < @countOrigenC)
					BEGIN 
						SELECT @ValorNoExistenteCatalogos = asuDel.AsuntoDetalleCatalogosId
						FROM AsuntosDetalleCatalogos asuDel
						WHERE asuDel.AsuntosNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdC AND  NOT EXISTS (
										 SELECT 1
										 FROM @CatalogosTable ctDel
										 WHERE asuDel.tipoAsuntoId = ctDel.tipoAsuntoId
										 AND asuDel.NoBloque = ctDel.NoBloque
										);						
						IF @ValorNoExistenteCatalogos > 0
							BEGIN
								--SET @ResultadoExpediente = @ValorNoExistenteC
								
								UPDATE AsuntosDetalleCatalogos
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntosNeunId = @pi_AsuntoNeunId
								AND TipoAsuntoId = @TipoAsuntoIdC
								AND AsuntoDetalleCatalogosId = @ValorNoExistenteCatalogos 
								AND FechaBaja IS NULL
								AND StatusReg = 1

								UPDATE PersonasAsuntosDetalleCatalogos
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND AsuntoDetalleCatalogosId = @ValorNoExistenteCatalogos 
								AND FechaBaja IS NULL
								AND StatusReg = 1	
							END
				END
			---VALIDACION PARA ELIMINACION

			-- OBTNER EL VALOR DE LA PROPIEDAD ESMULTIPLE DEL CAMPO
		    SELECT @EsMultipleC = ta.EsMultiple
				FROM viTiposAsunto vta WITH(NOLOCK)
				JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
            WHERE vta.StatusReg = 1
			AND vta.TipoCampoId = 16
		    AND vta.TipoAsuntoId = (SELECT vtaP.Padre FROM  viTiposAsunto vtaP WITH(NOLOCK) 
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdC)

			 IF @EsMultipleC = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDescC = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleCatalogos C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdC AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDescC = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleCatalogos C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdC AND StatusReg = 1)
				END
			--- DECLARACION DE VARIABLES ID´S MAXIMOS

			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) + 1 FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleCatalogos C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloque)
			
			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDesC BIGINT = (SELECT ISNULL(MAX(A.PersonaAsuntoDetalleCatalogoId),0) FROM PersonasAsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleCatalogosId = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdC AND A.NoBloque = @NoBloque))
			IF @RowCountPersonas = @TotalPersonas
				BEGIN 
					SET @NoCapturaMultiC = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleCatalogos C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdC AND C.NoBloque = @NoBloque)
				END
			ELSE
				BEGIN
					SET @NoCapturaMultiC = 1
				END 

			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleCatalogos adc WITH(NOLOCK)
				WHERE adc.AsuntosNeunId = @pi_AsuntoNeunId
				AND adc.TipoAsuntoId = @TipoAsuntoIdC
				AND adc.NoBloque = @NoBloque
				AND adc.FechaBaja IS NULL
				AND adc.StatusReg = 1				
				)
			 BEGIN --UPDATE
				UPDATE AsuntosDetalleCatalogos
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntosNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdC
				AND AsuntoDetalleCatalogosId =  (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) FROM AsuntosDetalleCatalogos A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdC AND A.NoBloque = @NoBloque)		
				AND NoBloque = @NoBloque
				AND FechaBaja IS NULL
				AND StatusReg = 1
				AND CatTipoCatalogoAsuntoId <> @CatalogoElementoIdC
				SET @RowsAffectedC = @@ROWCOUNT;	

				IF @RowsAffectedC > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
				BEGIN	
					INSERT INTO AsuntosDetalleCatalogos WITH (ROWLOCK)(AsuntosNeunId ,AsuntoId ,AsuntoDetalleCatalogosId ,TipoAsuntoId ,CatTipoCatalogoAsuntoId, CatCatalogoAsuntoId ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
					VALUES (@pi_AsuntoNeunId,@pi_AsuntoId, @IdAsuDetalles, @TipoAsuntoIdC,@CatalogoElementoIdC,@NumeroCatalogoC, @NoCapturaMultiC,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
			
					IF(@IdMultiPerDesC > 0)  ---VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS
					BEGIN
						IF(@CamposComunesPC = 0) -- ACTUALIZACION/INSERCION CON PARTES
							BEGIN
							--INSERCION CON PARTES
							EXEC [SISE3].[piUpInsertaPartesCatalogos] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdC,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloque

							
						END --FIN ACTUALIZACION/INSERCION CON PARTES
					END---FIN VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS 
					ELSE--- NO EXISTE REGISTRO EN PARTES PERO SI EN ASUNTOS
					BEGIN
						IF(@CamposComunesPC = 0) -- INSERCION CON PARTES
						BEGIN
							WHILE @IndexPersonasCatalogos <= @RowCountPersonas
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
							END	--FIN DE WHILE
						END ---- FIN INSERCION CON PARTES
					END --FIN DE ELSE					
				END	--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES			
			END--FIN DE IF SI EXIST
			ELSE -- SI NO EXISTE SE REALIZA INSERCION
			BEGIN
				INSERT INTO AsuntosDetalleCatalogos WITH (ROWLOCK)(AsuntosNeunId ,AsuntoId ,AsuntoDetalleCatalogosId ,TipoAsuntoId ,CatTipoCatalogoAsuntoId, CatCatalogoAsuntoId ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
			    VALUES (@pi_AsuntoNeunId,@pi_AsuntoId, @IdAsuDetalles, @TipoAsuntoIdC,@CatalogoElementoIdC,@NumeroCatalogoC, @NoCaptura,@NoBloqueDescC,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
			
				IF(@CamposComunesPC = 0) -- INSERCION CON PARTES
					BEGIN
						WHILE @IndexPersonasCatalogos <= @RowCountPersonas
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
						END	--FIN DEL WHILE
					END --FIN
			END-- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION
		 SET @IndexCatalogos = @IndexCatalogos + 1;
	END-- FIN DE WHILE PRINCIPAL

	-----------------
	--NUMEROS
	-----------------
	 WHILE @IndexNumeros <= @RowCountNumeros
		BEGIN
		    DECLARE @RowsAffectedN INT = 0
			DECLARE @TipoAsuntoIdN INT = 0
		    DECLARE @NumeroCampoAsuntoN INT = 0
			DECLARE @RoWN INT = 0
			DECLARE @CamposComunesPN BIT
			DECLARE @RowsAffectedPN INT = 0
		    DECLARE @PersonaIdPN INT = 0
			DECLARE @RoWPN INT = 0					
			DECLARE @EsMultipleN BIT = 0
			DECLARE @NoBloqueDescN INT
			DECLARE @IndexPersonasNumeros INT = 1
			DECLARE @NoCapturaMultiN INT = 0

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
			 @RoWN = NT.RowNum
			,@TipoAsuntoIdN = NT.TipoAsuntoId
			,@NumeroCampoAsuntoN = NT.NumeroCampoAsunto
			,@NoCaptura = NoCaptura
			,@NoBloque = NoBloque
			,@NoBloquePadre = NoBloquePadre
			,@CamposComunesPN = NT.CamposComunes
			FROM @NumerosTable NT
			WHERE NT.RowNum = @IndexNumeros
			ORDER BY NT.TipoAsuntoId ASC
			
			---VALIDACION PARA ELIMINACION
				DECLARE @countParamsN INT = (SELECT COUNT(*) FROM @NumerosTable DTDel WHERE DTDel.TipoAsuntoId = @TipoAsuntoIdN) 
				DECLARE @countOrigenN INT = (SELECT COUNT(*) FROM AsuntosDetalleNumeros asuDel WITH(NOLOCK) WHERE asuDel.AsuntosNeunId = @pi_AsuntoNeunId AND asuDel.TipoAsuntoId = @TipoAsuntoIdN AND asuDel.StatusReg = 1)
				DECLARE @ValorNoExistenteNumeros INT = 0

				IF(@countParamsN < @countOrigenN)
					BEGIN 

						SELECT @ValorNoExistenteNumeros = asuDel.AsuntoDetalleNumerosId
						FROM AsuntosDetalleNumeros asuDel
						WHERE asuDel.AsuntosNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdN AND  NOT EXISTS (
										 SELECT 1
										 FROM @NumerosTable dtDel
										 WHERE asuDel.tipoAsuntoId = dtDel.tipoAsuntoId
										 AND asuDel.NoBloque = dtDel.NoBloque
										);						
						IF @ValorNoExistenteNumeros > 0
							BEGIN
								UPDATE AsuntosDetalleNumeros
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntosNeunId = @pi_AsuntoNeunId
								AND TipoAsuntoId = @TipoAsuntoIdN
								AND AsuntoDetalleNumerosId = @ValorNoExistenteNumeros 
								AND FechaBaja IS NULL
								AND StatusReg = 1
								
								UPDATE PersonasAsuntosDetalleNumeros
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND AsuntoDetalleNumerosId = @ValorNoExistenteNumeros 
								AND FechaBaja IS NULL
								AND StatusReg = 1								
							END
				END
			---VALIDACION PARA ELIMINACION
								   			 		  		  		 	   			
			-- OBTNER EL VALOR DE LA PROPIEDAD ESMULTIPLE DEL CAMPO
			 SELECT @EsMultipleN = ta.EsMultiple
				FROM viTiposAsunto vta WITH(NOLOCK)
				JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
            WHERE vta.StatusReg = 1
			AND vta.TipoCampoId = 16
		    AND vta.TipoAsuntoId = (SELECT vtaP.Padre FROM  viTiposAsunto vtaP WITH(NOLOCK) 
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdN)

			 IF @EsMultipleN = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDescN = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleNumeros C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdN AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDescN = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleNumeros C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdN AND StatusReg = 1)
				END
			--- DECLARACION DE VARIABLES ID´S MAXIMOS

			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) + 1 FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleNumeros C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloque)
			
			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDesN BIGINT = (SELECT ISNULL(MAX(A.PersonaAsuntoDetalleNumerosId),0) FROM PersonasAsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleNumerosId = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdN AND A.NoBloque = @NoBloque)) 
			IF @RowCountPersonas = @TotalPersonas
				BEGIN 
					SET @NoCapturaMultiN = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleNumeros C WITH(NOLOCK) WHERE C.AsuntosNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdN AND C.NoBloque = @NoBloque)
				END
			ELSE
				BEGIN
					SET @NoCapturaMultiN = 1
				END 

			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleNumeros adn WITH(NOLOCK)
				WHERE adn.AsuntosNeunId = @pi_AsuntoNeunId
				AND adn.TipoAsuntoId = @TipoAsuntoIdN
				AND adn.NoBloque = @NoBloque
				AND adn.FechaBaja IS NULL
				AND adn.StatusReg = 1
				)
			 BEGIN --UPDATE
				UPDATE AsuntosDetalleNumeros
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntosNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdN
				AND AsuntoDetalleNumerosId =  (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdN AND A.NoBloque = @NoBloque)		
				AND NoBloque = @NoBloque
				AND StatusReg = 1
				AND NumeroCampoAsunto <> @NumeroCampoAsuntoN
				SET @RowsAffectedN = @@ROWCOUNT;	

				IF @RowsAffectedN > 0--IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
				BEGIN	
					INSERT INTO AsuntosDetalleNumeros WITH (ROWLOCK)(AsuntosNeunId ,AsuntoId ,AsuntoDetalleNumerosId ,TipoAsuntoId ,NumeroCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
			        VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdN ,@NumeroCampoAsuntoN, @NoCapturaMultiN,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
					
					IF(@IdMultiPerDesN > 0)---VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS
					BEGIN
					IF(@CamposComunesPN = 0) -- ACTUALIZACION/INSERCION CON PARTES
						BEGIN
							--INSERCION/EDICION DE PARTES
							EXEC [SISE3].[piUpInsertaPartesNumeros] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdN,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloque	
													   
						END ----FIN ACTUALIZACION/INSERCION CON PARTES
					END ---FIN VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS 
					ELSE--- NO EXISTE REGISTRO EN PARTES PERO SI EN ASUNTOS
					BEGIN
						IF(@CamposComunesPN = 0) -- INSERCION CON PARTES
						BEGIN
							WHILE @IndexPersonasNumeros <= @RowCountPersonas
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
							END	--FIN DE WHILE
						END -- FIN INSERCION CON PARTES
					END --FIN DEL ELSE
				END	--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES						
			END--FIN DE IF SI EXIST
			ELSE  -- SI NO EXISTE SE REALIZA INSERCION
			BEGIN
				INSERT INTO AsuntosDetalleNumeros WITH (ROWLOCK)(AsuntosNeunId ,AsuntoId ,AsuntoDetalleNumerosId ,TipoAsuntoId ,NumeroCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
			    VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdN ,@NumeroCampoAsuntoN, @NoCaptura,@NoBloqueDescN,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)

				IF(@CamposComunesPN = 0) -- INSERCION CON PARTES
					BEGIN
						WHILE @IndexPersonasNumeros <= @RowCountPersonas
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
						END	--FIN DEL WHILE
					END -- FIN DE INSERCION CON PARTES
			END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION
		 SET @IndexNumeros = @IndexNumeros + 1;
	END -- FIN DE WHILE PRINCIPAL		
	

	-----------------
	--OPCIONES
	-----------------
	  WHILE @IndexOpciones <= @RowCountOpciones
		BEGIN
		    DECLARE @RowsAffectedO INT = 0
			DECLARE @TipoAsuntoIdO INT = 0
		    DECLARE @OpcionCampoAsunto BIT = NULL
			DECLARE @RoWO INT = 0
			DECLARE @CamposComunesPO BIT
			DECLARE @RowsAffectedPO INT = 0
		    DECLARE @PersonaIdPO INT = 0
			DECLARE @RoWPO INT = 0	
			DECLARE @EsMultipleO BIT = 0
			DECLARE @NoBloqueDescO INT
			DECLARE @IndexPersonasOpciones INT = 1
			DECLARE @NoCapturaMultiO INT

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
			 @RoWO = OT.RowNum	 
			,@TipoAsuntoIdO = OT.TipoAsuntoId
			,@OpcionCampoAsunto = OT.OpcionCampoAsunto 		
			,@NoCaptura = NoCaptura
			,@NoBloque = NoBloque
			,@NoBloquePadre = NoBloquePadre
			,@CamposComunesPO = OT.CamposComunes
			FROM @OpcionesTable OT
			WHERE OT.RowNum = @IndexOpciones
			ORDER BY OT.TipoAsuntoId ASC
			
			---VALIDACION PARA ELIMINACION
				DECLARE @countParams INT = (SELECT COUNT(*) FROM @OpcionesTable DTDel WHERE DTDel.TipoAsuntoId = @TipoAsuntoIdO) 
				DECLARE @countOrigen INT = (SELECT COUNT(*) FROM AsuntosDetalleOpciones asuDel WITH(NOLOCK) WHERE asuDel.AsuntoNeunId = @pi_AsuntoNeunId AND asuDel.TipoAsuntoId = @TipoAsuntoIdO AND asuDel.StatusReg = 1)
				DECLARE @ValorNoExistenteOpciones INT = 0

				IF(@countParams < @countOrigen)
					BEGIN 
						SELECT @ValorNoExistenteOpciones = asuDel.AsuntoDetalleOpcionesId
						FROM AsuntosDetalleOpciones asuDel
						WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdO AND  NOT EXISTS (
										 SELECT 1
										 FROM @OpcionesTable dtDel
										 WHERE asuDel.tipoAsuntoId = dtDel.tipoAsuntoId
										 AND asuDel.NoBloque = dtDel.NoBloque
										);						
						IF @ValorNoExistenteOpciones > 0
							BEGIN
								--SET @ResultadoExpediente = @ValorNoExistente
								UPDATE AsuntosDetalleOpciones
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND TipoAsuntoId = @TipoAsuntoIdO
								AND AsuntoDetalleOpcionesId = @ValorNoExistenteOpciones 
								AND FechaBaja IS NULL
								AND StatusReg = 1

								UPDATE PersonasAsuntosDetalleOpciones
								SET FechaBaja = GETDATE(), StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND AsuntoDetalleOpcionesId = @ValorNoExistenteOpciones 
								AND FechaBaja IS NULL
								AND StatusReg = 1								
							END
				END
			---VALIDACION PARA ELIMINACION
			
			-- OBTNER EL VALOR DE LA PROPIEDAD ESMULTIPLE DEL CAMPO
		    SELECT @EsMultipleO = ta.EsMultiple
				FROM viTiposAsunto vta WITH(NOLOCK)
				JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
            WHERE vta.StatusReg = 1
			AND vta.TipoCampoId = 16
		    AND vta.TipoAsuntoId = (SELECT vtaP.Padre FROM  viTiposAsunto vtaP WITH(NOLOCK) 
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdO)

			 IF @EsMultipleO = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDescO = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleOpciones C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdO AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDescO = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleOpciones C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdO AND StatusReg = 1)
				END
			--- DECLARACION DE VARIABLES ID´S MAXIMOS
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) + 1 FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleOpciones C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloque)
						
			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDesO BIGINT  = (SELECT ISNULL(MAX(A.PersonaAsuntoDetalleOpcionesId),0) FROM PersonasAsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleOpcionesId = (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdO AND A.NoBloque = @NoBloque))
			
			IF @RowCountPersonas = @TotalPersonas
				BEGIN 
					SET @NoCapturaMultiO = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleOpciones C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdO AND C.NoBloque = @NoBloque)
				END
			ELSE
				BEGIN
					SET @NoCapturaMultiO = 1
				END 

			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (	SELECT 1 FROM AsuntosDetalleOpciones WITH(NOLOCK)
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdO
				AND NoBloque = @NoBloque
				AND FechaBaja IS NULL
				AND StatusReg = 1
				)
			 BEGIN --UPDATE
				UPDATE AsuntosDetalleOpciones
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdO
				AND AsuntoDetalleOpcionesId =  (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) FROM AsuntosDetalleOpciones A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdO AND A.NoBloque = @NoBloque)		
				AND NoBloque = @NoBloque
				AND FechaBaja IS NULL
				AND StatusReg = 1
				AND OpcionCampoAsunto <> @OpcionCampoAsunto
				SET @RowsAffectedO = @@ROWCOUNT;

				IF @RowsAffectedO > 0--IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
				BEGIN	
					INSERT INTO AsuntosDetalleOpciones WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId ,TipoAsuntoId ,OpcionCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
			        VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdO ,@OpcionCampoAsunto, @NoCapturaMultiO,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)	
					
					IF(@IdMultiPerDesO > 0)---VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS
					BEGIN
						IF(@CamposComunesPO = 0) -- ACTUALIZACION/INSERCION CON PARTES
						BEGIN
						--INSERCION/EDICION PARTES
							EXEC [SISE3].[piUpInsertaPartesOpciones] @pi_PersonasAsuntosSel_type,@pi_AsuntoNeunId,@pi_AsuntoId,@TipoAsuntoIdO,@IdAsuDetalles,@TotalPersonas,@RowCountPersonas,@NoBloque
														
						END --FIN ACTUALIZACION/INSERCION CON PARTES
					END---FIN VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS 
					ELSE--- NO EXISTE REGISTRO EN PARTES PERO SI EN ASUNTOS
					BEGIN
						IF(@CamposComunesPO = 0) -- INSERCION CON PARTES
						BEGIN
							WHILE @IndexPersonasOpciones <= @RowCountPersonas
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
							END	--FIN DE WHILE
						END-- FIN INSERCION CON PARTES				
					END--FIN DEL ELSE				
				END	--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES	
			END--FIN DE IF SI EXIST
			ELSE  -- SI NO EXISTE SE REALIZA INSERCION
			BEGIN
				INSERT INTO AsuntosDetalleOpciones WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId ,TipoAsuntoId ,OpcionCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
			    VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdO ,@OpcionCampoAsunto, @NoCaptura,@NoBloqueDescO,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
			
				IF(@CamposComunesPO = 0) -- INSERCION CON PARTES
					BEGIN
						WHILE @IndexPersonasOpciones <= @RowCountPersonas
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
						END	--FIN DEL WHILE
					END-- FIN DE INSERCION CON PARTES
			END-- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION
		 SET @IndexOpciones = @IndexOpciones + 1;
	END	-- FIN DE WHILE PRINCIPAL
	 
	COMMIT TRAN
	
	SELECT @ResultadoExpediente --- ES UN VALOR SOLO PARA PRUEBAS	    
			                           
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;