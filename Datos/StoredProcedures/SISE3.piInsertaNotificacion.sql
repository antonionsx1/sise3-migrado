SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  31/10/2013
-- Description: Inserta y actualizar Asunto Documento 
-- Basado en:   [uspx_tt_addDocumentoPromociones]
/*
	DECLARE @return_value int
	DECLARE @promo [SISE3].[PromocionesAcuerdo_type],
	   @DocumentoId int,
	   @po_NombreArchivo varchar(50), 
	   @asunto SISE3.AutoridadAsunto_type, 
	   @per [PersonasNotificacionIndividual]
        
   INSERT INTO @promo VALUES (174, 2023, 4,1)
   INSERT INTO @promo VALUES (141, 2023, 4,0)

   INSERT INTO @asunto([TipoAnexoId],[AnexoParteId],[AnexoParteDescripcion], TextoOficioLibre) values (6, 1837806, 'OFICIO','TEXTO LIBRE')

   INSERT INTO @per values (163079366, 0, 6, null, null, 0, 0)
  
  EXEC [SISE3].piInsertaActualizaDocumentoAcuerdo 
        @pi_AsuntoNeunId = 30314120,
		@pi_NombreDocumento = 'PRUEBA SISE',
        @pi_ExtensionDocumento  = '',
		@pi_Contenido = 3085,
		@pi_TipoCuaderno  = 933,
		@pi_FechaAcuerdo  = '2023-11-22',
		@pi_SintesisOrden = 48,

        @pi_IPUsuario  = '192.169.0.2',
        @pi_UsuarioCaptura  = 2,
        @pi_PromocionesDeterminacion  = @promo,
		@pi_AutoridadAsunto = @asunto,
		@pi_PersonasNotificacion =  @per,
        @pi_AsuntoDocumentoId = 48,
        @po_NombreArchivo = ''*/
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].piInsertaNotificacion

(
   		@pi_AsuntoNeunId BIGINT, 
		@pi_SintesisOrden INT = NULL,

		/***Sentencia***/
		@pi_IPUsuario [varchar](50),
		@pi_UsuarioCaptura BIGINT,
		@pi_TipoCuaderno SMALLINT,
		@pi_AsuntoDocumentoId INT OUTPUT, 
		@po_NombreArchivo  VARCHAR(50) OUTPUT ,
		@po_NumOrdenNotificacion INT OUTPUT, 
		@pi_NumeroOrdenDet INT
)
AS
BEGIN
	SET NOCOUNT ON
		
	BEGIN TRY

		DECLARE @CatOrganismoId INT 
		DECLARE @AsuntoId INT
		DECLARE @FechaExpediente DATETIME

		SELECT @CatOrganismoId = CatOrganismoId, @AsuntoId = AsuntoId, @FechaExpediente = FechaAlta
		FROM Asuntos
		WHERE AsuntoNeunId = @pi_AsuntoNeunId AND StatusReg = 1


		IF NOT EXISTS(SELECT TOP 1 [AsuntoNeunId] 
					  FROM [NotificacionElectronica] 
					  WHERE [CatOrganismoId] = @CatOrganismoId
							AND  [AsuntoNeunId] = @pi_AsuntoNeunId
							AND  [SintesisOrden] = @pi_SintesisOrden
							AND  [StatusReg]=1)
		BEGIN

			SET @po_NumOrdenNotificacion = (SELECT  ISNULL(MAX(NumeroOrden), 0) + 1 
											FROM NotificacionElectronica WITH(NOLOCK) 
											WHERE AsuntoNeunId=@pi_AsuntoNeunId)           

			INSERT INTO [NotificacionElectronica] WITH(ROWLOCK)
			(
				[AsuntoNeunId]
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
			(
				@pi_AsuntoNeunId
				,@AsuntoId
				,@pi_SintesisOrden
				,@po_NumOrdenNotificacion
				,@CatOrganismoId
				,@pi_TipoCuaderno
				,@pi_UsuarioCaptura
				,GETDATE()
				,1
				,NULL
				,0
				,@pi_IPUsuario
				,1
				,1
			)
			-- Martin Llamada a procedimiento para asignar permisos al archivo en expediente electronico
			EXEC piPermisoDeterminacionJudicial @AsuntoId, @pi_AsuntoNeunId, @pi_NumeroOrdenDet, @pi_SintesisOrden
		END
				
		/* Retorno la Información Requerida */
        SELECT @pi_SintesisOrden AS SintesisOrden
                ,@CatOrganismoId AS CatOrganismoId
				,@pi_NumeroOrdenDet AS NumeroOrden
	END TRY 
    BEGIN CATCH
		EXECUTE [SISE3].[peEliminaAcuerdo]
					@pi_AsuntoNeunId ,
					@pi_AsuntoDocumentoId, 
					@CatOrganismoId		

		EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;

END
