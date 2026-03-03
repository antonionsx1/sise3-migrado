USE [SISE_NEW]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [SISE3].[piInsertDescripcion]
 @pi_EmpleadoId INT 
,@pi_AsuntoId INT
,@pi_AsuntoNeunId INT
,@pi_AsuntoDetalleFechas_type [AsuntoDetalleFechas_type] READONLY 
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
	
	--------------  	  
	--  TEXTO 
	--------------
	WHILE @IndexDescripcion <= @RowCountDescripcion -- SE INICIA RECORRIDO
		BEGIN
		    DECLARE @RowsAffectedD INT = 0
			DECLARE @TipoAsuntoIdD INT = 0
		    DECLARE @ContenidoD VARCHAR(MAX)
			DECLARE @RoWD INT = 0
			DECLARE @CamposComunesPD BIT
			DECLARE @RowsAffectedPD INT = 0
		    DECLARE @PersonaIdPD INT = 0
			DECLARE @RoWPD INT = 0	
			DECLARE @EsMultiple BIT = 0

			DECLARE @NoBloqueDesc INT
			

			--SE OBTIENEN VALORES POR CADA ROW 
			SELECT 
				 @RoWD = DT.RowNum
				,@TipoAsuntoIdD = DT.TipoAsuntoId
				,@ContenidoD = DT.Contenido
				,@NoCaptura = DT.NoCaptura
				,@NoBloque = DT.NoBloque
				,@NoBloquePadre = DT.NoBloquePadre
				,@CamposComunesPD = DT.CamposComunes
			FROM @DescripcionTable DT
			WHERE DT.RowNum = @IndexDescripcion
			ORDER BY DT.TipoAsuntoId ASC

			---VALIDACION PARA ELIMINACION

				DECLARE @countParams INT = (SELECT COUNT(*) FROM @DescripcionTable DTDel WHERE DTDel.TipoAsuntoId = @TipoAsuntoIdD) 
				DECLARE @countOrigen INT = (SELECT COUNT(*) FROM AsuntosDetalleDescripcion asuDel WITH(NOLOCK) WHERE asuDel.TipoAsuntoId = @TipoAsuntoIdD)
				DECLARE @ValorNoExistente INT = 0
				DECLARE @RowsDelete INT = 0

				IF(@countParams <> @countOrigen)
					BEGIN 

						SELECT @ValorNoExistente = asuDel.AsuntoDetalleDescripcionId
						FROM AsuntosDetalleDescripcion asuDel
						WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdD AND  NOT EXISTS (
										 SELECT 1
										 FROM @DescripcionTable dtDel
										 WHERE asuDel.tipoAsuntoId = dtDel.tipoAsuntoId
										 AND asuDel.NoBloque = dtDel.NoBloque
										);
						
						IF @ValorNoExistente > 0
							BEGIN

								SET @ResultadoExpediente = @ValorNoExistente
								DELETE FROM AsuntosDetalleDescripcion WHERE AsuntoNeunId = @pi_AsuntoNeunId
																	AND TipoAsuntoId = @TipoAsuntoIdD
																	AND AsuntoDetalleDescripcionId = @ValorNoExistente
																	AND StatusReg = 1
																	SET @RowsDelete = @@ROWCOUNT

								DELETE FROM PersonasAsuntoDetalleDescripcion WHERE AsuntoDetalleDescripcionId = @ValorNoExistente 
																		 AND StatusReg = 1
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
			WHERE vtaP.TipoAsuntoId = @TipoAsuntoIdD)

			 IF @EsMultiple = 1 --- SE VALIDA SI ES UN CAMPO MULTIPLE
				BEGIN
				 SET @NoBloqueDesc = (SELECT ISNULL(MAX(C.NoBloque),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdD AND C.NoBloque = @NoBloque AND C.StatusReg = 1)
				END
			 ELSE
				BEGIN
				 SET @NoBloqueDesc = (SELECT ISNULL(MAX(C.NoBloque),0) FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdD AND StatusReg = 1)
				END


			--- DECLARACION DE VARIABLES ID´S MAXIMOS
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) + 1 FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloque)
		
		
			--DECLARACION DE VARIABLES PARA CAMPOS MULTIPLES
			DECLARE @IdMultiPerDes BIGINT = (SELECT ISNULL(MAX(A.PersonaAsuntoDetalleDescripcionId),0) FROM PersonasAsuntoDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdD AND A.NoBloque = @NoBloque)) 
			DECLARE @NoCapturaMulti INT = (SELECT ISNULL(MAX(C.NoCaptura),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK) WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.TipoAsuntoId = @TipoAsuntoIdD AND C.NoBloque = @NoBloque)

			--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleDescripcion asdd WITH(NOLOCK)
				WHERE asdd.AsuntoNeunId = @pi_AsuntoNeunId
					AND asdd.TipoAsuntoId = @TipoAsuntoIdD
					AND asdd.NoBloque = @NoBloque
					AND asdd.FechaBaja IS NULL
					AND asdd.StatusReg = 1
				)
				BEGIN --UPDATE

					  UPDATE AsuntosDetalleDescripcion
						SET FechaBaja = GETDATE(),
						StatusReg = 0
					  WHERE AsuntoNeunId = @pi_AsuntoNeunId
					  AND TipoAsuntoId = @TipoAsuntoIdD
					  AND AsuntoDetalleDescripcionId =  (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) FROM AsuntosDetalleDescripcion A WITH(NOLOCK) WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdD AND A.NoBloque = @NoBloque)
					  AND NoBloque = @NoBloque
					  AND FechaBaja IS NULL
					  AND StatusReg = 1
					  AND Contenido <> @ContenidoD
					  SET @RowsAffectedD = @@ROWCOUNT;						  

					IF @RowsAffectedD > 0 --IF DE ROWS AFECTADOS EN ASUNTOSDETALLES
						BEGIN	

							INSERT INTO AsuntosDetalleDescripcion WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId,Contenido,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
							VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdD ,@ContenidoD,@NoCapturaMulti,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)								
									
							
							IF(@IdMultiPerDes > 0) ---VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS
								BEGIN 
									IF(@CamposComunesPD = 0) -- ACTUALIZACION/INSERCION CON PARTES
									BEGIN
									
										WHILE @IndexPersonas <= @RowCountPersonas
										BEGIN				
											SELECT 
												@RoWPD = PT.RowNum
												,@PersonaIdPD = PT.PersonaId
											FROM @PersonasTable PT
											WHERE PT.RowNum = @IndexPersonas
											ORDER BY PT.PersonaId ASC	
								
											UPDATE PersonasAsuntoDetalleDescripcion
											SET FechaBaja = GETDATE(),
											StatusReg = 0
											WHERE AsuntoNeunId = @pi_AsuntoNeunId									
											AND PersonaAsuntoDetalleDescripcionId = @IdMultiPerDes
											AND FechaBaja IS NULL
											AND StatusReg = 1
											AND PersonaId = @PersonaIdPD		
											AND AsuntoDetalleDescripcionId <> @IdAsuDetalles
											SET @RowsAffectedPD = @@ROWCOUNT;
								
											IF(@RowsAffectedPD > 0)
												BEGIN 
												 INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
												 VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPD)
											END
										SET @IndexPersonas = @IndexPersonas + 1;
										END	--FIN DEL WHILE
									END--FIN ACTUALIZACION/INSERCION CON PARTES
								END ---FIN VALIDA SI EXISTE REGISTRO EN PARTES Y EN ASUNTOS 
							ELSE--- NO EXISTE REGISTRO EN PARTES PERO SI EN ASUNTOS
								BEGIN
									IF(@CamposComunesPD = 0) -- INSERCION CON PARTES
									BEGIN
										WHILE @IndexPersonas <= @RowCountPersonas
										BEGIN				
											SELECT 
												@RoWPD = PT.RowNum
												,@PersonaIdPD = PT.PersonaId
											FROM @PersonasTable PT
											WHERE PT.RowNum = @IndexPersonas
											ORDER BY PT.PersonaId ASC	

											INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
											VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPD)
										SET @IndexPersonas = @IndexPersonas + 1;
										END	--FIN DE WHILE
									END -- FIN INSERCION CON PARTES
								END --FIN DE ELSE	
						END--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES								   					 				  				  				 			   									   

					END --FIN DE IF SI EXIST
					ELSE    -- SI NO EXISTE SE REALIZA INSERCION
						BEGIN
						 
						INSERT INTO AsuntosDetalleDescripcion WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId,Contenido,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdD ,@ContenidoD,@NoCaptura,@NoBloqueDesc,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)								
						
						IF(@CamposComunesPD = 0) -- INSERCION CON PARTES
						BEGIN
							WHILE @IndexPersonas <= @RowCountPersonas
								BEGIN				
								SELECT 
									@RoWPD = PT.RowNum
									,@PersonaIdPD = PT.PersonaId
								FROM @PersonasTable PT
								WHERE PT.RowNum = @IndexPersonas
								ORDER BY PT.PersonaId ASC	

								INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
								VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaIdPD)							
								SET @IndexPersonas = @IndexPersonas + 1;
							END	--FIN DEL WHILE
					   END -- FIN DE INSERCION CON PARTES

					END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION
			

		 SET @IndexDescripcion = @IndexDescripcion + 1;
	END -- FIN DE WHILE PRINCIPAL


	 
	COMMIT TRAN
	
	SELECT @ResultadoExpediente --- ES UN VALOR SOLO PARA PRUEBAS	    
			                           
    END TRY
    BEGIN CATCH
		ROLLBACK TRAN

       -- EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
END;