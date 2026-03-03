USE [SISE_NEW]
GO
/****** Object:  UserDefinedFunction [SISE3].[fnEstadoAutorizacion]    Script Date: 12/14/2023 11:39:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Saul Garcia
-- Create date: 31/10/2023
-- Description:	Retorna el Estado de la autorización
-- Example: SELECT SISE3.fnEstadoAutorizacion(0,4)
-- =============================================
ALTER FUNCTION [SISE3].[fnEstadoAutorizacion]
(
	@pi_AsuntoDocumentoId INT, 
	@pi_CatDocumentoId INT
)
RETURNS INT
AS
BEGIN

	DECLARE @ps_Estatus INT

	SET @ps_Estatus = IIF((@pi_AsuntoDocumentoId = 0 OR @pi_AsuntoDocumentoId IS NULL), 1,--Sin Acuerdo
									IIF (@pi_CatDocumentoId  IN (4,8,9),5, --Cancelados
										IIF (@pi_CatDocumentoId NOT IN (2,3,4,8,9) AND NOT((@pi_AsuntoDocumentoId = 0 OR @pi_AsuntoDocumentoId IS NULL)), 2, --Con acuerdo
											IIF (@pi_CatDocumentoId  IN (2),3, -- Pre autorizados
												IIF (@pi_CatDocumentoId  IN (3),4,0))))) --Autorizados
	
	RETURN @ps_Estatus

END
