SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =======================================================================================================================================
-- Author:		GGHH
-- Create date: 17/08/2023
-- Description:	Obtiene los datos de la autoridad judicial buscado por nombre  
-- Example(S):	SISE3.pcAutoridadJudicialPorNombre 'Daniel Alejandro Rangel Gavia'
-- =======================================================================================================================================
CREATE OR ALTER PROCEDURE [SISE3].[pcAutoridadJudicialPorNombre]
	 @pi_Nombre VARCHAR(255)
    
AS
BEGIN
	BEGIN TRY
		SELECT	NombreCompleto = SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)
				,e.EmpleadoId
				,c.CargoDescripcion
				,eo.CatOrganismoId
				,o.NombreOficial
		FROM CatEmpleados e WITH (NOLOCK)
		INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) 
			ON eo.EmpleadoId=e.EmpleadoId
		INNER JOIN CatOrganismos o WITH (NOLOCK) 
			ON o.CatOrganismoId = eo.CatOrganismoId
		INNER JOIN CatCargo c WITH (NOLOCK) 
			ON eo.CargoId=c.CargoId
		INNER JOIN viCatEmpledosXOrgano v WITH (NOLOCK) 
			ON v.organismo = eo.CatOrganismoId and eo.EmpleadoId = v.EmpleadoId
		WHERE  eo.StatusRegistro = 1
			   AND e.StatusRegistro = 1 
			   AND o.StatusReg = 1
			   AND c.CargoId <> 63
			   --AND eo.EmpleadoId in (SELECT v.empleadoid FROM viCatEmpledosXOrgano v WHERE v.organismo = eo.CatOrganismoId ) 
			   AND (
					CONCAT(e.Nombre, e.ApellidoPaterno,e.ApellidoMaterno) LIKE CONCAT('%',REPLACE(@pi_Nombre, ' ', '%'),'%') 
			   		OR CONCAT(e.ApellidoPaterno,e.ApellidoMaterno,e.Nombre) LIKE CONCAT('%',REPLACE(@pi_Nombre, ' ', '%'),'%')
			   		OR CONCAT(e.ApellidoMaterno,e.ApellidoPaterno,e.Nombre) LIKE CONCAT('%',REPLACE(@pi_Nombre, ' ', '%'),'%')
			   		OR CONCAT(e.Nombre,e.ApellidoMaterno,e.ApellidoPaterno) LIKE CONCAT('%',REPLACE(@pi_Nombre, ' ', '%'),'%')
			   		OR o.NombreOficial LIKE CONCAT('%',REPLACE(@pi_Nombre, ' ', '%'),'%')
			   )
		ORDER BY e.EmpleadoId desc
	END TRY
	BEGIN CATCH 
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION; 
		EXECUTE usp_GetErrorInfo; 
		 
	END CATCH
END
