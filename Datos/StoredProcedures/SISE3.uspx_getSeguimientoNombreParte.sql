SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 06/10/2023
-- Description:	Consulta que carga el combo de asuntos en seguimiento
-- Exec [SISE3].[uspx_getSeguimientoNombreParte] 790,'57/2007', 'Causa Penal','Promoción','20150218',''
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getSeguimientoNombreParte]
	(
@pi_CatOrganismoId  INT,
@pi_Expediente    VARCHAR(50),
@pi_TipoAsunto    VARCHAR(50),
@pi_TipoDocumento VARCHAR(50),
@pi_Fecha  VARCHAR(50),
@pi_TipoProcedimiento NVARCHAR(50)=''
)
AS
BEGIN
   DECLARE @Fecha datetime
   SET @Fecha = (CONVERT(DATETIME, @pi_Fecha, 103)) 
  
	 SELECT DISTINCT  
	        AsuntoNeun,
	        CONCAT(NombreParte, APaternoParte,AMaternoParte) AS NombreParte,
			Caracter,
			TipoProcedimiento
	FROM  uvix_SeguimientoQR
	WHERE CatOrganismoId = @pi_CatOrganismoId
	  AND Expediente = @pi_Expediente
	  AND TipoAsunto = @pi_TipoAsunto
	  AND TipoDocumento= @pi_TipoDocumento
	  AND  CAST(FechaHora AS DATE) = CAST((CONVERT(NVARCHAR(10), CONVERT(DATE, @Fecha), 120)) AS DATE)
	  AND TipoProcedimiento = @pi_TipoProcedimiento;
	  

	
END
