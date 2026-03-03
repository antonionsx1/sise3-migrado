SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Mario Alejandro Santiago de la Cruz  
-- Create date:  08/09/2023 
-- Description: Obtener la información de un seguimiento en particular  
-- Actualizacion:  
-- Description: Se agregan descripcion del organismo y el área
-- EXEC SISE3.uspx_getSeguimientoExp 
-- EXEC SISE3.uspx_getSeguimientoExp '2015-02-19'
--EXEC SISE3.uspx_getSeguimientoExp '2014-06-13', '2014-06-18',340

-- =============================================  
  
CREATE procedure [SISE3].[uspx_getSeguimientoExp]
(
@pi_Fecha DATE = NULL,
@pi_FechaFin DATE = NULL,
@pi_CatOrganismoId INT=NULL
)

AS  
BEGIN 
IF (@pi_Fecha IS NOT NULL OR @pi_FechaFin IS NOT NULL)
    BEGIN
 
    EXEC  [SISE3].[uspx_getSeguimientoFecha] @pi_Fecha,@pi_FechaFin ,@pi_CatOrganismoId 
    END
ELSE 
BEGIN
SELECT DISTINCT
    SeguimientoId,
	CatOrganismoId,
	AreaId,
	Area,
	EmpleadoId,
	EmpleadoNombre,
	UserName,
	AsuntoNeun,
	FechaHora,
	CASE 
    WHEN FechaHora IS NOT NULL THEN CONVERT(NVARCHAR(10), CONVERT(DATE, FechaHora), 103)
      ELSE NULL
    END AS Fecha,
	CASE 
		WHEN FechaHora IS NOT NULL THEN CONVERT(NVARCHAR(8), CONVERT(TIME, FechaHora))
		ELSE	NULL
	END AS Hora,	
	Descripcion,
    Expediente,
	StatusReg,
	TipoAsunto,	
	TipoId,
	DocumentoId,
	TipoDocumento,
	NumeroAlias,
	FechaHora_F,
	PuestoDescripcion, 
	TipoProcedimiento
 FROM uvix_SeguimientoQR   
 WHERE   CatOrganismoId = @pi_CatOrganismoId  
 ORDER BY FechaHora DESC
   END   
END

