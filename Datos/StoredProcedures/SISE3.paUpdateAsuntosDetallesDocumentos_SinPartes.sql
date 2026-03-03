SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 08/10/2024 
-- Description: Actualiza los datos del apartado de captura de Documentos
-- Ejemplo : [SISE3].[paUpdateAsuntosDetallesDocumentos_SinPartes]
-- Original : [dbo].[usp_AsuntosDetallesDocumentosUpd_SinPartes]
-- ============================================= 
ALTER PROCEDURE [SISE3].[paUpdateAsuntosDetallesDocumentos_SinPartes]
	@pa_AsuntoNeunId INT						
	,@pa_EmpleadoId INT								
	,@pa_NoBloque INT
    ,@pa_CatTipoAsuntoId INT
    ,@pa_CatOrganismoId INT
	,@pa_AsuntoDetalleFechas_type [SISE3].[AsuntosDetalleFechas_type] READONLY 
	,@pa_AsuntoDetalleDescripcion_type [SISE3].[AsuntoDetalleDescripcion_type] READONLY 
	,@pa_AsuntoDetalleCatalogos_type [SISE3].[AsuntosDetalleCatalogos_type] READONLY 
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
		
			DECLARE @AsuntoId INT = NULL
			DECLARE @DocumentoId INT = NULL
			DECLARE @FechaRegistro DATETIME
			DECLARE @PersonaId INT
			
			SET @PersonaId = 0		
			SET @AsuntoId = (SELECT AsuntoId FROM [Asuntos] WITH(NOLOCK)
							WHERE AsuntoNeunId = @pa_AsuntoNeunId )

			SET @DocumentoId = (SELECT ISNULL(MAX(DocumentoId),1) FROM AsuntosApartadoDocumentos WITH(NOLOCK) 
								 WHERE CatOrganismoId = @pa_CatOrganismoId
								 AND AsuntoNeunId = @pa_AsuntoNeunId
								 AND PersonaId = @PersonaId
								 AND NoBloque = @pa_NoBloque
								 AND StatusReg = 1)

			SET @FechaRegistro = GETDATE()			
								
			-->OBTIENE EL XML DE LOS DATOS ANTES DE SU ACTUALIZACION
			DECLARE @DatosXmlAnteriores  XML	
			SET @DatosXmlAnteriores = [dbo].[fn_ObtieneDatosDocumentoXML_AccionInsDel_SinPartes](@pa_AsuntoNeunId, @pa_NoBloque)
			
			--> EL SIGUIENTE BLOQUE, ELIMINA AQUELLOS DATOS EN LOS QUE HUBO UN VALOR Y EL USUARIO NO VOLVIO A REALIZAR CAPTURA
			--  ES DECIR, AQUELLOS REGISTROS QUE CAPTURÓ EN ALGÚN MOMENTO PERO QUE LO QUITÓ DE LA PANTALLA.

			IF EXISTS(SELECT TipoAsuntoId FROM @pa_AsuntoDetalleFechas_type WHERE Eliminar = 1)
				BEGIN
					SELECT adf.AsuntoDetalleFechasId
					INTO #DatosFechaEliminar
					FROM AsuntosDetalleFechas adf WITH(NOLOCK)
					WHERE adf.AsuntoNeunId = @pa_AsuntoNeunId							
					AND adf.StatusReg = 1 
					AND adf.NoBloque = @pa_NoBloque
					AND adf.TipoAsuntoId IN (SELECT TipoAsuntoId FROM @pa_AsuntoDetalleFechas_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleFechas WITH(ROWLOCK) 
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND AsuntoDetalleFechasId IN (SELECT AsuntoDetalleFechasId 
													FROM #DatosFechaEliminar)
					AND NoBloque = @pa_NoBloque
					AND StatusReg = 1
												
					DROP TABLE #DatosFechaEliminar							
				END
			
			IF EXISTS(SELECT TipoAsuntoId FROM @pa_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)
				BEGIN
					SELECT adc.AsuntoDetalleCatalogosId
					INTO #DatosCatalogoEliminar
					FROM AsuntosDetalleCatalogos adc WITH(NOLOCK)
					WHERE adc.AsuntosNeunId = @pa_AsuntoNeunId							
					AND adc.StatusReg = 1 
					AND adc.NoBloque = @pa_NoBloque
					AND adc.TipoAsuntoId in (SELECT TipoAsuntoId FROM @pa_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleCatalogos WITH(ROWLOCK) 
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntosNeunId = @pa_AsuntoNeunId
					AND AsuntoDetalleCatalogosId IN (SELECT AsuntoDetalleCatalogosId 
													FROM #DatosCatalogoEliminar)
					AND NoBloque = @pa_NoBloque
					AND StatusReg = 1
					
					DROP TABLE #DatosCatalogoEliminar							
				END
			
			IF EXISTS(SELECT TipoAsuntoId FROM @pa_AsuntoDetalleDescripcion_type Where Eliminar = 1)
				BEGIN
					SELECT adde.AsuntoDetalleDescripcionId
					INTO #DatosDescripcionEliminar
					FROM AsuntosDetalleDescripcion adde WITH(NOLOCK)
					WHERE adde.AsuntoNeunId = @pa_AsuntoNeunId							
					AND adde.StatusReg = 1 
					AND adde.NoBloque = @pa_NoBloque
					AND adde.TipoAsuntoId in (SELECT TipoAsuntoId 
											  FROM @pa_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleDescripcion WITH(ROWLOCK) 
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND AsuntoDetalleDescripcionId IN (SELECT AsuntoDetalleDescripcionId 
														FROM #DatosDescripcionEliminar)
					AND NoBloque = @pa_NoBloque
					AND StatusReg = 1
												
					DROP TABLE #DatosDescripcionEliminar							
				END
				
					
			--> DATOS DE TIPO FECHA
			------------------------

			IF EXISTS(SELECT TipoAsuntoId FROM @pa_AsuntoDetalleFechas_type WHERE Eliminar = 1)
				BEGIN					
					-------------- borrado de los datos anteriores -------------------------------
					SELECT adf.AsuntoDetalleFechasId
					INTO #DatosFechaEliminar2
					FROM AsuntosDetalleFechas adf WITH(NOLOCK)
					WHERE adf.AsuntoNeunId = @pa_AsuntoNeunId							
					AND adf.StatusReg = 1 
					AND adf.NoBloque = @pa_NoBloque
					AND adf.TipoAsuntoId in (SELECT TipoAsuntoId 
											 FROM @pa_AsuntoDetalleFechas_type WHERE Eliminar = 1)														
					

					UPDATE AsuntosDetalleFechas WITH(ROWLOCK) 
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND AsuntoDetalleFechasId IN (SELECT AsuntoDetalleFechasId FROM #DatosFechaEliminar2)
					AND NoBloque = @pa_NoBloque
					AND StatusReg = 1
					
					DROP TABLE #DatosFechaEliminar2
					--------------------------------------------------------------------------------------					
					
					--> Cálculo del consecutivo de la tabla
					DECLARE @MaxAsuntoDetalleFechaId INT = NULL	
					SET @MaxAsuntoDetalleFechaId = (SELECT ISNULL(MAX([AsuntoDetalleFechasId]),0) 
													 FROM [AsuntosDetalleFechas] WITH(NOLOCK)
													 WHERE [AsuntoNeunId] = @pa_AsuntoNeunId )
				
					SELECT @pa_AsuntoNeunId  AsuntoNeunid
						, @AsuntoId as AsuntoId
						,((ROW_NUMBER()OVER (ORDER BY @pa_AsuntoNeunId ASC)) + @MaxAsuntoDetalleFechaId) AsuntoDetalleFechasId
						, TipoAsuntoId						
						, ValorCampoAsunto
						, NoCaptura
						, @pa_NoBloque NoBloque
						, 0 NoBloquePadre
						, Consecutivo
						, @pa_EmpleadoId EmpleadoId
					INTO #DatosFecha
					FROM @pa_AsuntoDetalleFechas_type
					WHERE Eliminar = 1
					
					INSERT INTO AsuntosDetalleFechas WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId ,TipoAsuntoId ,ValorCampoAsunto ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)
					SELECT * FROM #DatosFecha
					
					DROP TABLE #DatosFecha
			END

				
			--> DATOS DE TIPO CATÁLOGO
			--------------------------

			IF EXISTS(SELECT TipoAsuntoId FROM @pa_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)
				BEGIN
					-------------- borrado de los datos anteriores -------------------------------
					SELECT adc.AsuntoDetalleCatalogosId
					INTO #DatosCatalogoEliminar2
					FROM AsuntosDetalleCatalogos adc WITH(NOLOCK)
					WHERE adc.AsuntosNeunId = @pa_AsuntoNeunId							
					AND adc.StatusReg = 1 
					AND adc.NoBloque = @pa_NoBloque
					AND adc.TipoAsuntoId in (SELECT TipoAsuntoId FROM @pa_AsuntoDetalleCatalogos_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleCatalogos WITH(ROWLOCK)
					SET StatusReg = 0
					,FechaBaja = @FechaRegistro
					WHERE AsuntosNeunId = @pa_AsuntoNeunId
					AND AsuntoDetalleCatalogosId IN (SELECT AsuntoDetalleCatalogosId FROM #DatosCatalogoEliminar2)
					AND NoBloque = @pa_NoBloque
					AND StatusReg = 1
					
					DROP TABLE #DatosCatalogoEliminar2
					--------------------------------------------------------------------------------------
					
					--> Cálculo del consecutivo de la tabla
					DECLARE @MaxAsuntoDetalleCatalogoId INT = NULL	
					SET @MaxAsuntoDetalleCatalogoId = (SELECT ISNULL(MAX(AsuntoDetalleCatalogosId),0) 
													 FROM AsuntosDetalleCatalogos WITH(NOLOCK)
													 WHERE AsuntosNeunId = @pa_AsuntoNeunId )
					
					SELECT @pa_AsuntoNeunId as AsuntosNeunid
						, @AsuntoId AsuntoId
						,((ROW_NUMBER()OVER (ORDER BY @pa_AsuntoNeunId ASC)) + @MaxAsuntoDetalleCatalogoId) AsuntoDetalleCatalogosId
						, TipoAsuntoId						
						, CatalogoId
						, CatalogoElementoId
						, NoCaptura
						, @pa_NoBloque NoBloque
						, 0 NoBloquePadre
						, Consecutivo
						, @pa_EmpleadoId EmpleadoId
					INTO #DatosCatalogo
					FROM @pa_AsuntoDetalleCatalogos_type
					WHERE Eliminar = 1
					
					INSERT INTO AsuntosDetalleCatalogos WITH(ROWLOCK) (AsuntosNeunId ,AsuntoId ,AsuntoDetalleCatalogosId ,TipoAsuntoId ,CatTipoCatalogoAsuntoId,CatCatalogoAsuntoId ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)
					SELECT * FROM #DatosCatalogo
					
					DROP TABLE #DatosCatalogo
			END
			
			--> DATOS DE TIPO DESCRIPCIÓN	
			-------------------------------------

			IF EXISTS(SELECT TipoAsuntoId FROM @pa_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)
				BEGIN
					-------------- borrado de los datos anteriores -------------------------------
					SELECT adde.AsuntoDetalleDescripcionId
					INTO #DatosDescripcionEliminar2
					FROM AsuntosDetalleDescripcion adde WITH(NOLOCK)
					WHERE adde.AsuntoNeunId = @pa_AsuntoNeunId							
					AND adde.StatusReg = 1 
					AND adde.NoBloque = @pa_NoBloque
					AND adde.TipoAsuntoId in (SELECT TipoAsuntoId FROM @pa_AsuntoDetalleDescripcion_type WHERE Eliminar = 1)														
					
					UPDATE AsuntosDetalleDescripcion WITH(ROWLOCK)
					SET StatusReg = 0, FechaBaja = @FechaRegistro
					WHERE AsuntoNeunId = @pa_AsuntoNeunId
					AND AsuntoDetalleDescripcionId IN (SELECT AsuntoDetalleDescripcionId FROM #DatosDescripcionEliminar2)
					AND NoBloque = @pa_NoBloque
					AND StatusReg = 1
					
					DROP TABLE #DatosDescripcionEliminar2
					--------------------------------------------------------------------------------------
										
					--> Cálculo del consecutivo de la tabla
					DECLARE @MaxAsuntoDetalleDescripcionId INT = NULL	
					SET @MaxAsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(AsuntoDetalleDescripcionId),0) 
															FROM AsuntosDetalleDescripción WITH(NOLOCK)
															WHERE AsuntoNeunId = @pa_AsuntoNeunId )
				
					SELECT @pa_AsuntoNeunId AsuntoNeunid
						, @AsuntoId as AsuntoId
						,((ROW_NUMBER()OVER (ORDER BY @pa_AsuntoNeunId ASC)) + @MaxAsuntoDetalleDescripcionId) AsuntoDetalleDescripcionId
						, TipoAsuntoId						
						, Contenido
						, NoCaptura
						, @pa_NoBloque NoBloque
						, 0 NoBloquePadre
						, Consecutivo
						, @pa_EmpleadoId EmpleadoId
					INTO #DatosDescripcion
					FROM @pa_AsuntoDetalleDescripcion_type
					WHERE Eliminar = 1
					
					INSERT INTO AsuntosDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId ,Contenido ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId )
					SELECT * FROM #DatosDescripcion
					
					DROP TABLE #DatosDescripcion
			END
						
			/* SE DA DE BAJA EL REGISTRO DE LA TABLA AsuntosApartadoDocumentos y se procede a realizar la inserción 
				   de los nuevos registros. */

			SET @DocumentoId = (SELECT ISNULL(MAX(DocumentoId),1) 
								 FROM AsuntosApartadoDocumentos WITH(NOLOCK)
								 WHERE CatOrganismoId = @pa_CatOrganismoId
								 AND AsuntoNeunId = @pa_AsuntoNeunId
								 AND PersonaId = @PersonaId
								 AND NoBloque = @pa_NoBloque
								 AND StatusReg = 1)
			
			/* FECHAS*/
			----------------
			UPDATE aadf SET aadf.StatusReg = 0
			,aadf.FechaBaja = GETDATE()
			,aadf.EmpleadoId = @pa_EmpleadoId
			FROM AsuntosApartadoDocumentosFechas aadf 
			INNER JOIN @pa_AsuntoDetalleFechas_type adf ON aadf.TipoAsuntoId = adf.TipoAsuntoId 
			WHERE aadf.DocumentoId = @DocumentoId
			AND Eliminar = 1
			AND aadf.StatusReg = 1

			UPDATE aadf SET aadf.StatusReg = 0
			,aadf.FechaBaja = GETDATE()
			,aadf.EmpleadoId = @pa_EmpleadoId
			FROM AsuntosApartadoDocumentosFechas aadf 
			INNER JOIN @pa_AsuntoDetalleFechas_type adf ON aadf.TipoAsuntoId = adf.TipoAsuntoId 
			WHERE aadf.DocumentoId = @DocumentoId
			AND Eliminar = 1
			AND aadf.StatusReg = 1
			
			
			INSERT INTO AsuntosApartadoDocumentosFechas (DocumentoId, TipoAsuntoId, Valor, FechaAlta, StatusReg, EmpleadoId)
			SELECT
				@DocumentoId,
				TipoAsuntoId,
				ValorCampoAsunto,
				@FechaRegistro,
				1,
				@pa_EmpleadoId
			FROM @pa_AsuntoDetalleFechas_type
			WHERE Eliminar = 1

			/* CATALOGOS*/
			----------------
			UPDATE aadc Set aadc.StatusReg = 0
			,aadc.FechaBaja = GETDATE()
			,aadc.EmpleadoId = @pa_EmpleadoId
			FROM AsuntosApartadoDocumentosCatalogos aadc
			INNER JOIN @pa_AsuntoDetalleCatalogos_type adc ON aadc.TipoAsuntoId = adc.TipoAsuntoId 
			WHERE aadc.DocumentoId = @DocumentoId
			AND Eliminar = 1
			AND aadc.StatusReg = 1

			UPDATE aadc Set aadc.StatusReg = 0
			,aadc.FechaBaja = GETDATE()
			,aadc.EmpleadoId = @pa_EmpleadoId
			FROM AsuntosApartadoDocumentosCatalogos aadc
			INNER JOIN @pa_AsuntoDetalleCatalogos_type adc ON aadc.TipoAsuntoId = adc.TipoAsuntoId 
			WHERE aadc.DocumentoId = @DocumentoId
			AND Eliminar = 1
			AND aadc.StatusReg = 1
			
			INSERT INTO AsuntosApartadoDocumentosCatalogos (DocumentoId, TipoAsuntoId, CatalogoId, CatalogoElementoId, FechaAlta, StatusReg, EmpleadoId)
			SELECT 
				@DocumentoId,
				TipoAsuntoId,
				CatalogoId,
				CatalogoElementoId,
				@FechaRegistro,
				1,
				@pa_EmpleadoId
			FROM @pa_AsuntoDetalleCatalogos_type
			WHERE Eliminar = 1
			

			/* DESCRIPCIONES */
			---------------------------

			UPDATE aadd SET aadd.StatusReg = 0
			,aadd.FechaBaja = GETDATE()
			,aadd.EmpleadoId = @pa_EmpleadoId
			FROM AsuntosApartadoDocumentosDescripcion aadd
			INNER JOIN @pa_AsuntoDetalleDescripcion_type adde ON aadd.TipoAsuntoId = adde.TipoAsuntoId 
			WHERE aadd.DocumentoId = @DocumentoId
			AND Eliminar = 1
			AND aadd.StatusReg = 1

			UPDATE aadd SET aadd.StatusReg = 0
			,aadd.FechaBaja = GETDATE()
			,aadd.EmpleadoId = @pa_EmpleadoId
			FROM AsuntosApartadoDocumentosDescripcion aadd
			INNER JOIN @pa_AsuntoDetalleDescripcion_type adde ON aadd.TipoAsuntoId = adde.TipoAsuntoId 
			WHERE aadd.DocumentoId = @DocumentoId
			AND Eliminar = 1
			AND aadd.StatusReg = 1
			
			INSERT INTO AsuntosApartadoDocumentosDescripcion (DocumentoId, TipoAsuntoId, Valor, FechaAlta, StatusReg, EmpleadoId)
			SELECT 
				@DocumentoId,
				TipoAsuntoId,
				Contenido ,
				@FechaRegistro,
				1,
				@pa_EmpleadoId
			FROM @pa_AsuntoDetalleDescripcion_type
			WHERE Eliminar = 1		
			/* --------------------------------------------------------------------------------------------- */

			-->OBTIENE EL XML DE LOS DATOS DESPUES DE SU ACTUALIZACION
			DECLARE @DatosXmlPosterior  XML	
			SET @DatosXmlPosterior = [dbo].[fn_ObtieneDatosDocumentoXML_AccionInsDel_SinPartes] (@pa_AsuntoNeunId,@pa_NoBloque)

			-->MERGE DE XML ANTERIOR Y POSTERIOR
			DECLARE @MergeDatosXmlAnteriorPosterior XML
			SET @MergeDatosXmlAnteriorPosterior = (SELECT @DatosXmlAnteriores, @DatosXmlPosterior FOR XML PATH(''))

			--GUARDA EN BITACORA

			IF @MergeDatosXmlAnteriorPosterior.exist('/Documento') = 1
			BEGIN
				EXEC [SISE_NEWLOG].[dbo].[usp_BitacoraAsuntoDocumentos] @pa_AsuntoNeunId, @PersonaId, @pa_NoBloque ,2, @pa_EmpleadoId, @MergeDatosXmlAnteriorPosterior
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
			IF OBJECT_ID(N'tempdb..#DatosFecha', N'U') IS NOT NULL 
				BEGIN
					DROP TABLE #DatosFecha					
				END
			IF OBJECT_ID(N'tempdb..#DatosCatalogo', N'U') IS NOT NULL 
				BEGIN
					DROP TABLE #DatosCatalogo					
				END
			IF OBJECT_ID(N'tempdb..#DatosDescripcion', N'U') IS NOT NULL 
				BEGIN
					DROP TABLE #DatosDescripcion					
				END
		
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