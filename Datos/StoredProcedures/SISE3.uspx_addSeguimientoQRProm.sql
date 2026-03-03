SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 21/09/2023
-- Description:	Inserta el seguimiento de un documento. 
-- EXEC 
-- Modificacion:
-- EXEC [SISE3].[uspx_addSeguimientoQRProm] 14920378,'1/2014', 10,'Amparo indirecto',null,NULL,1494,5,'Principal','2023-05-04',1230,2023
--EXEC [SISE3].[uspx_addSeguimientoQRProm] null,'1/2014', null,'Inconformidades',null,NULL,1361,null,null,null,null,null
-- =============================================
CREATE procedure [SISE3].[uspx_addSeguimientoQRProm]
(
    @pi_AsuntoNeunId int  =null,
	@pi_AsuntoAlias  nvarchar(150)=null,
	@pi_CatTipoAsuntoId int = null,
	@pi_CatTipoAsunto  nvarchar(150) = null,
    @pi_TipoProcedimientoId nvarchar(50) = null,
	@pi_TipoProcedimiento  nvarchar(150) = null,    
    @pi_CatOrganismoId  int =null,
    
	@pi_CuadernoId int =null,
	@pi_Cuaderno  nvarchar (50)= null,
	@pi_FechaPresentacion datetime = null,
	@pi_NumeroRegistro  nvarchar(150) = null,
    @pi_YearPromocion int= null,
	@pi_ConsultaInserta bit null,
	@pi_EmpleadoId int =null
)
AS
BEGIN

	DECLARE @new_id bigint = 0
	
	DECLARE @pi_areaId bigint
	DECLARE @FilasInsertadas int
	IF (@pi_ConsultaInserta IS NULL)
	BEGIN
	  SET  @pi_ConsultaInserta= 0
	END
	
	-------------busca valores para insertar en caso de recibir nulos----------------------------------
	IF (@pi_AsuntoNeunId =1)
	BEGIN
	IF (@pi_AsuntoNeunId IS NULL)
	BEGIN
	  SET  @pi_AsuntoNeunId= (SELECT TOP 1 AsuntoNeunId FROM Asuntos WHERE AsuntoAlias=@pi_AsuntoAlias)
	 
	END
	END
	--------------------------------------------------------------------------------------------------
	
	SET @pi_areaId = (SELECT TOP 1 AreaId FROM Areas WHERE EmpleadoId = @pi_empleadoId  )
IF ((@pi_ConsultaInserta = 1) OR (@pi_ConsultaInserta = 2) )
BEGIN
	IF EXISTS (SELECT AsuntoNeunId FROM Asuntos WHERE AsuntoNeunId = @pi_AsuntoNeunId) 
       BEGIN
			IF  (@pi_areaId  IS NOT NULL)
				BEGIN 
					INSERT INTO Seguimiento (
					CatOrganismoId,
					AreaId, 
					EmpleadoId, 
					AsuntoNeun,
					FechaHora,
					Descripcion,
					StatusReg,
					Tipo,
					DocumentoId
					)
					VALUES (
					@pi_CatOrganismoId,
					@pi_areaId,
					@pi_empleadoId ,
					@pi_AsuntoNeunId ,
					GETDATE(),
					'La promoción ' + @pi_AsuntoAlias + ' fue turnada correctamente.',
					2,
					2,--@pi_tipo ,
					@pi_AsuntoAlias--@pi_documentoId 
							)
							
		          SET @FilasInsertadas  = (SELECT @@ROWCOUNT)
				  IF (@pi_ConsultaInserta = 1)
				  BEGIN
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
					AND TipoAsunto= @pi_CatTipoAsunto  ORDER BY FechaHora DESC

					END
					IF (@pi_ConsultaInserta = 2)
					BEGIN
					     SELECT  @@ROWCOUNT AS FilasInsertadas 
					END
			END
    
		END
END	

  IF (@pi_ConsultaInserta = 0)
	BEGIN
	 EXEC   [SISE3].[uspx_getSeguimientoCon] @pi_CatOrganismoId,@pi_AsuntoNeunId,@pi_CatTipoAsunto
    END
END



