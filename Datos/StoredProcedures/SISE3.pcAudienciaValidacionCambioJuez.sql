-- =============================================
-- Author:  Martin Tovar
-- Creation date: 28/11/2024 - MTS creación SP
-- Description: Obtiene las audiencias y resoluciones de un juez. 
-- EXEC [SISE3].[pcAudienciaValidacionCambioJuez]	1497,1
CREATE PROCEDURE [SISE3].[pcAudienciaValidacionCambioJuez]
	@pi_CatOrganismoId INT,
	@pi_TipoAudiencia INT
AS
	
SET NOCOUNT ON;
DECLARE
	@ErrorMessage NVARCHAR(4000),
	@ErrorSeverity INT,
	@ErrorState INT
BEGIN TRY			


IF @pi_TipoAudiencia = 1		--Juicio
BEGIN
	SELECT
		a.fkIdAsuntoNeun							AS NeunId
		,a.idAudiencia								AS idAudiencia
		,a.fkCatOrganismoId							AS IdOrganismo
		,a.fkIdTipoAudiencia						AS IdTipoAudiencia
		,a.sDescripcionAudiencia					AS DescripcionAudiencia
		,a.idEstatusAudiencia						AS idEstatusAudiencia
		,estatus.descripcionEstatusAudiencia		AS DescripcionEstatusAudiencia
		,cta.Descripcion							AS Salida
	FROM InformacionGeneralAudiencia a WITH (NOLOCK) 
	INNER JOIN CatEstatusAudiencia estatus WITH (NOLOCK) ON estatus.idEstatusAudiencia=a.idEstatusAudiencia
	INNER JOIN Asuntos asun WITH (NOLOCK) ON asun.AsuntoNeunId=a.fkIdAsuntoNeun
	LEFT JOIN CatTiposAsunto cta WITH (NOLOCK) ON cta.CatTipoAsuntoId=asun.CatTipoAsuntoId
	WHERE 1=1
		AND a.fkCatOrganismoId = @pi_CatOrganismoId
		AND a.fkIdTipoAudiencia IN (257,229,247,276,278,280,283)
END
ELSE	--Ejecución
BEGIN
	SELECT
		a.fkIdAsuntoNeun							AS NeunId
		,a.idAudiencia								AS idAudiencia
		,a.fkCatOrganismoId							AS IdOrganismo
		,a.fkIdTipoAudiencia						AS IdTipoAudiencia
		,a.sDescripcionAudiencia					AS DescripcionAudiencia
		,a.idEstatusAudiencia						AS idEstatusAudiencia
		,estatus.descripcionEstatusAudiencia		AS DescripcionEstatusAudiencia
		,cta.Descripcion							AS Salida
	FROM InformacionGeneralAudiencia a WITH (NOLOCK) 
	INNER JOIN CatEstatusAudiencia estatus WITH (NOLOCK) ON estatus.idEstatusAudiencia=a.idEstatusAudiencia
	INNER JOIN Asuntos asun WITH (NOLOCK) ON asun.AsuntoNeunId=a.fkIdAsuntoNeun
	LEFT JOIN CatTiposAsunto cta WITH (NOLOCK) ON cta.CatTipoAsuntoId=asun.CatTipoAsuntoId
	WHERE 1=1
		AND a.fkCatOrganismoId = @pi_CatOrganismoId
		AND a.fkIdTipoAudiencia IN (347,296,297,301,302,306,307,311,312,316,317,322,323,330)
END

END TRY
BEGIN CATCH
	SELECT 
		@ErrorMessage = ERROR_MESSAGE(),
		@ErrorSeverity = ERROR_SEVERITY(),                 
		@ErrorState =ERROR_STATE();
	RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
END CATCH
SET NOCOUNT OFF
