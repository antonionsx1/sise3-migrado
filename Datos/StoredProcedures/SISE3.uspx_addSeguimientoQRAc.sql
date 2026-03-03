SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 13/10/2023
-- Description:	Inserta el seguimiento de un documento. 
-- EXEC 
-- Modificacion:
-- EXEC [SISE3].[uspx_addSeguimientoQRProm] 111,264, 63151,11323378,'La promocion se registro correctamente',2,2,20826
--EXEC [SISE3].[uspx_addSeguimientoQRProm] null,'1/2014', null,'Inconformidades',null,NULL,1361,null,null,null,null,null
-- =============================================
CREATE procedure [SISE3].[uspx_addSeguimientoQRAc]
(
	-- representa el identificador del organismo donde se está registrando el movimiento del documento 
	@pi_organismoId int,

	-- representa el identificador del área donde se está turnando el documento 
	@pi_areaId int,

	-- representa el identificador del empleado que está recibiendo el documento 
	@pi_empleadoId bigint,

	-- representa el número de expediente único nacional del documento que se está recibiendo
	@pi_asuntoNeun bigint,

	/* es un texto amigable al usuario sobre el movimiento que se está registrando 
	 * <tpl>[Turno|creado] de [Expediente|Promocion|Oficio|Acuerdo], recibe el empleado {nombreEmpleado} del área {area}.</tpl>
	 * donde:
	 *		 [Expediente|Promocion|Oficio|Acuerdo] está dado por el @pi_Tipo 
	 *		 {nombre} es el nombre del empleado que corresponde al identficador @pi_empid
	 *		 {area} es el área que corresponde al identficador @pi_area
	 */
	@pi_descripcion nvarchar(255),

	/* representa el estado del registro donde:
	 * 1 = Creado
	 * 2 = Turnado
	 */
	@pi_status smallint,

	/* representa el identificador del tipo de documento donde:
	 * 1 = Expediente,
	 * 2 = Promoción,
	 * 3 = Oficio,
	 * 4 = Acuerdo
	 */
	@pi_tipo smallint,

	/* representa el identificador o nombre del documento (como el usuario lo reconoce), por ejemplo:
	 * para la promoción es el "número de registro"
	 * para el expediente es el "número de expediente xxx/aaaa"
	 * para el oficio es el "número de fólio"
	 */
	@pi_documentoId nvarchar(50)--,

	--@new_id int output
)
AS
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
						    @pi_organismoId,
							@pi_areaId ,
							@pi_empleadoId ,
							@pi_asuntoNeun ,
							GETDATE(),
							@pi_descripcion,
							@pi_status,
							@pi_tipo,--@pi_tipo ,
							@pi_documentoId--@pi_documentoId 
								)
		   
END



