CREATE PROCEDURE [SISE3].[TAU_pcMovimientosAudiencias]
(
@piNeun  BIGINT
)
AS

/***************************************************************************************************************************/
-- Autor : Martín Tovar
-- Fecha de Creacion:  2024-09-24
-- Descripcion: Consulta los movimientos por Audiencia
-- Basado en SP [dbo].[TAU_pcMovimientosAudiencias]
/***************************************************************************************************************************/
DECLARE 
@ErrorMessage NVARCHAR(4000),
@ErrorSeverity INT,
@ErrorState INT

SET NOCOUNT ON 

			BEGIN TRY
				SELECT	 i.idInformacionGeneralAudiencia
						,i.fkIdAsuntoNeun
						,ob.iAudiencia as NumeroAudiencia
						,i.fkIdTipoAudiencia
						,i.sDescripcionAudiencia
						,i.idEstatusAudiencia
						,est.descripcionEstatusAudiencia
						,tm.sDescripcion as DescTipoMovimiento
						,ob.fFechaRegistro as FechaModificacion
						,ob.sObservacion
						,isnull(co.sDescripcion,'') as CatObservacion
						,ob.iUsuario
						, CASE ob.iUsuario WHEN 0 THEN  isnull(ob.NombreUsuarioOraltis,'')
						  ELSE isnull(e.Nombre,'') +' '+ isnull(e.ApellidoPaterno,'')+ ' ' +isnull(e.ApellidoMaterno,'') end as UsuarioModifica
						, CASE ob.iUsuario WHEN 0 THEN 'OralTis'
						  ELSE 'SISE' END AS 'Sistema'
						,ob.fkIdTipoMovimiento AS IdTipoMovimiento
						FROM informacionGeneralAudiencia i WITH(NOLOCK) 
						INNER JOIN CatEstatusAudiencia est WITH(NOLOCK)  ON est.idEstatusAudiencia= i.idEstatusAudiencia
						INNER JOIN TAU_Mov_Observaciones ob WITH(NOLOCK) ON i.fkIdAsuntoNeun=ob.fAsuntoNeunId and i.idAudiencia=ob.iAudiencia
						LEFT JOIN TAU_Cat_Observaciones co WITH(NOLOCK) ON co.kIdObservacion=ob.fkIdObservacion and co.iTipo=ob.fkIdTipoMovimiento
						INNER JOIN CatEmpleados e WITH(NOLOCK) ON e.empleadoid=ob.iUsuario
						INNER JOIN TAU_Cat_TipoMovimiento tm WITH(NOLOCK) ON tm.kIdTipoMovimiento=ob.fkIdTipoMovimiento
						WHERE 
						i.fkIdAsuntoNeun= @piNeun
					    and	ob.iEstatus=1
			END TRY
								
			------Manejo de Errores.
			BEGIN CATCH			  
			   SELECT 
					  @ErrorMessage = ERROR_MESSAGE(),
                      @ErrorSeverity = ERROR_SEVERITY(),                 
                      @ErrorState =ERROR_STATE();

			 RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
			END CATCH

SET NOCOUNT OFF
