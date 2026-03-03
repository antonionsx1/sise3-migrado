SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 20/09/2023
-- Description:	Inserta el seguimiento de un documento. 
-- EXEC 
-- Modificacion:
-- EXEC [SISE3].[uspx_getSeguimientoCo] 14920378,'1/2014', 10,'Amparo indirecto',null,NULL,1494,5,'Principal','2023-05-04',1230,2023
--EXEC [SISE3].[uspx_getSeguimientoCo] null,'1/2014', null,'Inconformidades',null,NULL,1361,null,null,null,null,null
-- =============================================
CREATE procedure [SISE3].[uspx_getSeguimientoCon]
(
     @pi_CatOrganismoId  int =null,
	 @pi_AsuntoNeunId int  =null,
    @pi_CatTipoAsunto  nvarchar(150) = null
	
)
AS
BEGIN

	DECLARE @new_id bigint = 0
	DECLARE @pi_empleadoId bigint
	DECLARE @pi_areaId bigint
	DECLARE @FilasInsertadas int
	
	
	
	--------------------------------------------------------------------------------------------------
	SET @pi_empleadoId = (SELECT EmpleadoId FROM Asuntos WHERE AsuntoNeunId = @pi_AsuntoNeunId )
	SET @pi_areaId = (SELECT TOP 1 AreaId FROM Areas WHERE EmpleadoId = @pi_empleadoId  )

  
	SET @FilasInsertadas = 0
	   SELECT 
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
		TipoDocumento,
		@FilasInsertadas AS FilasInsertadas
	FROM uvix_SeguimientoQR 
    WHERE  
           CatOrganismoId = @pi_CatOrganismoId AND
      AsuntoNeun = @pi_AsuntoNeunId
	  AND TipoAsunto= @pi_CatTipoAsunto
	  ORDER BY FechaHora DESC

END
