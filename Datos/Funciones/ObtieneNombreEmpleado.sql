USE [SISE_NEW]
GO

/****** Object:  UserDefinedFunction [SISE3].[ObtieneNombreEmpleado]    Script Date: 10/12/2023 1:43:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Diana Quiroga MS
-- Create date: 09/08/2023
-- Description:	Retorna nombres del empleado
-- Example: SELECT SISE3.[ObtieneNombreEmpleado]( 38075, 'Nombre')
-- =============================================
CREATE FUNCTION [SISE3].[ObtieneNombreEmpleado]
(
	@pi_EmpleadoId BIGINT, 
	@pi_Tipo VARCHAR(100)
)
RETURNS VARCHAR(300)
AS
BEGIN

	DECLARE @ps_Nombre VARCHAR(300)


	SET @ps_Nombre = (SELECT CASE WHEN @pi_Tipo = 'Nombre' THEN Nombre
								  WHEN @pi_Tipo = 'ApellidoPaterno' THEN ApellidoPaterno
								  WHEN @pi_Tipo = 'ApellidoMaterno' THEN ApellidoMaterno
								  WHEN @pi_Tipo = 'UserName' THEN UserName
							 ELSE  SISE3.ConcatenarNombres(Nombre, ApellidoPaterno, ApellidoMaterno) 
							 END
					  FROM dbo.CatEmpleados
					  WHERE empleadoid= @pi_EmpleadoId);
	
	RETURN @ps_Nombre

END
GO

