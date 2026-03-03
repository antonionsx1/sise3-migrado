USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcConsultaCorreoMesa]    Script Date: 12/1/2023 6:14:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Diana Quiroga - MS
-- Alter date: 19/09/2023
-- Objetivo: Retornar los correos de acuerdo a la mesa asignada del secretario
--[SISE3].[pcConsultaCorreoMesa] 71961,1494
-- =============================================
CREATE PROCEDURE [SISE3].[pcConsultaCorreoMesa]
@pi_EmpleadoIdResponsable INT, 
@pi_CatOrganismoId INT 
AS
BEGIN
	SELECT DISTINCT a.EmpleadoId
		   ,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno, e.ApellidoMaterno)Nombre
		   ,ec.Correo
	FROM (
		SELECT  a.EmpleadoId
			   ,a.CatOrganismoId
		FROM Areas a
		WHERE a.EmpleadoId = @pi_EmpleadoIdResponsable
		AND a.CatOrganismoId = @pi_CatOrganismoId
		UNION
		SELECT  ae.EmpleadoId
			   ,a.CatOrganismoId
		FROM Areas a
		INNER JOIN AreasEmpleados ae ON a.AreaId = ae.AreaId
		WHERE a.EmpleadoId = @pi_EmpleadoIdResponsable
		AND a.CatOrganismoId = @pi_CatOrganismoId)a 
		INNER JOIN EmpleadoCorreos ec ON a.EmpleadoId = ec.EmpleadoId AND a.CatOrganismoId = ec.CatOrganismoId AND ec.StatusRegistro = 1
		INNER JOIN EmpleadoOrganismo eo ON ec.CatOrganismoId = eo.CatOrganismoId AND ec.EmpleadoId = eo.EmpleadoId AND eo.StatusRegistro = 1
		INNER JOIN CatEmpleados e 
		ON e.EmpleadoId = eo.EmpleadoId
		/*DECLARE @Magistrado TABLE (EmpleadoId int,
									NombreCompleto varchar(150)
									,Correo nvarchar (100))
		INSERT INTO @Magistrado (EmpleadoId, NombreCompleto, Correo)
		VALUES (108062, 'Jose Alfonso Montalvo Martinez', 'jamontalvo@cjf.gob.mx')

		SELECT DISTINCT e.EmpleadoId, SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno, e.ApellidoMaterno)Nombre
		,ec.Correo
		from CatEmpleados e
		INNER JOIN EmpleadoCorreos ec ON E.EmpleadoId = ec.EmpleadoId AND ec.StatusRegistro = 1
		WHERE E.EmpleadoId = 108046
		UNION ALL
		SELECT * FROM @Magistrado*/



END
GO

