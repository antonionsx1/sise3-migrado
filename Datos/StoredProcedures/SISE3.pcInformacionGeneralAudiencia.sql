-- =============================================
-- Author:  Martin Tovar
-- Creation date: 28/11/2024 - MTS creación SP por integración de campo ID Organismo.
-- Description: Obtiene los datos de información general de Audiencia/Alzada 
-- Basado en: dbo.usp_InformacionGeneralAudiencia
-- EXEC [SISE3].[pcInformacionGeneralAudiencia] 4328, 30327134, 1

CREATE PROCEDURE SISE3.pcInformacionGeneralAudiencia
  @pi_CatOrganismoId INT,
  @pi_fkIdAsuntoNeun  BIGINT,
  @piEsAlzada INT=NULL
AS

SET NOCOUNT ON;
DECLARE
	@ErrorMessage NVARCHAR(4000),
	@ErrorSeverity INT,
	@ErrorState INT,
	@fechaZh DATETIME
BEGIN TRY			
	EXEC @fechaZh = fnObtenFechaTZ @idOrganismo = @pi_CatOrganismoId;

	IF(@piEsAlzada=1)
	BEGIN
		SELECT a.idInformacionGeneralAudiencia
			 , a.idSala 
			 , a.fkIdAsuntoNeun
			 , a.idAudiencia 
			 , b.descripcionEstatusAudiencia 
			 , a.sDescripcionAudiencia
			 , ISNULL(a.fechaInicioCelebrada, a.fechaInicio) AS 'fechaInicio'
			 , ISNULL(a.fechaFinCelebrada,a.fechaFin) AS 'fechaFin'
			 , a.respuestaOtis
			 , CASE a.bEsPrivada WHEN 0 THEN 'No' WHEN 1 THEN 'Si' ELSE 'No' END AS 'EsPrivada'
			 , CASE WHEN a.idAgendaSIGJP > 0 THEN 'Si' ELSE 'No' END AS 'EnvioSIGJP'
			 , ISNULL(a.idAgendaSIGJP,0) AS 'idAgendaSIGJP'
			 , 'No' AS 'AudienciaOculta'
			 , (SELECT count(*) FROM VideosGeneradosAudiencia z WITH (NOLOCK) WHERE z.fkIdAsuntoNeun=a.fkIdAsuntoNeun AND z.idAudiencia=a.idAudiencia AND z.activo=1) AS 'VideosAudiencia'
			 , (SELECT count(*) FROM PersonasAudienciaOtis y WITH (NOLOCK) WHERE y.fkIdAsuntoNeun=a.fkIdAsuntoNeun AND y.idAudiencia=a.idAudiencia AND y.activo=1) AS 'AsistentesAudiencia'
			 , (SELECT count(*) FROM IndicesVideoAudiencia x WITH (NOLOCK) WHERE x.fkIdAsuntoNeun=a.fkIdAsuntoNeun AND x.idAudiencia=a.idAudiencia AND x.activo=1) AS 'IndicesVideoAudiencia'
			 , CASE WHEN a.fechaFin < getdate() THEN 1 ELSE 0 END  AS 'DescargaInformacion'
			 , ISNULL(a.idAgendaSIGJP,0) AS 'idAgendaSIGJP'
			 , a.fkIdTipoAudiencia
			 , a.bEsPrivada
			 , a.bDiferida
			 , CASE a.idUsuarioAlta WHEN 0 THEN 'OralTis' ELSE ISNULL((SELECT ISNULL(Nombre,'')+' '+ ISNULL(ApellidoPaterno,'')+' '+ ISNULL(ApellidoMaterno,'') FROM CatEmpleados WITH (NOLOCK) WHERE EmpleadoId=a.idUsuarioAlta),'Sin información') END AS 'Usuario'
			 , a.fechaModificacion
			 , @fechaZh AS 'FechaZh'
			 , a.idJuez
			 , CASE a.idJuez WHEN 0 THEN '' ELSE ISNULL((SELECT ISNULL(Nombre,'') + ' '+ ISNULL(ApellidoPaterno,'') + ' '+ ISNULL(ApellidoMaterno,'') FROM CatEmpleados WHERE EmpleadoId=a.idJuez),'') END AS 'NombreJuez'
			 , cSala.fiIdTipoSala
			 , '' as XmlAcuseGraficas
			 , a.fechaInicio AS 'fechaInicioS'
			 , a.fechaFin AS 'fechaFinS'
			 , a.fechaInicioCelebrada AS 'fechaInicioC'
			 , a.fechaFinCelebrada AS 'fechaFinC'
			 , (SELECT count(*) FROM TAU_REL_ResolucionesAudiencia rr WHERE rr.fkIdInformacionGeneralAudiencia=a.idInformacionGeneralAudiencia AND rr.iStatusReg=1) AS 'resolucionAudienciaFinal'
			 , a.idEstatusAudiencia
			 , ISNULL((SELECT rtipo.iCambioJuez FROM TAU_Rel_TipoAudienciaDuracion rtipo WHERE rtipo.fkIdTipoAudiencia=a.fkIdTipoAudiencia),0) AS 'iCambioJuez'
			 , (SELECT CASE WHEN EXISTS(SELECT * FROM TAU_Rel_ElementoAudiencia x WITH (NOLOCK) WHERE x.IdInformacionGeneralAudiencia=a.idInformacionGeneralAudiencia AND x.fkIdTipoElemento=1 AND x.iEstatus=1) THEN 1 ELSE 0 END ) as 'EsVideoConferencia'---SBGE 30/06/2023
			 , iad.iAudienciaEfectiva AS 'EsAudienciaEfectiva'
			 , aux.kIdOrganoAuxilio AS 'IdOrganoAuxilio'
		FROM InformacionGeneralAudiencia a WITH (NOLOCK)
		INNER JOIN ALZ_REL_InformacionGeneralAudiencia alz WITH (NOLOCK) 
		ON a.idInformacionGeneralAudiencia=alz.idInformacionGeneralAudiencia 
			AND a.fkIdAsuntoNeun=alz.fkIdAsuntoNeun
			AND a.fkCatOrganismoId=alz.idOrganismoOrigen
			AND a.idAudiencia = alz.idAudiencia
		INNER JOIN CatEstatusAudiencia b WITH (NOLOCK) 
		ON b.idEstatusAudiencia=a.idEstatusAudiencia		 
		INNER JOIN CatSalas cSala WITH (NOLOCK) 
		ON cSala.iNumeroSala=a.idSala
			AND cSala.idOrganismo=alz.idOrganismoSeAgenda
		LEFT JOIN InformacionAudienciaDetalle iad WITH (NOLOCK)
		ON a.idInformacionGeneralAudiencia = iad.idInformacionGeneralAudiencia
			AND iad.bEstatus = 1
		LEFT JOIN TAU_REL_AudienciaAuxilio aux
		ON a.idInformacionGeneralAudiencia = aux.fkIdInformacionGeneralAudiencia
			AND aux.iEstatus = 1
		WHERE fkCatOrganismoId = @pi_CatOrganismoId
			AND a.fkIdAsuntoNeun=@pi_fkIdAsuntoNeun
			AND cSala.idEstatus = 1
		GROUP BY a.idInformacionGeneralAudiencia
			 , a.idSala
			 , a.fkIdAsuntoNeun
			 , a.idAudiencia
			 , b.descripcionEstatusAudiencia
			 , a.sDescripcionAudiencia
			 , a.fechaInicioCelebrada
			 , a.fechaInicio
			 , a.fechaFinCelebrada
			 , a.fechaFin
			 , a.respuestaOtis
			 , a.bEsPrivada
			 , a.bDiferida
			 , a.idAgendaSIGJP
			 , a.fkIdTipoAudiencia
			 , a.bEsPrivada
			 , a.idUsuarioAlta
			 , a.fechaModificacion
			 , a.idJuez
			 , cSala.fiIdTipoSala
			 , a.idEstatusAudiencia
			 , iad.iAudienciaEfectiva
			 , aux.kIdOrganoAuxilio
		ORDER BY a.idAudiencia ASC
	END
	ELSE 
	BEGIN
		 SELECT a.idInformacionGeneralAudiencia 
			 , a.idSala 
			 , a.fkIdAsuntoNeun 
			 , a.idAudiencia 
			 , b.descripcionEstatusAudiencia 
			 , a.sDescripcionAudiencia 
			 , ISNULL(a.fechaInicioCelebrada, a.fechaInicio) AS 'fechaInicio'
			 , ISNULL(a.fechaFinCelebrada,a.fechaFin) AS 'fechaFin'
			 , a.respuestaOtis
			 , CASE a.bEsPrivada WHEN 0 THEN 'No' WHEN 1 THEN 'Si' ELSE 'No' END AS 'EsPrivada'
			 , CASE WHEN a.idAgendaSIGJP > 0 THEN 'Si' ELSE 'No' END AS 'EnvioSIGJP'
			 , ISNULL(a.idAgendaSIGJP,0) AS 'idAgendaSIGJP'
			 , 'No' AS 'AudienciaOculta'
			 , (SELECT count(*) FROM VideosGeneradosAudiencia z WITH (NOLOCK) WHERE z.fkIdAsuntoNeun=a.fkIdAsuntoNeun AND z.idAudiencia=a.idAudiencia AND z.activo=1) AS 'VideosAudiencia'
			 , (SELECT count(*) FROM PersonasAudienciaOtis y WITH (NOLOCK) WHERE y.fkIdAsuntoNeun=a.fkIdAsuntoNeun AND y.idAudiencia=a.idAudiencia AND y.activo=1) AS 'AsistentesAudiencia'
			 , (SELECT count(*) FROM IndicesVideoAudiencia x WITH (NOLOCK) WHERE x.fkIdAsuntoNeun=a.fkIdAsuntoNeun AND x.idAudiencia=a.idAudiencia AND x.activo=1) AS 'IndicesVideoAudiencia'
			 , CASE WHEN a.fechaFin < getdate() THEN 1 ELSE 0 END  AS 'DescargaInformacion'
			 , ISNULL(a.idAgendaSIGJP,0) AS 'idAgendaSIGJP'
			 , a.fkIdTipoAudiencia
			 , a.bEsPrivada
			 , a.bDiferida
			 , CASE a.idUsuarioAlta WHEN 0 THEN 'OralTis' ELSE ISNULL((SELECT ISNULL(Nombre,'')+' '+ ISNULL(ApellidoPaterno,'')+' '+ ISNULL(ApellidoMaterno,'') FROM CatEmpleados WITH (NOLOCK) WHERE EmpleadoId=a.idUsuarioAlta),'Sin información') END AS 'Usuario'
			 , a.fechaModificacion
			 , @fechaZh AS 'FechaZh'
			 , a.idJuez
			 , CASE a.idJuez WHEN 0 THEN '' ELSE ISNULL((SELECT ISNULL(Nombre,'') + ' '+ ISNULL(ApellidoPaterno,'') + ' '+ ISNULL(ApellidoMaterno,'') FROM CatEmpleados WHERE EmpleadoId=a.idJuez),'') END AS 'NombreJuez'
			 , cSala.fiIdTipoSala
			 , ISNULL(a.xmlPromedios,'') as XmlAcuseGraficas
			 , a.fechaInicio AS 'fechaInicioS'
			 , a.fechaFin AS 'fechaFinS'
			 , a.fechaInicioCelebrada AS 'fechaInicioC'
			 , a.fechaFinCelebrada AS 'fechaFinC'
			 , (SELECT count(*) FROM TAU_REL_ResolucionesAudiencia rr WHERE rr.fkIdInformacionGeneralAudiencia=a.idInformacionGeneralAudiencia AND rr.iStatusReg=1) AS 'resolucionAudienciaFinal'
			 , a.idEstatusAudiencia
			 , ISNULL((SELECT rtipo.iCambioJuez FROM TAU_Rel_TipoAudienciaDuracion rtipo WHERE rtipo.fkIdTipoAudiencia=a.fkIdTipoAudiencia),0) AS 'iCambioJuez'
			 , (SELECT CASE WHEN EXISTS(SELECT * FROM TAU_Rel_ElementoAudiencia x WITH (NOLOCK) where x.IdInformacionGeneralAudiencia=a.idInformacionGeneralAudiencia AND x.fkIdTipoElemento=1 AND x.iEstatus=1) THEN 1 ELSE 0 END ) as 'EsVideoConferencia'
			 , (SELECT  x.sElemento FROM TAU_Rel_ElementoAudiencia x WITH (NOLOCK) where x.IdInformacionGeneralAudiencia=a.idInformacionGeneralAudiencia AND x.fkIdTipoElemento=1 AND x.iEstatus=1) as 'FolioVideoConferencia'
			 , iad.iAudienciaEfectiva AS 'EsAudienciaEfectiva'
			 , aux.kIdOrganoAuxilio AS 'IdOrganoAuxilio'
		FROM InformacionGeneralAudiencia a WITH (NOLOCK) 
		INNER JOIN CatEstatusAudiencia b WITH (NOLOCK)
		ON b.idEstatusAudiencia=a.idEstatusAudiencia
		INNER JOIN CatSalas cSala WITH (NOLOCK)
		ON cSala.iNumeroSala=a.idSala AND cSala.idOrganismo=a.fkCatOrganismoId
		LEFT JOIN InformacionAudienciaDetalle iad WITH (NOLOCK)
		ON a.idInformacionGeneralAudiencia = iad.idInformacionGeneralAudiencia
			AND iad.bEstatus = 1
		LEFT JOIN TAU_REL_AudienciaAuxilio aux
		ON a.idInformacionGeneralAudiencia = aux.fkIdInformacionGeneralAudiencia
			AND aux.iEstatus = 1
		WHERE fkCatOrganismoId = @pi_CatOrganismoId
			AND a.fkIdAsuntoNeun=@pi_fkIdAsuntoNeun 
		ORDER BY a.idAudiencia ASC		 
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
