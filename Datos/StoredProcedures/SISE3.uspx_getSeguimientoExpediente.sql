SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 06/10/2023
-- Description:	Consulta que carga el combo de expediente en seguimiento
--EXEC [SISE3].[uspx_getSeguimientoExpediente] 1270,'982/2013','Expediente'
--EXEC [SISE3].[uspx_getSeguimientoExpediente] 340,'1/2014','Acuerdo'
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getSeguimientoExpediente](
	@pi_CatOrganismoId BIGINT,
	@pi_expediente NVARCHAR(25),
	@pi_tipoDocumento NVARCHAR(50))
AS
BEGIN
	SELECT DISTINCT 
	      --DocumentoId,
	      AsuntoNeun,
	      Expediente,
		  TipoAsunto,
		  TipoProcedimiento
   FROM uvix_SeguimientoQR
   WHERE CatOrganismoId=@pi_CatOrganismoId
   AND  @pi_expediente= Expediente
   AND   @pi_tipoDocumento = TipoDocumento

END
