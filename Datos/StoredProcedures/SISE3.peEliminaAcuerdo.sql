SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 12/10/23
-- Objetivo: Elimina acuerdo
-- EXEC [SISE3].peEliminaAcuerdo 3030114432233, 1,4
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[peEliminaAcuerdo]
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

			DECLARE @SintesisOrden INT = NULL

			SELECT @SintesisOrden = ad.SintesisOrden
			FROM AsuntosDocumentos ad
			INNER JOIN Asuntos a WITH(NOLOCK) on a.AsuntoNeunId= ad.AsuntoNeunId
				   WHERE a.AsuntoNeunId=@pi_AsuntoNeunId 
						and ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId 
						and a.CatOrganismoId = @pi_catIdOrganismo

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

			UPDATE s
			SET StatusReg = 0, FechaBaja=GETDATE()	
			FROM DeterminacionesJudiciales  s
			INNER JOIN AsuntosDocumentos ad WITH(NOLOCK) on s.AsuntoNeunId= ad.AsuntoNeunId
			WHERE s.AsuntoNeunId=@pi_AsuntoNeunId 
				and ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId 

			UPDATE NotificacionElectronica_Personas
			SET StatusReg = 0, FechaBaja=GETDATE()	
			WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND SintesisOrden = @SintesisOrden 
			
			UPDATE Promociones
			SET SintesisOrden = null
				,FechaAcuerdo = null
				,FechaActualiza=GETDATE()
				,AsuntoDocumentoId = null
			 WHERE AsuntoNeunId=@pi_AsuntoNeunId 
					and AsuntoDocumentoId=@pi_AsuntoDocumentoId 
						and CatOrganismoId = @pi_catIdOrganismo

			UPDATE [SISE_NEW].[dbo].[Anexos] 
			SET StatusRegistro = 0, FechaBaja=GETDATE()	
			WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND AsuntoDocumentoId=@pi_AsuntoDocumentoId 



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