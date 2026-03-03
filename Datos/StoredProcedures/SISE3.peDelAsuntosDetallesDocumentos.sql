SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 15/10/2024 
-- Description: Elimina colocando (StatusReg=0) en los datos
-- Original : [dbo].[usp_AsuntosDetallesDocumentosDel]
-- ============================================= 
CREATE PROCEDURE [SISE3].[peDelAsuntosDetallesDocumentos]
(
 @pe_AsuntoNeunId INT						
,@pe_PersonaId INT						
,@pe_EmpleadoId INT
,@pe_CatTipoAsuntoId INT
,@pe_CatOrganismoId INT
,@pe_NoBloque INT
,@pe_AsuntoDetalleFechas_type [SISE3].[AsuntosDetalleFechas_type] READONLY 
,@pe_AsuntoDetalleDescripcion_type [SISE3].[AsuntoDetalleDescripcion_type] READONLY 
,@pe_AsuntoDetalleCatalogos_type [SISE3].[AsuntosDetalleCatalogos_type] READONLY
)
AS
	BEGIN
		SET NOCOUNT ON
			DECLARE @LogId BIGINT

		BEGIN TRY
		
			DECLARE @DocumentoId INT = NULL
			DECLARE @FechaRegistro DATETIME
			
			SET @DocumentoId = (SELECT DocumentoId FROM AsuntosApartadoDocumentos WITH(NOLOCK)
								WHERE CatOrganismoId = @pe_CatOrganismoId
								AND AsuntoNeunId = @pe_AsuntoNeunId
								AND PersonaId = @pe_PersonaId
								AND NoBloque = @pe_NoBloque
								AND StatusReg = 1
							    )
			SET @FechaRegistro = GETDATE()

			IF NOT EXISTS(SELECT CatTipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) 
							WHERE TipoPropiedadId = 28 AND StatusReg = 1 AND CatTipoAsuntoId = @pe_CatTipoAsuntoId)
			BEGIN
				IF NOT EXISTS(SELECT PersonaId FROM PersonasAsunto WITH(NOLOCK) 
								WHERE AsuntoNeunId = @pe_AsuntoNeunId )
				BEGIN
					RAISERROR ('Operación no permitida, No hay Partes partes para el AsuntoNeunId ', -- Texto del Mensaje
						16, -- Severity
						1	-- State
						);
				END
			END
			
			IF NOT EXISTS (SELECT CatTipoAsuntoId FROM CamposPropiedades WITH(NOLOCK)  
							WHERE TipoPropiedadId = 28 AND StatusReg = 1 AND CatTipoAsuntoId = @pe_CatTipoAsuntoId)
				BEGIN
					DECLARE @Eliminar BIT = 0

					--> OBTIENE EL XML PARA POSTERIORMENTE ALMACENAR EN BITACORA

					DECLARE @DatosXML XML
					SET @DatosXML = (SELECT [dbo].[fn_ObtieneDatosDocumentoXML_AccionInsDel](@pe_AsuntoNeunId, @pe_PersonaId, @pe_NoBloque))

					--> ELIMINACIÓN DE LOS DATOS 
					IF EXISTS(SELECT TipoAsuntoId FROM @pe_AsuntoDetalleFechas_type WHERE Eliminar = 1)
						BEGIN
							SELECT adf.AsuntoDetalleFechasId
							INTO #DatosFechaEliminar
							FROM AsuntosDetalleFechas adf WITH(NOLOCK) 
							INNER JOIN PersonasAsuntosDetalleFechas padf WITH(NOLOCK) ON adf.AsuntoNeunId = padf.AsuntoNeunId
								AND adf.AsuntoDetalleFechasId = padf.AsuntoDetalleFechasId
							WHERE adf.AsuntoNeunId = @pe_AsuntoNeunId							
							AND adf.StatusReg = 1 
							AND padf.StatusReg = 1
							AND padf.PersonaId = @pe_PersonaId
							AND adf.NoBloque = @pe_NoBloque
							aND adf.TipoAsuntoId IN (SELECT TipoAsuntoId FROM @pe_AsuntoDetalleFechas_type WHERE Eliminar = 1)														
							
							UPDATE AsuntosDetalleFechas WITH(ROWLOCK) 
							SET StatusReg = 0, FechaBaja = @FechaRegistro, EmpleadoId = @pe_EmpleadoId
							WHERE AsuntoNeunId = @pe_AsuntoNeunId
							AND AsuntoDetalleFechasId IN (SELECT AsuntoDetalleFechasId FROM #DatosFechaEliminar)
							AND NoBloque = @pe_NoBloque
							AND StatusReg = 1
							
							UPDATE PersonasAsuntosDetalleFechas WITH(ROWLOCK)  
							SET StatusReg = 0, FechaBaja = @FechaRegistro
							WHERE AsuntoNeunId = @pe_AsuntoNeunId
							AND PersonaId = @pe_PersonaId
							AND AsuntoDetalleFechasId IN (SELECT AsuntoDetalleFechasId FROM #DatosFechaEliminar)
							AND StatusReg = 1			
							
							DROP TABLE #DatosFechaEliminar		
							
							SET @Eliminar = 1
						END
					
					IF EXISTS(SELECT TipoAsuntoId FROM @pe_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)
						BEGIN
							SELECT adc.AsuntoDetalleCatalogosId
							INTO #DatosCatalogoEliminar
							FROM AsuntosDetalleCatalogos adc WITH(NOLOCK)
							INNER JOIN PersonasAsuntosDetalleCatalogos padc WITH(NOLOCK) ON adc.AsuntosNeunId = padc.AsuntoNeunId
								AND adc.AsuntoDetalleCatalogosId = padc.AsuntoDetalleCatalogosId
							WHERE adc.AsuntosNeunId = @pe_AsuntoNeunId							
							AND adc.StatusReg = 1 
							AND padc.StatusReg = 1
							AND padc.PersonaId = @pe_PersonaId
							AND adc.NoBloque = @pe_NoBloque
							AND adc.TipoAsuntoId IN (SELECT TipoAsuntoId FROM @pe_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)														
							
							UPDATE AsuntosDetalleCatalogos WITH(ROWLOCK)  
							SET StatusReg = 0, FechaBaja = @FechaRegistro
							WHERE AsuntosNeunId = @pe_AsuntoNeunId
							AND AsuntoDetalleCatalogosId IN (SELECT AsuntoDetalleCatalogosId FROM #DatosCatalogoEliminar)
							AND NoBloque = @pe_NoBloque
							AND StatusReg = 1
							
							UPDATE PersonasAsuntosDetalleCatalogos WITH(ROWLOCK) 
							SET StatusReg = 0, FechaBaja = @FechaRegistro
							WHERE AsuntoNeunId = @pe_AsuntoNeunId
							AND PersonaId = @pe_PersonaId
							AND AsuntoDetalleCatalogosId IN (SELECT AsuntoDetalleCatalogosId FROM #DatosCatalogoEliminar)
							AND StatusReg = 1							
							
							DROP TABLE #DatosCatalogoEliminar							
							
							SET @Eliminar = 1
						END
					
					IF EXISTS(SELECT TipoAsuntoId FROM @pe_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)
						BEGIN
							SELECT adde.AsuntoDetalleDescripcionId
							INTO #DatosDescripcionEliminar
							FROM AsuntosDetalleDescripcion adde WITH(NOLOCK)
							INNER JOIN PersonasAsuntoDetalleDescripcion padd WITH(NOLOCK) ON adde.AsuntoNeunId = padd.AsuntoNeunId
								AND adde.AsuntoDetalleDescripcionId = padd.AsuntoDetalleDescripcionId
							WHERE adde.AsuntoNeunId = @pe_AsuntoNeunId							
							AND adde.StatusReg = 1 
							AND padd.StatusReg = 1
							AND padd.PersonaId = @pe_PersonaId
							AND adde.NoBloque = @pe_NoBloque
							AND adde.TipoAsuntoId IN (SELECT TipoAsuntoId FROM @pe_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)														
							
							UPDATE AsuntosDetalleDescripcion WITH(ROWLOCK)  
							SET StatusReg = 0, FechaBaja = @FechaRegistro
							WHERE AsuntoNeunId = @pe_AsuntoNeunId
							AND AsuntoDetalleDescripcionId IN (SELECT AsuntoDetalleDescripcionId FROM #DatosDescripcionEliminar)
							AND NoBloque = @pe_NoBloque
							AND StatusReg = 1
							
							UPDATE PersonasAsuntoDetalleDescripcion WITH(ROWLOCK) 
							SET StatusReg = 0, FechaBaja = @FechaRegistro
							WHERE AsuntoNeunId = @pe_AsuntoNeunId
							AND PersonaId = @pe_PersonaId
							AND AsuntoDetalleDescripcionId IN (SELECT AsuntoDetalleDescripcionId FROM #DatosDescripcionEliminar)
							AND StatusReg = 1	

							DROP TABLE #DatosDescripcionEliminar			
							
							SET @Eliminar = 1
						END
						
						IF @Eliminar = 1
							BEGIN				 
								
								DECLARE @TipoDocumento INT
								
								UPDATE AsuntosApartadoDocumentos WITH(ROWLOCK)
								SET StatusReg = 0, FechaBaja = @FechaRegistro, EmpleadoId = @pe_EmpleadoId
								WHERE DocumentoId = @DocumentoId
								AND CatOrganismoId = @pe_CatOrganismoId
								AND AsuntoNeunId = @pe_AsuntoNeunId
								AND PersonaId = @pe_PersonaId
								AND NoBloque = @pe_NoBloque
								AND StatusReg = 1
								
								UPDATE AsuntosApartadoDocumentosFechas WITH(ROWLOCK)
								SET StatusReg = 0, FechaBaja = @FechaRegistro, EmpleadoId = @pe_EmpleadoId
								WHERE DocumentoId = @DocumentoId
								AND StatusReg = 1
								
								UPDATE AsuntosApartadoDocumentosCatalogos WITH(ROWLOCK)
								SET StatusReg = 0, FechaBaja = @FechaRegistro, EmpleadoId = @pe_EmpleadoId
								WHERE DocumentoId = @DocumentoId
								AND StatusReg = 1
								
								UPDATE AsuntosApartadoDocumentosDescripcion WITH(ROWLOCK)
								SET StatusReg = 0, FechaBaja = @FechaRegistro, EmpleadoId = @pe_EmpleadoId
								WHERE DocumentoId = @DocumentoId
								AND StatusReg = 1
								
								SELECT @TipoDocumento = CatalogoDependienteElementoIdNew
								FROM CatalogosDependientes WITH(NOLOCK)
								WHERE CatalogoDependienteId = 17
								AND CatalogoDependienteDescripcion LIKE'%billete de depósito%'
								AND StatusRegistro = 1
								
								UPDATE DocumentoArchivos WITH(ROWLOCK)
								SET StatusReg=0 ,FechaBaja = @FechaRegistro
								WHERE AsuntoNeunId=@pe_AsuntoNeunId
								AND PersonaId=@pe_PersonaId
								AND NoBloque=@pe_NoBloque
								AND TipoDocumentoId=@TipoDocumento
								AND StatusReg = 1

						       --GUARDA EN BITACORA
								IF @DatosXML IS NOT NULL
									BEGIN
										EXEC @LogId = [SISE_NEWLOG].[dbo].[usp_BitacoraAsuntoDocumentos] @pe_AsuntoNeunId, @pe_PersonaId, @pe_NoBloque ,3, @pe_EmpleadoId, @DatosXML
									END
							END
				END
			ELSE			
				BEGIN
					
					EXEC [SISE3].[peDelAsuntosDetallesDocumentos_SinPartes] @pe_AsuntoNeunId, @pe_EmpleadoId, @pe_NoBloque, @pe_AsuntoDetalleCatalogos_type, @pe_AsuntoDetalleDescripcion_type, @pe_AsuntoDetalleFechas_type							
				END
			
		END TRY
		BEGIN CATCH
			
			IF OBJECT_ID(N'tempdb..#DatosFechaEliminar', N'U') IS NOT NULL 
				BEGIN
					DROP TABLE #DatosFechaEliminar					
				END
			IF OBJECT_ID(N'tempdb..#DatosCatalogoEliminar', N'U') IS NOT NULL 
				BEGIN
					DROP TABLE #DatosCatalogoEliminar					
				END
			IF OBJECT_ID(N'tempdb..#DatosDescripcionEliminar', N'U') IS NOT NULL 
				BEGIN
					DROP TABLE #DatosDescripcionEliminar					
				END
			
			--SI OCURRIO UN ERROR BORRA DE LA BITACORA LO ANTERIORMENTE REGISTRADO
			exec [SISE_NEWLOG].[dbo].[usp_EliminarBitacoraAsuntoDocumentos] @LogId
		    
			-- Ejecuto ROLLBACK solo en caso de error
			--IF @@TRANCOUNT > 0
			--	ROLLBACK TRANSACTION;
			
			-- Ejecuta la rutina de recuperacion de errores.
			--EXECUTE dbo.usp_GetErrorInfo;
			DECLARE 
				@ErrorMessage    NVARCHAR(4000),
				@ErrorNumber     INT,
				@ErrorSeverity   INT,
				@ErrorState      INT,
				@ErrorLine       INT,
				@ErrorProcedure  NVARCHAR(200);
			SELECT 
				@ErrorNumber = ERROR_NUMBER(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE(),
				@ErrorLine = ERROR_LINE(),
				@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');

			-- Build the message string that will contain original
			-- error information.
			SELECT @ErrorMessage = 
				N'Error %d, Nivel %d, Estado %d, Procedimiento %s, Linea %d, ' + 
					'Mensaje: '+ ERROR_MESSAGE();

			-- Raise an error: msg_str parameter of RAISERROR will contain
			-- the original error information.
			RAISERROR 
				(
				@ErrorMessage, 
				@ErrorSeverity, 
				1,               
				@ErrorNumber,    -- parameter: original error number.
				@ErrorSeverity,  -- parameter: original error severity.
				@ErrorState,     -- parameter: original error state.
				@ErrorProcedure, -- parameter: original error procedure name.
				@ErrorLine       -- parameter: original error line number.
				);
				
		END CATCH;
	    -- Completo mi transaccion
		--IF @@TRANCOUNT > 0
		--	COMMIT TRANSACTION;
		SET NOCOUNT OFF
	END

