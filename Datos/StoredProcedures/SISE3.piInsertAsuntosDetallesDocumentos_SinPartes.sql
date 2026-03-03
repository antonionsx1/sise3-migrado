SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Anabel Gonzalez 
-- Alter date: 07/10/2024 
-- Description: Inserta datos del apartado de captura de Documentos
-- Ejemplo :[SISE3].[piInsertAsuntosDetallesDocumentos_SinPartes]
-- Original : [dbo].[usp_AsuntosDetallesDocumentosIns_SinPartes]
-- ============================================= 
ALTER PROCEDURE [SISE3].[piInsertAsuntosDetallesDocumentos_SinPartes]
 @pi_AsuntoNeunId INT					
,@pi_EmpleadoId INT	
,@pi_CatOrganismoId INT
,@pi_AsuntoDetalleFechas_type [SISE3].[AsuntosDetalleFechas_type] READONLY 
,@pi_AsuntoDetalleDescripcion_type [SISE3].[AsuntoDetalleDescripcion_type] READONLY 
,@pi_AsuntoDetalleCatalogos_type [SISE3].[AsuntosDetalleCatalogos_type] READONLY
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
			BEGIN TRAN
		
			DECLARE @AsuntoId INT = NULL
			DECLARE @PersonaId INT
			DECLARE @DocumentoId INT = NULL
			DECLARE @FechaRegistro DATETIME
			
			SET @AsuntoId = (SELECT AsuntoId FROM [Asuntos] WITH(NOLOCK)
							 WHERE [AsuntoNeunId] = @pi_AsuntoNeunId )	
			SET @FechaRegistro = GETDATE()
			SET @PersonaId = 0
			
			
			--> CÁLCULO DE NOBLOQUE
			DECLARE @NoBloque INT = 0
			DECLARE @NoBloqueTmp INT = 0
			
			SELECT @NoBloque = ISNULL(MAX(adf.NoBloque),0)
			FROM AsuntosDetalleFechas adf WITH(NOLOCK)
			INNER JOIN CamposPropiedades cp WITH(NOLOCK) ON adf.TipoAsuntoId = cp.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @pi_AsuntoNeunId
			AND cp.TipoPropiedadId = 5
			AND adf.StatusReg = 1 And cp.StatusReg = 1
			AND cp.Observaciones = 'FechaDeExhibicion'
			
			--> Se obtiene el NoBloque de otro campo (considerado como siempre requerido) con la finalidad
			--  conocer si existe un valor más alto que la fecha de exhibición, pues dado los problemas de
			--  migración puede ser probable que la fecha de exhibición no exista.

			SELECT @NoBloqueTmp = ISNULL(MAX(adde.NoBloque),0)
			FROM AsuntosDetalleDescripcion adde WITH(NOLOCK)
			INNER JOIN CamposPropiedades cp WITH(NOLOCK) ON adde.TipoAsuntoId = cp.TipoAsuntoId
			WHERE adde.AsuntoNeunId = @pi_AsuntoNeunId
			AND cp.TipoPropiedadId = 5
			AND adde.StatusReg = 1 And cp.StatusReg = 1
			AND cp.Observaciones = 'NumeroDeRegistro'
			
			--> Con el siguiente bloque de condiciones, se busca obtener el número más alto de Nobloque existente
			--  en caso de que pudiera no tenerse el valor del campo Fecha de exhibición. Con esto se evitaría 
			--  guardar datos en NoBloque que sí existe pero que no se pudo obtener debido a que el valor de fecha
			--  de exhibición no se migró.

			IF @NoBloque != @NoBloqueTmp
				BEGIN
					IF @NoBloque > @NoBloqueTmp
						Set @NoBloque = @NoBloque + 1
					ELSE
						Set @NoBloque = @NoBloqueTmp + 1
				END
			ELSE 
				SET @NoBloque = @NoBloque + 1
				
			IF EXISTS(SELECT TipoAsuntoId From @pi_AsuntoDetalleFechas_type) Or
			   EXISTS(SELECT TipoAsuntoId From @pi_AsuntoDetalleCatalogos_type) Or
			   EXISTS(SELECT TipoAsuntoId From @pi_AsuntoDetalleDescripcion_type)
			BEGIN
				INSERT INTO AsuntosApartadoDocumentos WITH(ROWLOCK) (CatOrganismoId, AsuntoNeunId, PersonaId, NoBloque, FechaAlta, StatusReg, EmpleadoId)
				VALUES (@pi_CatOrganismoId, @pi_AsuntoNeunId, @PersonaId, @NoBloque, @FechaRegistro ,1, @pi_EmpleadoId)
				SET @DocumentoId = (SELECT ISNULL(MAX(DocumentoId),1) FROM AsuntosApartadoDocumentos WITH(NOLOCK) )
				
			END
															
			--> DATOS DE TIPO FECHA
			-------------------------
			IF EXISTS(SELECT TipoAsuntoId From @pi_AsuntoDetalleFechas_type)
				BEGIN
					--> Cálculo del consecutivo de la tabla
					DECLARE @MaxAsuntoDetalleFechaId [int] = null	
					SET @MaxAsuntoDetalleFechaId = (SELECT ISNULL(MAX(AsuntoDetalleFechasId),0) 
													FROM AsuntosDetalleFechas WITH(ROWLOCK) 
													WHERE AsuntoNeunId = @pi_AsuntoNeunId )
				
					SELECT @pi_AsuntoNeunId AsuntoNeunid
						, @AsuntoId AsuntoId
						,((ROW_NUMBER()OVER (ORDER BY  @pi_AsuntoNeunId ASC) ) + @MaxAsuntoDetalleFechaId) AsuntoDetalleFechasId
						, TipoAsuntoId						
						, ValorCampoAsunto
						, NoCaptura
						, @NoBloque NoBloque
						, 0 NoBloquePadre
						, Consecutivo
						, @pi_EmpleadoId EmpleadoId
					INTO #DatosFecha
					FROM @pi_AsuntoDetalleFechas_type
					WHERE Eliminar = 1
					
					INSERT INTO AsuntosDetalleFechas WITH(ROWLOCK) (AsuntoNeunId ,AsuntoId ,AsuntoDetalleFechasId ,TipoAsuntoId ,ValorCampoAsunto ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)
					SELECT * FROM #DatosFecha
					
					INSERT INTO AsuntosApartadoDocumentosFechas WITH(ROWLOCK) (DocumentoId, TipoAsuntoId,Valor,FechaAlta,StatusReg,EmpleadoId)
					SELECT 
						@DocumentoId,
						TipoAsuntoId,
						ValorCampoAsunto,
						@FechaRegistro,
						1,
						@pi_EmpleadoId
					FROM #DatosFecha
					
					DROP TABLE #DatosFecha
				END
				
			--> DATOS DE TIPO CATÁLOGO
			------------------------------------
			IF EXISTS(SELECT TipoAsuntoId FROM @pi_AsuntoDetalleCatalogos_type)
				BEGIN
					--> Cálculo del consecutivo de la tabla
					DECLARE @MaxAsuntoDetalleCatalogoId INT = NULL	
					SET @MaxAsuntoDetalleCatalogoId = (SELECT ISNULL(MAX(AsuntoDetalleCatalogosId),0) 
													 FROM AsuntosDetalleCatalogos WITH(NOLOCK) 
													 WHERE AsuntosNeunId = @pi_AsuntoNeunId )
					
					SELECT @pi_AsuntoNeunId AsuntosNeunid
						, @AsuntoId AsuntoId
						,((ROW_NUMBER ()OVER (ORDER BY @pi_AsuntoNeunId ASC) ) + @MaxAsuntoDetalleCatalogoId) AsuntoDetalleCatalogosId
						, TipoAsuntoId						
						, CatalogoId
						, CatalogoElementoId
						, NoCaptura
						, @NoBloque NoBloque
						, 0 NoBloquePadre
						, Consecutivo
						, @pi_EmpleadoId EmpleadoId
					INTO #DatosCatalogo
					FROM @pi_AsuntoDetalleCatalogos_type
					WHERE Eliminar = 1
					
					INSERT INTO AsuntosDetalleCatalogos WITH(ROWLOCK)(AsuntosNeunId ,AsuntoId ,AsuntoDetalleCatalogosId ,TipoAsuntoId ,CatTipoCatalogoAsuntoId,CatCatalogoAsuntoId ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)
					SELECT * FROM #DatosCatalogo
					
					INSERT INTO AsuntosApartadoDocumentosCatalogos WITH(ROWLOCK)(DocumentoId, TipoAsuntoId,CatalogoId, CatalogoElementoId,FechaAlta,StatusReg,EmpleadoId)
					SELECT 
						@DocumentoId,
						TipoAsuntoId,
						CatalogoId,
						CatalogoElementoId,
						@FechaRegistro,
						1,
						@pi_EmpleadoId
					FROM #DatosCatalogo
					
					
					DROP TABLE #DatosCatalogo
				END
			
			--> DATOS DE TIPO DESCRIPCIÓN	
			--------------------------------
			IF EXISTS(SELECT TipoAsuntoId FROM @pi_AsuntoDetalleDescripcion_type)
				BEGIN
					--> Cálculo del consecutivo de la tabla
					DECLARE @MaxAsuntoDetalleDescripcionId INT = null	
					SET @MaxAsuntoDetalleDescripcionId = (SELECT ISNULL(MAX(AsuntoDetalleDescripcionId),0) 
															FROM [AsuntosDetalleDescripción] WITH(NOLOCK)
															WHERE [AsuntoNeunId] = @pi_AsuntoNeunId )
				
					SELECT @pi_AsuntoNeunId AsuntoNeunid
						, @AsuntoId as AsuntoId
						,((ROW_NUMBER()OVER (ORDER BY @pi_AsuntoNeunId ASC) ) + @MaxAsuntoDetalleDescripcionId) AsuntoDetalleDescripcionId
						, TipoAsuntoId						
						, Contenido
						, NoCaptura
						, @NoBloque NoBloque
						, 0 NoBloquePadre
						, Consecutivo
						, @pi_EmpleadoId EmpleadoId
					INTO #DatosDescripcion
					FROM @pi_AsuntoDetalleDescripcion_type
					WHERE Eliminar = 1
					
					INSERT INTO AsuntosDetalleDescripcion WITH(ROWLOCK)(AsuntoNeunId ,AsuntoId ,AsuntoDetalleDescripcionId ,TipoAsuntoId ,Contenido ,NoCaptura,NoBloque,NoBloquePadre,Consecutivo, EmpleadoId)
					SELECT * From #DatosDescripcion
										
					INSERT INTO AsuntosApartadoDocumentosDescripcion WITH(ROWLOCK)(DocumentoId, TipoAsuntoId,Valor, FechaAlta,StatusReg,EmpleadoId)
					SELECT 
						@DocumentoId,
						TipoAsuntoId,
						Contenido,
						@FechaRegistro,
						1,
						@pi_EmpleadoId
					FROM #DatosDescripcion
					
					DROP TABLE #DatosDescripcion
				END

			--> GUARDAR EN BITACORA 

			DECLARE @DatosXML XML
			SET @DatosXML = (SELECT [dbo].[fn_ObtieneDatosDocumentoXML_AccionInsDel_SinPartes](@pi_AsuntoNeunId, @NoBloque))
			
			IF @DatosXML IS NOT NULL
			BEGIN
				EXEC [SISE_NEWLOG].[dbo].[usp_BitacoraAsuntoDocumentos] @pi_AsuntoNeunId, @PersonaId, @NoBloque ,1, @pi_EmpleadoId, @DatosXML
			END
			
			
		END TRY
		BEGIN CATCH
			
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
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION;
		SET NOCOUNT OFF
	END