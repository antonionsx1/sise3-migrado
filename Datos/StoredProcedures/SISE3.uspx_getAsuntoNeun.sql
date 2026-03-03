SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [SISE3].[uspx_getAsuntoNeun]
(
        @pi_Expediente VARCHAR(50) = NULL,
        @pi_OrganismoId INT = NULL       
)
AS
BEGIN
        SELECT TOP 1 AsuntoNeun
        FROM    uvix_SeguimientoQR
        WHERE   Expediente= @pi_Expediente 
		AND     CatOrganismoId = ISNULL(@pi_OrganismoId, CatOrganismoId)
        
END

