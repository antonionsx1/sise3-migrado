USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[peEliminaPromocion]    Script Date: 12/1/2023 6:24:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 03/04/11
-- Objetivo: Elimina la promoción y sus anexos. 
-- EXEC [SISE3].peEliminaPromocion 3030114432233, 1,2023,4
-- =============================================
CREATE PROCEDURE [SISE3].[peEliminaPromocion]
@pi_AsuntoNeunId [bigint] ,
--@pi_AsuntoID [int], 
@pi_YearPromocion [int], 
@pi_NumeroOrden [int], 
@pi_catIdOrganismo [int]
AS 
BEGIN 
	IF NOT EXISTS (SELECT NumeroRegistro 
				   FROM Promociones 
				   WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
						--and [Promociones].AsuntoID=@pi_AsuntoID 
						and [Promociones].YearPromocion=@pi_YearPromocion 
						and [Promociones].NumeroOrden=@pi_NumeroOrden 
						and [Promociones].CatOrganismoId=@pi_catIdOrganismo and [Promociones].StatusReg in (1,2))
		THROW 51000,'Error, promoción no existe',1;
 
	BEGIN TRY
		BEGIN TRAN	
			UPDATE Promociones
			SET StatusReg = 0, FechaBaja=GETDATE()	
			WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
							--and [Promociones].AsuntoID=@pi_AsuntoID 
							and [Promociones].YearPromocion=@pi_YearPromocion 
							and [Promociones].NumeroOrden=@pi_NumeroOrden 
							and [Promociones].CatOrganismoId=@pi_catIdOrganismo and [Promociones].StatusReg in (1,2);

			UPDATE Pa
			SET Pa.StatusArchivo=0, FechaBaja=GETDATE()	
			FROM dbo.PromocionArchivos Pa  
				 INNER JOIN  [dbo].[Promociones] Pr 
					ON Pa.AsuntoNeunId=Pr.AsuntoNeunId and Pa.NumeroOrden=Pr.NumeroOrden 
					  --and Pa.AsuntoId=Pr.AsuntoId 
					  and Pa.NumeroRegistro=Pr.NumeroRegistro
					  and Pa.YearPromocion=Pr.YearPromocion 
					  and Pa.StatusArchivo=1 --and Pa.DescripcionAnexo=5031
			WHERE Pr.AsuntoNeunId=@pi_AsuntoNeunId 
				  --and Pr.AsuntoID=@pi_AsuntoID 
				  and Pr.YearPromocion=@pi_YearPromocion 
				  and Pa.NombreArchivo IS NOT NULL
				  and Pr.NumeroOrden=@pi_NumeroOrden 
				  and Pr.CatOrganismoId=@pi_catIdOrganismo and Pr.StatusReg in (1,2)

		Print 'Promoción eliminada exitosamente'
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
GO

