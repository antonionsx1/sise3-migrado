SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  11/09/2013
-- Description: Registra un anexo en la tabla PromocionArchivos basado en uspx_op_addDocumento
-- Basado en:   [SISE3].[piInsertaDocumento] 
-- =============================================


CREATE OR ALTER PROCEDURE [SISE3].[piInsertaDocumento] 
(
        @pi_AsuntoNeunId bigint,
        @pi_YearPromocion int,
        @pi_NumeroOrden int,
        @pi_RegistroEmpleadoId int,
        @pi_Clase int,
        @pi_Descripcion int,
        @pi_Caracter int,
        @pi_Fojas smallint,
		@pi_Origen int, 
		@pi_NombreArchivoReal [nvarchar] (150) = null,
        @po_NombreArchivo varchar(50) output,
        @po_NumeroConsecutivo int output
       
        
)
AS
BEGIN
        SET NOCOUNT ON
                DECLARE @CatOrganismoId INT
                DECLARE @AsuntoId INT
                DECLARE @NumeroRegistro INT
                DECLARE @pi_ClaseSISE1 INT
                DECLARE @pi_DescripcionSISE1 INT 
                DECLARE @pi_CaracterSISE1 INT
                DECLARE @pi_NumeroConsecutivo INT = null
                DECLARE @pi_PromoFileIdentificador UNIQUEIDENTIFIER = null      
                DECLARE @insertaAnexo INT = 1
                DECLARE @IdRuta INT
                
                
                SET @pi_ClaseSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(1,@pi_Clase)
                SET @pi_DescripcionSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(2,@pi_Descripcion)
                SET @pi_CaracterSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(3,@pi_Caracter)

                --Asigno ID de ruta actual para guardar relación de archivo con ruta
                SELECT @IdRuta = kId FROM Cat_RutasChunk rc
                WHERE rc.iGrupo = 2 AND rc.iEscritura = 1 
                                
                SELECT  @CatOrganismoId = a.CatOrganismoId,
                              @AsuntoId = a.AsuntoId,
                        @NumeroRegistro = p.NumeroRegistro
                FROM Asuntos a 
                INNER JOIN Promociones p ON a.AsuntoNeunId = p.AsuntoNeunId
                WHERE a.AsuntoNeunId = @pi_AsuntoNeunId
                AND p.YearPromocion = @pi_YearPromocion
                AND p.NumeroOrden = @pi_NumeroOrden
                
				--SELECT @CatOrganismoId, @AsuntoId, @NumeroRegistro,@pi_RegistroEmpleadoId
                                
                --QUE EL EMPLEADO PERTENEZCA AL ORGANISMOS DEL ASUNTO
                IF NOT EXISTS(  SELECT TOP 1 IdCatEmpleado 
                                                FROM SISE3.REL_RolEmpleadoXOrganismo 
                                                WHERE IdCatEmpleado = @pi_RegistroEmpleadoId
												AND IdOrganismo = @CatOrganismoId
                                                AND bStatus = 1 
                                               -- AND CatOrganismoId IN(@CatOrganismoId,3)
											   )
				BEGIN 
                        SET @insertaAnexo = 0--CON CERO INDICAMOS QUE EL USUARIO NO PERTENECE AL ORGANO DEL ASUNTO POR LO TANTO NO INSERTA 
				END

		IF @po_NumeroConsecutivo is null or @po_NumeroConsecutivo = 0
		BEGIN
                SET @pi_NumeroConsecutivo=(SELECT isnull(max(Consecutivo),0) + 1 as nroConsecutivo
                                                                                FROM PromocionArchivos With(NoLock) 
                                                                                WHERE AsuntoNeunId =@pi_AsuntoNeunId 
                                                                                AND AsuntoId=@AsuntoId 
                                                                                AND YearPromocion =@pi_YearPromocion 
                                                                                AND NumeroRegistro =@NumeroRegistro 
                                                                                AND NumeroOrden = @pi_NumeroOrden)
                SET @po_NumeroConsecutivo = @pi_NumeroConsecutivo

				IF (@pi_Clase= 0)
				BEGIN
				SET @pi_NumeroConsecutivo = (SELECT isnull(max(Consecutivo),0) as nroConsecutivo
                                            FROM PromocionArchivos With(NoLock) 
                                            WHERE AsuntoNeunId =@pi_AsuntoNeunId 
                                            AND AsuntoId=@AsuntoId 
                                            AND YearPromocion =@pi_YearPromocion 
                                            AND NumeroRegistro =@NumeroRegistro 
                                            AND NumeroOrden = @pi_NumeroOrden
											AND ClaseAnexo = 0)
				SET @pi_NumeroConsecutivo = IIF(@pi_NumeroConsecutivo=0, @po_NumeroConsecutivo, @pi_NumeroConsecutivo)
				END

				select @pi_NumeroConsecutivo
         END        
		 ELSE 
		 BEGIN

			
			IF (@pi_Clase= 0)
			BEGIN
				SET @pi_NumeroConsecutivo = (SELECT isnull(max(Consecutivo),0) as nroConsecutivo
                                            FROM PromocionArchivos With(NoLock) 
                                            WHERE AsuntoNeunId =@pi_AsuntoNeunId 
                                            AND AsuntoId=@AsuntoId 
                                            AND YearPromocion =@pi_YearPromocion 
                                            AND NumeroRegistro =@NumeroRegistro 
                                            AND NumeroOrden = @pi_NumeroOrden
											AND ClaseAnexo = @pi_Clase)
				SET @pi_NumeroConsecutivo = IIF(@pi_NumeroConsecutivo=0, @po_NumeroConsecutivo, @pi_NumeroConsecutivo)
			END
			ELSE
			BEGIN
				SET @pi_NumeroConsecutivo = @po_NumeroConsecutivo
			END
		 END
                
                --El nombre se forma: 4 (corid) + 12 (Asuid) + 6 (Orden) + 6 (Registro)+ 3(Consecutivo) + 0(Significa que es capturada desde SISE 2.0)
                DECLARE @file VARCHAR(250)
                SET @file =     dbo.fnPonCeros(CAST(@CatOrganismoId AS VARCHAR(50)),4)
                                        + dbo.fnPonCeros(CAST(@pi_AsuntoNeunId AS VARCHAR(50)),12) 
                                        + dbo.fnPonCeros(CAST(@pi_NumeroOrden AS VARCHAR(50)),6)
                                        + dbo.fnPonCeros(CAST(@NumeroRegistro AS VARCHAR(50)),6) 
                                        + dbo.fnPonCeros(CAST(@pi_NumeroConsecutivo AS VARCHAR(50)),3)
                                        + CAST(@pi_Origen AS VARCHAR(2))
                                        + '.pdf'
                                        
                SET @po_NombreArchivo=@file
                
                BEGIN TRY
                        BEGIN TRAN              
                                IF (@insertaAnexo = 1)
                                BEGIN


										---Validar si existen archivos.
										MERGE INTO PromocionArchivos trg
										USING 
											( SELECT @CatOrganismoId AS CatOrganismoId, @pi_AsuntoNeunId AS AsuntoNeunId 
														,@AsuntoId AS AsuntoId, @pi_NumeroOrden AS NumeroOrden 
														,@NumeroRegistro AS NumeroRegistro, @pi_YearPromocion AS YearPromocion
														,@pi_NumeroConsecutivo AS Consecutivo, @pi_Origen AS Origen 
														,CAST(@file AS VARCHAR(50)) AS NombreArchivo
														,@pi_Clase AS ClaseAnexo, @pi_Descripcion AS DescripcionAnexo
														,@pi_Caracter AS CaracterAnexo, 1 AS StatusArchivo, GETDATE() AS FechaAlta
														,ISNULL(@pi_RegistroEmpleadoId,0) AS RegistroEmpleadoSISEId  
                                                        ,@pi_NombreArchivoReal AS NombreArchivoReal 
													    ,1 AS EstatusArchivo-- CUANDO EL DOCUMENTO ESTE EN LA SAN, FU LO CAMBIA A 1
                                                        ,@pi_Fojas AS Fojas
                                                        ,@idRuta AS RutaArchivoNAS
											) AS src
										ON (trg.CatOrganismoId = src.CatOrganismoId AND
										trg.AsuntoNeunId = src.AsuntoNeunId AND 
										trg.AsuntoId = src.AsuntoId AND
										trg.NumeroOrden = src.NumeroOrden AND 
										trg.NumeroRegistro = src.NumeroRegistro AND 
										trg.YearPromocion= src.YearPromocion AND
										trg.Consecutivo = src.Consecutivo AND
										trg.Origen = src.Origen)

										WHEN NOT MATCHED THEN  
											INSERT (CatOrganismoId, AsuntoNeunId ,AsuntoId ,NumeroOrden
											,NumeroRegistro, YearPromocion, Consecutivo, Origen                         
											,NombreArchivo, ClaseAnexo, DescripcionAnexo, CaracterAnexo
											,StatusArchivo, FechaAlta, RegistroEmpleadoSISEId, EstatusArchivo, NombreArchivoReal, Fojas, RutaArchivoNAS)
											VALUES(src.CatOrganismoId, src.AsuntoNeunId, src.AsuntoId, src.NumeroOrden
												,src.NumeroRegistro, src.YearPromocion, src.Consecutivo, src.Origen                         
												,src.NombreArchivo, src.ClaseAnexo, src.DescripcionAnexo, src.CaracterAnexo
												,src.StatusArchivo, src.FechaAlta, src.RegistroEmpleadoSISEId, src.EstatusArchivo, src.NombreArchivoReal, src.Fojas, src.RutaArchivoNAS)
										
										WHEN MATCHED THEN
											UPDATE SET StatusArchivo = IIF(@pi_NombreArchivoReal IS NOT NULL, 1,0)
													  ,EstatusArchivo = IIF(@pi_NombreArchivoReal IS NOT NULL, 1,0)
													  ,NombreArchivoReal = src.NombreArchivoReal
													  ,NombreArchivo = src.NombreArchivo
                                                      ,Fojas = src.Fojas
                                                      ,RutaArchivoNAS = src.RutaArchivoNAS
													  ,DescripcionAnexo = IIF(trg.DescripcionAnexo = 5031, trg.DescripcionAnexo,src.DescripcionAnexo)
													  ,CaracterAnexo = src.CaracterAnexo
													  ,ClaseAnexo = src.ClaseAnexo;
                                       
                                         
                                        SET @pi_PromoFileIdentificador = (SELECT PromoFileIdentificador 
                                         FROM PromocionArchivos with(rowlock) 
                                         WHERE CatOrganismoId = @CatOrganismoId 
                                         AND AsuntoNeunId = @pi_AsuntoNeunId 
                                         AND AsuntoId = @AsuntoId 
                                         AND NumeroOrden = @pi_NumeroOrden 
                                         AND NumeroRegistro = @NumeroRegistro 
                                         AND YearPromocion = @pi_YearPromocion
                                         AND Consecutivo = @pi_NumeroConsecutivo 
                                         AND Origen = @pi_Origen--0 
                                         AND StatusArchivo = 1)
                                        
                                                        
                                        EXEC usp_Promocion_Bitacora @CatOrganismoId,@pi_YearPromocion,@pi_NumeroOrden,@pi_Origen,6--el 6 es el origen(SISE) y el 3 indica que es una alta en tabla promocionArchivos de un anexo
                                END
                               /* ELSE
                                BEGIN
                                         RAISERROR ('El usuario que intenta insertar la promoción no es válido para el expediente', -- Texto del Mensaje
                                                16, -- Severity
                                                1       -- State
                                                );
                                END*/
               END TRY
                BEGIN CATCH
                 -- EJECUTO ROLLBACK SOLO EN CASO DE ERROR
                        IF @@TRANCOUNT > 0
                                ROLLBACK TRANSACTION;
                        -- EJECUTA LA RUTINA DE RECUPERACION DE ERRORES.
                        --EXECUTE dbo.usp_GetErrorInfo;
                END CATCH;
         -- COMPLETO MI TRANSACCION
                IF @@TRANCOUNT > 0
                        COMMIT TRANSACTION;
                        --IF (@CatOrganismoId IN (949,964,981,982,1275,1277,1281) and(@insertaAnexo=1))
                        --BEGIN
                        --EXEC sisecjfdb02.sise.dbo.usp_EXPE_PromocionAnexosArchivoSISE1Ins @CatOrganismoId,@pi_AsuntoNeunId,@pi_NumeroOrden,@NumeroRegistro,@pi_YearPromocion,@pi_NumeroConsecutivo,@file,@pi_ClaseSISE1,@pi_DescripcionSISE1,@pi_CaracterSISE1,@pi_PromoFileIdentificador
                        --END
                SET NOCOUNT OFF
        END
