SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE [SISE3].[piInsertaArchivoPromocion]
	@AsuntoNeunId BIGINT,
	@YearPromocion INT,
	@pi_CatOrganismoId INT,
	@pi_EmpleadoId BIGINT,
	@pi_NumeroOrden INT,
	@pi_Fojas INT,
	@pi_OrigenPromocion INT,
	@po_NombreArchivo VARCHAR(50) OUTPUT,
	@po_NumeroConsecutivo INT OUTPUT
AS
BEGIN
	BEGIN TRY
		--DECLARE @CatOrganismoId INT
		DECLARE @AsuntoId INT
		DECLARE @NumeroRegistro INT
		DECLARE @pi_NumeroConsecutivo INT = null
		DECLARE @pi_PromoFileIdentificador UNIQUEIDENTIFIER = null      
		DECLARE @insertaAnexo INT = 1
		DECLARE @ClaseAnexo INT =0
					
									
		SELECT
			@AsuntoId = a.AsuntoId,
			@NumeroRegistro = p.NumeroRegistro
		FROM Asuntos a 
		INNER JOIN Promociones p 
			ON a.AsuntoNeunId = p.AsuntoNeunId
		WHERE a.AsuntoNeunId = @AsuntoNeunId
			AND p.YearPromocion = @YearPromocion
			AND p.NumeroOrden = @pi_NumeroOrden

					
		--QUE EL EMPLEADO PERTENEZCA AL ORGANISMOS DEL ASUNTO
		IF NOT EXISTS(  SELECT TOP 1 IdCatEmpleado
									--FROM EmpleadoOrganismo 
									FROM SISE3.REL_RolEmpleadoXOrganismo
									--WHERE EmpleadoId = @pi_EmpleadoId
									WHERE IdCatEmpleado = @pi_EmpleadoId
									--AND StatusRegistro = 1 
									and bStatus = 1
									--AND CatOrganismoId IN(@pi_CatOrganismoId,3))
									AND IdOrganismo IN (@pi_CatOrganismoId,3))
		BEGIN 
			SET @insertaAnexo = 0--CON CERO INDICAMOS QUE EL USUARIO NO PERTENECE AL ORGANO DEL ASUNTO POR LO TANTO NO INSERTA 
		END

		SELECT @ClaseAnexo = 1
		FROM PromocionArchivos With(NoLock) 
		WHERE AsuntoNeunId =@AsuntoNeunId 
		AND AsuntoId=@AsuntoId 
		AND YearPromocion =@YearPromocion 
		AND NumeroRegistro =@NumeroRegistro 
		AND NumeroOrden = @pi_NumeroOrden
		AND ClaseAnexo = 0

		IF(@ClaseAnexo = 0)
		BEGIN
			SET @pi_NumeroConsecutivo = 1
				
			SET @pi_NumeroConsecutivo=(SELECT isnull(max(Consecutivo),0) + 1 as nroConsecutivo
				--SET @pi_NumeroConsecutivo=(SELECT IIF(MAX(CONSECUTIVO) IS NULL,0,MAX(CONSECUTIVO)+1)
																				FROM PromocionArchivos With(NoLock) 
																				WHERE AsuntoNeunId =@AsuntoNeunId 
																				AND AsuntoId=@AsuntoId 
																				AND YearPromocion =@YearPromocion 
																				AND NumeroRegistro =@NumeroRegistro 
																				AND NumeroOrden = @pi_NumeroOrden)

			SET @po_NumeroConsecutivo = @pi_NumeroConsecutivo

			--El nombre se forma: 4 (corid) + 12 (Asuid) + 6 (Orden) + 6 (Registro)+ 3(Consecutivo) + 0(Significa que es capturada desde SISE 2.0)
			DECLARE @file VARCHAR(250)
			SET @file =     dbo.fnPonCeros(CAST(@pi_CatOrganismoId AS VARCHAR(50)),4)
					+ dbo.fnPonCeros(CAST(@AsuntoNeunId AS VARCHAR(50)),12) 
					+ dbo.fnPonCeros(CAST(@pi_NumeroOrden AS VARCHAR(50)),6)
					+ dbo.fnPonCeros(CAST(@NumeroRegistro AS VARCHAR(50)),6) 
					+ dbo.fnPonCeros(CAST(@pi_NumeroConsecutivo AS VARCHAR(50)),3)
					+ CAST(@pi_OrigenPromocion AS VARCHAR(1))
					+ '.pdf'
			
			SET @po_NombreArchivo=@file

			IF(@insertaAnexo = 1)
			BEGIN
				INSERT INTO PromocionArchivos WITH(ROWLOCK)
					(CatOrganismoId
					,AsuntoNeunId
					,AsuntoId                                       
					,NumeroOrden
					,NumeroRegistro                                         
					,YearPromocion                          
					,Consecutivo           
					,Origen                         
					,NombreArchivo
					,ClaseAnexo
					,DescripcionAnexo
					,CaracterAnexo
					,StatusArchivo
					,FechaAlta                             
					,RegistroEmpleadoSISEId
					,EstatusArchivo
					,Fojas
					)
				VALUES
					(@pi_CatOrganismoId
					,@AsuntoNeunId
					,@AsuntoId
					,@pi_NumeroOrden
					,@NumeroRegistro
					,@YearPromocion                                      
					,@pi_NumeroConsecutivo 
					,@pi_OrigenPromocion --ORIGEN 0:SISE, 1:FESE, 1:SL
					,CAST(@file AS VARCHAR(50))
					,0
					,5031
					,0
					,-1
					,GETDATE()
					,ISNULL(@pi_EmpleadoId,0)      
					,0-- CUANDO EL DOCUMENTO ESTE EN LA SAN, FU LO CAMBIA A 1
					,@pi_Fojas
					)
			
				SET @pi_PromoFileIdentificador = (SELECT PromoFileIdentificador 
					FROM PromocionArchivos with(rowlock) 
					WHERE CatOrganismoId = @pi_CatOrganismoId 
					AND AsuntoNeunId = @AsuntoNeunId 
					AND AsuntoId = @AsuntoId 
					AND NumeroOrden = @pi_NumeroOrden 
					AND NumeroRegistro = @NumeroRegistro 
					AND YearPromocion = @YearPromocion
					AND Consecutivo = @pi_NumeroConsecutivo 
					AND Origen = @pi_OrigenPromocion--0 
					AND StatusArchivo = 1)


				EXEC usp_Promocion_Bitacora @pi_CatOrganismoId,@YearPromocion,@pi_NumeroOrden,@pi_OrigenPromocion,6--el 6 es el origen(SISE) y el 3 indica que es una alta en tabla promocionArchivos de un anexo
			END
			ELSE
			BEGIN
				RAISERROR ('El usuario que intenta insertar la promición no es válido para el expediente', -- Texto del Mensaje
                                                16, -- Severity
                                                1       -- State
                                                );
			END
		END
	END TRY
	BEGIN CATCH
		-- EJECUTO ROLLBACK SOLO EN CASO DE ERROR
		IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
		-- EJECUTA LA RUTINA DE RECUPERACION DE ERRORES.
		EXECUTE dbo.usp_GetErrorInfo;
	END CATCH
END
