SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		GGHH
-- Create date: 13/03/2024
-- Description: Genera un expediente tipo COE y su informacion en esquema para una notificación
-- =============================================
CREATE OR ALTER PROCEDURE SISE3.piInsertaCOE
	@pi_NotElecId BIGINT,
	@pi_Expediente VARCHAR(MAX),
	@pi_TipoComunicacion  INT,
	@pi_NumeroOrigen VARCHAR(MAX),
	@pi_FechaEnvio   DATETIME,
	@pi_Secretario  INT,
	@pi_Mesa  VARCHAR(MAX),
	@pi_TipoAsunto INT,
	@pi_NumeroExpedienteOrigen VARCHAR(MAX),
	@pi_Destinatario  VARCHAR(MAX),
	@pi_Objetivo   VARCHAR(MAX),
	@pi_OficinaCorrespondenciaComun  INT,
	@pi_EmpleadoId INT

AS
BEGIN
	DECLARE
	@AsuntosDetalleCatalogos [AsuntoDetalleCatalogos_type],
	@AsuntosDetalleDescripcion  [AsuntoDetalleDescripcion_type],
	@AsuntosDetalleFechas [AsuntoDetalleFechas_type],
	@AsuntosDetalleNumeros [AsuntoDetalleNumeros_type],
	@AsuntosDetalleOpciones [AsuntoDetalleOpciones_type],
	@AsuntoPersonas [AsuntoPersonas_type],
	@NoBloque INT = 0,
	@NoCaptura INT = 1,
	@CatMateriaId INT,
	@CatOrganismoId INT,
	@CatTipoAsuntoId INT = 44,
	@AsuntoNeunId BIGINT,
	@AsuntoId INT

	BEGIN TRY
		SELECT @CatOrganismoId = a.CatOrganismoId
		FROM NotificacionElectronica_Personas n 
		CROSS APPLY SISE3.fnExpediente(n.AsuntoNeunId) a
		WHERE n.NotElecId = @pi_NotElecId


		PRINT CONCAT('CatOrganismoId: ', @CatOrganismoId)
		IF @CatOrganismoId IS NULL OR @CatOrganismoId < 1
			THROW 51000,'No existe información para el identificador de la notificación',1;

		SELECT @CatMateriaId = CatMateriaId 
		FROM OrganismosTipoAsuntoMaterias
		WHERE CatTipoAsuntoId = @CatTipoAsuntoId
		AND CatOrganismoId = @CatOrganismoId 	

		-- SE crea la COE
		EXEC usp_AsuntosIns 
			@CatMateriaId,
			@CatOrganismoId,
			@CatTipoAsuntoId,
			'',
			@pi_Expediente,
			0,
			@pi_EmpleadoId,
			@AsuntoNeunId OUTPUT,
			@AsuntoId OUTPUT

		PRINT CONCAT('AsuntoNeunId: ', @AsuntoNeunId)

		--Se actualiza la relación entre la notificación y la COE
		UPDATE SISE3.REL_NotificacionCOE
		SET fkIdAsuntoNEUNCOE = @AsuntoNeunId
		WHERE fkIdNotElecId = @pi_NotElecId

		--Fecha
		INSERT INTO @AsuntosDetalleFechas(TipoAsuntoId, ValorCampoAsunto,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES (1288,@pi_FechaEnvio,@NoCaptura,@NoBloque,0,8,0)

		--Catalogo 
		INSERT INTO @AsuntosDetalleCatalogos(TipoAsuntoId,CatalogoId,CatalogoElementoId,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES(1289,(SELECT Catalogo FROM TiposAsunto WHERE TipoAsuntoId = 1289),@pi_Secretario,@NoCaptura,@NoBloque,0,3,0)

		INSERT INTO @AsuntosDetalleCatalogos(TipoAsuntoId,CatalogoId,CatalogoElementoId,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES(13765,(SELECT Catalogo FROM TiposAsunto WHERE TipoAsuntoId = 1289),@pi_OficinaCorrespondenciaComun,@NoCaptura,@NoBloque,0,7,0)  

		INSERT INTO @AsuntosDetalleCatalogos(TipoAsuntoId,CatalogoId,CatalogoElementoId,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES(14416,(SELECT Catalogo FROM TiposAsunto WHERE TipoAsuntoId = 14416),@pi_TipoAsunto,@NoCaptura,@NoBloque,0,6,0)  

		INSERT INTO @AsuntosDetalleCatalogos(TipoAsuntoId,CatalogoId,CatalogoElementoId,NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES(1287,(SELECT Catalogo FROM TiposAsunto WHERE TipoAsuntoId = 1287),@pi_TipoComunicacion,@NoCaptura,@NoBloque,0,2,0)  
 
		--Descripción
		INSERT INTO @AsuntosDetalleDescripcion(TipoAsuntoId, Contenido, NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES (1290,@pi_Mesa,@NoCaptura,@NoBloque,0,10,0)  

		INSERT INTO @AsuntosDetalleDescripcion(TipoAsuntoId, Contenido, NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES (1306,@pi_NumeroExpedienteOrigen,@NoCaptura,@NoBloque,0,12,0)  

		INSERT INTO @AsuntosDetalleDescripcion(TipoAsuntoId, Contenido, NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES (1307,@pi_Destinatario,@NoCaptura,@NoBloque,0,13,0) 

		INSERT INTO @AsuntosDetalleDescripcion(TipoAsuntoId, Contenido, NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES (1308,@pi_Objetivo,@NoCaptura,@NoBloque,0,14,0)   

		INSERT INTO @AsuntosDetalleDescripcion(TipoAsuntoId, Contenido, NoCaptura,NoBloque,NoBloquePadre,Consecutivo,Eliminar)
		VALUES (1295,@pi_NumeroOrigen,@NoCaptura,@NoBloque,0,9,0)   
   
		EXEC [dbo].[usp_AsuntosDetallesIns]
			@pi_AsuntoNeunId = @AsuntoNeunId,							
			@pi_AsuntoId = @AsuntoId,								
			@pi_NoCaptura = 1 ,							
			@pi_Operacion = 1,							
			@pi_AsuntosDetalleCatalogos = @AsuntosDetalleCatalogos,
			@pi_AsuntosDetalleDescripcion = @AsuntosDetalleDescripcion,
			@pi_AsuntosDetalleFechas = @AsuntosDetalleFechas,
			@pi_AsuntosDetalleNumeros = @AsuntosDetalleNumeros,
			@pi_AsuntosDetalleOpciones = @AsuntosDetalleOpciones,
			@pi_AsuntoPersonas_type = @AsuntoPersonas
	END TRY
	BEGIN CATCH
		IF(@AsuntoNeunId IS NOT NULL)
		BEGIN
			UPDATE Asuntos 
			SET StatusReg = 0
			WHERE AsuntoNeunId =  @AsuntoNeunId
		END
		EXECUTE dbo.usp_GetErrorInfo;
		SELECT 'Error'
	END CATCH
END
