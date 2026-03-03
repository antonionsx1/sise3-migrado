SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  07/12/2023
-- Description: Inserta y actualizar Asunto Documento y Sintesis
-- Basado en:   [uspx_tt_addDocumentoPromociones]
/*
	DECLARE @return_value int
  
	EXEC [SISE3].[piInsertaActualizaSintesisAcuerdo]
        @pi_AsuntoNeunId = 30314120,
		@pi_TipoCuaderno  = 933,
		@pi_NombreDocumento = 'PRUEBA SISE',
		@pi_Contenido = 3085,
		@pi_FechaAcuerdo  = '2023-11-22',
        @pi_UsuarioCaptura  = 2,
        @po_AsuntoDocumentoId = 48,
		@pi_Sintesis = '', 
        @po_SintesisOrden = 48*/
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaActualizaSintesisAcuerdo]

(
   		@pi_AsuntoNeunId BIGINT, 
		@pi_TipoCuaderno SMALLINT,
		@pi_NombreDocumento VARCHAR(255) = NULL, --Nombre real del documento
		@pi_ExtensionDocumento VARCHAR(20) = NULL,
		@pi_Contenido SMALLINT, ---Id Tipo de contenido,
		@pi_FechaAcuerdo DATETIME, --Fecha del documento
		@pi_UsuarioCaptura BIGINT,        
		@po_AsuntoDocumentoId INT OUTPUT, 
		@pi_Sintesis VARCHAR(MAX) = NULL, 
		@po_SintesisOrden INT = NULL OUTPUT, 
		@po_NombreArchivo  VARCHAR(50) = NULL OUTPUT 
)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

		DECLARE @AsuntoId INT
		DECLARE @CatOrganismoId INT
		DECLARE @FechaExpediente DATETIME
		DECLARE @ClasificaCuaderno INT
		DECLARE @TipoAsunto INT
		DECLARE @Update SMALLINT
		DECLARE @TipoArchivo INT = 0
		DECLARE @Sigilo BIT = 0
		DECLARE @SentenciaDefinitiva BIT = 0
		DECLARE @EsJDA BIT = 0
		DECLARE @TitularId BIGINT
		DECLARE @SecretarioPId BIGINT
		DECLARE @SecretarioCId BIGINT = 0
		DECLARE @Resumen NVARCHAR(MAX)
        DECLARE @CatAutorizacionId INT

		SET @Update = 0

		SELECT @CatOrganismoId = CatOrganismoId, @AsuntoId = AsuntoId, @FechaExpediente = FechaAlta
		FROM Asuntos
		WHERE StatusReg = 1  AND AsuntoNeunId = @pi_AsuntoNeunId

			 
		IF CAST(@pi_FechaAcuerdo AS DATE) < CAST(@FechaExpediente AS DATE)
			THROW 51000,'Fecha de presentación de acuerdo no puede ser inferior a fecha de expediente',1;

      	SELECT @TipoAsunto = CatTipoAsuntoId 
		FROM Asuntos with(nolock) 
		WHERE AsuntoId=@AsuntoId AND AsuntoNeunId=@pi_AsuntoNeunId  

	    IF @TipoAsunto IN (1,2,4,46,67,74,109,124)
		BEGIN
			SET @ClasificaCuaderno = (Select dbo.fnObtieneClasificacionCuadernoDeTipoCuaderno (@pi_TipoCuaderno))
		END 
		ELSE
		BEGIN
			SET @ClasificaCuaderno = 0
		END

		---Validación Sintesis Nueva o Edición	
        IF(@po_SintesisOrden IS NULL OR @po_SintesisOrden = 0  )
        BEGIN

			SELECT @po_SintesisOrden = ISNULL(MAX(SintesisOrden),0)+1 
			FROM SintesisAcuerdoAsunto WITH(NOLOCK) 
			WHERE AsuntoNeunId = @pi_AsuntoNeunId 

			SELECT @po_AsuntoDocumentoId = ISNULL(MAX(AsuntoDocumentoId),0)+1
			FROM AsuntosDocumentos WITH(NOLOCK)
			WHERE AsuntoNeunId = @pi_AsuntoNeunId

			--SET @pi_Sintesis = 'Síntesis creada automáticamente desde Determinaciones Judiciales' 
		END
		ELSE
		BEGIN
			SET @Update = 1		

			SELECT 	@po_NombreArchivo = IIF(ISNULL(@po_NombreArchivo, '')='', NombreArchivo , @po_NombreArchivo), 
					@pi_ExtensionDocumento = IIF(ISNULL(@pi_ExtensionDocumento, '')='', ExtensionDocumento , @pi_ExtensionDocumento) 
					FROM AsuntosDocumentos WITH(NOLOCK)
					WHERE AsuntoNeunId = @pi_AsuntoNeunId 
					AND AsuntoDocumentoId = @po_AsuntoDocumentoId
		END

		/* SE CREA LA SINTESIS */
		MERGE INTO SintesisAcuerdoAsunto trg
		USING 
		(	
			SELECT @po_SintesisOrden AS SintesisOrden, @AsuntoId AS AsuntoId, @pi_AsuntoNeunId AS AsuntoNeunId, @CatOrganismoId AS CatOrganismoId
				  ,GETDATE() AS FechaAcuerdo, @pi_Sintesis AS Sintesis
				  ,null AS FechaPublicacion, 0 AS Titular, 0 AS Actuario, @ClasificaCuaderno AS ClasificacionCuaderno
				  ,@pi_TipoCuaderno AS TipoCuaderno, 0 AS Parte1, 0 AS Parte2,'' AS Parte1YOtros,'' AS Parte2YOtros,1 AS EstatusSintesis
				  ,@pi_UsuarioCaptura AS UsuarioCaptura, GETDATE() AS FechaAlta, 2 AS StatusReg, @po_AsuntoDocumentoId AS IdDocumento, 7 AS TipoOrigen
		) AS src
		ON 
		(
			trg.CatOrganismoId = src.CatOrganismoId
            AND trg.AsuntoNeunId = src.AsuntoNeunId
            AND trg.SintesisOrden = src.SintesisOrden
		)          
						
		WHEN NOT MATCHED THEN  
		INSERT ([SintesisOrden] ,[AsuntoId],[AsuntoNeunId],[CatOrganismoId],[FechaAuto] ,[Sintesis] ,[FechaPublicacion] ,[Titular] ,[Actuario] , [ClasificacionCuaderno], [TipoCuaderno] 
			,[Parte1],[Parte2],[Parte1YOtros],[Parte2YOtros],[EstatusSintesis],[UsuarioCaptura],[FechaAlta],[StatusReg],[IdDocumento],[TipoOrigen])
		VALUES (src.SintesisOrden, src.AsuntoId, src.AsuntoNeunId, src.CatOrganismoId,src.FechaAcuerdo, src.Sintesis, src.FechaPublicacion, src.Titular, src.Actuario,src.ClasificacionCuaderno, 
			src.TipoCuaderno,src.Parte1, src.Parte2,src.Parte1YOtros,src.Parte2YOtros,src.EstatusSintesis,src.UsuarioCaptura, src.FechaAlta, src.StatusReg, src.IdDocumento, src.TipoOrigen)
        
		WHEN MATCHED THEN
			UPDATE      
			SET Sintesis = ISNULL(src.Sintesis,trg.Sintesis), FechaAuto = src.FechaAcuerdo, TipoOrigen = 7,FechaActualizacion =GETDATE(), StatusReg = 1;


        SELECT @CatAutorizacionId =CatAutorizacionDocumentosId
        FROM AsuntosDocumentos WITH(NOLOCK)
        WHERE AsuntoNeunId = @pi_AsuntoNeunId 
        AND AsuntoDocumentoId = @po_AsuntoDocumentoId
		
		MERGE INTO [AsuntosDocumentos] tra
		USING 
		(	SELECT  @pi_AsuntoNeunId AS AsuntoNeunId, @AsuntoId AS AsuntoId, @po_AsuntoDocumentoId AS AsuntoDocumentoId, @pi_NombreDocumento AS NombreDocumento,'' AS RutaDocumento
			, @po_NombreArchivo AS NombreArchivo, IIF(@CatAutorizacionId IS NULL, 1, @CatAutorizacionId) AS CatAutorizacionDocumentosId, @pi_ExtensionDocumento AS ExtensionDocumento, 0 AS CatPlantillaId, @pi_Contenido AS CatContenidoId
			, '' AS ContenidoDocumento, CONVERT(varbinary(max),'') AS ContenidoAsunto, @po_SintesisOrden AS SintesisOrden, @pi_TipoCuaderno AS TipoCuaderno
			, @TipoArchivo AS TipoArchivo, @Sigilo AS Sigilo, @SentenciaDefinitiva AS SentenciaDefinitiva, @EsJDA AS esJDA, @SecretarioPId AS SecretarioPId
			, @SecretarioCId AS SecretarioCId, @TitularId AS TitularId,@pi_UsuarioCaptura AS UsuarioCaptura, @Resumen AS Resumen, @pi_FechaAcuerdo AS FechaAcuerdo  , 7 TipoRuta                
		)AS asd
		ON (tra.AsuntoNeunId = asd.AsuntoNeunId AND tra.AsuntoDocumentoId = asd.AsuntoDocumentoId )
					
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

		/* Retorno la Información Requerida */
        /* SELECT @po_AsuntoDocumentoId AS AsuntoDocumentoId
                ,@po_SintesisOrden AS SintesisOrden
                ,@CatOrganismoId AS CatOrganismoId
				,@pi_NumeroOrdenDet AS NumeroOrden**/

        END TRY 
        BEGIN CATCH
				EXECUTE [SISE3].[peEliminaAcuerdo]
					@pi_AsuntoNeunId ,
					@po_AsuntoDocumentoId, 
					@CatOrganismoId		
                -- Ejecuta la rutina de recuperacion de errores.	
                EXECUTE dbo.usp_GetErrorInfo;
        END CATCH;

END
