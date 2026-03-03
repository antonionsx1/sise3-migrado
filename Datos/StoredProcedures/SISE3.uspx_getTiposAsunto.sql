SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 27/09/2023
-- Description:	Consulta todos los tipo asuntos relacionadios con  el catOrganismoId logueado. 
-- EXEC 
-- Modificacion:
-- EXEC [SISE3].[uspx_getTiposAsunto] 1494
--EXEC [SISE3].[uspx_getTiposAsunto] 1270
-- =============================================
CREATE procedure [SISE3].[uspx_getTiposAsunto]
(
@pi_CatOrganismoId  INT

)
AS
BEGIN
		SELECT DISTINCT  AsuntoNeun,
		                TipoAsunto,
						Expediente ,
						TipoProcedimiento,
						TipoDocumento
		FROM uvix_SeguimientoQR
	   WHERE CatOrganismoId = @pi_CatOrganismoId
	   	  
END
