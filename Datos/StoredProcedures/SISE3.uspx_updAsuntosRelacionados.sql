SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:	Mario Alejandro Santiago de la Cruz
-- Date : 16/11/2023
-- Description:	Actualiza un asunto  con status 0 o 1 a partir del AuntoNeunId y del Expediente
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_updAsuntosRelacionados]
@IdAsuntoRela BIGINT,
@EmpleadoId INT,
@statusreg INT
AS
BEGIN

SET NOCOUNT ON
		BEGIN TRY
			
			UPDATE AsuntosRelacionados
			SET 			
			EmpleadoIdOrg =CASE @statusreg  WHEN 1 THEN  @EmpleadoId END,   
			status = @statusreg,
			FechaDestino = CASE @statusreg  WHEN 1 THEN  GETDATE() END,
			FechaCancelacion = CASE @statusreg  WHEN 0 THEN  GETDATE()  END,
			EmpleadoIdCancela = CASE @statusreg  WHEN 0 THEN  @EmpleadoId  END
			WHERE IdAsuntoRela = @IdAsuntoRela
				
		END TRY
		BEGIN CATCH
		    			
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
	    		
		SET NOCOUNT OFF

END