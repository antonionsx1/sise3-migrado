SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author: Anabel
-- Create date: 12/08/2024
-- Description:	Valida los privilegios del empleado.
-- EXEC [SISE3].[pcValidarPrivilegioEmpleado] 180,6712,163
-- ==========================================================================================
ALTER PROCEDURE [SISE3].[pcValidarPrivilegioEmpleado]
	@pc_CatOrganismoId INT,
    @pc_EmpleadoId INT = NULL,
	@pc_PrivilegioId INT
AS
BEGIN
	BEGIN TRY

		SELECT COUNT(*) 
		FROM SISE3.REL_RolEmpleadoXOrganismo REO WITH(NOLOCK)
		INNER JOIN SISE3.REL_PrivilegioXRol PR WITH(NOLOCK) ON PR.IdRol = REO.IdRol
		WHERE IdCatEmpleado = @pc_EmpleadoId 
		AND PR.IdPrivilegio = @pc_PrivilegioId 
		AND REO.IdOrganismo = @pc_CatOrganismoId
		
    END TRY
	BEGIN CATCH
		
	END CATCH
END

