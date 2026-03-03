SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Saul Garcia
-- Create date:  21/12/2013
-- Description: Registra la recepción del oficio
/*
	DECLARE @return_value int,
	@pi_Oficios SISE3.Oficios_type
	
    INSERT INTO @pi_Oficios([AnexoId],[AsuntoNeunId],[Folio]) values (7, 30315305, '605'),(12, 30315305, '607')
	EXEC [SISE3].[piRegistraOficio] 3,180,@pi_Oficios
*/
-- =============================================

CREATE OR ALTER PROC [SISE3].[piRegistraOficio](
	@pi_IdEmpleado BIGINT,
	@pi_CatOrganismoId INT,
	@pi_Oficios AS SISE3.Oficios_type READONLY
)
AS
BEGIN
	BEGIN TRY
		SELECT  AnexoId
			   ,AsuntoNeunId
			   ,Folio
		INTO #Oficios
		FROM @pi_Oficios
	
		IF EXISTS ( --Valida que existan registros con diferente empleado para cambiar el status y mantener el histórico
			SELECT 1
			FROM #Oficios o
			WHERE EXISTS (
				SELECT 1
				FROM [SISE3].[HIS_RecepcionOficio] t
				WHERE t.fkAnexoId = o.AnexoId
				  AND t.AsuntoNeunId = o.AsuntoNeunId
				  AND t.fkCatOrganismoId = @pi_CatOrganismoId
			)
		)
		BEGIN
			UPDATE [SISE3].[HIS_RecepcionOficio] 
			SET StatusReg=0
			FROM [SISE3].[HIS_RecepcionOficio] ro
			INNER JOIN #Oficios o
				ON ro.AsuntoNeunId=o.AsuntoNeunId
				AND ro.fkAnexoId=o.AnexoId
				AND ro.fkCatOrganismoId = @pi_CatOrganismoId
		END

		INSERT INTO [SISE3].[HIS_RecepcionOficio]
		(FechaRecepcion
		,idEmpleadoRecepcion
		,fkAnexoId
		,AsuntoNeunId
		,fkCatOrganismoId
		,StatusReg)
		SELECT
			 GETDATE()
			,@pi_IdEmpleado
			,AnexoId
			,AsuntoNeunId
			,@pi_CatOrganismoId
			,1
		FROM #Oficios
	END TRY
    BEGIN CATCH
    -- Ejecuta la rutina de recuperacion de errores.
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH
END