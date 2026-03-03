SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 15/10/2024 
-- Description: Elimina colocando (StatusReg=0) en los datos donde no se capturan partes
-- Original : [dbo].[usp_AsuntosDetallesDocumentosDel_SinPartes]
-- ============================================= 
CREATE PROCEDURE [SISE3].[peDelAsuntosDetallesDocumentos_SinPartes]
(
 @pe_AsuntoNeunId INT
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
		DECLARE @LogId INT
		BEGIN TRY
		
			DECLARE @CatTipoAsuntoId INT = NULL
			DECLARE @CatOrganismoId INT = NULL
			DECLARE @DocumentoId INT = NULL
			DECLARE @FechaRegistro DATETIME
			DECLARE @PersonaId INT
			
			SET @PersonaId = 0
			SET @DocumentoId = (SELECT DocumentoId FROM AsuntosApartadoDocumentos WITH(NOLOCK)
			WHERE CatOrganismoId = @CatOrganismoId
								 AND AsuntoNeunId = @pe_AsuntoNeunId
								 AND PersonaId = @PersonaId
								 AND NoBloque = @pe_NoBloque
								 AND StatusReg = 1)

			SET @FechaRegistro = GETDATE()
			
			DECLARE @Eliminar BIT = 0

			--> OBTIENE EL XML PARA POSTERIORMENTE ALMACENAR EN BITACORA

			DECLARE @DatosXML XML
			SET @DatosXML = (SELECT [dbo].[fn_ObtieneDatosDocumentoXML_AccionInsDel_SinPartes] (@pe_AsuntoNeunId, @pe_NoBloque))

			--> ELIMINACIÓN DE LOS DATOS 
			IF EXISTS (SELECT TipoAsuntoId FROM @pe_AsuntoDetalleFechas_type WHERE Eliminar = 1)
				BEGIN
					SELECT adf.AsuntoDetalleFechasId
					INTO #DatosFechaEliminar
					FROM AsuntosDetalleFechas adf WITH(NOLOCK)
					WHERE adf.AsuntoNeunId = @pe_AsuntoNeunId							
					AND adf.StatusReg = 1 
					AND adf.NoBloque = @pe_NoBloque
					AND adf.TipoAsuntoId IN (SELECT TipoAsuntoId FROM @pe_AsuntoDetalleFechas_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleFechas WITH(ROWLOCK)  
					SET StatusReg = 0, FechaBaja = @FechaRegistro, EmpleadoId = @pe_EmpleadoId
					WHERE AsuntoNeunId = @pe_AsuntoNeunId
					AND AsuntoDetalleFechasId IN (SELECT AsuntoDetalleFechasId FROM #DatosFechaEliminar)
					AND NoBloque = @pe_NoBloque
					AND StatusReg = 1
												
					DROP TABLE #DatosFechaEliminar		
					
					SET @Eliminar = 1
				END
			
			IF EXISTS(SELECT TipoAsuntoId FROM @pe_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)
				BEGIN
					SELECT adc.AsuntoDetalleCatalogosId
					INTO #DatosCatalogoEliminar
					FROM AsuntosDetalleCatalogos adc WITH(NOLOCK)
					WHERE adc.AsuntosNeunId = @pe_AsuntoNeunId							
					AND adc.StatusReg = 1 
					AND adc.NoBloque = @pe_NoBloque
					AND adc.TipoAsuntoId IN (SELECT TipoAsuntoId 
											 FROM @pe_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleCatalogos WITH(ROWLOCK) 
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntosNeunId = @pe_AsuntoNeunId
					AND AsuntoDetalleCatalogosId IN (SELECT AsuntoDetalleCatalogosId FROM #DatosCatalogoEliminar)
					AND NoBloque = @pe_NoBloque
					AND StatusReg = 1
												
					DROP TABLE #DatosCatalogoEliminar							
					
					SET @Eliminar = 1
				END
			
			IF EXISTS(SELECT TipoAsuntoId FROM @pe_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)
				BEGIN
					SELECT adde.AsuntoDetalleDescripcionId
					INTO #DatosDescripcionEliminar
					FROM AsuntosDetalleDescripcion adde WITH(NOLOCK)
					WHERE adde.AsuntoNeunId = @pe_AsuntoNeunId							
					AND adde.StatusReg = 1 
					AND adde.NoBloque = @pe_NoBloque
					AND adde.TipoAsuntoId IN (SELECT TipoAsuntoId FROM @pe_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleDescripcion WITH(ROWLOCK)
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntoNeunId = @pe_AsuntoNeunId
					AND AsuntoDetalleDescripcionId IN (SELECT AsuntoDetalleDescripcionId FROM #DatosDescripcionEliminar)
					AND NoBloque = @pe_NoBloque
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
						AND PersonaId = @PersonaId
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
						FROM CatalogosDependientes with(nolock)
						WHERE CatalogoDependienteId = 17
						AND CatalogoDependienteDescripcion like '%billete de depósito%'
						AND StatusRegistro = 1
						
						UPDATE DocumentoArchivos WITH(ROWLOCK)
						SET StatusReg=0,FechaBaja = @FechaRegistro
						WHERE AsuntoNeunId=@pe_AsuntoNeunId
						AND PersonaId=@PersonaId
						AND NoBloque=@pe_NoBloque
						AND TipoDocumentoId=@TipoDocumento
						AND StatusReg = 1

						--GUARDA EN BITACORA

						If @DatosXML IS NOT NULL
							BEGIN
								EXEC @LogId = [SISE_NEWLOG].[dbo].[usp_BitacoraAsuntoDocumentos] @pe_AsuntoNeunId, @PersonaId, @pe_NoBloque ,3, @pe_EmpleadoId, @DatosXML
							END
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
			EXEC [SISE_NEWLOG].[dbo].[usp_EliminarBitacoraAsuntoDocumentos] @LogId
		    
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