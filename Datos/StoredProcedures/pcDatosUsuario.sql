USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcDatosUsuario]    Script Date: 12/1/2023 6:14:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- =============================================
-- Author:  Diana Quiroga
-- Alter date:  13/10/2013
-- Description: <Consulta los datos del usuario de acuerdo al username y catorganismoId> -- Basado en usp_CatEmpleadosOrganismoDatosSel
-- Permite la carga masiva de archivos para ser asociados a diferentes promociones basado en el Año, numero de orden y numero de Organismo
-- Basado en: usp_CatEmpleadosOrganismoDatosSel 
-- Ejemplo: EXEC [SISE3].[pcDatosusuario] 35332, 1494

CREATE PROCEDURE [SISE3].[pcDatosUsuario]
	-- Add the parameters for the stored procedure here
	@pi_EmpleadoId INT, 
	@pi_CatOrganismoId INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT  Id = ROW_NUMBER() OVER (PARTITION BY EmpleadoId ORDER BY FechaAlta DESC)
		   ,EmpleadoId 
		   ,Correo
	INTO #TempCorreo
	FROM  dbo.empleadocorreos
	WHERE EmpleadoId = @pi_EmpleadoId
	AND CatOrganismoId = @pi_CatOrganismoId


  	SELECT  TOP 1 CAST(a.EmpleadoId AS INT) AS EmpleadoId
		   ,UPPER(a.Nombre + ' ' + a.ApellidoPaterno + ' ' + a.ApellidoMaterno) AS Completo
		   ,eo.CargoId
		   ,c.CargoDescripcion
		   ,b.CatOrganismoId
		   ,b.NombreOficial
		   ,b.CatTipoOrganismoId
		   ,b.CatCircuitoId
		   ,ISNULL(d.CatMateriaId,0) AS CatMateriaId
		   ,e.CatCircuitoClasificacionId
		   ,a.estatusactivacion
		   ,a.Nombre
		   ,a.ApellidoPaterno
		   ,a.ApellidoMaterno
		   ,ISNULL(re.StatusReg,0) AS StatusReg
		   ,b.consultaexp,b.vetramite
		   ,b.veridcampocaptura
		   ,CatClasificacionOrganismoId = ISNULL(b.CatClasificacionOrganismoId,0) --GGHH 301116 Para validar que no se muestren organos de pruebas
		   ,registro -- SBGE 06/03/2017 se obtiene el identificadorpara obtener con este los permisos de archivos en tabla PermisosArchivo
		   ,tc.correo AS EMail 
	FROM dbo.CatEmpleados AS a WITH (NOLOCK) 
	INNER JOIN dbo.EmpleadoOrganismo AS eo 
		ON a.EmpleadoId = eo.EmpleadoId 
	INNER JOIN dbo.CatOrganismos AS b WITH (NOLOCK) 
		ON b.CatOrganismoId = eo.CatOrganismoId 
	INNER JOIN dbo.CatCargo AS c WITH (NoLock) 
		ON eo.CargoId = c.CargoId 
	LEFT JOIN dbo.OrganismosTipoAsuntoMaterias AS d 
		ON b.CatOrganismoId = d.CatOrganismoId 
		AND d.StatusReg = 1 
	LEFT JOIN dbo.CatCircuitos AS e 
		ON e.CatCircuitoId = b.CatCircuitoId 
	LEFT JOIN dbo.RolesEmpleados AS re 
		ON re.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN #TempCorreo tc 
		ON tc.EmpleadoId = a.EmpleadoId 
		AND tc.Id = 1
	WHERE (b.CatOrganismoId > 0) 
	AND (a.StatusRegistro = 1) 
	AND (eo.StatusRegistro = 1)
	and a.EmpleadoId = @pi_EmpleadoId
	AND b.CatOrganismoId = @pi_CatOrganismoId
	AND eo.CargoId<>63--BVM 21052014 SE AGREGA ESTA INSTRUCCIÓN PARA NO TOMAR EN CUENTA EL CARGO DE TITULAR DEL ÓRGANO
	ORDER BY re.FechaAlta DESC

END
GO

