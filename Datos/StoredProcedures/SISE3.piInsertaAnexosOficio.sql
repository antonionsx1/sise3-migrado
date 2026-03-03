SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  16/11/2013
-- Description: Inserta y actualizar Anexo de oficios
-- Basado en:   [usp_Word_Anexos_AnexosOficiosIns3]

	/*DECLARE @return_value int,
		   @pi_AutoridadAsunto SISE3.AutoridadAsunto_type
		   DECLARE @GUID UNIQUEIDENTIFIER = NEWID()
	
    INSERT INTO @pi_AutoridadAsunto([TipoAnexoId],[AnexoParteId],[AnexoParteDescripcion], TextoOficioLibre) --values (6, 1837806, 'OFICIO','TEXTO LIBRE')
	SELECT AnexoTipoId, AnexoParteId, 'Oficio', 'Oficio'
	FROM Anexos where AsuntoNeunId = 30315077
	and AnexoId in (41,42)
	EXEC [SISE3].[piInsertaAnexosOficio]
				30314120 ,
				180 ,  
				2 ,
				48 ,
				@pi_AutoridadAsunto,
				'0180000030315077023',
				'.docx',
				@GUID*/
-- =============================================
-- Basado en:   [piInsertaAnexosOficio]
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaAnexosOficio]
(
@pi_AsuntoNeunId bigint ,
@pi_CatOrganismoId int ,
@pi_TipoAnexoId int ,
@pi_AsuntoDocumentoId int,
@pi_AsuntosPartes AS SISE3.AutoridadAsunto_type  READONLY   -- Tipo Tabla donde se pasa el IDParte y NombreParte
,@pi_NombreArchivo VARCHAR (50),
@pi_ExtensionDocumento VARCHAR(20),
@pi_GUID UNIQUEIDENTIFIER
)
AS

DECLARE @TipoRuta int = 3 
DECLARE @IdTipoRuta INT
				
BEGIN
SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRAN

            SELECT @IdTipoRuta = rc.kId
            FROM  CAT_RutasChunk rc 
            WHERE rc.iGrupo = 1 
            AND rc.iEscritura = 1

			-- Valido si el arreglo trae registros, de lo contrario, no se hace nada
			IF (SELECT COUNT(AnexoParteId) FROM @pi_AsuntosPartes) = 0
				RETURN (0)
				
			-- Creo Tabla para trabajar
			SELECT (ROW_NUMBER () OVER (ORDER BY AnexoParteId))AS RowId, AnexoParteId , UPPER(AnexoParteDescripcion) AS AnexoParteDescripcion, 0 AS Folio, TipoAnexoId As TipoAnexoId,  TextoOficioLibre
			INTO #Partes 
			FROM @pi_AsuntosPartes

			-- Variable que me servira para saber que Folio le fue asignado
			DECLARE @Folio int
			DECLARE @FolioInicial int
			SET @Folio = 0
				
				
			WHILE EXISTS(SELECT AnexoParteId FROM #Partes WHERE Folio = 0)
			BEGIN
				SET @Folio = 0 
		      
			      
				IF EXISTS(select * from OficiosFolios where CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE()) AND StatusFolio = 0 AND TipoAnexoId = @pi_TipoAnexoId)
				BEGIN
					SELECT @Folio = MIN(Folio) from OficiosFolios where CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE()) AND StatusFolio = 0 AND TipoAnexoId = @pi_TipoAnexoId
			 		UPDATE OficiosFolios SET StatusReg=1 where CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE()) AND StatusFolio = 0 AND TipoAnexoId = @pi_TipoAnexoId AND Folio = @Folio
		      
				END
				ELSE
				BEGIN
					SELECT TOP 1 @Folio = ISNULL(Max(Folio),0) FROM OficiosFolios with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE()) AND StatusFolio = 1 AND TipoAnexoId = @pi_TipoAnexoId
					SELECT @FolioInicial = IsNull(Max(NumeroInicial),0) FROM AnexosConf with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND AnexosTipo = @pi_TipoAnexoId AND Anio = YEAR(GETDATE())
					IF @Folio < @FolioInicial
					BEGIN
						INSERT INTO OficiosFolios with(rowlock)(CatOrganismoId, Año, Folio,TipoAnexoId, StatusFolio, FechaAlta, FechaBaja, StatusReg) 
						SELECT @pi_CatOrganismoId,
							YEAR(GETDATE()),
							IsNull(Max(@FolioInicial),0),
							@pi_TipoAnexoId,
							1,
							GETDATE(),
							NULL,
							1
						FROM OficiosFolios with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE())  AND TipoAnexoId = @pi_TipoAnexoId			      
						SET @Folio = (SELECT Max(Folio) FROM OficiosFolios with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE())  AND TipoAnexoId = @pi_TipoAnexoId )
					END
					ELSE 
					BEGIN
					--	Voy a generar un folio
						INSERT INTO OficiosFolios with(rowlock) (CatOrganismoId, Año, Folio,TipoAnexoId, StatusFolio, FechaAlta, FechaBaja, StatusReg) 
						SELECT @pi_CatOrganismoId,
							YEAR(GETDATE()),
							IsNull(Max(Folio),0) + 1,
							@pi_TipoAnexoId,
							1,
							GETDATE(),
							NULL,
							1
						FROM OficiosFolios with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE())  AND TipoAnexoId = @pi_TipoAnexoId
						SET @Folio = (SELECT Max(Folio) FROM OficiosFolios with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND Año = YEAR(GETDATE())  AND TipoAnexoId = @pi_TipoAnexoId )
						SET ROWCOUNT 1
					END
					UPDATE #Partes SET Folio = @Folio,
						AnexoParteId = CASE WHEN ISNULL(AnexoParteId, 0) = 0 THEN @Folio ELSE AnexoParteId END						
					WHERE Folio = 0
			END			
		END	
				
				
		SET ROWCOUNT 0	
		
		DECLARE @Maximo INT
		
		---Insert las partes nuevas
		SELECT 	@Maximo = ISNULL(max(AnexoId), 0) FROM Anexos with(nolock) WHERE CatOrganismoId = @pi_CatOrganismoId AND AsuntoNeunId = @pi_AsuntoNeunId 
		INSERT INTO [SISE_NEW].[dbo].[Anexos]
					([AsuntoNeunId] ,[AsuntoId],[AsuntoDocumentoId],[AnexoId],[AnexoTipoId],[AnexoParteId],[AnexoParteDescripcion],[AnexoStatus] ,[CatOrganismoId]
					,[Año],[Folio],[NombreDocumento],[RutaAnexo],[NombreArchivo],[ExtensionDocumento],[FechaAlta],[FechaBaja],[StatusRegistro],[RutaArchivoNAS],[Texto])	
		SELECT  @pi_AsuntoNeunId ,1 , @pi_AsuntoDocumentoId , (RowId + @Maximo), p.TipoAnexoId, p.AnexoParteId, p.AnexoParteDescripcion , 1, @pi_CatOrganismoId,
					YEAR(GETDATE()) , p.Folio , null,null,null, null,  GETDATE(), NULL,	1,@TipoRuta, p.TextoOficioLibre
		FROM #Partes p LEFT JOIN [SISE_NEW].[dbo].[Anexos] a 
			ON a.[AsuntoNeunId] = @pi_AsuntoNeunId AND a.[AsuntoId] = 1 AND p.TipoAnexoId = a.[AnexoTipoId] AND p.AnexoParteId = a.AnexoParteId and a.AsuntoDocumentoId = @pi_AsuntoDocumentoId
		WHERE a.AnexoParteId is null
		
		--Se agrega rutina para insertar y actualizar los datos para el control de Oficios generados que serán firmados
		INSERT INTO [SISE3].[EstadoOficio]
					([AsuntoNeunId] ,[AsuntoId],[AsuntoDocumentoId],[AnexoId],[AnexoTipoId],[ParteId],[Estatus] ,[CatOrganismoId]
					,[Año],[Folio],[kIdRuta],[NombreArchivo],[ExtensionDocumento],[FechaAlta],[FechaBaja],Firmado,uGuid)
		SELECT  @pi_AsuntoNeunId ,1 , @pi_AsuntoDocumentoId , (RowId + @Maximo), p.TipoAnexoId, p.AnexoParteId, 1, @pi_CatOrganismoId,
					YEAR(GETDATE()) , p.Folio , @IdTipoRuta,@pi_NombreArchivo,@pi_ExtensionDocumento, GETDATE(), NULL,0,newid()
		FROM #Partes p LEFT JOIN [SISE_NEW].[SISE3].[EstadoOficio] a 
			ON a.[AsuntoNeunId] = @pi_AsuntoNeunId AND a.[AsuntoId] = 1 AND p.TipoAnexoId = a.[AnexoTipoId] AND p.AnexoParteId = a.ParteId and a.AsuntoDocumentoId = @pi_AsuntoDocumentoId
		WHERE a.ParteId is null

		---Actualizados
		UPDATE a
		SET AnexoTipoId= p.TipoAnexoId, 
		AnexoParteDescripcion = p.AnexoParteDescripcion,
		[RutaArchivoNAS] = @TipoRuta,
		[Texto] = p.TextoOficioLibre,	
		Folio = p.Folio
		FROM #Partes p INNER JOIN [SISE_NEW].[dbo].[Anexos] a with(nolock)
			ON  p.TipoAnexoId = a.[AnexoTipoId] AND p.AnexoParteId = a.AnexoParteId
		where
		a.[AsuntoNeunId] = @pi_AsuntoNeunId
		AND a.[AsuntoId] = 1
		AND a.AsuntoDocumentoId = @pi_AsuntoDocumentoId

		UPDATE a
		SET AnexoTipoId= p.TipoAnexoId, 
		--AnexoParteDescripcion = p.AnexoParteDescripcion,
		[kIdRuta] = @IdTipoRuta,
		--[Texto] = p.TextoOficioLibre,	
		Folio = p.Folio
		FROM #Partes p INNER JOIN [SISE_NEW].[SISE3].[EstadoOficio] a 
			ON  p.TipoAnexoId = a.[AnexoTipoId] AND p.AnexoParteId = a.ParteId
		where 
		a.[AsuntoNeunId] = @pi_AsuntoNeunId 
		AND a.[AsuntoId] = 1 
		AND a.AsuntoDocumentoId = @pi_AsuntoDocumentoId


		UPDATE a
		SET AnexoTipoId= p.TipoAnexoId, 
		AnexoParteDescripcion = p.AnexoParteDescripcion,
		[RutaArchivoNAS] = @TipoRuta,
		[Texto] = p.TextoOficioLibre,	
		Folio = p.Folio
		FROM  [SISE_NEW].[dbo].[Anexos] a with(nolock)  LEFT JOIN #Partes p 
			ON   p.TipoAnexoId = a.[AnexoTipoId] AND p.AnexoParteId = a.AnexoParteId
		WHERE
		a.[AsuntoNeunId] = @pi_AsuntoNeunId 
		AND a.[AsuntoId] = 1
		and a.AsuntoDocumentoId = @pi_AsuntoDocumentoId
		and p.TipoAnexoId IS NULL
		

		UPDATE a
		SET AnexoTipoId= p.TipoAnexoId, 
		--AnexoParteDescripcion = p.AnexoParteDescripcion,
		[kIdRuta] = @IdTipoRuta,
		--[Texto] = p.TextoOficioLibre,	
		Folio = p.Folio
		FROM  [SISE_NEW].[SISE3].[EstadoOficio] a  LEFT JOIN #Partes p 
			ON   p.TipoAnexoId = a.[AnexoTipoId] AND p.AnexoParteId = a.ParteId
		WHERE 
		a.[AsuntoNeunId] = @pi_AsuntoNeunId
		AND a.[AsuntoId] = 1
		and a.AsuntoDocumentoId = @pi_AsuntoDocumentoId
		AND p.TipoAnexoId IS NULL
		
		


	--SET ROWCOUNT 0
		DECLARE @FOLIOS VARCHAR(255)
				
		SELECT Folio,AnexoParteId,TipoAnexoId,AnexoParteDescripcion FROM #Partes
	
	END TRY
BEGIN CATCH
	-- Ejecuto ROLLBACK solo en caso de error
	--IF @@TRANCOUNT > 0
	--	ROLLBACK TRANSACTION;
	---- Ejecuta la rutina de recuperacion de errores.
	--EXECUTE dbo.usp_GetErrorInfo;
END CATCH;
-- Completo mi transaccion
--IF @@TRANCOUNT > 0
	COMMIT TRANSACTION;
SET NOCOUNT OFF
END
