USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piInsertarNotificacionesOficio]    Script Date: 12/1/2023 6:27:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Diana Quiroga - MS
-- Create date: 28/08/2023 
-- Description: Registra un nuevo expediente, promoción y archivo de promoción
-- Basado en: usp_EXPE_PromocionOficialiaIns
-- ============================================= 

CREATE procedure [SISE3].[piInsertarNotificacionesOficio]
@pi_AsuntoNeunId [bigint],
@pi_AsuntoId [int],
@pi_SintesisOrden [int],
@pi_CatOrganismoId [int],
@pi_TipoCuadernoId [int],
@pi_TipoConstanciaId [int],
@pi_ActuarioId [int],
@pi_RegistroEmpleadoId [int],
@pi_IpUsuario VARCHAR(16),
@pi_PersonasNotificacion [PersonasNotificacionIndividual] READONLY,
@po_NombreArchivo VARCHAR(50) OUTPUT,
@po_NumOrden INT OUTPUT,
@pi_IdOrigen INT = 3 --Notificaciones Judiciales

AS
BEGIN
       SET NOCOUNT ON
       BEGIN TRY
             BEGIN TRAN
				
                    -----------Control PartesNotificacion 03/06/2016 -------------------
                    DECLARE @personaIdTmp INT
                    DECLARE @promoventeIdTmp INT
                    DECLARE @tipoNotificacionTmp INT
					DECLARE @TipoConstanciaIdTmp INT
					DECLARE @DescripcionConstanciaTmp VARCHAR(200)
					DECLARE @TipoPromoventeTmp SMALLINT --SBGE NUEVO CAMPO 19072018
					DECLARE @NumIntentosNotificacion INT --Nuevo campo 12/feb/2019
					DECLARE @PartesNotificacion TABLE(PersonaId INT, PromoventeId INT, TipoNotificacionId INT, TipoConstanciaId INT, DescripcionConstancia VARCHAR(200), TipoPromovente SMALLINT,NumIntentosNotificacion INT, Upd INT)--SBGE NUEVO CAMPO 19072018
				  
				    INSERT INTO @PartesNotificacion (PersonaId, PromoventeId, TipoNotificacionId, TipoConstanciaId, DescripcionConstancia, TipoPromovente,NumIntentosNotificacion, Upd)--SBGE NUEVO CAMPO 19072018
					SELECT PersonaId, PromoventeId, TipoNotificacionId, TipoConstanciaId, DescripcionConstancia, isnull(TipoPromovente,0),NumIntentosNotificacion, 0--SBGE NUEVO CAMPO 19072018
					FROM @pi_PersonasNotificacion

                    WHILE EXISTS(SELECT 1 FROM @PartesNotificacion WHERE Upd = 0)
                    BEGIN 
                           SELECT TOP 1 @personaIdTmp = PersonaId, @promoventeIdTmp = PromoventeId, @tipoNotificacionTmp = TipoNotificacionId, 
							@TipoConstanciaIdTmp = TipoConstanciaId,
							@DescripcionConstanciaTmp = DescripcionConstancia, 
							@TipoPromoventeTmp = TipoPromovente,--SBGE NUEVO CAMPO 19072018
							@NumIntentosNotificacion = NumIntentosNotificacion
							FROM @PartesNotificacion WHERE Upd = 0	

                           IF EXISTS(SELECT 1 FROM NotificacionElectronica_Personas 
												        WHERE AsuntoNeunId = @pi_AsuntoNeunId 
														AND SintesisOrden = @pi_SintesisOrden 
                                                        AND ISNULL(PersonaId, 0) = @personaIdTmp 
														AND ISNULL(PromoventeId,0) = @promoventeIdTmp 
														AND ISNULL(NumIntentosNotificacion,0) = @NumIntentosNotificacion
														AND statusReg = 1)
                           BEGIN
                                 SET @po_NumOrden = 0
                           END
                           ELSE
                           BEGIN            
                                  IF NOT EXISTS(SELECT 1 FROM  NotificacionElectronica WHERE AsuntoNeunId=@pi_AsuntoNeunId AND SintesisOrden=@pi_SintesisOrden AND StatusReg=1)
                                  BEGIN              
									SET @po_NumOrden = (SELECT  ISNULL(MAX(NumeroOrden), 0) + 1 FROM NotificacionElectronica WITH(NOLOCK) WHERE AsuntoNeunId=@pi_AsuntoNeunId)
              
                                        INSERT INTO NotificacionElectronica (AsuntoNeunId,AsuntoId,SintesisOrden,NumeroOrden,CatOrganismoId,TipoCuadernoId,
                                                                   RegistroEmpleadoId,FechaAlta,FechaActualiza,StatusReg,NombreArchivo,NombreArchivoReal,EstatusArchivo,IpUsuario,ObservacionesArchivo,ConsecutivoArchivo, [UbicacionNombreArchivo] )
                                        VALUES(@pi_AsuntoNeunId, @pi_AsuntoId, @pi_SintesisOrden, @po_NumOrden, @pi_CatOrganismoId, @pi_TipoCuadernoId
                                               , @pi_RegistroEmpleadoId, GETDATE(), NULL, 1, NULL, NULL, 0, NULL, NULL, 1, 1)
                                  END              
                                  SELECT @po_NumOrden = MAX([NumeroOrden]) FROM [NotificacionElectronica] WITH(NOLOCK)
                                  WHERE AsuntoNeunId = @pi_AsuntoNeunId AND StatusReg = 1 AND SintesisOrden = @pi_SintesisOrden
            
                                  DECLARE @NombreArchivo varchar(50)
                                  SET @NombreArchivo = dbo.fnPonCeros(CAST(@pi_CatOrganismoId AS VARCHAR(50)), 4)
                                                            + dbo.fnPonCeros(CAST(@pi_AsuntoNeunId AS VARCHAR(50)), 12)
                                                            + dbo.fnPonCeros(CAST(@pi_SintesisOrden AS VARCHAR(50)), 4)
                                                            + dbo.fnPonCeros(CAST(@po_NumOrden AS VARCHAR(50)), 4)
                                                            + [dbo].[fnPonCeros](CAST(CASE @personaIdTmp WHEN 0 THEN @promoventeIdTmp ELSE @personaIdTmp END AS VARCHAR(50)), 12)
                                                            + [dbo].[fnPonCeros]('1', 2)
            
								  IF NOT EXISTS (SELECT TOP 1 AsuntoNeunId 
												 FROM NotificacionElectronica_Personas
												 WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden =  @pi_SintesisOrden AND PersonaId = @personaIdTmp)
								  BEGIN 
									INSERT INTO NotificacionElectronica_Personas WITH(ROWLOCK)
                                        (AsuntoId, AsuntoNeunId, NumeroOrden, SintesisOrden, PersonaId, FechaAlta, StatusReg, PromoventeId,      
											 TipoNotificacion, Origen, NotificacionElectronicaJL, TipoConstanciaId, 
											 DescripcionTipoConstancia,ActuarioId,TipoPromovente,NumIntentosNotificacion)    --SBGE NUEVO CAMPO 19072018     
									SELECT @pi_AsuntoId 
                                               ,@pi_AsuntoNeunId
                                               ,@po_NumOrden 
											   ,@pi_SintesisOrden 
											   ,@personaIdTmp
											   ,GETDATE()
                                               ,1
                                               ,@promoventeIdTmp
                                               ,@tipoNotificacionTmp
                                               ,@pi_IdOrigen                                         
                                               ,CASE @tipoNotificacionTmp WHEN 3 THEN 4157 ELSE NULL END
                                               , ISNULL(@TipoConstanciaIdTmp, @pi_TipoConstanciaId)
											   ,@DescripcionConstanciaTmp	
                                               ,@pi_ActuarioId
											   ,@TipoPromoventeTmp --SBGE NUEVO CAMPO 19072018  
											   ,@NumIntentosNotificacion 
								END
								ELSE 
								BEGIN
									UPDATE NotificacionElectronica_Personas 
									SET DescripcionTipoConstancia = @DescripcionConstanciaTmp,
										TipoPromovente = @TipoPromoventeTmp,
										NumIntentosNotificacion = @NumIntentosNotificacion, 
										TipoNotificacion = @tipoNotificacionTmp 
									WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden =  @pi_SintesisOrden AND PersonaId = @personaIdTmp
								 END 
												   
                                  IF  @tipoNotificacionTmp = 3 AND @personaIdTmp != 0
                                  BEGIN
									   INSERT INTO JL_REL_NotificacionesMovil (AsuntoNeunId
														,AsuntoId
														,SintesisOrden
														,NumeroOrden
														,PersonaId
														,EstatusMovil
														,EmpleadoId
														,FechaAlta
														,Activo)  
												  SELECT @pi_AsuntoNeunId AS AsuntoNeunId        -- AsuntoNeunId - bigint
														,@pi_AsuntoId AS AsuntoId                      -- AsuntoId - int
														,@pi_SintesisOrden AS SintesisOrden            -- SintesisOrden - int
														,@po_NumOrden AS NumeroOrden                   -- NumeroOrden - int
														,@personaIdTmp AS PersonaId                           -- PersonaId - int
														,'No Visto' AS EstatusMovil                           -- EstatusMovil - varchar(50)
														,@pi_RegistroEmpleadoId AS EmpleadoId          -- EmpleadoId - int
														,GETDATE() AS FechaAlta                               -- FechaAlta - datetime
														,1 AS Activo                                          -- Activo - bit
					--                                         
												  END
                           END
                           UPDATE @PartesNotificacion SET Upd = 1 WHERE PersonaId = @personaIdTmp AND isnull(PromoventeId,0) = isnull(@promoventeIdTmp, 0) AND TipoNotificacionId = @tipoNotificacionTmp
                    END    
       ------------------Termina Control PartesNotificacion------------------------------    
  END TRY
  BEGIN CATCH
    -- Ejecuto ROLLBACK solo en caso de error
       IF @@TRANCOUNT > 0
         ROLLBACK TRANSACTION;
             -- Ejecuta la rutina de recuperacion de errores.
             EXECUTE dbo.usp_GetErrorInfo;
  END CATCH;        
  -- Completo mi transaccion
  IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
  SET NOCOUNT OFF
END




GO

