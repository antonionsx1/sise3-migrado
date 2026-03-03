SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 13/10/2023
-- Description:	Obtiene todos los asuntos relacionados en la tabla asuntos relacionados. 
--  EXEC [SISE3].[uspx_getAsuntoRelacionado]
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getAsuntoRelacionado](
	@AsuntoNeunIdOrg BIGINT = NULL,
	@AsuntoNeunIdDest BIGINT = NULL,
	@CatOrganismoId BIGINT = NULL,
	@AsuntoIdOrg BIGINT = NULL
	)
AS
BEGIN
	SELECT 
    a.IdAsuntoRela,
    a.FechaOrigen, 
    a.FechaDestino,
    a.AsuntoNeunIdOrg,  
    a.AsuntoNeunIdDest, 
	cOrg.NombreOficial AS OrganoOrigen,
    cDest.NombreOficial AS OrganoDestino,	
	dOrg.Descripcion AS TipoAsuntoOrigen,
    dDest.Descripcion AS TipoAsuntoDestino,
	bOrg.AsuntoAlias AS ExpedienteOrigen,
    bDest.AsuntoAlias AS ExpedienteDestino,
    a.EmpleadoIdOrg,
    ceOrg.Nombre + ' ' + ceOrg.ApellidoPaterno + ' ' + ceOrg.ApellidoMaterno AS NombreEmpleadoOrigen,
    a.EmpleadoIdDest,
    ceDest.Nombre + ' ' + ceDest.ApellidoPaterno + ' ' + ceDest.ApellidoMaterno AS NombreEmpleadoDestino,
	a.EmpleadoIdCancela,
	ceCan.Nombre + ' ' + ceCan.ApellidoPaterno + ' ' + ceCan.ApellidoMaterno AS NombreEmpleadoCancela,	
	aso.CatTipoProcedimiento AS CatProcedimientoOrigen,
	asDest.CatTipoProcedimiento AS CatProcedimientoDestino,
	aso.TipoProcedimiento AS ProcedimientoOrigen,
	asDest.TipoProcedimiento AS ProcedimientoDestino
FROM 
    AsuntosRelacionados a
	INNER JOIN 
    Asuntos bOrg ON bOrg.AsuntoNeunId = a.AsuntoNeunIdOrg
	INNER JOIN 
    CatOrganismos cOrg ON cOrg.CatOrganismoId = bOrg.CatOrganismoId
	INNER JOIN 
    CatTiposAsunto dOrg ON dOrg.CatTipoAsuntoId = bOrg.CatTipoAsuntoId
INNER JOIN 
    Asuntos bDest ON bDest.AsuntoNeunId = a.AsuntoNeunIdDest
INNER JOIN 
    CatOrganismos cDest ON cDest.CatOrganismoId = bDest.CatOrganismoId
INNER JOIN 
    CatTiposAsunto dDest ON dDest.CatTipoAsuntoId = bDest.CatTipoAsuntoId
INNER JOIN 
    CatEmpleados ceOrg ON ceOrg.EmpleadoId = a.EmpleadoIdOrg
INNER JOIN 
    CatEmpleados ceDest ON ceDest.EmpleadoId = a.EmpleadoIdDest
LEFT JOIN 
    CatEmpleados ceCan ON ceCan.EmpleadoId = a.EmpleadoIdCancela
	CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunIdOrg) aso
	CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunIdDest) asDest
WHERE a.AsuntoNeunIdOrg = @AsuntoNeunIdOrg	
   AND a.AsuntoNeunIdDest = @AsuntoNeunIdDest
   AND a.AsuntoIdOrg = @AsuntoIdOrg
   AND bOrg.CatOrganismoId = @CatOrganismoId
   AND bOrg.CatOrganismoId = @CatOrganismoId

END
