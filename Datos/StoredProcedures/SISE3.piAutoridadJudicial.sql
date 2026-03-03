SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Diana Quiroga - MS
-- Create date: 18/09/2023
-- Description:	Inserta la autoridad Judicial
/* 
	DECLARE @po_PersonaId INT
	EXEC [SISE3].[piAutoridadJudicial] 30301043,57691,'Secretaría de Educación Pública','','',3,13,@po_PersonaId OUTPUT,33
	SELECT @po_PersonaId
*/
-- =============================================
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[piAutoridadJudicial]
        @pi_AsuntoNeunId [BIGINT], 
        @pi_catIdOrganismo [INT], 
        @pi_EmpleadoId [INT], 
        @pi_RegistroEmpleadoId [INT], 
        @po_AutoridadJudicialId INT = NULL OUTPUT,
		@pi_numeroOrden INT
AS
BEGIN
        DECLARE @AsuntoId int
        BEGIN TRY
                SELECT 
                        @AsuntoId = AsuntoId
                FROM 
                        Asuntos
                WHERE 
                        AsuntoNeunId = @pi_AsuntoNeunId
                        
                EXEC usp_EXPE_AutoridadJudicialOficialiaIns 
                        @pi_AsuntoNeunId, 
                        @AsuntoId, 
                        @pi_catIdOrganismo, 
                        @pi_EmpleadoId, 
                        @pi_RegistroEmpleadoId, 
                        @po_AutoridadJudicialId OUTPUT

				     
                UPDATE p
				SET TipoPromovente  = @po_AutoridadJudicialId
				FROM promociones p INNER JOIN AutoridadJudicial pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_NumeroOrden
				WHERE p.AsuntoNeunId = @pi_AsuntoNeunId
				AND  p.ClasePromovente = 3;


        END TRY
        BEGIN CATCH
                EXECUTE usp_GetErrorInfo; 
        END CATCH
END




