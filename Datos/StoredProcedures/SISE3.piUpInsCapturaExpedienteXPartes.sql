SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 03/12/2024 
-- Description: Se realiza la inserción y edición de informacion de campos delitos, objetos y pruebas
-- Ejemplo : [SISE3].[piInsertarCapturaExpediente]
-- ============================================= 
ALTER PROCEDURE [SISE3].[piUpInsCapturaExpedienteXPartes]
 @pi_EmpleadoId INT 
,@pi_AsuntoId INT
,@pi_AsuntoNeunId INT
,@pi_EsDelito BIT
,@pi_EsEliminacion BIT
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

	 DECLARE @ResultadoExpediente BIGINT = 7		
	
	  DECLARE @NoCaptura INT = 0
	  DECLARE @NoBloque INT = 0
	  DECLARE @NoBloquePadre INT = 0
	  DECLARE @RowConuntFechas INT = 0, @RowCountDescripcion INT = 0 ,@RowCountCatalogos INT = 0, @RowCountNumeros INT = 0, @RowCountOpciones INT = 0,@RowCountPersonas INT = 0
	  DECLARE @IndexFecha INT = 1, @IndexDescripcion INT = 1,@IndexCatalogos INT = 1,@IndexNumeros INT = 1,@IndexOpciones INT = 1
	  	  
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
	  ,F.TipoAsuntoId
	  ,F.ValorCampoAsunto
	  ,F.NoCaptura
	  ,F.NoBloque
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
			DECLARE @PersonaFecha INT = 0
			
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

		  IF(@pi_EsEliminacion = 1)
			 BEGIN 
				DECLARE @EliminarFechaId INT = 0
				SELECT @EliminarFechaId = asuDel.AsuntoDetalleFechasId
						FROM AsuntosDetalleFechas asuDel
						INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON asuDel.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId											
						WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
						AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
						AND asuDel.StatusReg = 1
						AND asuDel.TipoAsuntoId = @TipoAsuntoIdF 

	            IF @EliminarFechaId > 0
					BEGIN
						UPDATE AsuntosDetalleFechas
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pi_AsuntoNeunId
						AND TipoAsuntoId = @TipoAsuntoIdF
						AND AsuntoDetalleFechasId = @EliminarFechaId 
						AND FechaBaja IS NULL
						AND StatusReg = 1

						UPDATE PersonasAsuntosDetalleFechas
						SET FechaBaja = GETDATE(), StatusReg = 0
						WHERE AsuntoNeunId = @pi_AsuntoNeunId
						AND AsuntoDetalleFechasId = @EliminarFechaId 
						AND FechaBaja IS NULL
						AND StatusReg = 1
					END

			 END
			 ELSE
			 BEGIN			

		   	--- DECLARACION DE VARIABLES ID´S MAXIMOS	
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) + 1 
											    FROM AsuntosDetalleFechas A WITH(NOLOCK) 							   
											    WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 

			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleFechas C WITH(NOLOCK) 
									  INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON C.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId
									  WHERE C.AsuntoNeunId = @pi_AsuntoNeunId 
									  AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
									  AND C.NoBloque = @NoBloqueFecha
									  AND C.StatusReg =  1)

			SET @PersonaFecha = (SELECT PersonaId FROM @PersonasTable)
		  
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
				INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON adf.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId										
				WHERE adf.AsuntoNeunId = @pi_AsuntoNeunId
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND adf.TipoAsuntoId = @TipoAsuntoIdF
				AND adf.NoBloque = @NoBloqueFecha
				AND adf.FechaBaja IS NULL
				AND adf.StatusReg = 1
				)
			 BEGIN	--UPDATE					
				DECLARE @FechaIdAsuntos INT = (SELECT ISNULL(MAX(A.AsuntoDetalleFechasId),0) FROM AsuntosDetalleFechas A WITH(NOLOCK)
											 INNER JOIN PersonasAsuntosDetalleFechas perDetalle WITH(NOLOCK) ON A.AsuntoDetalleFechasId = perDetalle.AsuntoDetalleFechasId								
							  				 WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  
											 AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
											 AND A.TipoAsuntoId = @TipoAsuntoIdF 
											 AND A.NoBloque = @NoBloqueFecha
											 AND A.StatusReg = 1) 

				UPDATE AsuntosDetalleFechas
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdF
				AND AsuntoDetalleFechasId = @FechaIdAsuntos
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

								UPDATE PersonasAsuntosDetalleFechas
								SET FechaBaja = GETDATE(),
								StatusReg = 0
								WHERE AsuntoNeunId = @pi_AsuntoNeunId	
								AND StatusReg = 1
								AND PersonaId = @PersonaFecha		
								AND AsuntoDetalleFechasId = @FechaIdAsuntos
								SET @RowsAffectedPF = @@ROWCOUNT;	

								IF(@RowsAffectedPF > 0)
								BEGIN 				
								    INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId)	 
									VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaFecha)
								END

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
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@TipoAsuntoIdF,@ValorCampoAsuntoF,@NoCaptura,@NoBloqueFecha,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
				
				INSERT INTO PersonasAsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId,PersonaId,EmpleadoId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaFecha,@pi_EmpleadoId)					
			END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION
		  END---FIN VALIDACION ELSE PARA ELIMINACION
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
			DECLARE @PersonaTexto INT = 0

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
			IF(@pi_EsEliminacion = 1)
			BEGIN 
				DECLARE @EliminarDescripcion INT = 0

				SELECT @EliminarDescripcion = asuDel.AsuntoDetalleDescripcionId
				FROM AsuntosDetalleDescripcion asuDel
				INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON asuDel.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId	
				WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND asuDel.StatusReg = 1
				AND asuDel.TipoAsuntoId = @TipoAsuntoIdD 

				IF @EliminarDescripcion > 0
					BEGIN
					UPDATE AsuntosDetalleDescripcion
					SET FechaBaja = GETDATE(),
					StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdD
					AND AsuntoDetalleDescripcionId = @EliminarDescripcion 
					AND FechaBaja IS NULL
					AND StatusReg = 1

					UPDATE PersonasAsuntoDetalleDescripcion
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND AsuntoDetalleDescripcionId = @EliminarDescripcion 
					AND FechaBaja IS NULL
					AND StatusReg = 1	
				END
			END
			ELSE
			BEGIN	
			--- DECLARACION DE VARIABLES ID´S MAXIMOS
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) + 1 
											    FROM AsuntosDetalleDescripcion A WITH(NOLOCK) 							   
											    WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 

			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleDescripcion C WITH(NOLOCK)
									INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON C.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId
									WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloqueDesc
									AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
									AND C.StatusReg = 1)
				
			 SET @PersonaTexto = (SELECT PersonaId FROM @PersonasTable)

	    	--SE VALIDA SI EL DATO A EDITAR O AGREGAR EXISTE
			IF EXISTS (
				SELECT 1 FROM AsuntosDetalleDescripcion asdd WITH(NOLOCK)
				INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON asdd.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId											
				WHERE asdd.AsuntoNeunId = @pi_AsuntoNeunId
					AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
					AND asdd.TipoAsuntoId = @TipoAsuntoIdD
					AND asdd.NoBloque = @NoBloqueDesc
					AND asdd.FechaBaja IS NULL
					AND asdd.StatusReg = 1
				)
				BEGIN --UPDATE

				DECLARE @TextoIdAsuntos INT = (SELECT ISNULL(MAX(A.AsuntoDetalleDescripcionId),0) 
														 FROM AsuntosDetalleDescripcion A WITH(NOLOCK) 
														 INNER JOIN PersonasAsuntoDetalleDescripcion perDetalle WITH(NOLOCK) ON A.AsuntoDetalleDescripcionId = perDetalle.AsuntoDetalleDescripcionId										
														 WHERE A.AsuntoNeunId = @pi_AsuntoNeunId  
														 AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
														 AND A.TipoAsuntoId = @TipoAsuntoIdD 
														 AND A.NoBloque = @NoBloqueDesc
														 AND A.StatusReg = 1)
					  UPDATE AsuntosDetalleDescripcion
						SET FechaBaja = GETDATE(),
						StatusReg = 0
					  WHERE AsuntoNeunId = @pi_AsuntoNeunId
					  AND TipoAsuntoId = @TipoAsuntoIdD
					  AND AsuntoDetalleDescripcionId =  @TextoIdAsuntos
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
									UPDATE PersonasAsuntoDetalleDescripcion
									SET FechaBaja = GETDATE(),
									StatusReg = 0
									WHERE AsuntoNeunId = @pi_AsuntoNeunId	
									AND StatusReg = 1
									AND PersonaId = @PersonaTexto		
									AND AsuntoDetalleDescripcionId = @TextoIdAsuntos										
									SET @RowsAffectedPD = @@ROWCOUNT;
									
									IF(@RowsAffectedPD > 0)
									BEGIN 	
										INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
										VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaTexto)
									END
								END--FIN ACTUALIZACION/INSERCION CON PARTES
						END--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES	
					END --FIN DE IF SI EXIST
					ELSE    -- SI NO EXISTE SE REALIZA INSERCION
						BEGIN

						INSERT INTO AsuntosDetalleDescripcion WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId,Contenido,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,EmpleadoId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdD ,@ContenidoD,@NoCaptura,@NoBloqueDesc,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)								
						
						INSERT INTO PersonasAsuntoDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId,PersonaId)	 
						VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaTexto)	

					END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION

		    END ---FIN VALIDACION ELSE PARA ELIMINACION
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
			DECLARE @PersonaCatalogo INT = 0

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

			IF(@pi_EsEliminacion = 1)
			BEGIN
				DECLARE @EliminarCatalogoId INT = 0

				SELECT @EliminarCatalogoId = asuDel.AsuntoDetalleCatalogosId
				FROM AsuntosDetalleCatalogos asuDel
				INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON asuDel.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId
				WHERE asuDel.AsuntosNeunId =  @pi_AsuntoNeunId 
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND asuDel.StatusReg = 1
				AND asuDel.TipoAsuntoId = @TipoAsuntoIdC

				IF(@EliminarCatalogoId > 0)
				BEGIN
					UPDATE AsuntosDetalleCatalogos
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntosNeunId = @pi_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdC
					AND AsuntoDetalleCatalogosId = @EliminarCatalogoId 
					AND FechaBaja IS NULL
					AND StatusReg = 1

					UPDATE PersonasAsuntosDetalleCatalogos
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND AsuntoDetalleCatalogosId = @EliminarCatalogoId 
					AND FechaBaja IS NULL
					AND StatusReg = 1
				END
			END
			ELSE
			BEGIN
			
			--- DECLARACION DE VARIABLES ID´S MAXIMOS

			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) + 1 
								   FROM AsuntosDetalleCatalogos A WITH(NOLOCK) 
									WHERE A.AsuntosNeunId = @pi_AsuntoNeunId) 

			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleCatalogos C WITH(NOLOCK)
									  INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON C.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId
									  WHERE C.AsuntosNeunId = @pi_AsuntoNeunId
									  AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
									  AND C.NoBloque = @NoBloque
									  AND C.StatusReg = 1)
			
			SET @PersonaCatalogo = (SELECT PersonaId FROM @PersonasTable)

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
				INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON adc.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId		
				WHERE adc.AsuntosNeunId = @pi_AsuntoNeunId
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND adc.TipoAsuntoId = @TipoAsuntoIdC
				AND adc.NoBloque = @NoBloque
				AND adc.FechaBaja IS NULL
				AND adc.StatusReg = 1				
				)
			 BEGIN --UPDATE
			
			 DECLARE @CatalogosIdAsuntos INT = (SELECT ISNULL(MAX(A.AsuntoDetalleCatalogosId),0) 
												 FROM AsuntosDetalleCatalogos A WITH(NOLOCK)
												 INNER JOIN PersonasAsuntosDetalleCatalogos perDetalle WITH(NOLOCK) ON A.AsuntoDetalleCatalogosId = perDetalle.AsuntoDetalleCatalogosId
												 WHERE A.AsuntosNeunId = @pi_AsuntoNeunId 
												 AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
												 AND A.TipoAsuntoId = @TipoAsuntoIdC AND A.NoBloque = @NoBloque 
												 AND A.StatusReg = 1)

				UPDATE AsuntosDetalleCatalogos
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntosNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdC
				AND AsuntoDetalleCatalogosId =  @CatalogosIdAsuntos
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
							
							UPDATE PersonasAsuntosDetalleCatalogos
							SET FechaBaja = GETDATE(),
							StatusReg = 0
							WHERE AsuntoNeunId = @pi_AsuntoNeunId	
							AND StatusReg = 1
							AND PersonaId = @PersonaCatalogo		
							AND AsuntoDetalleCatalogosId = @CatalogosIdAsuntos										
							SET @RowsAffectedPF = @@ROWCOUNT;	
					
							IF(@RowsAffectedPF > 0)
							BEGIN 		
								INSERT INTO PersonasAsuntosDetalleCatalogos WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleCatalogosId,PersonaId)	 
								VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaCatalogo)
							END											
							
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
			    VALUES (@pi_AsuntoNeunId,@pi_AsuntoId, @IdAsuDetalles, @TipoAsuntoIdC,@CatalogoElementoIdC,@NumeroCatalogoC, @NoCaptura,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
			
				INSERT INTO PersonasAsuntosDetalleCatalogos WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleCatalogosId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaCatalogo)
			END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION

			END ---FIN VALIDACION ELSE PARA ELIMINACION

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
			DECLARE @PersonaNumero INT = 0

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

			IF(@pi_EsEliminacion = 1)
			BEGIN
				DECLARE @EliminarNumeroId INT = 0

				SELECT @EliminarNumeroId = asuDel.AsuntoDetalleNumerosId
				FROM AsuntosDetalleNumeros asuDel
				INNER JOIN PersonasAsuntosDetalleNumeros perDetalle WITH(NOLOCK) ON asuDel.AsuntoDetalleNumerosId = perDetalle.AsuntoDetalleNumerosId
				WHERE asuDel.AsuntosNeunId = @pi_AsuntoNeunId 
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND asuDel.StatusReg = 1
				AND asuDel.TipoAsuntoId = @TipoAsuntoIdN 

			    IF(@EliminarNumeroId > 0)
				BEGIN 
					UPDATE AsuntosDetalleNumeros
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntosNeunId = @pi_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdN
					AND AsuntoDetalleNumerosId = @EliminarNumeroId 
					AND FechaBaja IS NULL
					AND StatusReg = 1
					
					UPDATE PersonasAsuntosDetalleNumeros
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND AsuntoDetalleNumerosId = @EliminarNumeroId 
					AND FechaBaja IS NULL
					AND StatusReg = 1	
				END
			END
			ELSE
			BEGIN								   			 		  		  		 	   			
			--- DECLARACION DE VARIABLES ID´S MAXIMOS

			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) + 1 
											    FROM AsuntosDetalleNumeros A WITH(NOLOCK) 							   
											    WHERE A.AsuntosNeunId = @pi_AsuntoNeunId) 


			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleNumeros C WITH(NOLOCK) 
									  INNER JOIN PersonasAsuntosDetalleNumeros perDetalle WITH(NOLOCK) ON C.AsuntoDetalleNumerosId = perDetalle.PersonaAsuntoDetalleNumerosId
									  WHERE C.AsuntosNeunId = @pi_AsuntoNeunId 
									  AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
									  AND C.NoBloque = @NoBloque
									  AND C.StatusReg = 1)

			SET @PersonaNumero = (SELECT PersonaId FROM @PersonasTable)
			
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
				INNER JOIN PersonasAsuntosDetalleNumeros perDetalle WITH(NOLOCK) ON adn.AsuntoDetalleNumerosId = perDetalle.AsuntoDetalleNumerosId
				WHERE adn.AsuntosNeunId = @pi_AsuntoNeunId
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND adn.TipoAsuntoId = @TipoAsuntoIdN
				AND adn.NoBloque = @NoBloque
				AND adn.FechaBaja IS NULL
				AND adn.StatusReg = 1
				)
			 BEGIN --UPDATE

			   DECLARE @NumeroIdAsuntos INT = (SELECT ISNULL(MAX(A.AsuntoDetalleNumerosId),0) FROM AsuntosDetalleNumeros A WITH(NOLOCK) 
											   INNER JOIN PersonasAsuntosDetalleNumeros perDetalle WITH(NOLOCK) ON A.AsuntoDetalleNumerosId = perDetalle.AsuntoDetalleNumerosId
											   WHERE A.AsuntosNeunId = @pi_AsuntoNeunId  AND A.TipoAsuntoId = @TipoAsuntoIdN AND A.NoBloque = @NoBloque
											   AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
											   AND A.StatusReg = 1)	

				UPDATE AsuntosDetalleNumeros
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntosNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdN
				AND AsuntoDetalleNumerosId =  @NumeroIdAsuntos	
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
							UPDATE PersonasAsuntosDetalleNumeros
							SET FechaBaja = GETDATE(),
							StatusReg = 0
							WHERE AsuntoNeunId = @pi_AsuntoNeunId	
							AND StatusReg = 1
							AND PersonaId = @PersonaNumero
							AND AsuntoDetalleNumerosId = @NumeroIdAsuntos										
							SET @RowsAffectedPF = @@ROWCOUNT;

							IF(@RowsAffectedPF > 0)
							BEGIN 
								INSERT INTO PersonasAsuntosDetalleNumeros WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleNumerosId,PersonaId)	 
								VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaNumero)
							END						   
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
			    VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdN ,@NumeroCampoAsuntoN, @NoCaptura,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)

				INSERT INTO PersonasAsuntosDetalleNumeros WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleNumerosId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaNumero)									

			END -- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION

		   END--- FIN VALIDACION ELSE PARA ELIMINACION
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
			 DECLARE @PersonaOpciones INT = 0

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

			IF(@pi_EsEliminacion = 1)
			BEGIN
				DECLARE @EliminarOpcionId INT = 0

				SELECT @EliminarOpcionId = asuDel.AsuntoDetalleOpcionesId
				FROM AsuntosDetalleOpciones asuDel
				INNER JOIN PersonasAsuntosDetalleOpciones perDetalle WITH(NOLOCK) ON asuDel.AsuntoDetalleOpcionesId = perDetalle.AsuntoDetalleOpcionesId
				WHERE asuDel.AsuntoNeunId =  @pi_AsuntoNeunId 
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND asuDel.StatusReg = 1
				AND asuDel.TipoAsuntoId = @TipoAsuntoIdO

				IF(@EliminarOpcionId > 0)
				BEGIN 
					UPDATE AsuntosDetalleOpciones
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND TipoAsuntoId = @TipoAsuntoIdO
					AND AsuntoDetalleOpcionesId = @EliminarOpcionId 
					AND FechaBaja IS NULL
					AND StatusReg = 1

					UPDATE PersonasAsuntosDetalleOpciones
					SET FechaBaja = GETDATE(), StatusReg = 0
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND AsuntoDetalleOpcionesId = @EliminarOpcionId 
					AND FechaBaja IS NULL
					AND StatusReg = 1
				END
			END
			ELSE
			BEGIN			
			
			--- DECLARACION DE VARIABLES ID´S MAXIMOS
			SET @IdAsuDetalles  = (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) + 1 
											    FROM AsuntosDetalleOpciones A WITH(NOLOCK) 							   
											    WHERE A.AsuntoNeunId = @pi_AsuntoNeunId) 
			SET @ConseAsuDetalles  = (SELECT ISNULL(MAX(C.Consecutivo),0) + 1 FROM AsuntosDetalleOpciones C WITH(NOLOCK)
									  INNER JOIN PersonasAsuntosDetalleOpciones perDetalle WITH(NOLOCK) ON C.AsuntoDetalleOpcionesId = perDetalle.AsuntoDetalleOpcionesId	
									  WHERE C.AsuntoNeunId = @pi_AsuntoNeunId AND C.NoBloque = @NoBloque
									  AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
									  AND C.StatusReg = 1)

			 SET @PersonaOpciones = (SELECT PersonaId FROM @PersonasTable)
						
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
			IF EXISTS (	SELECT 1 FROM AsuntosDetalleOpciones asuOpciones WITH(NOLOCK)
				INNER JOIN PersonasAsuntosDetalleOpciones perDetalle WITH(NOLOCK) ON asuOpciones.AsuntoDetalleOpcionesId = perDetalle.AsuntoDetalleOpcionesId
				WHERE asuOpciones.AsuntoNeunId = @pi_AsuntoNeunId
				AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable)
				AND asuOpciones.TipoAsuntoId = @TipoAsuntoIdO
				AND asuOpciones.NoBloque = @NoBloque
				AND asuOpciones.FechaBaja IS NULL
				AND asuOpciones.StatusReg = 1
				)
			 BEGIN --UPDATE

				DECLARE @OpcionesIdAsuntos INT =  (SELECT ISNULL(MAX(A.AsuntoDetalleOpcionesId),0) 
												FROM AsuntosDetalleOpciones A WITH(NOLOCK) 
												INNER JOIN PersonasAsuntosDetalleOpciones perDetalle WITH(NOLOCK) ON A.AsuntoDetalleOpcionesId = perDetalle.AsuntoDetalleOpcionesId
												WHERE A.AsuntoNeunId = @pi_AsuntoNeunId 
												AND perDetalle.PersonaId = (SELECT PersonaId FROM @PersonasTable) 
												AND A.TipoAsuntoId = @TipoAsuntoIdO AND A.NoBloque = @NoBloque
												AND A.StatusReg = 1)
				UPDATE AsuntosDetalleOpciones
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND TipoAsuntoId = @TipoAsuntoIdO
				AND AsuntoDetalleOpcionesId = @OpcionesIdAsuntos		
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
							UPDATE PersonasAsuntosDetalleOpciones
							SET FechaBaja = GETDATE(),
							StatusReg = 0
							WHERE AsuntoNeunId = @pi_AsuntoNeunId	
							AND StatusReg = 1
							AND PersonaId = @PersonaOpciones		
							AND AsuntoDetalleOpcionesId = @OpcionesIdAsuntos										
							SET @RowsAffectedPF = @@ROWCOUNT;	

							IF(@RowsAffectedPF > 0)
							BEGIN 
								INSERT INTO PersonasAsuntosDetalleOpciones WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId,PersonaId)	 
								VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaOpciones)
							END					
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
									VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaOpciones)

								SET @IndexPersonasOpciones = @IndexPersonasOpciones + 1;
							END	--FIN DE WHILE
						END-- FIN INSERCION CON PARTES				
					END--FIN DEL ELSE				
				END	--FIN DE IF DE ROWS AFECTADOS EN ASUNTOSDETALLES	
			END--FIN DE IF SI EXIST
			ELSE  -- SI NO EXISTE SE REALIZA INSERCION
			BEGIN
				INSERT INTO AsuntosDetalleOpciones WITH (ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId ,TipoAsuntoId ,OpcionCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)	 
			    VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles, @TipoAsuntoIdO ,@OpcionCampoAsunto, @NoCaptura,@NoBloque,@NoBloquePadre,@ConseAsuDetalles,@pi_EmpleadoId)
			
				INSERT INTO PersonasAsuntosDetalleOpciones WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleOpcionesId,PersonaId)	 
				VALUES (@pi_AsuntoNeunId,@pi_AsuntoId,@IdAsuDetalles,@PersonaOpciones)

			END-- FIN DE ELSE SI NO EXISTE SE REALIZA INSERCION

		   END ---FIN VALIDACION ELSE PARA ELIMINACION
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