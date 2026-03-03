SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 06/10/2023
-- Description:	Consulta que carga el combo de asuntos en seguimiento
--EXEC [SISE3].[uspx_getSeguimientoAsuntos] 270,'26/2001','Causa Penal','Promoción'
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getSeguimientoAsuntos]
(
@pi_CatOrganismoId  INT,
@pi_Expediente NVARCHAR(50),
@pi_TipoAsunto NVARCHAR(30),
@pi_TipoDocumento NVARCHAR(50),
@pi_TipoProcedimiento NVARCHAR(50)=''
)
AS
BEGIN
		SELECT DISTINCT  AsuntoNeun,
		                TipoAsunto,
						Expediente ,
						TipoProcedimiento,
						TipoDocumento,
						FechaHora_F,
						DocumentoId
		FROM uvix_SeguimientoQR
	   WHERE CatOrganismoId = @pi_CatOrganismoId
	   AND Expediente = @pi_Expediente 
	   AND TipoAsunto = @pi_TipoAsunto
	   AND TipoDocumento = @pi_TipoDocumento
	   AND TipoProcedimiento = @pi_TipoProcedimiento 	   
END