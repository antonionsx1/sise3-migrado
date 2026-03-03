SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 11 de Octubre del 2023
-- Description:	Consulta el expediente y el tipo asunto  recibiendo como parametro el expediente
-- EXEC [SISE3].[uspx_getSeguimientoAllExpediente] '157/2003', 'Causa Penal',340, ''
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getSeguimientoAllExpediente]
	(
	@pi_AsuntoAlias AS NVARCHAR(50),
	@pi_TipoAsunto AS NVARCHAR(150),
	@pi_CatOrganismoId AS BIGINT,
	@pi_TipoProcedimiento AS VARCHAR(150)=''
	)
	AS
BEGIN
       SELECT DISTINCT   
	          s.AsuntoNeun,
			  s.CatOrganismoId,
			  s.FechaHora,
			  CONVERT(NVARCHAR(10), CONVERT(DATE, s.FechaHora), 105) AS Fecha,
			  CONVERT (VARCHAR(8),CONVERT(TIME, s.FechaHora))  AS Hora,
			  CONVERT(NVARCHAR(10), CONVERT(DATE, s.FechaHora), 105) AS Fecha_F,
			  CONVERT (VARCHAR(8),CONVERT(TIME, s.FechaHora))  AS Hora_F,
			  cr.AsuntoAlias AS Expediente,
              s.DocumentoId,			  
		      CASE s.Tipo WHEN 1 THEN 'Expediente' WHEN 2 THEN 'Promoción' WHEN 3 THEN 'Acuerdo' WHEN 4 THEN 'Oficio' END AS TipoDocumento,
			  LOWER(emp.UserName) AS UserName,
			  CONCAT( emp.Nombre,' ', emp.ApellidoPaterno,'  ',emp.ApellidoMaterno ) AS EmpleadoNombre, 
		      emp.PuestoDescripcion,
			  a.Nombre AS Area,
			  ta.Descripcion AS TipoAsunto,
			  c.Cuaderno AS Tipo,
			  cr.TipoProcedimiento

FROM            dbo.Seguimiento AS s 
                CROSS APPLY SISE3.fnExpediente(s.AsuntoNeun) cr
				LEFT OUTER JOIN
                dbo.Areas AS a ON s.AreaId = a.AreaId 
				INNER JOIN
                dbo.CatEmpleados AS emp ON emp.EmpleadoId = s.EmpleadoId 
				INNER JOIN
                dbo.CatTiposAsunto AS ta ON cr.CatTipoAsuntoId = ta.CatTipoAsuntoId 
				INNER JOIN
                dbo.PersonasAsunto AS pas ON cr.AsuntoNeunId = pas.AsuntoNeunId
				INNER JOIN
                dbo.CatCaracterPersonaAsunto AS car ON pas.CatCaracterPersonaAsuntoId = car.CatCaracterPersonaAsuntoId 
				INNER JOIN
				AsuntosDocumentos AS ad ON s.AsuntoNeun = ad.AsuntoNeunId 
				INNER JOIN
				tbx_CatCuadernos c ON c.CuadernoId = ad.TipoCuaderno
				
		WHERE a.StatusReg = 1
			AND  cr.AsuntoAlias= @pi_AsuntoAlias
			AND ta.Descripcion =@pi_TipoAsunto
			AND cr.CatTipoProcedimiento= @pi_TipoProcedimiento
			AND cr.CatOrganismoId= @pi_CatOrganismoId 
                         
END
