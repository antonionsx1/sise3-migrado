SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 03/04/23
-- Objetivo: Elimina la promoción y sus anexos. 
-- EXEC EXECUTE  [SISE3].[paActualizaExpedientePromocionyArchivo] 8353555,8353555,2010,70,126,0,40262,0,1864,null,null,null
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[paActualizaExpedientePromocionyArchivo]
@pi_AsuntoNeunId [bigint] ,
@pi_AsuntoID [int], 
@pi_YearPromocion [int], 
@pi_NumeroOrden [int], 
@pi_catIdOrganismo [int], 
@pi_Origen [int],  
@pi_RegistroEmpleadoSISEId [int] =  null, 
@pi_ClaseAnexo [int], 
@pi_NumeroRegistro [int], 
@pi_NombreArchivoReal [nvarchar] (150), 
@pi_Descripcion int = null,
@pi_Caracter int= null, 
@pi_NumeroConsecutivo int, 
@pi_Fojas smallint
AS
BEGIN
	DECLARE @Cantidad INT = 0;

	IF NOT EXISTS (SELECT AsuntoNeunId FROM Asuntos where AsuntoNeunId = @pi_AsuntoNeunId and AsuntoId = @pi_AsuntoID and CatOrganismoId = @pi_catIdOrganismo)
		THROW 51000,'Error, Expediente no existe',1;
	IF NOT EXISTS (SELECT NumeroRegistro 
				   FROM Promociones 
				   WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
						and [Promociones].AsuntoID=@pi_AsuntoID 
						and [Promociones].YearPromocion=@pi_YearPromocion 
						and [Promociones].NumeroOrden=@pi_NumeroOrden 
						and [Promociones].CatOrganismoId=@pi_catIdOrganismo and [Promociones].StatusReg in (1,2))
		THROW 51000,'Error, promoción no existe',1;

	BEGIN TRY
		BEGIN TRAN	

			DECLARE @po_NombreArchivo varchar(50)

			EXEC [SISE3].[piInsertaDocumento] 
			   @pi_AsuntoNeunId
			  ,@pi_YearPromocion
			  ,@pi_NumeroOrden
			  ,@pi_RegistroEmpleadoSISEId
			  ,@pi_ClaseAnexo
			  ,@pi_Descripcion
			  ,@pi_Caracter
			  ,@pi_Fojas
			  ,@pi_Origen
			  ,@pi_NombreArchivoReal
			  ,@po_NombreArchivo OUTPUT
			  ,@pi_NumeroConsecutivo OUTPUT


			---Cantidad de archivos por promoción
			SELECT  @Cantidad = COUNT(*)
			FROM dbo.PromocionArchivos Pa  
				INNER JOIN  [dbo].[Promociones] Pr 
				ON Pa.AsuntoId=Pr.AsuntoId 
					and Pa.AsuntoNeunId=Pr.AsuntoNeunId and Pa.NumeroOrden=Pr.NumeroOrden 
					and Pa.NumeroRegistro=Pr.NumeroRegistro
					and Pa.YearPromocion=Pr.YearPromocion-- and Pa.DescripcionAnexo=5031
			WHERE Pr.StatusReg in (1,2)
				and Pa.StatusArchivo = 1
				and Pa.EstatusArchivo = 1
				and Pr.AsuntoNeunId = @pi_AsuntoNeunId
				and Pr.AsuntoID = @pi_AsuntoID
				and Pr.YearPromocion = @pi_YearPromocion
				and Pa.NombreArchivo IS NOT NULL
				and Pr.NumeroOrden = @pi_NumeroOrden
				and Pr.CatOrganismoId = @pi_catIdOrganismo 
				and Pa.ClaseAnexo <> 0
				; 

			
			UPDATE Promociones
			SET NumeroAnexos = @Cantidad
			WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
				and [Promociones].AsuntoID=@pi_AsuntoID 
				and [Promociones].YearPromocion=@pi_YearPromocion 
				and [Promociones].NumeroOrden=@pi_NumeroOrden 
				and [Promociones].CatOrganismoId=@pi_catIdOrganismo and [Promociones].StatusReg in (1,2);
		
		EXEC usp_Promocion_Bitacora @pi_catIdOrganismo,@pi_YearPromocion,@pi_NumeroOrden,@pi_Origen,6
		Print 'Promoción Archivo Actualizado'
	END TRY
	BEGIN CATCH
		    -- Ejecuto ROLLBACK solo en caso de error
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			-- Ejecuta la rutina de recuperacion de errores.
			EXECUTE dbo.usp_GetErrorInfo;
	END CATCH;
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
	SET NOCOUNT OFF
END