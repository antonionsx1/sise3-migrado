SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Snatiago de la Cruz
-- Create date: 04/09/2023
-- Description:	Obtener la información del seguimiento por fecha actual
-- Description: La consulta apunta a la vista
-- EXEC [SISE3].[uspx_getSeguimientoFecha] '2014-10-03'
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getSeguimientoFecha]
(
  -- FECHA QUE SE DESEA CONSULTAR(Fecha actual o rango de fechas)	
	@pi_FechaIni DATE = NULL,
	@pi_FechaFin DATE = NULL,
	@pi_CatOrganismoId INT=NULL
)

AS
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
WHERE CatOrganismoId = @pi_CatOrganismoId  AND
       (     (@pi_FechaIni IS NOT NULL AND @pi_FechaFin IS NOT NULL AND CONVERT(DATE, FechaHora) BETWEEN @pi_FechaIni AND @pi_FechaFin) OR
            (@pi_FechaIni IS NOT NULL AND @pi_FechaFin IS NULL AND CONVERT(DATE, FechaHora) = @pi_FechaIni)             
        )
ORDER BY FechaHora DESC

	
END