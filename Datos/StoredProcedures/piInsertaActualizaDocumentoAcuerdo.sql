USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piInsertaActualizaDocumentoAcuerdo]    Script Date: 12/1/2023 6:25:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  31/10/2013
-- Description: Inserta y actualizar Asunto Documento 
-- Basado en:   [uspx_tt_addDocumentoPromociones]
/*
	DECLARE @return_value int
	DECLARE @promo [SISE3].[PromocionesAcuerdo_type],
	   @DocumentoId int,
	   @po_NombreArchivo varchar(50), 
	   @asunto SISE3.AutoridadAsunto_type, 
	   @per [PersonasNotificacionIndividual]
        
   INSERT INTO @promo VALUES (174, 2023, 4,1)
   INSERT INTO @promo VALUES (141, 2023, 4,0)

   INSERT INTO @asunto([TipoAnexoId],[AnexoParteId],[AnexoParteDescripcion], TextoOficioLibre) values (6, 1837806, 'OFICIO','TEXTO LIBRE')

   INSERT INTO @per values (163079366, 0, 6, null, null, 0, 0)
  
  EXEC [SISE3].piInsertaActualizaDocumentoAcuerdo 
        @pi_AsuntoNeunId = 30314120,
		@pi_NombreDocumento = 'PRUEBA SISE',
        @pi_ExtensionDocumento  = '.docx',
		@pi_Contenido = 3085,
		@pi_TipoCuaderno  = 933,
		@pi_FechaAcuerdo  = '2023-11-22',
		@pi_SintesisOrden = 48,

        @pi_IPUsuario  = '192.169.0.2',
        @pi_UsuarioCaptura  = 2,
        @pi_PromocionesDeterminacion  = @promo,
		@pi_AutoridadAsunto = @asunto,
		@pi_PersonasNotificacion =  @per,
        @po_AsuntoDocumentoId = 48,
        @po_NombreArchivo = ''*/
-- =============================================
CREATE PROCEDURE [SISE3].[piInsertaActualizaDocumentoAcuerdo]

(
   		@pi_AsuntoNeunId BIGINT, 
		@pi_NombreDocumento VARCHAR(255), --Nombre real del documento
		@pi_ExtensionDocumento VARCHAR(20),
		@pi_Contenido SMALLINT, ---Id Tipo de contenido,
		@pi_TipoCuaderno SMALLINT,
		@pi_FechaAcuerdo DATETIME, --Fecha del documento
		@pi_SintesisOrden INT = NULL,

		/***Sentencia***/
		@pi_IPUsuario [varchar](50),
		@pi_UsuarioCaptura BIGINT,
		@pi_PromocionesDeterminacion [SISE3].[PromocionesAcuerdo_type] READONLY, --Datos de promociones
		@pi_AutoridadAsunto as SISE3.AutoridadAsunto_type  READONLY ,  -- Tipo Tabla donde se pasa el IDParte y NombreParte (Tipo Asunto 1 Oficio, 6 Oficio Libre)
		@pi_PersonasNotificacion [PersonasNotificacionIndividual] READONLY,
        
		@po_AsuntoDocumentoId INT OUTPUT, 
		@po_NombreArchivo  VARCHAR(50) OUTPUT 

)
AS
BEGIN
	SET NOCOUNT ON


		BEGIN TRY

			DECLARE @IsOpcionActiva BIT
            DECLARE @CatAutorizacionId INT
			DECLARE @AsuntoId INT
			/***Sentencia***/
			DECLARE @TipoArchivo INT
			DECLARE @Sigilo BIT
			DECLARE @SentenciaDefinitiva BIT
			DECLARE @EsJDA BIT
			DECLARE @TitularId BIGINT
			DECLARE @SecretarioPId BIGINT
			DECLARE @SecretarioCId BIGINT
			DECLARE @ActuarioId BIGINT
			DECLARE @Resumen NVARCHAR(MAX)
			DECLARE @CatOrganismoId INT
			DECLARE @EstatusArchivo INT
			DECLARE @IPUsuario [varchar](50)
			DECLARE @UsuarioCaptura BIGINT
			DECLARE @IdOrigen INT
			DECLARE @TipoOrigen INT
			DECLARE @VersionPub INT
			DECLARE @InfoReservada int
			DECLARE @Perspectiva INT
			DECLARE @Criterio INT
			DECLARE @Trascedental INT
			DECLARE @EsTratadoInternacional INT
			DECLARE @TipoActo INT = null
			DECLARE @NombreTratado INT =null
			DECLARE @Derecho INT
			DECLARE @SubClasificacionDerecho INT
			DECLARE @TipoActoOtro varchar(200) = null
			DECLARE @SolicitudReparacion  int
			DECLARE @SolicitudReparacionOpcion int = null
			DECLARE @SolicitudReparacionOtro VARCHAR(200)
			DECLARE @LecturaFacil BIT = NULL
			DECLARE @TemaEquidadGenero INT = NULL
			DECLARE @AplicacionEfectivaDerechoMujeres BIT = NULL
			DECLARE @TemaAsuntosInternacionales INT = NULL
			DECLARE @AplicacionCriteriosPersGenero INT=NULL
			DECLARE @CriterioPerspecGenAplicado VARCHAR(500)
			DECLARE @Justificacion varchar(255) = NULL
			DECLARE @CountExist INT
			DECLARE @FechaExpediente DATETIME

			--Sentencia
			SET @TipoArchivo = 0
			SET @Sigilo = 0
			SET @SentenciaDefinitiva = 0
			SET @EsJDA = 0
			--SET @TitularId = Se obtiene de la consulta ,
			--SET @SecretarioPId = Sale de la consulta de  ,
			SET @SecretarioCId = 0
			SET @ActuarioId = 0
			SET @Resumen = NULL
			SET @EstatusArchivo = 0
			SET @IdOrigen  = 7
			SET @TipoOrigen = 7
			SET @VersionPub =0 
			SET @InfoReservada = 0
			SET @Perspectiva = 0
			SET @Criterio = NULL
			SET @Trascedental = NULL
			SET @EsTratadoInternacional = 0
			SET @TipoActo  = 0
			SET @NombreTratado  = 0
			SET @Derecho = 0
			SET @SubClasificacionDerecho = 0
			SET @TipoActoOtro = NULL
			SET @SolicitudReparacion  = NULL
			SET @SolicitudReparacionOpcion = 0
			SET @SolicitudReparacionOtro = NULL
			SET @LecturaFacil  = NULL
			SET @TemaEquidadGenero  = NULL
			SET @AplicacionEfectivaDerechoMujeres  = NULL
			SET @TemaAsuntosInternacionales  = NULL
			SET @AplicacionCriteriosPersGenero =NULL
			SET @CriterioPerspecGenAplicado = NULL
			SET @Justificacion = NULL
			SET @CountExist = 0
			
			
            /* SE VALIDA QUE LA TABLA TEMPORAL NO EXISTA */ 
            IF OBJECT_ID('tempdb..#tmpPromociones') IS NOT NULL 
                    DROP TABLE #tmpPromociones; 
         
			 DECLARE @OrganismoId INT

			 SELECT @CatOrganismoId = CatOrganismoId, @AsuntoId = AsuntoId, @FechaExpediente = FechaAlta
			 FROM Asuntos
			 WHERE AsuntoNeunId = @pi_AsuntoNeunId AND StatusReg = 1

			 
			IF CAST(@pi_FechaAcuerdo AS DATE) < CAST(@FechaExpediente AS DATE)
					THROW 51000,'Fecha de presentación de acuerdo no puede ser inferior a fecha de expediente',1;

			
			 DECLARE @AsuntoDocumentoId INT
			 DECLARE @SintesisOrden INT
			 DECLARE @NombreArchivo VARCHAR(100)
			 SET @SintesisOrden = (SELECT ISNULL(MAX(SintesisOrden),0)+1 FROM SintesisAcuerdoAsunto WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId) 
      
			 DECLARE @ClasificaCuaderno int
			 DECLARE @TipoAsunto int
			 Set @TipoAsunto=(select CatTipoAsuntoId from Asuntos with(nolock) where AsuntoNeunId=@pi_AsuntoNeunId and AsuntoId=@AsuntoId)

			 IF @TipoAsunto IN (1,2,4,46,67,74,109,124)
				BEGIN
					SET @ClasificaCuaderno = (Select dbo.fnObtieneClasificacionCuadernoDeTipoCuaderno (@pi_TipoCuaderno))
				END 
			 ELSE
				 BEGIN
				 SET @ClasificaCuaderno = 0
			 END

			DECLARE @pi_NumeroOrdenDet INT
			DECLARE @pi_NumeroOrdenSentencia INT
			DECLARE @CargoTitular INT
			DECLARE @NombreArchivoCompleto varchar(100)

			IF (@po_AsuntoDocumentoId IS NOT NULL)
			BEGIN
				SET @AsuntoDocumentoId  = @po_AsuntoDocumentoId

			END

			SET @po_NombreArchivo = @pi_NombreDocumento  +  dbo.fnRellenaValor(ISNULL(MAX(@AsuntoDocumentoId),0) + 1,3,'0',0)

            IF(@AsuntoDocumentoId IS NULL OR @AsuntoDocumentoId = 0  )
                BEGIN

					SELECT @AsuntoDocumentoId = ISNULL(MAX(AsuntoDocumentoId),0)+1
					FROM AsuntosDocumentos WITH(NOLOCK)
					WHERE AsuntoNeunId = @pi_AsuntoNeunId

					SELECT @SintesisOrden = ISNULL(MAX(SintesisOrden),0)+1 
					FROM SintesisAcuerdoAsunto WITH(NOLOCK) 
					WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					
					DECLARE @TipoCuadernoSise1 VARCHAR(50)
					SET @TipoCuadernoSise1=dbo.fnObtieneATipoSISE2aSISE1(@pi_TipoCuaderno,null)
                
					SET @pi_NumeroOrdenDet = (SELECT isnull(MAX(NumeroOrden),0)+1 FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId)

				END
			ELSE 
			BEGIN 
                    /* ACTUALIZACION DE SINTESIS */
                        
                    SELECT @IsOpcionActiva = Activa 
                    FROM ConfiguracionSISE WITH(NOLOCK) 
                    WHERE ConfiguracionOpcionSISEId = 6 
                    AND CatOrganismoId = @CatOrganismoId

					SELECT @CatAutorizacionId =CatAutorizacionDocumentosId,
                    @SintesisOrden = SintesisOrden
					FROM AsuntosDocumentos WITH(NOLOCK)
					WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					AND AsuntoDocumentoId = @AsuntoDocumentoId
                        
                    /* ACTUALIZACION PROMOCIONES */         
                   -- UPDATE Promociones WITH(ROWLOCK)
                   -- SET AsuntoDocumentoId = 0, EstadoPromocion = 0,SintesisOrden = NULL
                   -- WHERE AsuntoNeunId = @pi_AsuntoNeunId AND AsuntoDocumentoId = @AsuntoDocumentoId

					SET @SintesisOrden = @pi_SintesisOrden

					SET @pi_NumeroOrdenDet = (SELECT isnull(MAX(NumeroOrden),0) FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @SintesisOrden )
		END

		
			/* SE CREA LA SINTESIS */
			MERGE INTO SintesisAcuerdoAsunto trg
			USING 
			(	SELECT @SintesisOrden AS SintesisOrden, @AsuntoId AS AsuntoId, @pi_AsuntoNeunId AS AsuntoNeunId, @CatOrganismoId AS CatOrganismoId
					    ,getdate() AS FechaAcuerdo, 'Síntesis creada automáticamente desde Determinaciones Judiciales' AS Sintesis
						, null AS FechaPublicacion, 0 AS Titular, 0 AS Actuario, @ClasificaCuaderno AS ClasificacionCuaderno
						,@pi_TipoCuaderno AS TipoCuaderno, 0 AS Parte1, 0 AS Parte2,'' AS Parte1YOtros,'' AS Parte2YOtros,1 AS EstatusSintesis
						,@pi_UsuarioCaptura AS UsuarioCaptura, GETDATE() AS FechaAlta, 2 AS StatusReg, @AsuntoDocumentoId AS IdDocumento, 7 AS TipoOrigen
			) AS src
					ON (trg.CatOrganismoId = src.CatOrganismoId
                        AND trg.AsuntoNeunId = src.AsuntoNeunId
                        AND trg.SintesisOrden = src.SintesisOrden)          
						
			WHEN NOT MATCHED THEN  
				INSERT ([SintesisOrden] ,[AsuntoId],[AsuntoNeunId],[CatOrganismoId],[FechaAuto] ,[Sintesis] ,[FechaPublicacion] ,[Titular] ,[Actuario] , [ClasificacionCuaderno], [TipoCuaderno] 
							,[Parte1],[Parte2],[Parte1YOtros],[Parte2YOtros],[EstatusSintesis],[UsuarioCaptura],[FechaAlta],[StatusReg],[IdDocumento],[TipoOrigen])
				VALUES (src.SintesisOrden, src.AsuntoId, src.AsuntoNeunId, src.CatOrganismoId,src.FechaAcuerdo, src.Sintesis, src.FechaPublicacion, src.Titular, src.Actuario,src.ClasificacionCuaderno, 
				        src.TipoCuaderno,src.Parte1, src.Parte2,src.Parte1YOtros,src.Parte2YOtros,src.EstatusSintesis,src.UsuarioCaptura, src.FechaAlta, src.StatusReg, src.IdDocumento, src.TipoOrigen)
            WHEN MATCHED THEN
				UPDATE      
				SET Sintesis = src.Sintesis, FechaAuto = src.FechaAcuerdo, TipoOrigen = 7,FechaActualizacion =GETDATE();

			---Validar si existen archivos.

			MERGE INTO [AsuntosDocumentos] tra
			USING 
			(	SELECT  @pi_AsuntoNeunId AS AsuntoNeunId, @AsuntoId AS AsuntoId, @AsuntoDocumentoId AS AsuntoDocumentoId, @pi_NombreDocumento AS NombreDocumento,'' AS RutaDocumento
			   , @po_NombreArchivo AS NombreArchivo, 1 AS CatAutorizacionDocumentosId, @pi_ExtensionDocumento AS ExtensionDocumento, 0 AS CatPlantillaId, @pi_Contenido AS CatContenidoId
			   , '' AS ContenidoDocumento, CONVERT(varbinary(max),'') AS ContenidoAsunto, @SintesisOrden AS SintesisOrden, @pi_TipoCuaderno AS TipoCuaderno
			   , @TipoArchivo AS TipoArchivo, @Sigilo AS Sigilo, @SentenciaDefinitiva AS SentenciaDefinitiva, @EsJDA AS esJDA, @SecretarioPId AS SecretarioPId
			   , @SecretarioCId AS SecretarioCId, @TitularId AS TitularId,@pi_UsuarioCaptura AS UsuarioCaptura, @Resumen AS Resumen, @pi_FechaAcuerdo AS FechaAcuerdo  , 7 TipoRuta                
			)AS asd
					ON (tra.AsuntoNeunId = asd.AsuntoNeunId AND tra.AsuntoDocumentoId = asd.AsuntoDocumentoId 
						/*AND tra.SintesisOrden = asd.SintesisOrden*/
						)
					
					WHEN NOT MATCHED THEN  
					 INSERT ([AsuntoNeunId],[AsuntoID],[AsuntoDocumentoId],[NombreDocumento],[RutaDocumento],[NombreArchivo],[CatAutorizacionDocumentosId],[ExtensionDocumento]
								 ,[CatPlantillaId],[CatContenidoId],[ContenidoDocumento],[ContenidoAsunto],[SintesisOrden],[TipoCuaderno],[TipoArchivo],[Sigilo] 
								 ,[SentenciaDefinitiva],[esJDA] ,[SecretarioPId] ,[SecretarioCId] ,[TitularId],[CreadorId],[Resumen],[FechaAlta],[TipoRuta])
					 VALUES (asd.AsuntoNeunId,asd.AsuntoID, asd.AsuntoDocumentoId, asd.NombreDocumento, asd.RutaDocumento, asd.NombreArchivo, asd.CatAutorizacionDocumentosId, asd.ExtensionDocumento
								,asd.CatPlantillaId,asd.CatContenidoId, asd.ContenidoDocumento, asd.ContenidoAsunto,asd.SintesisOrden,asd.TipoCuaderno,asd.TipoArchivo,asd.Sigilo
								,asd.SentenciaDefinitiva, asd.esJDA, asd.SecretarioPId, asd.SecretarioCId, asd.TitularId, asd.UsuarioCaptura, asd.Resumen, asd.FechaAcuerdo , asd.TipoRuta)
					
					WHEN MATCHED THEN
					  UPDATE SET NombreDocumento = asd.NombreDocumento
                         , TipoCuaderno = asd.TipoCuaderno
                         , ContenidoDocumento = asd.ContenidoDocumento
						 , CatContenidoId = asd.CatContenidoId
                         , ContenidoAsunto = asd.ContenidoAsunto
                         , CatAutorizacionDocumentosId = CASE WHEN asd.CatAutorizacionDocumentosId = 4 THEN 5 ELSE asd.CatAutorizacionDocumentosId END
                         , FechaAlta = asd.FechaAcuerdo
                         , NombreArchivo = asd.NombreArchivo
                         , CreadorId = asd.UsuarioCaptura
                         , ExtensionDocumento = asd.ExtensionDocumento;

			

			SET @CargoTitular = (SELECT top 1 c.CargoId 
									FROM EmpleadoOrganismo eo WITH(NOLOCK) inner join CatCargo c WITH(NOLOCK) on eo.CargoId = c.CargoId 
									WHERE CatOrganismoId = @CatOrganismoId and eo.EmpleadoId = @TitularId and eo.StatusRegistro=1 and c.StatusReg=1)
			
			SET @NombreArchivoCompleto =(Select NombreArchivo+''+ExtensionDocumento FROM AsuntosDocumentos with(nolock) where AsuntoNeunId = @pi_AsuntoNeunId and SintesisOrden = @SintesisOrden and StatusReg=1)

			MERGE INTO DeterminacionesJudiciales dj
			USING 
			(	SELECT @AsuntoId AS AsuntoId, @pi_AsuntoNeunId AS AsuntoNeunId, @pi_NumeroOrdenDet AS NumeroOrden, @SintesisOrden AS SintesisOrden, @pi_TipoCuaderno AS TipoCuaderno,
				 @pi_Contenido AS Contenido, @TitularId AS TitularId , @CargoTitular AS CargoTitular, @SecretarioPId AS SecretarioPId, @ActuarioId AS ActuarioId,
				 @pi_FechaAcuerdo AS FechaAuto,@CatOrganismoId AS CatOrganismoId,NULL AS NomArchivoReal, @EstatusArchivo EstatusArchivo,
				 @pi_IPUsuario AS IPUsuario, GETDATE() AS FechaAlta, NULL AS FechaBaja, @pi_UsuarioCaptura AS UsuarioCaptura, 2 AS StatusReg,
				 @IdOrigen AS Origen,@TipoOrigen AS TipoOrigen,@Justificacion AS Justificacion, @pi_NumeroOrdenSentencia AS NumeroOrdenSentencia,
				 @NombreArchivoCompleto AS NombreArchivo, @TipoArchivo AS TipoArchivo, @Sigilo AS Sigilo, @SentenciaDefinitiva AS SentenciaDefinitiva, 
				 @EsJDA AS EsJDA, @SecretarioCId AS SecretarioCId, @Resumen AS Resumen, @VersionPub AS VersionPub,@InfoReservada AS InfoReservada,
				 @Criterio AS Criterio, @Trascedental AS Trascedental, @EsTratadoInternacional AS EsTratadoInternacional, @TipoActo AS TipoActo,
				 @NombreTratado AS NombreTratado, @Derecho AS Derechos, @SubClasificacionDerecho AS SubClasificacionDerechos, 
				 @TipoActoOtro AS TipoActoOtro , @SolicitudReparacion AS SolicitudReparacion, @SolicitudReparacionOpcion AS SolicitudReparacionOpcion, 
				 @SolicitudReparacionOtro AS SolicitudReparacionOtro, @LecturaFacil AS LecturaFacil, @TemaEquidadGenero AS TemaEquidadGenero, 
				 @AplicacionEfectivaDerechoMujeres AS AplicacionEfectivaDerechoMujeres, @TemaAsuntosInternacionales AS TemaAsuntosInternacionales, 
				 @AplicacionCriteriosPersGenero AS AplicaCritPerspecGenero, @CriterioPerspecGenAplicado AS CriterioPerspectivaGenAplicado

 			)AS det
			ON (dj.AsuntoNeunId = det.AsuntoNeunId AND dj.NumeroOrden = det.NumeroOrden AND dj.NumeroOrden = det.NumeroOrden AND dj.SintesisOrden = det.SintesisOrden) 
				
			WHEN NOT MATCHED THEN 
			
				INSERT (AsuntoId ,AsuntoNeunId ,NumeroOrden ,SintesisOrden ,TipoCuaderno ,Contenido ,TitularId ,CargoTitular,SecretarioPId, ActuarioId,
				FechaAuto ,CatOrganismoId ,NombreArchivo ,NomArchivoReal ,EstatusArchivo ,IPUsuario ,FechaAlta,FechaBaja,UsuarioCaptura,StatusReg,
				Origen,TipoOrigen,Justificacion)	
				VALUES (det.AsuntoId ,det.AsuntoNeunId ,det.NumeroOrden ,det.SintesisOrden ,det.TipoCuaderno ,det.Contenido ,det.TitularId ,det.CargoTitular,det.SecretarioPId,det.ActuarioId,
				det.FechaAuto, det.CatOrganismoId,det.NombreArchivo,det.NomArchivoReal,det.EstatusArchivo,det.IPUsuario,det.FechaAlta,det.FechaBaja,det.UsuarioCaptura,det.StatusReg,
				det.Origen,det.TipoOrigen,det.Justificacion)	
			
			WHEN MATCHED THEN 
			
				UPDATE  
				SET NumeroOrdenSentencia = det.NumeroOrdenSentencia
					,NombreArchivo = det.NombreArchivo
					,TipoArchivo = det.TipoArchivo
					,Sigilo = det.Sigilo
					,SentenciaDefinitiva = det.SentenciaDefinitiva 
					,EsJDA = det.EsJDA 			
					,SecretarioCId = det.SecretarioCId 
					,Resumen = det.Resumen
					,VersionPub=det.VersionPub
					,InfoReservada=det.InfoReservada
					,Criterio=det.Criterio 
					,Trascedental=det.Trascedental 
					,EsTratadoInternacional =det.EsTratadoInternacional 
					,TipoActo =det.TipoActo
					,NombreTratado=det.NombreTratado
					,Derechos=det.Derechos
					,SubClasificacionDerechos=det.SubClasificacionDerechos
					,TipoActoOtro=det.TipoActoOtro 
					,SolicitudReparacion =det.SolicitudReparacion
					,SolicitudReparacionOpcion =det.SolicitudReparacionOpcion
					,SolicitudReparacionOtro = det.SolicitudReparacionOtro
					,LecturaFacil = det.LecturaFacil
					,TemaEquidadGenero = det.TemaEquidadGenero
					,AplicacionEfectivaDerechoMujeres = det.AplicacionEfectivaDerechoMujeres
					,TemaAsuntosInternacionales = det.TemaAsuntosInternacionales
					,AplicaCritPerspecGenero=det.AplicaCritPerspecGenero                                          
					,CriterioPerspectivaGenAplicado=det.CriterioPerspectivaGenAplicado
					,Justificacion= det.Justificacion;
			
			
					
					
			/*----------------Se inserta en bitácora el registro de la determinación judicial
			DECLARE @tipoCuadernoBitacora INT
            DECLARE @DJIndice INT
			DECLARE @contenido INT
			DECLARE @numeroOrdenSentencia INT
            DECLARE @CargoTitularActual INT
            DECLARE @fechaAuto DATETIME
            DECLARE @fechaPublicacionDJ DATETIME
            DECLARE @nombreArchivoDJ NVARCHAR(30)
            DECLARE @nombreArchivoReal NVARCHAR(150)
            DECLARE @observacionesArchivo NVARCHAR(200)
            DECLARE @fechaAlta DATETIME
            DECLARE @origen INT              
            DECLARE @consecutivoArchivo INT

            SELECT @tipoCuadernoBitacora = TipoCuaderno 
                    ,@DJIndice = DJIndiceId
                    ,@contenido = Contenido
                    ,@numeroOrdenSentencia = NumeroOrdenSentencia
                    ,@tipoArchivo = TipoArchivo
                    ,@sigilo = Sigilo
                    ,@sentenciaDefinitiva = SentenciaDefinitiva
                    ,@esJDA = EsJDA
                    ,@titularId = TitularId
                    ,@CargoTitularActual = CargoTitular
                    ,@secretarioPId = SecretarioPId
                    ,@SecretarioCId = SecretarioCId
                    ,@actuarioId = ActuarioId
                    ,@resumen = Resumen
                    ,@fechaAuto = FechaAuto
                    ,@fechaPublicacionDJ = FechaPublicacion
                    ,@nombreArchivoDJ = NombreArchivo
                    ,@nombreArchivoReal = NomArchivoReal
                    ,@estatusArchivo = EstatusArchivo
                    ,@ipUsuario = IPUsuario
                    ,@observacionesArchivo = ObservacionesArchivo
                    ,@usuarioCaptura = UsuarioCaptura
                    ,@fechaAlta = FechaAlta
                    ,@origen = Origen
                    ,@tipoOrigen = TipoOrigen               
                    ,@consecutivoArchivo = ConsecutivoArchivo
            FROM DeterminacionesJudiciales 
            WHERE AsuntoNeunId = @pi_AsuntoNeunId 
                    AND NumeroOrden = @pi_NumeroOrden
                    AND SintesisOrden = @SintesisOrden
                    AND CatOrganismoId = @CatOrganismoId 
                    AND StatusReg = 2                                                        
                                                                                                                                             
            EXEC SISE_NEWLOG.dbo.usp_DeterminacionesJudiciales_Bitacora 
                    @DJIndice,@AsuntoId,@pi_AsuntoNeunId
                    ,@pi_NumeroOrden,@SintesisOrden,@tipoCuadernoBitacora
                    ,@contenido,@numeroOrdenSentencia
                    ,@tipoArchivo,@sigilo
                    ,@sentenciaDefinitiva
                    ,@esJDA
                    ,@titularId
                    ,@CargoTitularActual
                    ,@secretarioPId
                    ,@secretarioCId
                    ,@actuarioId
                    ,@resumen
                    ,@fechaAuto
                    ,@FechaPublicacionDJ
                    ,@CatOrganismoId
                    ,@nombreArchivoDJ
                    ,@nombreArchivoReal
                    ,@estatusArchivo
                    ,@ipUsuario
                    ,@observacionesArchivo
                    ,@fechaAlta
                    ,NULL
                    ,@usuarioCaptura
                    ,2
                    ,@origen
                    ,@tipoOrigen
					,null
                    ,@consecutivoArchivo
            ----------------fin inserción en bitácora      */
		
				  
			IF EXISTS(SELECT * FROM @pi_PromocionesDeterminacion WHERE YearPromocion > 1 )
            BEGIN 
			
				DECLARE @NumeroOrden INT
				DECLARE @YearPromocion INT
				DECLARE @EstadoPromocionId INT                                     
				
				UPDATE Promociones WITH(ROWLOCK)
				SET SintesisOrden = @SintesisOrden
					,EstadoPromocion = m.EstadoPromocionId
					,FechaAcuerdo =@pi_FechaAcuerdo
					,FechaActualiza=GETDATE()
					,AsuntoDocumentoId = @AsuntoDocumentoId
				FROM Promociones p INNER JOIN @pi_PromocionesDeterminacion m 
					ON p.AsuntoNeunId = @pi_AsuntoNeunId
					   AND p.NumeroOrden = m.NumeroOrden
					  -- AND p.YearPromocion = m.YearPromocion
					   AND p.StatusReg IN (1,2)
				WHERE m.[Proceso] = 0
								

				UPDATE Promociones WITH(ROWLOCK)
				SET SintesisOrden =null
					,EstadoPromocion = m.EstadoPromocionId
					,FechaAcuerdo = null
					,FechaActualiza=GETDATE()
					,AsuntoDocumentoId = null
				FROM Promociones p INNER JOIN @pi_PromocionesDeterminacion m 
					ON p.AsuntoNeunId = @pi_AsuntoNeunId
					   AND p.NumeroOrden = m.NumeroOrden
				--	   AND p.YearPromocion = m.YearPromocion
					   AND p.StatusReg IN (1,2)
				WHERE m.[Proceso] = 1

				/*		DECLARE @origenPromo INT
						SET @origenPromo= (SELECT TOP 1 OrigenPromocion FROM Promociones WHERE AsuntoNeunId = @pi_AsuntoNeunId
								AND NumeroOrden = @NumeroOrden
								AND YearPromocion=@YearPromocion
								AND StatusReg in (1,2))*/
                                               
						--EXEC usp_Promocion_Bitacora @CatOrganismoId,@YearPromocion,@NumeroOrden,@origenPromo,4 --4 indica que es cambio en tabla promociones 

						/*IF(@SintesisOrden=0)
						BEGIN 
							INSERT INTO [SISE_NEWLOG].[dbo].[BitacoraPromocionesSintesisOrden]
										([SintesisOrden]
										,[AsuntoNeunId]
										,[CatOrganismoId]
										,[YearPromocion]
										,[NoRegistro]
										,[EstadoPromocion]
										,[FechaMovimiento]
										,[UsuarioId]
										,[ProcedimientoAlmacenado])
								VALUES (@SintesisOrden,@pi_AsuntoNeunId,@CatOrganismoId,@YearPromocion,0,@EstadoPromocionId,GETDATE(),1,'SISE_piDocumentosCargaPanel')
						END*/                             
			END


			DECLARE @po_NumOrdenNotificacion INT
            SET @po_NumOrdenNotificacion = (SELECT  ISNULL(MAX(NumeroOrden), 0) + 1 FROM NotificacionElectronica WITH(NOLOCK) 
											WHERE AsuntoNeunId=@pi_AsuntoNeunId)           
            
		
			IF NOT EXISTS(SELECT TOP 1 [AsuntoNeunId] 
			   FROM [NotificacionElectronica] 
			   WHERE [CatOrganismoId] = @CatOrganismoId
			    AND  [AsuntoNeunId] = @pi_AsuntoNeunId
				AND  [SintesisOrden] = @SintesisOrden
				AND  [StatusReg]=1)
			BEGIN
				INSERT INTO [NotificacionElectronica] WITH(ROWLOCK)
					([AsuntoNeunId]
					,[AsuntoId]
					,[SintesisOrden]
					,[NumeroOrden]
					,[CatOrganismoId]
					,[TipoCuadernoId]
					,[RegistroEmpleadoId]
					,[FechaAlta]
					,[StatusReg]
					,[NombreArchivo]
					,[EstatusArchivo]
					,[IpUsuario]
					,[ConsecutivoArchivo]
					,UbicacionNombreArchivo)
				VALUES
					(@pi_AsuntoNeunId
					,@AsuntoId
					,@SintesisOrden
					,@po_NumOrdenNotificacion
					,@CatOrganismoId
					,@pi_TipoCuaderno
					,@pi_UsuarioCaptura
					,GETDATE()
					,1
					,NULL
					,0
					,@pi_IPUsuario
					,1
					,1)
				-- Martin Llamada a procedimiento para asignar permisos al archivo en expediente electronico
				EXEC piPermisoDeterminacionJudicial @AsuntoId, @pi_AsuntoNeunId, @pi_NumeroOrdenDet, @SintesisOrden
            END
				
			

			DECLARE @dt datetime
            SET @dt = getdate() 

			
            /* Llamada al SP para guardar en bitacora el movimiento de la Sintesis de Actuaria  LAGS 21.10.2015*/
        --    EXEC usp_SintesisAcuerdoAsunto_Bitacora @AsuntoId,@pi_AsuntoNeunId,@CatOrganismoId,@SintesisOrden,1               

			/* Bitacora para AsuntosDocumentos */
         --   EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@AsuntoDocumentoId,1,@dt,@pi_UsuarioCaptura

			/*Insert oficio autoridad juidical*/
			IF EXISTS(SELECT * FROM @pi_AutoridadAsunto)
			BEGIN 

				
				CREATE TABLE #Temppartes
					(folio int, 
					 AnexoParteId int, 
					 TipoAnexoId int, 
					 AnexoParteDescripcion varchar(max)
					)


				INSERT INTO #Temppartes
				EXEC [SISE3].[piInsertaAnexosOficio]
				@pi_AsuntoNeunId ,
				@CatOrganismoId ,  
				2 ,
				@AsuntoDocumentoId ,
				@pi_AutoridadAsunto   -- Tipo Tabla donde se pasa el IDParte y NombreParte
					
			END 
				
				
			/*Insert notificación electronica*/
				IF EXISTS(SELECT * FROM @pi_PersonasNotificacion)
				BEGIN 
			
			                                 
					DECLARE @PersonasNotificacion_temp [PersonasNotificacionIndividual]
				
					--IF EXISTS(SELECT * FROM @pi_PersonasNotificacion  a WHERE a.[TipoNotificacionId] = 3)
					--BEGIN    
					--		Print 'Personas'

							Insert into @PersonasNotificacion_temp
							SELECT * FROM @pi_PersonasNotificacion  a --WHERE a.[TipoNotificacionId] = 3
													   

						EXEC [SISE3].piInsertarNotificacionesOficio
							 	@pi_AsuntoNeunId ,
								@AsuntoId ,
								@SintesisOrden ,
								@CatOrganismoId,
								@pi_TipoCuaderno ,
								5736	,--@pi_TipoConstanciaId
								10273  , --@pi_ActuarioId
								31729 , --@pi_RegistroEmpleadoId,
								@pi_IpUsuario,
								@PersonasNotificacion_temp ,
								null,
								null,
								3 --Notificaciones Judiciales @pi_IdOrigen INT = 
					--END 
				END 
			

			/* Retorno la Información Requerida */
            SELECT @AsuntoDocumentoId AS AsuntoDocumentoId
                ,@SintesisOrden AS SintesisOrden
                ,@CatOrganismoId AS CatOrganismoId
				,@po_NombreArchivo AS NombreArchivo
				,@pi_NumeroOrdenDet AS NumeroOrden
        END TRY 
        BEGIN CATCH
                -- Ejecuta la rutina de recuperacion de errores.
                EXECUTE dbo.usp_GetErrorInfo;
        END CATCH;

END
GO

