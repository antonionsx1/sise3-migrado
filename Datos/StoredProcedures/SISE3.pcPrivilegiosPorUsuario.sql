SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 12/12/2023
-- Description: Obtiene los privilegios asignados a un empleado en un organismo
-- EXEC [SISE3].[pcPrivilegiosPorUsuario] 6712, 1494
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[pcPrivilegiosPorUsuario] (@pi_EmpleadoId int, @pi_CatOrganismoId int)
AS
BEGIN
	SELECT pr.IdPrivilegio
	FROM SISE3.REL_PrivilegioXRol pr
	LEFT JOIN SISE3.REL_RolEmpleadoXOrganismo re on pr.IdRol = re.IdRol
	WHERE re.IdCatEmpleado = @pi_EmpleadoId
	AND re.IdOrganismo = @pi_CatOrganismoId
	AND pr.bEstatus = 1
	AND re.bStatus = 1
	GROUP BY pr.IdPrivilegio
END


