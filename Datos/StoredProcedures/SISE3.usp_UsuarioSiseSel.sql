SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		GGHH
-- Create date: 16052023
-- Description:	Autenticación del usuario SISE, regresando información básica
--EXEC SISE3.usp_UsuarioSiseSel 'MaricLopezHerna'
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[usp_UsuarioSiseSel]
	@pi_UserName VARCHAR(20)
AS
BEGIN
	BEGIN TRY
		SELECT 
			e.EmpleadoId, e.Nombre, e.ApellidoPaterno, e.ApellidoMaterno, eo.CargoId, cc.CargoDescripcion,e.Sexo, e.Expediente, e.UserName,
			o.CatOrganismoId, OrganismoNombre = o.NombreOficial
		FROM CatEmpleados e 
		INNER JOIN EmpleadoOrganismo eo ON e.EmpleadoId = eo.EmpleadoId AND eo.StatusRegistro = 1
		INNER JOIN CatOrganismos o ON o.CatOrganismoId = eo.CatOrganismoId AND o.StatusReg = 1
		INNER JOIN CatCargo cc ON cc.CargoId = eo.CargoId 
		WHERE UserName = @pi_UserName
		AND e.StatusRegistro = 1
	END TRY
	BEGIN CATCH
		EXECUTE usp_GetErrorInfo; 
	END CATCH
END
