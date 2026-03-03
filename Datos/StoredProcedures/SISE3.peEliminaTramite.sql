SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Alter date: 13/03/2024
-- Objetivo: Elimina  el registro a partir del AsuntoAlis y el CatOrganismoId cambiando el estatus  
-- EXEC [SISE3].peEliminaTramite '1/2015',1202
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[peEliminaTramite]
@pi_AsuntoAlias NVARCHAR(50),
@pi_catIdOrganismo [int],
@pi_fecha DATE
AS 
  BEGIN 
    BEGIN TRY
		DECLARE @AsuntoNeunId INT

		SET @AsuntoNeunId =(SELECT DISTINCT AsuntoNeunId 
		FROM Asuntos 
		WHERE AsuntoAlias=@pi_AsuntoAlias AND CatOrganismoId= @pi_catIdOrganismo);

		PRINT @AsuntoNeunId

		UPDATE Asuntos SET StatusReg = 0 
		WHERE AsuntoNeunId= @AsuntoNeunId 
		AND CatOrganismoId= @pi_catIdOrganismo
		AND FechaAlta = @pi_fecha 
	
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