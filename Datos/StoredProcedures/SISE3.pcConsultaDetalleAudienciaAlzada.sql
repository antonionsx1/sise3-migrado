-- ==========================================================================================
-- Author:		Martin Tovar
-- Create date: 26/12/2024
-- Description:	SP [SISE3].[pcConsultaDetalleAudienciaAlzada] apartir del sp [dbo].[TAU_pcAudiencia], para proceso de Audiencias de Alzada.
-- Ejemplo de ejecución: exec [SISE3].[pcConsultaDetalleAudienciaAlzada] 1512, 20678121, NULL, NULL

-- ==========================================================================================
CREATE  PROCEDURE [SISE3].[pcConsultaDetalleAudienciaAlzada]
(	@pi_CatOrganismoId INT
	,@fasuntoneunid BIGINT
	,@pi_FechaInicial DATETIME = NULL,
	@pi_FechaFinal DATETIME = NULL)
AS 
BEGIN 

DECLARE 
@ErrorMessage NVARCHAR(4000),
@ErrorSeverity INT,
@ErrorState INT

SET NOCOUNT ON
BEGIN TRY 

SELECT 
	iga.fkIdAsuntoNeun
	,iga.idInformacionGeneralAudiencia
	,iga.AsuntoAlias
	,iga.idAudiencia
	,iga.fkIdTipoAudiencia
	,iga.sDescripcionAudiencia
	,iga.fechaInicio
	,iga.fechaFin
	,ISNULL(CASE WHEN GETDATE() <= iga.fechaFin THEN 1 ELSE 0 END,0)	AS bEnTiempo
	,iga.idSala
	,sala.descripcionSala
	,iga.bEsPrivada
	,iga.idEstatusAudiencia
	,CASE WHEN iga.idEstatusAudiencia = 5 AND iga.BDIFERIDA = 1 THEN 'Diferida' ELSE ea.descripcionEstatusAudiencia END		AS descripcionEstatusAudiencia 
	,CASE WHEN iga.bEsPrivada = 1 THEN 'Si' WHEN iga.bEsPrivada = 0 THEN 'No' END	AS EsPrivada
	,CONCAT(ce.Nombre, ' ', ce.ApellidoPaterno, ' ', ce.ApellidoMaterno) Capturo
	,(SELECT count(*) FROM TAU_REL_ResolucionesAudiencia rr WITH (NOLOCK) WHERE rr.fkIdInformacionGeneralAudiencia = iga.idInformacionGeneralAudiencia AND rr.iStatusReg=1)	AS ResolucionAudiencia
	,iga.BDIFERIDA
FROM InformacionGeneralAudiencia AS iga WITH (NOLOCK)
INNER JOIN CatEmpleados ce WITH (NOLOCK)
    ON iga.idUsuarioAlta = ce.EmpleadoId
INNER JOIN CatSalas sala WITH (NOLOCK)
    ON sala.idSala = iga.idSala
INNER JOIN CatEstatusAudiencia ea WITH (NOLOCK)
    ON ea.idEstatusAudiencia = iga.idEstatusAudiencia
WHERE iga.fkIdTipoAudiencia in (236, 267)
	AND iga.fkCatOrganismoId = @pi_CatOrganismoId
	AND iga.fkIdAsuntoNeun = @fasuntoneunid
    AND (
        (@pi_FechaInicial IS NULL OR iga.fechaInicio >= @pi_FechaInicial)
        AND (@pi_FechaFinal IS NULL OR iga.fechaFin <= @pi_FechaFinal)
    )
ORDER BY iga.idAudiencia

END TRY
BEGIN CATCH
	ROLLBACK TRAN TAUpaCambioJuez
	SELECT 
		@ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),                 
        @ErrorState =ERROR_STATE();

	RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
END CATCH

END
