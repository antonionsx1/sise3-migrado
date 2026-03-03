SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 11 de Octubre del 2023
-- Description:	Consulta el expediente y el tipo asunto  recibiendo como parametro el expediente
-- Exec [SISE3].[uspx_getSeguimientoBusca] '1/2013' ,'772'
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getSeguimientoBusca]
	(
	@pi_Expediente AS NVARCHAR(50),
	@pi_CatOrganismoId AS BIGINT
	)
	AS
BEGIN
       SELECT DISTINCT cr.AsuntoAlias AS Expediente,
              ta.Descripcion AS TipoAsunto,
			  cr.CatOrganismoId AS OrganismoId,
			  cr.TipoProcedimiento
       FROM   dbo.Seguimiento s
	          CROSS APPLY SISE3.fnExpediente(s.AsuntoNeun) cr
	          INNER JOIN            
			  dbo.CatTiposAsunto AS ta ON cr.CatTipoAsuntoId = ta.CatTipoAsuntoId	          	           
			 WHERE cr.AsuntoAlias= @pi_Expediente 
			 AND  cr.CatOrganismoId=@pi_CatOrganismoId

	
                         

END
