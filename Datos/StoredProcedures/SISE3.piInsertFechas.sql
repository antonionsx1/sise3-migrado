USE [SISE_NEW]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [SISE3].[piInsertFechas]
 @pi_EmpleadoId INT 
,@pi_AsuntoId INT
,@pi_AsuntoNeunId INT
,@pi_AsuntoDetalleFechas_type [SISE3].[AsuntosDetalleFechas_type] READONLY 
,@pi_AsuntoDetalleDescripcion_type [SISE3].[AsuntoDetalleDescripcion_type] READONLY 
,@pi_AsuntoDetalleCatalogos_type [AsuntoDetalleCatalogos_type] READONLY 
,@pi_AsuntoDetalleNumeros_type [AsuntoDetalleNumeros_type] READONLY 
,@pi_AsuntoDetalleOpciones_type [AsuntoDetalleOpciones_type] READONLY 
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
	  DECLARE @IndexFecha INT = 1,@IndexDescripcion INT = 1,@IndexCatalogos INT = 1,@IndexNumeros INT = 1,@IndexOpciones INT = 1, @IndexPersonas INT = 1
	  
	  
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
	

	 --FECHAS	
	 WHILE @IndexFecha <= @RowConuntFechas
		BEGIN		
			DECLARE @RowsAffected INT = 0
			DECLARE @TipoAsuntoIdF INT = 0
		    DECLARE @ValorCampoAsuntoF DATETIME = NULL;
			DECLARE @RoWF INT = 0
			DECLARE @CamposComunesF BIT
			DECLARE @RowsAffectedPF INT = 0
		    DECLARE @PersonaIdF INT = 0
			DECLARE @RoWPF INT = 0	
			
			DECLARE @EsMultiple BIT = 0

			DECLARE @NoBloqueDesc INT
			
			SELECT 
			 @RoWF = FT.RowNum
			,@TipoAsuntoIdF = FT.TipoAsuntoId
			,@ValorCampoAsuntoF = FT.ValorCampoAsunto
			,@NoCaptura = FT.NoCaptura
			,@NoBloque = FT.NoBloque
			,@NoBloquePadre = FT.NoBloquePadre
			,@CamposComunesF = FT.CamposComunes
			FROM @FechasTable FT
			WHERE FT.RowNum = @IndexFecha
			ORDER BY FT.TipoAsuntoId ASC		
			
			---VALIDACION PARA ELIMINACION

				DECLARE @countParams INT = (SELECT COUNT(*) FROM @FechasTable FTDel WHERE FTDel.TipoAsuntoId = @TipoAsuntoIdF) 
				DECLARE @countOrigen INT = (SELECT COUNT(*) FROM AsuntosDetalleFechas asuDel WITH(NOLOCK) WHERE asuDel.TipoAsuntoId = @TipoAsuntoIdF)
				DECLARE @ValorNoExistente INT = 0
				DECLARE @RowsDelete INT = 0

				IF(@countParams <> @countOrigen)
					BEGIN 

						SELECT @ValorNoExistente = asuDel.AsuntoDetalleFechasId
						FROM AsuntosDetalleFechas asuDel
						WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdF AND  NOT EXISTS (
										 SELECT 1
										 FROM @FechasTable ftDel
										 WHERE asuDel.tipoAsuntoId = ftDel.tipoAsuntoId
										 AND asuDel.NoBloque = ftDel.NoBloque
										);
						
						IF @ValorNoExistente > 0
							BEGIN

								SET @ResultadoExpediente = @ValorNoExistente
								--DELETE FROM AsuntosDetalleFechas WHERE AsuntoNeunId = @pi_AsuntoNeunId
								--									AND TipoAsuntoId = @TipoAsuntoIdF
								--									AND AsuntoDetalleFechasId = @ValorNoExistente
								--									AND StatusReg = 1
								--									SET @RowsDelete = @@ROWCOUNT

								--DELETE FROM PersonasAsuntosDetalleFechas WHERE AsuntoDetalleFechasId = @ValorNoExistente 
								--										 AND StatusReg = 1
							END


					--SET @ResultadoExpediente = 23
				END

			---VALIDACION PARA ELIMINACION


		   -- OBTNER EL VALOR DE LA PROPIEDAD ESMULTIPLE DEL CAMPO

		    SELECT @EsMultiple = ta.EsMultiple
				FROM viTiposAsunto vta WITH(NOLOCK)
				JOIN TiposAsunto ta WITH(NOLOCK) ON ta.TipoAsuntoId = vta.TipoAsuntoId
            WHERE vta.StatusReg = 1
			AND vta.TipoCampoId = 16
		    AND vta.TipoAsuntoId = (SELECT vtaP.Padre FROM  viTiposAsunto vtaP WITH(NOLOCK) 
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdF)

			 IF @EsMultiple = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDesc = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdF AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDesc = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdF AND StatusReg = 1)
				END

			--- DECLARACION DE VARIABLES ID´S MAXIMOS	
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) + 1 FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloque)
		    DECLARE @IdPersonasDetalles BIGINT  = (SELECT ISNULL(MAX(A.PersonaAsuntoDetallesFechasId),0) FROM PersonasAsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF)) 

			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDes BIGINT = (SELECT ISNULL(MAX(A.PersonaAsuntoDetallesFechasId),0) FROM PersonasAsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF AND A.NoBloque = @NoBloque)) 
			DECLARE @NoCapturaMulti INT = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdF AND C.NoBloque = @NoBloque)

			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE

			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleFechas adf WITH(NOLOCK)
				WHERE adf.AsuntoNeunId = @pi_AsuntoNeunId
				AND adf.TipoAsuntoId = @TipoAsuntoIdF
				AND adf.NoBloque = @NoBloque
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
			 BEGIN	--UPDATE		 			 		 
				UPDATE AsuntosDetalleFechas
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdF
				AND AsuntoDetalleFechasId = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdF AND A.NoBloque = @NoBloque) 
				AND NoBloque = @NoBloque
				AND FechaBaja IS NULL
				AND StatusReg = 1
				AND CONVERT(DATE,ValorCampoAsunto) <> CONVERT(DATE,@ValorCampoAsuntoF)
				SET @RowsAffected = @@ROWCOUNT;				

				IF @RowsAffected > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
				BEGIN	

					INSERT INTO AsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId ,TipoAsuntoId ,ValorCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
					VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@TipoAsuntoIdF,@ValorCampoAsuntoF,@NoCapturaMulti,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)	
						
						IF(@IdMultiPerDes > 0) ---VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS
						BEGIN 
							IF(@CamposComunesF = 0) -- ACTUALIZACION/INSERCION CON PARTES
							BEGIN
								WHILE @IndexPersonas <= @RowCountPersonas
								BEGIN				
									SELECT 
										 @RoWPF = PT.RowNum
										,@PersonaIdF = PT.PersonaId
									FROM @PersonasTable PT
									WHERE PT.RowNum = @IndexPersonas
									ORDER BY PT.PersonaId ASC	
									
									UPDATE PersonasAsuntosDetalleFechas
									SET FechaBaja = GETDATE(),
									StatusReg = 0
									WHERE AsuntoNeunId = @pi_AsuntoNeunId									
									AND PersonaAsuntoDetallesFechasId = @IdMultiPerDes
									AND FechaBaja IS NULL
									AND StatusReg = 1
									AND PersonaId = @PersonaIdF		
									AND AsuntoDetalleFechasId <> @IdAsuDetalles
									SET @RowsAffectedPF = @@ROWCOUNT;

									IF(@RowsAffectedPF > 0)
									BEGIN 
										 INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId,EmpleadoId)	 
										 VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF,@pi_EmpleadoId)
									END
								SET @IndexPersonas = @IndexPersonas + 1;
								END	--FIN DEL WHILE
							 END --FIN ACTUALIZACION/INSERCION CON PARTES
						END--FIN VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS 
						ELSE --- NO EXISTE REGISTRO EN PERSONAS DETALLES PERO SI EN ASUNTOS
						BEGIN 							
							IF(@CamposComunesF = 0) -- INSERCION CON PARTES
							BEGIN
								WHILE @IndexPersonas <= @RowCountPersonas
								BEGIN				
									SELECT 
									@RoWPF = PT.RowNum
									,@PersonaIdF = PT.PersonaId
									FROM @PersonasTable PT
									WHERE PT.RowNum = @IndexPersonas
									ORDER BY PT.PersonaId ASC	

									INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId,EmpleadoId)	 
									VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF,@pi_EmpleadoId)										

								SET @IndexPersonas = @IndexPersonas + 1;
								END	--FIN DE WHILE
							END -- FIN INSERCION CON PARTES
						END --FIN DEL ELSE

				END--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES	
			END --FIN DE IF SI EXIST
			ELSE  -- SI NO EXISTE SE REALIZA INSERCION
			BEGIN

			SET @ResultadoExpediente = @NoBloqueDesc
				INSERT INTO AsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId ,TipoAsuntoId ,ValorCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@TipoAsuntoIdF,@ValorCampoAsuntoF,@NoCaptura,@NoBloqueDesc,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
				
				IF(@CamposComunesF = 0) -- INSERCION CON PARTES
					BEGIN
						WHILE @IndexPersonas <= @RowCountPersonas
							BEGIN				
							SELECT 
							@RoWPF = PT.RowNum
							,@PersonaIdF = PT.PersonaId
							FROM @PersonasTable PT
							WHERE PT.RowNum = @IndexPersonas
							ORDER BY PT.PersonaId ASC	

							INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId,EmpleadoId)	 
							VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdF,@pi_EmpleadoId)										

							SET @IndexPersonas = @IndexPersonas + 1;
						END	--FIN DEL WHILE
					END-- FIN DE INSERCION CON PARTES
			END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION

		 SET @IndexFecha = @IndexFecha + 1;
	END	-- FIN DE WHILE PRINCIPAL	   

	
	COMMIT TRAN
	
	SELECT @ResultadoExpediente --- ES UN VALOR SOLO PARA PRUEBAS	    
			                           
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;