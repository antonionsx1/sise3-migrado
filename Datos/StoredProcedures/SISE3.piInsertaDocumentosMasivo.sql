SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Christian Araujo MS
-- Alter date:  18/09/2013
-- Description: Registra un anexo en la tabla PromocionArchivos basado en uspx_op_addDocumento
-- Permite la carga masiva de archivos para ser asociados a diferentes promociones basado en el Año, numero de orden y numero de Organismo
-- Basado en: EXEC   [SISE3].[piInsertaDocumentosMasivo] 2023, 50161, 1494, 'CargaMasiva-x', 6712, null , null, null
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaDocumentosMasivo] 
(
        @pi_YearPromocion int,
        @pi_NumeroRegistro int,
        @pi_CatOrganismoId int,
        --@pi_Descripcion int,
        @pi_NombreArchivoReal [nvarchar] (150),
        @pi_RegistroEmpleadoId INT,
        @po_NumeroConsecutivo INT OUTPUT,
        @po_NombreArchivo VARCHAR(250) OUTPUT,
		@po_ExpedienteProcesado VARCHAR (50) OUTPUT
)
AS
BEGIN
        SET NOCOUNT ON
                DECLARE @CatOrganismoId INT
                DECLARE @AsuntoNeunId INT
                DECLARE @AsuntoId INT
                DECLARE @NumeroOrden INT
                DECLARE @pi_ClaseSISE1 INT
                DECLARE @pi_Descripcion int
                DECLARE @pi_DescripcionSISE1 INT 
                DECLARE @pi_CaracterSISE1 INT
                DECLARE @pi_NumeroConsecutivo INT = null
                DECLARE @pi_PromoFileIdentificador UNIQUEIDENTIFIER = null      
                DECLARE @insertaAnexo INT = 1
                DECLARE @pi_origen INT
                DECLARE @pi_Clase INT = 0
                DECLARE @pi_Caracter INT = 0
                DECLARE @IdRuta INT

                SET @pi_ClaseSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(1,@pi_Clase)
                SET @pi_DescripcionSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(2,@pi_Descripcion)
                SET @pi_CaracterSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(3,@pi_Caracter)
                                
                SELECT  @CatOrganismoId = a.CatOrganismoId,
                              @AsuntoId = a.AsuntoId,
                        @NumeroOrden = p.NumeroOrden,
                        @AsuntoNeunId = a.AsuntoNeunId,
                        @pi_origen = p.OrigenPromocion
                FROM Asuntos a 
                INNER JOIN Promociones p ON a.AsuntoNeunId = p.AsuntoNeunId
                WHERE a.CatOrganismoId = @pi_CatOrganismoId
                AND p.YearPromocion = @pi_YearPromocion
                AND p.NumeroRegistro = @pi_NumeroRegistro
				AND p.StatusReg = 1

				IF @NumeroOrden IS NULL
					THROW 51000,'Promoción inexistente',1;
					

                SELECT @IdRuta = kId FROM Cat_RutasChunk rc
                WHERE rc.iGrupo = 2 AND rc.iEscritura = 1 
                
				--SELECT @CatOrganismoId, @AsuntoId, @NumeroRegistro,@pi_RegistroEmpleadoId
                                
                --QUE EL EMPLEADO PERTENEZCA AL ORGANISMOS DEL ASUNTO
				IF NOT EXISTS(  SELECT TOP 1 IdCatEmpleado
									--FROM EmpleadoOrganismo 
									FROM SISE3.REL_RolEmpleadoXOrganismo
									--WHERE EmpleadoId = @pi_EmpleadoId
									WHERE IdCatEmpleado = @pi_RegistroEmpleadoId
									--AND StatusRegistro = 1 
									and bStatus = 1
									--AND CatOrganismoId IN(@pi_CatOrganismoId,3))
									AND IdOrganismo IN (@pi_CatOrganismoId,3))
				BEGIN 
                        SET @insertaAnexo = 0--CON CERO INDICAMOS QUE EL USUARIO NO PERTENECE AL ORGANO DEL ASUNTO POR LO TANTO NO INSERTA 
				END
				
				--Valido si la promoción tiene acuerdo
                IF EXISTS (SELECT 1 FROM Promociones  p
                                    LEFT JOIN [AsuntosDocumentos] ad on p.AsuntoDocumentoId = ad.AsuntoDocumentoId and p.AsuntoId = ad.AsuntoId and p.AsuntoNeunID = ad.AsuntoNeunID
                                    WHERE ad.CatAutorizacionDocumentosId = 3
                                    AND p.AsuntoNeunId = @AsuntoNeunId
                                    AND p.CatOrganismoId = @CatOrganismoId
                                    AND p.YearPromocion = @pi_YearPromocion
                                    AND p.NumeroRegistro = @pi_NumeroRegistro)
                BEGIN
                    DECLARE @msg nvarchar (100) = 'No se puede vincular la promoción '+convert(varchar(10),@pi_NumeroRegistro) + ' debido a que el acuerdo ya está autorizado.';
                    THROW 51010,@msg,1;
                END


		IF EXISTS (SELECT  Consecutivo
                                                FROM PromocionArchivos With(NoLock) 
                                                WHERE AsuntoNeunId =@AsuntoNeunId 
                                                AND AsuntoId=@AsuntoId 
                                                AND YearPromocion =@pi_YearPromocion 
                                                AND NumeroRegistro =@pi_NumeroRegistro 
                                                AND NumeroOrden = @NumeroOrden
												AND ClaseAnexo = 0)
		BEGIN

					    SET @pi_NumeroConsecutivo=(SELECT  MAX(Consecutivo) Consecutivo
                                                FROM PromocionArchivos With(NoLock) 
                                                WHERE AsuntoNeunId =@AsuntoNeunId 
                                                AND AsuntoId=@AsuntoId 
                                                AND YearPromocion =@pi_YearPromocion 
                                                AND NumeroRegistro =@pi_NumeroRegistro 
                                                AND NumeroOrden = @NumeroOrden
												AND ClaseAnexo = 0
												)

							--					select @pi_NumeroConsecutivo
							
					SET @po_NumeroConsecutivo = @pi_NumeroConsecutivo
		END


		ELSE
		BEGIN
                SET @pi_NumeroConsecutivo=(SELECT isnull(max(Consecutivo),0) + 1 as nroConsecutivo
                                                                                FROM PromocionArchivos With(NoLock) 
                                                                                WHERE AsuntoNeunId =@AsuntoNeunId 
                                                                                AND AsuntoId=@AsuntoId 
                                                                                AND YearPromocion =@pi_YearPromocion 
                                                                                AND NumeroRegistro =@pi_NumeroRegistro 
                                                                                AND NumeroOrden = @NumeroOrden)
                SET @po_NumeroConsecutivo = @pi_NumeroConsecutivo
         END        
	
                
                --El nombre se forma: 4 (corid) + 12 (Asuid) + 6 (Orden) + 6 (Registro)+ 3(Consecutivo) + 0(Significa que es capturada desde SISE 2.0)
                DECLARE @file VARCHAR(250)
                SET @file =     dbo.fnPonCeros(CAST(@CatOrganismoId AS VARCHAR(50)),4)
                                        + dbo.fnPonCeros(CAST(@AsuntoNeunId AS VARCHAR(50)),12) 
                                        + dbo.fnPonCeros(CAST(@NumeroOrden AS VARCHAR(50)),6)
                                        + dbo.fnPonCeros(CAST(@pi_NumeroRegistro AS VARCHAR(50)),6) 
                                        + dbo.fnPonCeros(CAST(@pi_NumeroConsecutivo AS VARCHAR(50)),3)
                                        + CAST(@pi_Origen AS VARCHAR(1))
                                        + '.pdf'
                                        
                SET @po_NombreArchivo=@file
                
                BEGIN TRY
                        BEGIN TRAN              
                                IF (@insertaAnexo = 1)
                                BEGIN
								
										---Validar si existen archivos.
										MERGE INTO PromocionArchivos trg
										USING 
											( SELECT @CatOrganismoId AS CatOrganismoId, @AsuntoNeunId AS AsuntoNeunId 
														,@AsuntoId AS AsuntoId, @NumeroOrden AS NumeroOrden 
														,@pi_NumeroRegistro AS NumeroRegistro, @pi_YearPromocion AS YearPromocion
														,@pi_NumeroConsecutivo AS Consecutivo, @pi_Origen AS Origen 
														,CAST(@file AS VARCHAR(50)) AS NombreArchivo
														,@pi_Clase AS ClaseAnexo/*, @pi_Descripcion AS DescripcionAnexo*/
														,@pi_Caracter AS CaracterAnexo, 1 AS StatusArchivo, GETDATE() AS FechaAlta
														,ISNULL(@pi_RegistroEmpleadoId,0) AS RegistroEmpleadoSISEId
                                                                                                                ,@idRuta AS RutaArchivoNAS
                                                                                                                ,@pi_NombreArchivoReal AS NombreArchivoReal 
													        ,1 AS EstatusArchivo-- CUANDO EL DOCUMENTO ESTE EN LA SAN, FU LO CAMBIA A 1
                                                                                                                
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
											,NombreArchivo, ClaseAnexo, /*DescripcionAnexo,*/ CaracterAnexo
											,StatusArchivo, FechaAlta, RegistroEmpleadoSISEId, EstatusArchivo, NombreArchivoReal, RutaArchivoNAS)
											VALUES(src.CatOrganismoId, src.AsuntoNeunId, src.AsuntoId, src.NumeroOrden
												,src.NumeroRegistro, src.YearPromocion, src.Consecutivo, src.Origen                         
												,src.NombreArchivo, src.ClaseAnexo, /*src.DescripcionAnexo,*/ src.CaracterAnexo
												,src.StatusArchivo, src.FechaAlta, src.RegistroEmpleadoSISEId, src.EstatusArchivo, src.NombreArchivoReal, src.RutaArchivoNAS)
										
										WHEN MATCHED THEN
											UPDATE SET ClaseAnexo = src.ClaseAnexo
												--,DescripcionAnexo = src.DescripcionAnexo
												,CaracterAnexo = src.CaracterAnexo 
												,StatusArchivo = IIF(@pi_NombreArchivoReal IS NOT NULL, 1,0)
												,EstatusArchivo = IIF(@pi_NombreArchivoReal IS NOT NULL, 1,0)
                                                ,NombreArchivoReal = src.NombreArchivoReal
                                                ,RutaArchivoNAS = src.RutaArchivoNAS;
                                       
                                         
                                        SET @pi_PromoFileIdentificador = (SELECT PromoFileIdentificador 
                                         FROM PromocionArchivos with(rowlock) 
                                         WHERE CatOrganismoId = @CatOrganismoId 
                                         AND AsuntoNeunId = @AsuntoNeunId 
                                         AND AsuntoId = @AsuntoId 
                                         AND NumeroOrden = @NumeroOrden 
                                         AND NumeroRegistro = @pi_NumeroRegistro 
                                         AND YearPromocion = @pi_YearPromocion
                                         AND Consecutivo = @pi_NumeroConsecutivo 
                                         AND Origen = @pi_Origen--0 
                                         AND StatusArchivo = 1)

										 SET @po_ExpedienteProcesado = (SELECT CONCAT('Promoción vinculada al expediente ',AsuntoAlias) AS Mensaje
										 FROM Asuntos
										 where AsuntoNeunId = @AsuntoNeunId 
										 AND CatOrganismoId = @CatOrganismoId )
                                        
                                                        
                                        EXEC usp_Promocion_Bitacora @CatOrganismoId,@pi_YearPromocion,@NumeroOrden,@pi_Origen,6--el 6 es el origen(SISE) y el 3 indica que es una alta en tabla promocionArchivos de un anexo
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
                        --EXEC sisecjfdb02.sise.dbo.usp_EXPE_PromocionAnexosArchivoSISE1Ins @CatOrganismoId,@AsuntoNeunId,@pi_NumeroOrden,@NumeroRegistro,@pi_YearPromocion,@pi_NumeroConsecutivo,@file,@pi_ClaseSISE1,@pi_DescripcionSISE1,@pi_CaracterSISE1,@pi_PromoFileIdentificador
                        --END
                SET NOCOUNT OFF
        END
