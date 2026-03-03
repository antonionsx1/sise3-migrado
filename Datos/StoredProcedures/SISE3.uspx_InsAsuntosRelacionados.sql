SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:	Mario Alejandro Santiago de la Cruz
-- Date : 16/11/2023
-- Description:	inserta un asunto hecho disponible  por primera vez con status -1 a partir del AuntoNeunId y del Expediente
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_InsAsuntosRelacionados]
@AsuntoNeunId BIGINT,
@AsuntoNeunIdDes BIGINT,
@EmpleadoIdDes INT

AS
BEGIN

SET NOCOUNT ON
		BEGIN TRY
			
			DECLARE @asuntoIdOri bigint
			SET @asuntoIdOri = (SELECT AsuntoId FROM Asuntos WHERE AsuntoNeunId = @AsuntoNeunId)

			DECLARE @AsuntoIdDes bigint
			SET @AsuntoIdDes = (SELECT AsuntoId FROM Asuntos WHERE AsuntoNeunId = @AsuntoNeunIdDes)

			INSERT INTO AsuntosRelacionados WITH(ROWLOCK) 
			(asuntoneunidorg,
			asuntoidorg,
			empleadoidorg,
			AsuntoNeunIdDest,
			AsuntoIdDest,
			EmpleadoIdDest,
			status,
			FechaDestino)
			VALUES (
			@AsuntoNeunId,
			@asuntoIdOri,
			null,
			@AsuntoNeunIdDes,
			@AsuntoIdDes,
			@EmpleadoIdDes,
			-1,
			GETDATE()
			)
		END TRY
		BEGIN CATCH		    						
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
	    		
		SET NOCOUNT OFF

END
