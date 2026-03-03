SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 12/12/2023
-- Description: Obtiene los privilegios asignados a un empleado en un organismo Y el API asociado
-- EXEC [SISE3].[pcPrivilegiosXApi]
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[pcPrivilegiosXApi] --(@pi_EmpleadoId int, @pi_CatOrganismoId int)
AS
BEGIN
	/*SELECT p.IdPrivilegio, ca.sURL, ra.sVerbo
    FROM SISE3.CatPrivilegio p
    LEFT JOIN SISE3.REL_PrivilegioXRol pr ON p.IdPrivilegio = pr.IdPrivilegio
    --LEFT JOIN SISE3.REL_RolEmpleadoXOrganismo re ON pr.IdRol = re.IdRol
    LEFT JOIN SISE3.CatRol r ON pr.IdRol = r.IdRol
    --LEFT JOIN SISE3.PermisosPersonalizados pp ON pp.IdEmpleadoRol = re.IdEmpleadoRol
    LEFT JOIN SISE3.REL_RolAPi ra ON ra.IdPrivilegio = p.IdPrivilegio
    LEFT JOIN SISE3.CatApi ca ON ra.IdApi = ca.IdApi
    WHERE p.bEstatus = 1
    AND r.bEstatus = 1
	--and pr.bEstatus = 1
    GROUP BY p.IdPrivilegio, ca.sURL, ra.sVerbo*/

	SELECT p.IdPrivilegio, ca.sURL, ra.sVerbo
	FROM SISE3.CatAPI ca
	LEFT JOIN SISE3.REL_RolAPi ra on ra.IdAPI = ca.IdApi
	--LEFT JOIN SISE3.REL_PrivilegioXRol pr on pr.IdPrivilegio = ra.IdPrivilegio
	LEFT JOIN SISE3.CatPrivilegio p ON p.IdPrivilegio = ra.IdPrivilegio
	WHERE p.bEstatus = 1
	GROUP BY p.IdPrivilegio, ca.sURL, ra.sVerbo
END
