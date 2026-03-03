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
	EXEC [SISE3].paVinculaPromocionAcuerdo 
        @pi_AsuntoNeunId = 30314120,
		@pi_FechaAcuerdo  = '2023-11-22',
		@pi_SintesisOrden = 48,
		@po_AsuntoDocumentoId = 48,
        @pi_PromocionesDeterminacion  = @promo
	*/
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].paVinculaPromocionAcuerdo

(
   		@pi_AsuntoNeunId BIGINT, 
		@pi_FechaAcuerdo DATETIME, --Fecha del documento
		@pi_SintesisOrden INT = NULL,
		@pi_AsuntoDocumentoId INT OUTPUT, 
		@pi_PromocionesDeterminacion [SISE3].[PromocionesAcuerdo_type] READONLY --Datos de promociones

)
AS
BEGIN
SET NOCOUNT ON
	BEGIN TRY
		DECLARE @CatOrganismoId INT

		SELECT @CatOrganismoId = CatOrganismoId
		FROM Asuntos
		WHERE AsuntoNeunId = @pi_AsuntoNeunId AND StatusReg = 1

		UPDATE Promociones WITH(ROWLOCK)
		SET SintesisOrden = @pi_SintesisOrden
			,EstadoPromocion = m.EstadoPromocionId
			,FechaAcuerdo =@pi_FechaAcuerdo
			,FechaActualiza=GETDATE()
			,AsuntoDocumentoId = @pi_AsuntoDocumentoId
		FROM Promociones p INNER JOIN @pi_PromocionesDeterminacion m ON p.AsuntoNeunId = @pi_AsuntoNeunId AND p.NumeroOrden = m.NumeroOrden
			 AND p.YearPromocion = m.YearPromocion AND p.StatusReg IN (1,2)
		WHERE m.[Proceso] = 0
								
	END TRY 
    BEGIN CATCH
               EXECUTE [SISE3].[peEliminaAcuerdo]
					@pi_AsuntoNeunId ,
					@pi_AsuntoDocumentoId, 
					@CatOrganismoId					
                -- Ejecuta la rutina de recuperacion de errores.
                EXECUTE dbo.usp_GetErrorInfo;
        END CATCH;

END
