SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  07/12/2023
-- Description: Inserta o actualiza una determinación y cambia la bandera de firmado sobre el acuerdo. 
-- Basado en:   [uspx_tt_addDocumentoPromociones]
/*
	DECLARE @return_value int
	EXEC [SISE3].[piInsertaActualizaDeterminacion] 
        @pi_AsuntoNeunId = 30314120,
		@pi_Contenido = 3085,
		@pi_TipoCuaderno  = 933,
		@pi_FechaAcuerdo  = '2023-11-22',
		@pi_SintesisOrden = 48,
		@pi_NombreArchivoCompleto = 'PRUEBA SISE049.docx',
		@pi_AsuntoDocumentoId = 48,
        @pi_IPUsuario  = '192.169.0.2',
        @pi_UsuarioCaptura  = 2
        
    EXEC [SISE3].[piInsertaActualizaDeterminacion] 
        @pi_GUID = 'd6d70e25-e7ce-4759-963c-6508477b475f',
        @pi_Firmado = 1,
        @pi_Nombre = '0180000030315424004',
        @pi_Extension = '.pdf'        
*/

    
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaActualizaDeterminacion]
 
(
   		/*Parámetros anteriores
		@pi_AsuntoNeunId BIGINT, 
		@pi_Contenido SMALLINT, ---Id Tipo de contenido,
		@pi_TipoCuaderno SMALLINT,
		@pi_FechaAcuerdo DATETIME, --Fecha del documento
		@pi_SintesisOrden INT = NULL,
		@pi_NombreArchivoCompleto VARCHAR(100),
		@pi_AsuntoDocumentoId INT OUTPUT, 
		@pi_IPUsuario [varchar](50),
		@pi_UsuarioCaptura BIGINT,
		@po_NumeroOrdenDet INT = NULL OUTPUT*/
		@pi_GUID UNIQUEIDENTIFIER,
		@pi_Firmado BIT,
		@pi_IdRuta INT = NULL,
		@pi_Nombre VARCHAR(100) = NULL,
		@pi_Extension VARCHAR(5) = NULL
)
AS
BEGIN
	SET NOCOUNT ON
 
	-- BEGIN TRY
 
		DECLARE @AsuntoId INT
		/***Sentencia***/
		DECLARE @TipoArchivo INT = 0
		DECLARE @Sigilo BIT = 0
		DECLARE @SentenciaDefinitiva BIT = 0
		DECLARE @EsJDA BIT = 0
		DECLARE @TitularId BIGINT
		DECLARE @SecretarioPId BIGINT
		DECLARE @SecretarioCId BIGINT = 0
		DECLARE @ActuarioId BIGINT = 0
		DECLARE @Resumen NVARCHAR(MAX) = NULL
		DECLARE @CatOrganismoId INT
		DECLARE @EstatusArchivo INT = 0
		DECLARE @UsuarioCaptura BIGINT
		DECLARE @IdOrigen INT = 7
		DECLARE @TipoOrigen INT = 7
		DECLARE @VersionPub INT = 0
		DECLARE @InfoReservada INT = 0
		DECLARE @Perspectiva INT = 0
		DECLARE @Criterio INT = NULL
		DECLARE @Trascedental INT = NULL
		DECLARE @EsTratadoInternacional INT = 0
		DECLARE @TipoActo INT =  0
		DECLARE @NombreTratado INT = 0
		DECLARE @Derecho INT = 0
		DECLARE @SubClasificacionDerecho INT = 0
		DECLARE @TipoActoOtro varchar(200) = NULL
		DECLARE @SolicitudReparacion  INT = NULL
		DECLARE @SolicitudReparacionOpcion INT = 0
		DECLARE @SolicitudReparacionOtro VARCHAR(200) = NULL		   
		DECLARE @LecturaFacil BIT = NULL
		DECLARE @TemaEquidadGenero INT = NULL
		DECLARE @AplicacionEfectivaDerechoMujeres BIT = NULL
		DECLARE @TemaAsuntosInternacionales INT = NULL
		DECLARE @AplicacionCriteriosPersGenero INT=NULL
		DECLARE @CriterioPerspecGenAplicado VARCHAR(500) = NULL
		DECLARE @Justificacion varchar(255) = NULL
		DECLARE @FechaExpediente DATETIME
		DECLARE @pi_NumeroOrdenSentencia INT = NULL
		DECLARE @CargoTitular INT
		DECLARE @pi_AsuntoNeunId BIGINT 
		DECLARE @pi_Contenido SMALLINT ---Id Tipo de contenido,
		DECLARE @pi_TipoCuaderno SMALLINT
		DECLARE @pi_FechaAcuerdo DATETIME --Fecha del documento
		DECLARE @pi_SintesisOrden INT = NULL
		DECLARE @pi_NombreArchivoCompleto VARCHAR(100) =  @pi_Nombre + @pi_Extension
		DECLARE @pi_IPUsuario [varchar](50)
		DECLARE @pi_UsuarioCaptura BIGINT
        DECLARE @po_NumeroOrdenDet INT = NULL
        DECLARE @pi_AsuntoDocumentoId INT


		SELECT 
             @pi_AsuntoNeunId = ad.AsuntoNeunId
            ,@pi_Contenido = ad.CatContenidoId
            ,@pi_TipoCuaderno = saa.TipoCuaderno
            ,@pi_FechaAcuerdo = ad.FechaAlta
            ,@pi_SintesisOrden = ad.SintesisOrden
            ,@pi_NombreArchivoCompleto = ISNULL(@pi_NombreArchivoCompleto, ad.NombreArchivo +  ad.ExtensionDocumento)
            ,@pi_UsuarioCaptura = ad.CreadorId
            ,@pi_AsuntoDocumentoId = ad.AsuntoDocumentoId
		FROM AsuntosDocumentos ad
        INNER JOIN Asuntos a
            ON a.AsuntoNeunId = ad.AsuntoNeunId
            AND a.StatusReg = 1
        INNER JOIN SintesisAcuerdoAsunto saa
					ON saa.AsuntoNeunId = ad.AsuntoNeunId
					AND saa.CatOrganismoId = a.CatOrganismoId
					AND saa.IdDocumento=ad.AsuntoDocumentoId
					AND saa.StatusReg != 0
		WHERE uGuidDocumento = @pi_GUID
 
		SELECT @CatOrganismoId = CatOrganismoId, @AsuntoId = AsuntoId, @FechaExpediente = FechaAlta
		FROM Asuntos
		WHERE AsuntoNeunId = @pi_AsuntoNeunId AND StatusReg = 1
 
        IF(@pi_SintesisOrden IS NULL OR @pi_SintesisOrden = 0  )
		BEGIN
			SET @po_NumeroOrdenDet = (SELECT isNULL(MAX(NumeroOrden),0)+1 FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId)
		END
		ELSE 
		BEGIN 
			SET @po_NumeroOrdenDet = (SELECT isNULL(MAX(NumeroOrden),0) FROM DeterminacionesJudiciales WITH(NOLOCK) WHERE AsuntoNeunId = @pi_AsuntoNeunId AND SintesisOrden = @pi_SintesisOrden )
		END
 
		SET @CargoTitular = (SELECT TOP 1 c.CargoId 
							 FROM EmpleadoOrganismo eo WITH(NOLOCK) inner join CatCargo c WITH(NOLOCK) on eo.CargoId = c.CargoId 
							 WHERE CatOrganismoId = @CatOrganismoId and eo.EmpleadoId = @TitularId and eo.StatusRegistro=1 and c.StatusReg=1)
		MERGE INTO DeterminacionesJudiciales dj
		USING 
		(	SELECT @AsuntoId AS AsuntoId, @pi_AsuntoNeunId AS AsuntoNeunId, @po_NumeroOrdenDet AS NumeroOrden, @pi_SintesisOrden AS SintesisOrden, @pi_TipoCuaderno AS TipoCuaderno,
				@pi_Contenido AS Contenido, @TitularId AS TitularId , @CargoTitular AS CargoTitular, @SecretarioPId AS SecretarioPId, @ActuarioId AS ActuarioId,
				@pi_FechaAcuerdo AS FechaAuto,@CatOrganismoId AS CatOrganismoId,NULL AS NomArchivoReal, @EstatusArchivo EstatusArchivo,
				NULL AS IPUsuario, GETDATE() AS FechaAlta, NULL AS FechaBaja, @pi_UsuarioCaptura AS UsuarioCaptura, 2 AS StatusReg,
				@IdOrigen AS Origen,@TipoOrigen AS TipoOrigen,@Justificacion AS Justificacion, @pi_NumeroOrdenSentencia AS NumeroOrdenSentencia,
				@pi_NombreArchivoCompleto AS NombreArchivo, @TipoArchivo AS TipoArchivo, @Sigilo AS Sigilo, @SentenciaDefinitiva AS SentenciaDefinitiva, 
				@EsJDA AS EsJDA, @SecretarioCId AS SecretarioCId, @Resumen AS Resumen, @VersionPub AS VersionPub,@InfoReservada AS InfoReservada,
				@Criterio AS Criterio, @Trascedental AS Trascedental, @EsTratadoInternacional AS EsTratadoInternacional, @TipoActo AS TipoActo,
				@NombreTratado AS NombreTratado, @Derecho AS Derechos, @SubClasificacionDerecho AS SubClasificacionDerechos, 
				@TipoActoOtro AS TipoActoOtro , @SolicitudReparacion AS SolicitudReparacion, @SolicitudReparacionOpcion AS SolicitudReparacionOpcion, 
				@SolicitudReparacionOtro AS SolicitudReparacionOtro, @LecturaFacil AS LecturaFacil, @TemaEquidadGenero AS TemaEquidadGenero, 
				@AplicacionEfectivaDerechoMujeres AS AplicacionEfectivaDerechoMujeres, @TemaAsuntosInternacionales AS TemaAsuntosInternacionales, 
				@AplicacionCriteriosPersGenero AS AplicaCritPerspecGenero, @CriterioPerspecGenAplicado AS CriterioPerspectivaGenAplicado
 
		)AS det
		ON (dj.AsuntoNeunId = det.AsuntoNeunId AND dj.NumeroOrden = det.NumeroOrden AND dj.NumeroOrden = det.NumeroOrden AND dj.SintesisOrden = det.SintesisOrden) 
		WHEN NOT MATCHED THEN 
			INSERT (AsuntoId ,AsuntoNeunId ,NumeroOrden ,SintesisOrden ,TipoCuaderno ,Contenido ,TitularId ,CargoTitular,SecretarioPId, ActuarioId,
			FechaAuto ,CatOrganismoId ,NombreArchivo ,NomArchivoReal ,EstatusArchivo ,IPUsuario ,FechaAlta,FechaBaja,UsuarioCaptura,StatusReg,
			Origen,TipoOrigen,Justificacion)	
			VALUES (det.AsuntoId ,det.AsuntoNeunId ,det.NumeroOrden ,det.SintesisOrden ,det.TipoCuaderno ,det.Contenido ,det.TitularId ,det.CargoTitular,det.SecretarioPId,det.ActuarioId,
			det.FechaAuto, det.CatOrganismoId,det.NombreArchivo,det.NomArchivoReal,det.EstatusArchivo,det.IPUsuario,det.FechaAlta,det.FechaBaja,det.UsuarioCaptura,det.StatusReg,
			det.Origen,det.TipoOrigen,det.Justificacion)	
		WHEN MATCHED THEN 
			UPDATE  
			SET NumeroOrdenSentencia = det.NumeroOrdenSentencia
				,NombreArchivo = det.NombreArchivo
				,TipoArchivo = det.TipoArchivo
				,Sigilo = det.Sigilo
				,SentenciaDefinitiva = det.SentenciaDefinitiva 
				,EsJDA = det.EsJDA 			
				,SecretarioCId = det.SecretarioCId 
				,Resumen = det.Resumen
				,VersionPub=det.VersionPub
				,InfoReservada=det.InfoReservada
				,Criterio=det.Criterio 
				,Trascedental=det.Trascedental 
				,EsTratadoInternacional =det.EsTratadoInternacional 
				,TipoActo =det.TipoActo
				,NombreTratado=det.NombreTratado
				,Derechos=det.Derechos
				,SubClasificacionDerechos=det.SubClasificacionDerechos
				,TipoActoOtro=det.TipoActoOtro 
				,SolicitudReparacion =det.SolicitudReparacion
				,SolicitudReparacionOpcion =det.SolicitudReparacionOpcion
				,SolicitudReparacionOtro = det.SolicitudReparacionOtro
				,LecturaFacil = det.LecturaFacil
				,TemaEquidadGenero = det.TemaEquidadGenero
				,AplicacionEfectivaDerechoMujeres = det.AplicacionEfectivaDerechoMujeres
				,TemaAsuntosInternacionales = det.TemaAsuntosInternacionales
				,AplicaCritPerspecGenero=det.AplicaCritPerspecGenero                                          
				,CriterioPerspectivaGenAplicado=det.CriterioPerspectivaGenAplicado
				,Justificacion= det.Justificacion;
			/* Retorno la Información Requerida */
            SELECT @pi_SintesisOrden AS SintesisOrden
                ,@CatOrganismoId AS CatOrganismoId
				,@po_NumeroOrdenDet AS NumeroOrden

            UPDATE AsuntosDocumentos
            SET Firmado = @pi_Firmado
            WHERE uGuidDocumento = @pi_GUID
 
        -- END TRY 
        -- BEGIN CATCH
		-- 	EXECUTE [SISE3].[peEliminaAcuerdo]
		-- 			@pi_AsuntoNeunId ,
		-- 			@pi_AsuntoDocumentoId, 
		-- 			@CatOrganismoId					
        --         -- Ejecuta la rutina de recuperacion de errores.
        --     EXECUTE dbo.usp_GetErrorInfo;
        -- END CATCH;
 
END
