USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piAsunto]    Script Date: 12/1/2023 6:24:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ============================================= 
-- Author: Diana Quiroga - MS
-- Alter date: 09/10/2023 
-- Description: Registra un nuevo expediente
-- Basado en: uspx_addAsunto
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--EXEC [SISE3].[piAsunto] 1494,1, '000000043232/2023','1983/2023',6712, 1, 30314103
-- ============================================= 
CREATE PROCEDURE [SISE3].[piAsunto]
	@pi_CatOrganismoId [int]  ,					-- Parametro que contiene el Identificador de organismmo para el asunto 
	@pi_CatTipoAsuntoId [int]  ,				-- Parametro que contiene el Identificador del Tipo Asunto
	@pi_NumeroOCC [varchar](50)  ,				-- Parametro para el Numero que se asigna a este expediente en OCC
	@pi_NoExpediente [varchar](50),		-- Parametro para el Numero de Expediente que se asigna al Asunto
	@pi_EmpleadoId [bigint],					--Identificador del empleado que creo el expediente
	@pi_TipoProcedimiento [int]	= null,			--Se agrego este parámetro para los tipo de asunto 6 y 9
	@pi_EsActualizacion [int],			--Bandera para identificar si es insert (0) o actualización (1)
	@pi_AsuntoNeunId bigint = null,
	@po_AsuntoNeunId  bigint  = NULL OUTPUT,
	@po_AsuntoId  int = NULL OUTPUT
AS
BEGIN
	
	DECLARE @CatMateriaId [smallint]
	DECLARE @AsuntoNeunId [bigint]
	DECLARE	@AsuntoId [int]
	
	SET @pi_NumeroOCC = dbo.fnPonCeros(@pi_NumeroOCC,11) 
	SET @pi_TipoProcedimiento = ISNULL(@pi_TipoProcedimiento,0)
	
	SELECT @CatMateriaId = CatMateriaId 
	FROM OrganismosTipoAsuntoMaterias
	WHERE CatTipoAsuntoId = @pi_CatTipoAsuntoId
	AND CatOrganismoId = @pi_CatOrganismoId 						

	IF @pi_EsActualizacion = 0
	BEGIN
		--print 'Inserto Nuevo'
		EXEC usp_AsuntosIns 
		@CatMateriaId,
		@pi_CatOrganismoId,
		@pi_CatTipoAsuntoId,
		@pi_NumeroOCC,
		@pi_NoExpediente,
		@pi_TipoProcedimiento,
		@pi_EmpleadoId,
		@AsuntoNeunId OUTPUT,
		@AsuntoId OUTPUT

		SET @po_AsuntoNeunId =@AsuntoNeunId
		SET @po_AsuntoId = @AsuntoId

		SELECT @po_AsuntoNeunId AsuntoNeunId, @po_AsuntoId AsuntoId
	END
	ELSE BEGIN
		--Print 'Actualizo'
		set @po_AsuntoId = 1

		UPDATE Asuntos
		SET NumeroOCC = @pi_NumeroOCC
		WHERE AsuntoNeunId = @pi_AsuntoNeunId
		AND CatTipoAsuntoId = @pi_CatTipoAsuntoId
		AND CatOrganismoId = @pi_CatOrganismoId

		SET @po_AsuntoNeunId =@pi_AsuntoNeunId
		SELECT @po_AsuntoNeunId AsuntoNeunId, @po_AsuntoId as AsuntoId
	END
	
END
GO

