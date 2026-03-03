SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Autor: Anabel Gonzalez
-- Fecha de Creación:21 de Junio 2024
-- Descripción: Obtiene la lista de empleados por organismo
-- Ejemplo : EXEC [SISE3].[pcEmpleadosXOrganismo] 180
-- ============================================= 
CREATE PROCEDURE [SISE3].[pcEmpleadosXOrganismo]
@pi_CatOrganismoId [int]
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
		
		SELECT DISTINCT (CONVERT(INT,CatEmp.EmpleadoId)) IdEmpleado
						,LTRIM(CatEmp.Nombre) + ' ' + ISNULL(CatEmp.ApellidoPaterno,'') +' ' + ISNULL(CatEmp.ApellidoMaterno,'') Descripcion  
		FROM  CatEmpleados CatEmp WITH(NOLOCK)
		INNER JOIN SISE3.REL_RolEmpleadoXOrganismo EOrg WITH(NOLOCK) ON EOrg.IdCatEmpleado = CatEmp.EmpleadoId
		WHERE EOrg.IdOrganismo = @pi_CatOrganismoId
			  AND CatEmp.StatusRegistro = 1
			  AND EOrg.bStatus = 1
        ORDER BY Descripcion
		
        END TRY
		BEGIN CATCH
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
		SET NOCOUNT OFF
	END

