USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[peEliminaAcuerdo]    Script Date: 12/1/2023 6:23:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 12/10/23
-- Objetivo: Elimina acuerdo
-- EXEC [SISE3].peEliminaAcuerdo 3030114432233, 1,2023,4
-- =============================================
CREATE PROCEDURE [SISE3].[peEliminaAcuerdo]
@pi_AsuntoNeunId [bigint] ,
@pi_AsuntoDocumentoId [int], 
@pi_catIdOrganismo [int]
AS 
BEGIN 
	IF NOT EXISTS (SELECT ad.AsuntoDocumentoId 
				   FROM AsuntosDocumentos ad 
				   INNER JOIN Asuntos a WITH(NOLOCK) on a.AsuntoNeunId= ad.AsuntoNeunId
				   WHERE a.AsuntoNeunId=@pi_AsuntoNeunId 
						and ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId 
						and a.CatOrganismoId = @pi_catIdOrganismo)
		THROW 51000,'Error, acuerdo no existe',1;
 
	BEGIN TRY
		BEGIN TRAN	
			UPDATE ad
			SET StatusReg = 0, FechaBaja=GETDATE()	, CatAutorizacionDocumentosId = 1
			FROM AsuntosDocumentos ad
			INNER JOIN Asuntos a WITH(NOLOCK) on a.AsuntoNeunId= ad.AsuntoNeunId
				   WHERE a.AsuntoNeunId=@pi_AsuntoNeunId 
						and ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId 
						and a.CatOrganismoId = @pi_catIdOrganismo

			UPDATE s
			SET StatusReg = 0, FechaBaja=GETDATE()	
			FROM SintesisAcuerdoAsunto  s
			INNER JOIN AsuntosDocumentos ad WITH(NOLOCK) on s.AsuntoNeunId= ad.AsuntoNeunId
			WHERE s.AsuntoNeunId=@pi_AsuntoNeunId 
				and ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId 

			
			UPDATE Promociones
			SET AsuntoDocumentoId = 0
			 WHERE AsuntoNeunId=@pi_AsuntoNeunId 
					and AsuntoDocumentoId=@pi_AsuntoDocumentoId 
						and CatOrganismoId = @pi_catIdOrganismo

		Print 'Acuerdo eliminado exitosamente'
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

