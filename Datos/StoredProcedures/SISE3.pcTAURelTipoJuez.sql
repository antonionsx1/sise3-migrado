CREATE PROCEDURE [SISE3].[pcTAURelTipoJuez]
	@pi_idOrganismo			INT
AS
/***************************************************************************************************************************/
-- Autor : Martin Tovar
-- Fecha de Creacion:  2025-01-06
-- Descripcion: Obtiene catálogo Tipos de Jueces, ID organismo opcional.  
-- Ejemplo : EXEC sise3.pcTAUTipoJuez 1460
-- SP Original : EXEC [dbo].[TAU_pcRelTipoJuez] 1460
/***************************************************************************************************************************/
BEGIN
	DECLARE 
	@ErrorMessage NVARCHAR(4000),
	@ErrorSeverity INT,
	@ErrorState INT

	SET NOCOUNT ON
	BEGIN TRY 
		SELECT
			a.fCatOrganismoId		AS OrganismoId
			,a.kIdRelTipoJuez		AS IdRelTipoJuez
			,a.fEmpleadoId			AS EmpleadoId
			,c.Nombre + ' ' + c.ApellidoPaterno + ' ' + c.ApellidoMaterno	AS Juez
			,b.kIdTipoJuez			AS IdTipoJuez
			,b.sDescripcion			AS TipoJuez
		FROM TAU_Rel_TipoJuez a WITH (NOLOCK)
		INNER JOIN TAU_CAT_TipoJuez b WITH (NOLOCK)
			ON b.kIdTipoJuez = a.fkIdTipoJuez
		LEFT JOIN Catempleados c WITH (NOLOCK) 
			ON c.EmpleadoId = a.fEmpleadoId
		WHERE (@pi_idOrganismo = 0 OR a.fCatOrganismoId = @pi_idOrganismo)
			AND a.iEstatus=1
		ORDER BY Juez, TipoJuez
	END TRY

	BEGIN CATCH
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),                 
            @ErrorState =ERROR_STATE();
		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH
	SET NOCOUNT OFF

END
