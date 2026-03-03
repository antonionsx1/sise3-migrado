SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  31/10/2023
-- Description: Inserta y actualizar Asunto Documento 
-- Basado en:   [uspx_tt_addDocumentoPromociones]
/*
	
  DECLARE @pi_PartePromoventeNotificacion SISE3.PersonaPromoventeNotificacion_type 
  DECLARE @pi_PromocionesDeterminacion SISE3.PromocionesAcuerdo_type
  
  INSERT INTO @pi_PartePromoventeNotificacion (PersonaId, PromoventeId,	TipoNotificacionId, TipoAnexoId, TextoOficioLibre, NombreParte)
  VALUES(171532145,NULL, 5,1,'','NombreParte1 NombreParte2 NombreParte3 - QUEJOSO'),
		(NULL,24314543,11,6,'Texto oficio libre','Oscar Guerrero'),
		(171532146,NULL,11,6,'Texto oficio libre','Juzgado 10 de CDMX - AUTORIDAD RESPONSABLE')
  EXEC [SISE3].piInsertaActualizaDocumentoAcuerdo
        @pi_AsuntoNeunId = 30326415,
		@pi_NombreDocumento = '',
        @pi_ExtensionDocumento  = '',
		@pi_Contenido = 5706,
		@pi_TipoCuaderno  = 5645,
		@pi_FechaAcuerdo  = '2024-04-21',
		@pi_SintesisOrden = NULL,
        @pi_IPUsuario  = '192.169.0.2',
        @pi_UsuarioCaptura  = 2,
		@pi_PromocionesDeterminacion = @pi_PromocionesDeterminacion,
		@pi_PartePromoventeNotificacion = @pi_PartePromoventeNotificacion,
        @po_AsuntoDocumentoId = NULL,
        @po_NombreArchivo = ''*/

-- Modifiçación: SBGE 07/11/2023 Se inserta/actualiza el campo EtapaProcesal en la tabla SISE3.AsuntosDocumentosAdicional
-- Modificación: SBGE 07/04/2025 Se actualiza la tabla de Determinaciones Judiciales el campo FechaAto que es la Fecha del acuerdo
-- Modificación: AGA 25/04/2025 Se comentan lineas relacionadas al firmado de oficios
-- Modificación: JSM 08/05/2025 Se ajusta condición para un acuerdo de WS al trabajarlo en sise2 hasta la autorización y editarlo en sise3, no se pierda el archivo firmado.
-- Modificación: SBGE 19/05/2025 Para agregar registro en notificacionelectronica se considera el status 2 para verificar si ya existe el registro, ya que puede existir en estatus 2
--               hasta que el acuerdo se autoriza y preautoriza cambia a  1.
-- Modificación: AGA Se agrega validación TipoNotificacionId > 0 en la inserción de notificacion electronica esto para no permitir tipos de notificación = sinNotificación
-- =============================================
ALTER PROCEDURE [SISE3].[piInsertaActualizaDocumentoAcuerdo]

(
   		@pi_AsuntoNeunId BIGINT, 
		@pi_NombreDocumento VARCHAR(255) = NULL,
		@pi_ExtensionDocumento VARCHAR(20) = NULL,
		@pi_Contenido SMALLINT, 
		@pi_TipoCuaderno SMALLINT,
		@pi_FechaAcuerdo DATETIME, 
		@pi_SintesisOrden INT = NULL,
		@pi_IPUsuario [varchar](50),
		@pi_UsuarioCaptura BIGINT,
		@pi_PromocionesDeterminacion SISE3.PromocionesAcuerdo_type READONLY,
		@pi_PartePromoventeNotificacion SISE3.PersonaPromoventeNotificacion_type READONLY,
		@po_AsuntoDocumentoId INT OUTPUT, 
		@po_NombreArchivo  VARCHAR(50) OUTPUT,
		@pi_AgendaId BIGINT = NULL, 
		@pi_ResultadoId INT = NULL,
		@pi_PonenciaId INT = NULL,
		@pi_TipoAcuerdoId INT = NULL
		,@pi_EtapaProcesalId INT = NULL
		,@pi_SintesisIA VARCHAR(MAX) = NULL
		,@pi_TipoAudienciaId INT = NULL
		,@pi_SegundaAgendaId  BIGINT = NULL
		,@pi_SegundaAudienciaId INT = NULL


)
AS
BEGIN
	SET NOCOUNT ON
		BEGIN TRY

			DECLARE @IsOpcionActiva BIT
            DECLARE @CatAutorizacionId INT
			DECLARE @AsuntoId INT
			/***Sentencia***/
			DECLARE @TipoArchivo INT = 0
			DECLARE @Sigilo BIT = 0
			DECLARE @SentenciaDefinitiva BIT = 0
			DECLARE @EsJDA BIT = 0 
			DECLARE @TitularId BIGINT
			DECLARE @SecretarioPId BIGINT
			DECLARE @SecretarioCId BIGINT = 0
			DECLARE @ActuarioId BIGINT = 0
			DECLARE @Resumen NVARCHAR(MAX) = NULL
			DECLARE @CatOrganismoId INT
			DECLARE @EstatusArchivo INT = 1
			DECLARE @IPUsuario [varchar](50)
			DECLARE @UsuarioCaptura BIGINT
			DECLARE @IdOrigen INT = 7
			DECLARE @TipoOrigen INT = 7
			DECLARE @VersionPub INT = 0
			DECLARE @InfoReservada INT = 0
			DECLARE @Perspectiva INT = 0
			DECLARE @Criterio INT = NULL
			DECLARE @Trascedental INT = NULL
			DECLARE @EsTratadoInternacional INT = 0
			DECLARE @TipoActo INT = 0
			DECLARE @NombreTratado INT = 0
			DECLARE @Derecho INT = 0
			DECLARE @SubClasificacionDerecho INT = 0
			DECLARE @TipoActoOtro varchar(200) = NULL
			DECLARE @SolicitudReparacion  INT = NULL
			DECLARE @SolicitudReparacionOpcion INT = 0
			DECLARE @SolicitudReparacionOtro VARCHAR(200)
			DECLARE @LecturaFacil BIT = NULL
			DECLARE @TemaEquidadGenero INT = 0
			DECLARE @AplicacionEfectivaDerechoMujeres BIT = NULL
			DECLARE @TemaAsuntosInternacionales INT = 0
			DECLARE @AplicacionCriteriosPersGenero INT=NULL
			DECLARE @CriterioPerspecGenAplicado VARCHAR(500)
			DECLARE @Justificacion varchar(255) = NULL
			DECLARE @CountExist INT = 0
			DECLARE @FechaExpediente DATETIME
			DECLARE @GuidDocumento UNIQUEIDENTIFIER = NEWID()
            DECLARE @IdTipoRuta INT
			DECLARE @fkIdPonenciaEmpleado INT

			
            /* SE VALIDA QUE LA TABLA TEMPORAL NO EXISTA */ 
            IF OBJECT_ID('tempdb..#tmpPromociones') IS NOT NULL 
                    DROP TABLE #tmpPromociones; 
         
			DECLARE @OrganismoId INT

			SELECT @CatOrganismoId = CatOrganismoId, @AsuntoId = ISNULL(AsuntoId,1), @FechaExpediente = FechaAlta
			FROM Asuntos
			WHERE AsuntoNeunId = @pi_AsuntoNeunId AND StatusReg = 1
			
			 
			--IF CAST(@pi_FechaAcuerdo AS DATE) < CAST(@FechaExpediente AS DATE)
					--THROW 51000,'Fecha de presentación de acuerdo no puede ser inferior a fecha de expediente',1;

			
            SELECT @IdTipoRuta = rc.kId
            FROM  CAT_RutasChunk rc 
            WHERE rc.iGrupo = 1 
            AND rc.iEscritura = 1

			DECLARE @AsuntoDocumentoId INT
			DECLARE @SintesisOrden INT
			DECLARE @NombreArchivo VARCHAR(100)
			SET @SintesisOrden = (SELECT ISNULL(MAX(SintesisOrden),0)+1 FROM SintesisAcuerdoAsunto WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId) 
			 
			DECLARE @ClasificaCuaderno INT
			DECLARE @TipoAsunto INT
			SET @TipoAsunto=(SELECT CatTipoAsuntoId from Asuntos WITH(NOLOCK) where AsuntoNeunId=@pi_AsuntoNeunId and AsuntoId=@AsuntoId)

			 IF @TipoAsunto IN (1,2,4,46,67,74,109,124)
				BEGIN
					SET @ClasificaCuaderno = (SELECT dbo.fnObtieneClasificacionCuadernoDeTipoCuaderno (@pi_TipoCuaderno))
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

			IF ISNULL(@pi_NombreDocumento, '') <> '' 
				SET @po_NombreArchivo = dbo.fnPonCeros(CAST(@CatOrganismoId AS VARCHAR(50)),4)+dbo.fnPonCeros(CAST(@pi_AsuntoNeunId AS VARCHAR(50)),12)+ dbo.fnPonCeros(CAST(@AsuntoDocumentoId AS VARCHAR(50)),3) 

            IF(@AsuntoDocumentoId IS NULL OR @AsuntoDocumentoId = 0  )
                BEGIN

					SELECT @pi_NumeroOrdenSentencia = ISNULL(MAX(NumeroOrdenSentencia),0)+1 
					FROM DeterminacionesJudiciales  WITH(NOLOCK) 
					WHERE AsuntoNeunId = @pi_AsuntoNeunId

					SELECT @AsuntoDocumentoId = ISNULL(MAX(AsuntoDocumentoId),0)+1
					FROM AsuntosDocumentos WITH(NOLOCK)
					WHERE AsuntoNeunId = @pi_AsuntoNeunId

					SELECT @SintesisOrden = ISNULL(MAX(SintesisOrden),0)+1 
					FROM SintesisAcuerdoAsunto WITH(NOLOCK) 
					WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					
					DECLARE @TipoCuadernoSise1 VARCHAR(50)
					SET @TipoCuadernoSise1=dbo.fnObtieneATipoSISE2aSISE1(@pi_TipoCuaderno,null)
                
					SET @pi_NumeroOrdenDet = (SELECT isnull(MAX(NumeroOrden),0)+1 
					FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId)

					SET @po_NombreArchivo = dbo.fnPonCeros(CAST(@CatOrganismoId AS VARCHAR(50)),4)
												+ dbo.fnPonCeros(CAST(@pi_AsuntoNeunId AS VARCHAR(50)),12) 
												+ dbo.fnPonCeros(CAST(@AsuntoDocumentoId AS VARCHAR(50)),3) 

				END
			ELSE 
			BEGIN 
                    /* ACTUALIZACION DE SINTESIS */
                        
                    SELECT @IsOpcionActiva = Activa 
                    FROM ConfiguracionSISE WITH(NOLOCK) 
                    WHERE ConfiguracionOpcionSISEId = 6 
                    AND CatOrganismoId = @CatOrganismoId

					SELECT @CatAutorizacionId =CatAutorizacionDocumentosId,
                    @SintesisOrden = SintesisOrden, 
					@po_NombreArchivo = IIF(ISNULL(@po_NombreArchivo, '')='', NombreArchivo , @po_NombreArchivo), 
					@pi_ExtensionDocumento = IIF(ISNULL(@pi_ExtensionDocumento, '')='', ExtensionDocumento , @pi_ExtensionDocumento) 
					FROM AsuntosDocumentos WITH(NOLOCK)
					WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					AND AsuntoDocumentoId = @AsuntoDocumentoId

					SET @SintesisOrden = @pi_SintesisOrden
					/*REVISAR SI SE ACTUALIZA CUANDO SE ACTUALIZA EL DOCUMENTO */
					--SET @pi_NumeroOrdenDet = (SELECT isnull(MAX(NumeroOrden),0) FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @SintesisOrden )
					
					SELECT @pi_NumeroOrdenSentencia = NumeroOrdenSentencia,
						@pi_NumeroOrdenDet = NumeroOrden
					FROM DeterminacionesJudiciales  WITH(NOLOCK) 
					WHERE AsuntoNeunId = @pi_AsuntoNeunId
					AND SintesisOrden = @SintesisOrden

					IF(@pi_NumeroOrdenDet = 0 OR @pi_NumeroOrdenDet IS NULL)
					BEGIN 
						SET @pi_NumeroOrdenDet = (SELECT isnull(MAX(NumeroOrden),0) FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId )
					END
		END
		
			/* SE CREA LA SINTESIS */
			MERGE INTO SintesisAcuerdoAsunto trg
			USING 
			(	SELECT @SintesisOrden AS SintesisOrden, @AsuntoId AS AsuntoId, @pi_AsuntoNeunId AS AsuntoNeunId, @CatOrganismoId AS CatOrganismoId
					    ,@pi_FechaAcuerdo AS FechaAcuerdo, NULL AS Sintesis
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
			DECLARE @date DATETIME 
			SET @date = GETDATE()
			DECLARE @pi_CatAutorizacionDocumentosId INT
			SET @pi_CatAutorizacionDocumentosId = IIF(@CatAutorizacionId IS NULL, 1, CASE WHEN @CatAutorizacionId IN (4,8,9)  THEN 5 ELSE @CatAutorizacionId END)

			MERGE INTO [AsuntosDocumentos] tra
			USING 
			(	SELECT  @pi_AsuntoNeunId AS AsuntoNeunId, @AsuntoId AS AsuntoId, @AsuntoDocumentoId AS AsuntoDocumentoId, @pi_NombreDocumento AS NombreDocumento,'' AS RutaDocumento
			   , @po_NombreArchivo AS NombreArchivo, IIF(@CatAutorizacionId IS NULL, 1, @CatAutorizacionId) AS CatAutorizacionDocumentosId, @pi_ExtensionDocumento AS ExtensionDocumento, 0 AS CatPlantillaId, @pi_Contenido AS CatContenidoId
			   , '' AS ContenidoDocumento, CONVERT(varbinary(max),'') AS ContenidoAsunto, @SintesisOrden AS SintesisOrden, @pi_TipoCuaderno AS TipoCuaderno
			   , @TipoArchivo AS TipoArchivo, @Sigilo AS Sigilo, @SentenciaDefinitiva AS SentenciaDefinitiva, @EsJDA AS esJDA, @SecretarioPId AS SecretarioPId
			   , @SecretarioCId AS SecretarioCId, @TitularId AS TitularId,@pi_UsuarioCaptura AS UsuarioCaptura, @Resumen AS Resumen, @pi_FechaAcuerdo AS FechaAcuerdo, @IdTipoRuta TipoRuta
			   , @GuidDocumento AS uGuidDocumento
			)AS asd
					ON (tra.AsuntoNeunId = asd.AsuntoNeunId AND tra.AsuntoDocumentoId = asd.AsuntoDocumentoId 
						/*AND tra.SintesisOrden = asd.SintesisOrden*/
						)
					
					WHEN NOT MATCHED THEN  
					 INSERT ([AsuntoNeunId],[AsuntoID],[AsuntoDocumentoId],[NombreDocumento],[RutaDocumento],[NombreArchivo],[CatAutorizacionDocumentosId],[ExtensionDocumento]
								 ,[CatPlantillaId],[CatContenidoId],[ContenidoDocumento],[ContenidoAsunto],[SintesisOrden],[TipoCuaderno],[TipoArchivo],[Sigilo] 
								 ,[SentenciaDefinitiva],[esJDA] ,[SecretarioPId] ,[SecretarioCId] ,[TitularId],[CreadorId],[Resumen],[FechaAlta],[TipoRuta], [uGuidDocumento]
								)
					 VALUES (asd.AsuntoNeunId,asd.AsuntoID, asd.AsuntoDocumentoId, asd.NombreDocumento + @pi_ExtensionDocumento, asd.RutaDocumento, asd.NombreArchivo, asd.CatAutorizacionDocumentosId, asd.ExtensionDocumento
								,asd.CatPlantillaId,asd.CatContenidoId, asd.ContenidoDocumento, asd.ContenidoAsunto,asd.SintesisOrden,asd.TipoCuaderno,asd.TipoArchivo,asd.Sigilo
								,asd.SentenciaDefinitiva, asd.esJDA, asd.SecretarioPId, asd.SecretarioCId, asd.TitularId, asd.UsuarioCaptura, asd.Resumen, asd.FechaAcuerdo , asd.TipoRuta, uGuidDocumento
								)
					
					WHEN MATCHED THEN
					  UPDATE SET NombreDocumento = CASE WHEN ISNULL(@pi_NombreDocumento,'') <> '' THEN asd.NombreDocumento + @pi_ExtensionDocumento ELSE tra.NombreDocumento END
                         , TipoCuaderno = asd.TipoCuaderno
                         , ContenidoDocumento = asd.ContenidoDocumento
						 , CatContenidoId = asd.CatContenidoId
                         , ContenidoAsunto = asd.ContenidoAsunto
                         , CatAutorizacionDocumentosId = CASE WHEN asd.CatAutorizacionDocumentosId IN (4,8,9)  THEN 5 ELSE asd.CatAutorizacionDocumentosId END
						 , uGuidDocumento = CASE WHEN asd.CatAutorizacionDocumentosId IN (4,8,9)  THEN NEWID() ELSE tra.uGuidDocumento END
                         , Firmado = CASE WHEN asd.CatAutorizacionDocumentosId IN (4,8,9)  THEN 0 ELSE tra.Firmado END
						 , FechaAlta = asd.FechaAcuerdo
                         , NombreArchivo = asd.NombreArchivo
                         , CreadorId = asd.UsuarioCaptura
                         , ExtensionDocumento = asd.ExtensionDocumento;

			
			SELECT @fkIdPonenciaEmpleado = EmpleadoId FROM Areas WHERE AreaId = @pi_PonenciaId
			MERGE INTO SISE3.AsuntosDocumentosAdicional tra
			USING 
			(	SELECT  @pi_AsuntoNeunId AS AsuntoNeunId, 
						@AsuntoDocumentoId AS AsuntoDocumentoId,
						@pi_ExtensionDocumento AS ExtensionDocumentoOriginal,
						@pi_NombreDocumento AS NombreArchivoOriginal,
						@pi_AgendaId AS AgendaId,
						@pi_PonenciaId AS fkIdPonencia,
						@pi_TipoAcuerdoId AS TipoAcuerdoId,
						@fkIdPonenciaEmpleado AS fkIdPonenciaEmpleado
						,@pi_EtapaProcesalId AS EtapaProcesalId,
						@pi_SintesisIA AS SintesisIA
						,@pi_SegundaAgendaId As SegundaAgendaId
						,@pi_SegundaAudienciaId As SegundaAudienciaId

			)AS asd
			ON (tra.AsuntoNeunId = asd.AsuntoNeunId AND tra.AsuntoDocumentoId = asd.AsuntoDocumentoId)
			WHEN NOT MATCHED THEN  
				INSERT (AsuntoNeunId,
						AsuntoDocumentoId,
						ExtensionDocumentoOriginal,
						NombreArchivoOriginal,
						AgendaId,
						fkIdTipoAcuerdo,
						fkIdPonencia,
						fkIdPonenciaEmpleado,
						FechaElaboracion,
						EtapaProcesalId)
				VALUES(	
					asd.AsuntoNeunId,
					asd.AsuntoDocumentoId,
					asd.ExtensionDocumentoOriginal,
					asd.NombreArchivoOriginal,
					asd.AgendaId,
					asd.TipoAcuerdoId,
					asd.fkIdPonencia,
					asd.fkIdPonenciaEmpleado,
					GETDATE()
					,asd.EtapaProcesalId
				)
			WHEN MATCHED THEN			

				UPDATE SET  
						NombreArchivoOriginal = CASE WHEN ISNULL(asd.NombreArchivoOriginal,'') <> '' THEN asd.NombreArchivoOriginal ELSE tra.NombreArchivoOriginal END,
						ExtensionDocumentoOriginal = 
							CASE WHEN ISNULL(asd.NombreArchivoOriginal,'') <> '' 
								THEN asd.ExtensionDocumentoOriginal 
								ELSE CASE WHEN ISNULL(tra.ExtensionDocumentoOriginal,'') = '' AND SUBSTRING(@po_NombreArchivo, LEN(@po_NombreArchivo) - CHARINDEX('.',REVERSE(@po_NombreArchivo)) + 1, 100) <> '.pdf'
									THEN SUBSTRING(@po_NombreArchivo, LEN(@po_NombreArchivo) - CHARINDEX('.',REVERSE(@po_NombreArchivo)) + 1, 100)
									ELSE tra.ExtensionDocumentoOriginal END
								END,
						AgendaId=asd.AgendaId,
						SegundaAgendaId=asd.SegundaAgendaId,						
						fkIdTipoAcuerdo = asd.TipoAcuerdoId,
						fkIdPonencia = asd.fkIdPonencia,
						fkIdPonenciaEmpleado = asd.fkIdPonenciaEmpleado
						,EtapaProcesalId=asd.EtapaProcesalId,
						SintesisIA = CASE 
                          WHEN @pi_SintesisIA IS NOT NULL 
                          THEN @pi_SintesisIA 
                          ELSE tra.SintesisIA 
                          END;



			IF(@pi_AgendaId IS NOT NULL AND @pi_ResultadoId IS NOT NULL)
			BEGIN 
				UPDATE AUD_AsuntosDetalleFechas
				SET AudienciaID=@pi_TipoAudienciaId, ResultadoId = @pi_ResultadoId
				WHERE AgendaId = @pi_AgendaId
			END 


			SET @CargoTitular = (SELECT top 1 c.CargoId 
									FROM EmpleadoOrganismo eo WITH(NOLOCK) inner join CatCargo c WITH(NOLOCK) on eo.CargoId = c.CargoId 
									WHERE CatOrganismoId = @CatOrganismoId and eo.EmpleadoId = @TitularId and eo.StatusRegistro=1 and c.StatusReg=1)
			
			--SET @NombreArchivoCompleto =(SELECT NombreArchivo+''+ExtensionDocumento FROM AsuntosDocumentos WITH(NOLOCK) where AsuntoNeunId = @pi_AsuntoNeunId and SintesisOrden = @SintesisOrden and StatusReg=1)
			SET @NombreArchivoCompleto =(SELECT AD.NombreArchivo+''+
                                        --VALIDACIÓN PARA ESTADO DE AUTOS PROVENIENTES DE WORDSISE
                                        IIF( (DJ.TipoOrigen =5 AND AD.CatAutorizacionDocumentosId = 3 AND Firmado IS NULL AND AD.ExtensionDocumento = '.doc'),'.pdf',AD.ExtensionDocumento )
                                         FROM AsuntosDocumentos AD WITH(NOLOCK)
                                         LEFT JOIN DeterminacionesJudiciales DJ WITH(NOLOCK) ON AD.AsuntoNeunId = DJ.AsuntoNeunId AND AD.SintesisOrden = DJ.SintesisOrden
                                        where AD.AsuntoNeunId = @pi_AsuntoNeunId and AD.SintesisOrden = @SintesisOrden and AD.StatusReg=1 AND DJ.StatusReg=1)

			--VALIDACIÓN PARA TRUNCAR NOMBRE DE DOCUMENTO PARA DJ
			MERGE INTO DeterminacionesJudiciales dj
			USING 
			(	SELECT @AsuntoId AS AsuntoId, @pi_AsuntoNeunId AS AsuntoNeunId, @pi_NumeroOrdenDet AS NumeroOrden, @SintesisOrden AS SintesisOrden, @pi_TipoCuaderno AS TipoCuaderno,
				 @pi_Contenido AS Contenido, @TitularId AS TitularId , @CargoTitular AS CargoTitular, @SecretarioPId AS SecretarioPId, @ActuarioId AS ActuarioId,
				 @pi_FechaAcuerdo AS FechaAuto,@CatOrganismoId AS CatOrganismoId,LEFT(@pi_NombreDocumento, 150) AS NomArchivoReal, @EstatusArchivo EstatusArchivo,
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
				Origen,TipoOrigen,Justificacion,
				NumeroOrdenSentencia,TipoArchivo,Sigilo,SentenciaDefinitiva,EsJDA,
				VersionPub, InfoReservada,EsTratadoInternacional,TipoActo,NombreTratado,Derechos,SubClasificacionDerechos,
				SolicitudReparacionOpcion,Fojas,TemaEquidadGenero,TemaAsuntosInternacionales)	
				VALUES (det.AsuntoId ,det.AsuntoNeunId ,det.NumeroOrden ,det.SintesisOrden ,det.TipoCuaderno ,det.Contenido ,det.TitularId ,det.CargoTitular,det.SecretarioPId,det.ActuarioId,
				det.FechaAuto, det.CatOrganismoId,det.NombreArchivo,det.NomArchivoReal + @pi_ExtensionDocumento,det.EstatusArchivo,det.IPUsuario,det.FechaAlta,det.FechaBaja,det.UsuarioCaptura,det.StatusReg,
				det.Origen,det.TipoOrigen,det.Justificacion,
				det.NumeroOrdenSentencia, det.TipoArchivo, det.Sigilo,det.SentenciaDefinitiva,det.EsJDA,
				det.VersionPub, det.InfoReservada,det.EsTratadoInternacional,det.TipoActo,det.NombreTratado,det.Derechos,det.SubClasificacionDerechos,
				det.SolicitudReparacionOpcion,0,det.TemaEquidadGenero,det.TemaAsuntosInternacionales)	
			
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
					,Justificacion= det.Justificacion
					,NumeroOrden = @pi_NumeroOrdenDet
					,Contenido=det.Contenido
					,FechaAuto=@pi_FechaAcuerdo;--SBGE 07/04/2025
			
							  
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
                    
			END


			DECLARE @po_NumOrdenNotificacion INT
            SET @po_NumOrdenNotificacion = (SELECT  ISNULL(MAX(NumeroOrden), 0) + 1 FROM NotificacionElectronica WITH(NOLOCK) 
											WHERE AsuntoNeunId=@pi_AsuntoNeunId)           
            
		
			IF NOT EXISTS(SELECT TOP 1 [AsuntoNeunId] 
			   FROM [NotificacionElectronica] 
			   WHERE [CatOrganismoId] = @CatOrganismoId
			    AND  [AsuntoNeunId] = @pi_AsuntoNeunId
				AND  [SintesisOrden] = @SintesisOrden
				AND  [StatusReg] in (1,2))--SBGE 19/05/2025 Se considera status 2 ya que la notificacion electronica puede existir con ese estatus hasta que se preautoriza y autoriza el acuerdo cambia a 1
				
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
					,2
					,NULL
					,0
					,@pi_IPUsuario
					,1
					,1)
				EXEC piPermisoDeterminacionJudicial @AsuntoId, @pi_AsuntoNeunId, @pi_NumeroOrdenDet, @SintesisOrden
            END
				
			

			DECLARE @dt datetime
            SET @dt = getdate() 


			/*Insert oficio autoridad juidical*/
			/*IF EXISTS(SELECT * FROM @pi_PartePromoventeNotificacion WHERE TipoNotificacionId IN (5,11))
			BEGIN 
				CREATE TABLE #Temppartes
					(folio INT, 
					 AnexoParteId INT, 
					 TipoAnexoId INT, 
					 AnexoParteDescripcion varchar(max)
					)
				
				UPDATE Anexos 
				SET AnexoStatus = 0, FechaBaja = GETDATE(), Texto = 'Cancelado desde trámite.'
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND AsuntoDocumentoId = @AsuntoDocumentoId
				AND AnexoParteId NOT IN (	SELECT ISNULL(PersonaId,PromoventeId)
											FROM @pi_PartePromoventeNotificacion
											WHERE TipoNotificacionId IN (5,11)
										)
				AND AnexoStatus <> 0

				DELETE EstadoOficio
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND ParteId NOT IN (	SELECT ISNULL(PersonaId,PromoventeId)
										FROM @pi_PartePromoventeNotificacion
										WHERE TipoNotificacionId IN (5,11)
									)
				AND AsuntoDocumentoId = @AsuntoDocumentoId

				DECLARE @Oficios SISE3.AutoridadAsunto_type
				INSERT INTO @Oficios (TipoAnexoId,AnexoParteId,AnexoParteDescripcion, TextoOficioLibre)
				SELECT TipoAnexoId, ISNULL(PersonaId,PromoventeId), NombreParte, TextoOficioLibre
				FROM @pi_PartePromoventeNotificacion
				WHERE TipoNotificacionId IN (5,11)

				INSERT INTO #Temppartes
				EXEC [SISE3].[piInsertaAnexosOficio]
				@pi_AsuntoNeunId ,
				@CatOrganismoId ,  
				2 ,
				@AsuntoDocumentoId ,
				@Oficios,  
				@po_NombreArchivo,
				@pi_ExtensionDocumento,
				@GuidDocumento
					
			END 
			ELSE 
			BEGIN 
				UPDATE Anexos 
				SET AnexoStatus = 0, FechaBaja = GETDATE(), Texto = 'Cancelado desde trámite'
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND AsuntoDocumentoId = @AsuntoDocumentoId
				AND AnexoStatus <> 0

				DELETE EstadoOficio
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND AsuntoDocumentoId = @AsuntoDocumentoId
			END
			*/
				
			/*Insert notificación electronica*/
				IF EXISTS(SELECT * FROM @pi_PartePromoventeNotificacion WHERE TipoNotificacionId > 0)
				BEGIN 
			
			                                 
					DECLARE @PersonasNotificacion_temp  [SISE3].[PersonasNotificacionIndividual_type]
				
					--IF EXISTS(SELECT * FROM @pi_PersonasNotificacion  a WHERE a.[TipoNotificacionId] = 3)
					--BEGIN    
					--		Print 'Personas'

							INSERT INTO @PersonasNotificacion_temp(PersonaId,PromoventeId,TipoNotificacionId,TipoPromovente,NumIntentosNotificacion,TieneCOE)							
							SELECT PersonaId, PromoventeId, TipoNotificacionId,0,0,TieneCOE 
							FROM @pi_PartePromoventeNotificacion  a
																				   

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


EXEC SISE_NEWLOG.dbo.usp_BitacoraAsuntoDocumentosIns @pi_AsuntoNeunId,@AsuntoDocumentoId,@pi_CatAutorizacionDocumentosId,@date,@pi_UsuarioCaptura
						

			/* Retorno la Información Requerida */
            SELECT @AsuntoDocumentoId AS AsuntoDocumentoId
                ,@SintesisOrden AS SintesisOrden
                ,@CatOrganismoId AS CatOrganismoId
				,@po_NombreArchivo AS NombreArchivo
				,@pi_NumeroOrdenDet AS NumeroOrden
				,@GuidDocumento AS GuidDocumento
        END TRY 
        BEGIN CATCH
                -- Ejecuta la rutina de recuperacion de errores.
                EXECUTE dbo.usp_GetErrorInfo;
        END CATCH;

END