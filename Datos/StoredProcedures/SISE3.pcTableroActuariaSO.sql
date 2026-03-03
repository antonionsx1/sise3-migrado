SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Efrén Peña MS
-- Alter date:  19/12/2023
-- ALTER DATE: 04/06/2024 - JSM Se agrega WITH(NOLOCK), que filtre por órgano y value status 1
-- Description: consulta para tablero de Actuaría 
-- Basado en:   [SISE3].[pcTableroTramites] 
-- [SISE3].[pcTableroActuaria] 180, 1000,1, null,'2024-01-01','2024-03-16',null, null, '', null, 0 ,null,null
-- Modificación: LAGS, 18.03.2025, Se agrega consulta para campo Promovente para tomarse en cuenta en el # de Notificaciones.
-- Modificación: LAGS, 26.03.2025, se agrega llamado diferente a la tabla Promociones para que no repita registros.
-- Modificación ARS: 26.03.2025, se agregó el tipo de notificación interconexión AJ 
-- Modificación: SBGE 07/04/2025 se recupera la fecha del acuerdo de la tabla AsuntosDocumentos, esta fecha es la misma en FechaAuto de tablas SintesisAcuerdoAsunto y DeterminacionesJudiciales
-- Modificación: SBGE 10/04/2025 En el tablero solo deben mostrarse los acuerdos autorizados  CatAutorizacionDocumentosId=3
-- Modificación Fanny Lemus 07/05/2025, se cambia la l+ogica de cómo se obtiene la columna TieneArchivo para que concuerde con [SISE3].[pcTableroActuaria] ya que falla el contador de ConAcuse
-- Modificación AGA: 19/05/2025, Se modifico una consulta nep.StatusReg = 1 por nep.StatusReg IN(1,2)
-- Modificación ARS: Se agregó la columna OrigenPromoción para el órgano origen
-- Modificación JRE: 12/06/2025, Se actualiza la columna por la cual ordena los registros para retorno de nombre organo origen de asuntos juridicos tarea 23691

-- exec [SISE3].[pcTableroActuariaSO] 1494,'2025-03-09','2025-04-07'
-- =============================================

ALTER   PROCEDURE [SISE3].[pcTableroActuariaSO] 

	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaAutorizacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaAutorizacionFin DATE = NULL
AS
BEGIN

	DECLARE @FechaIniciaOperaciones DATE 

IF(@pi_FechaAutorizacionIni IS NULL AND @pi_FechaAutorizacionFin IS NULL)
	BEGIN
		SELECT @FechaIniciaOperaciones = FechaAlta 
		FROM  SISE3.ConfiguracionOrganismo
		WHERE CatOrganismoId = @pi_CatOrganismoId

		SET @FechaIniciaOperaciones = ISNULL(@FechaIniciaOperaciones,GETDATE())

		SET @pi_FechaAutorizacionIni = ISNULL(@pi_FechaAutorizacionIni,@FechaIniciaOperaciones)
		SET @pi_FechaAutorizacionFin = ISNULL(@pi_FechaAutorizacionFin,GETDATE())

	END
        
-- Tabla temporal con datos de Notificaciones electronicas personas desde asuntos documentos
		/*SELECT nep.PersonaId as Parte*/
		SELECT /*nep.PersonaId as Parte*/
			case when isnull(nep.PromoventeId,0)> 0 then  nep.PromoventeId
			else nep.PersonaId
			end as Parte
		,ad.AsuntoNeunId
		,ad.AsuntoId
		,ad.SintesisOrden
		/*,pas.Nombre
		,pas.APaterno
		,pas.AMaterno*/
		,case when isnull(nep.PromoventeId,0)>0 then 
			(Select isnull(Nombre,'') FROM Promovente prom  with(nolock)  WHERE prom.PromoventeId=nep.PromoventeId and prom.Estatus = 1)
			else
			(Select isnull(Nombre,'') FROM PersonasAsunto prom  with(nolock) WHERE prom.PersonaId=nep.PersonaId and prom.statusreg = 1)
			end as Nombre
		,case when isnull(nep.PromoventeId,0)>0 then 
			(Select isnull(APaterno,'') FROM Promovente prom  with(nolock)  WHERE prom.PromoventeId=nep.PromoventeId and prom.Estatus = 1)
			else
			(Select isnull(APaterno,'') FROM PersonasAsunto prom  with(nolock) WHERE prom.PersonaId=nep.PersonaId and prom.statusreg = 1)
			end as APaterno
		,case when isnull(nep.PromoventeId,0)>0 then 
			(Select isnull(AMaterno,'') FROM Promovente prom  with(nolock) WHERE prom.PromoventeId=nep.PromoventeId and prom.Estatus = 1 )
			else
			(Select isnull(AMaterno,'') FROM PersonasAsunto prom  with(nolock) WHERE prom.PersonaId=nep.PersonaId and prom.statusreg = 1)
			end as AMaterno
		,nep.FechaNotificacion
		--,IIF(nea.NombreArchivo is null,0,1) AS TieneArchivo
		, CASE WHEN (SELECT TOP 1 ISNULL(an.tipoAcuseId, 1) FROM NotificacionElectronica_Archivos nea  
					LEFT JOIN SISE3.Mov_AcuseNotificacion an ON nea.ArchivoId = an.fkArchivoId AND an.iEstatusReg = 1 WHERE nep.NotElecId = nea.NotElecId AND nea.StatusReg = 1) 
					IN (5726, 5231, 5732) THEN 0 ELSE 1 END AS TieneArchivo 	-- (5726, 5231, 5732) Citatorios, Edicto e Instructivo
		--,CASE 
		--	WHEN (
		--		 SELECT TOP 1 an.tipoAcuseId
		--		 FROM NotificacionElectronica_Archivos nea  
		--		 LEFT JOIN SISE3.Mov_AcuseNotificacion an ON nea.ArchivoId = an.fkArchivoId 
		--		 AND an.iEstatusReg = 1 		
		--		 WHERE nep.NotElecId = nea.NotElecId
		--		 AND nea.StatusReg = 1
		--		 ) IS NOT NULL THEN 0 ELSE 1
		--END AS TieneArchivo -- SE CAMBIA POR LÓGICA DE ARRIBA PARA QUE NO IGNORE LOS NULL EN LOS CONTADORES
		,nep.ActuarioId
		,ada.SintesisIA
		INTO #TMP_TABLE
		FROM ASUNTOS A WITH(NOLOCK)
		    INNER JOIN  AsuntosDocumentos ad WITH(NOLOCK) ON A.AsuntoNeunId = ad.AsuntoNeunId  
			INNER JOIN NotificacionElectronica_Personas nep WITH(NOLOCK) ON ad.AsuntoID=nep.AsuntoId AND ad.AsuntoNeunId=nep.AsuntoNeunId AND  ad.SintesisOrden = nep.SintesisOrden
			LEFT JOIN SISE3.AsuntosDocumentosAdicional ada WITH(NOLOCK) ON A.AsuntoNeunId = ada.AsuntoNeunId AND ad.AsuntoDocumentoId = ada.AsuntoDocumentoId
			--INNER JOIN SintesisAcuerdoAsunto saa WITH(NOLOCK) ON saa.AsuntoNeunId=nep.AsuntoNeunId AND saa.SintesisOrden = nep.SintesisOrden-- SBGE 07/04/2025 para obtener fecha de auto (fecha acuerdo)
			/*INNER join PersonasAsunto  pas WITH(NOLOCK) ON  ad.AsuntoId = pas.AsuntoId and ad.AsuntoNeunId = pas.AsuntoNeunId AND nep.PersonaId = pas.PersonaId
			LEFT JOIN NotificacionElectronica_Archivos nea WITH(NOLOCK) ON nep.NotElecId = nea.NotElecId and nea.StatusReg =1*/
		WHERE 
			ad.StatusReg=1 AND nep.StatusReg IN(1,2) --AGA
			--AND saa.StatusReg=1
			--and pas.StatusReg=1  
			AND A.StatusReg=1
			and A.CatOrganismoId = @pi_CatOrganismoId
			AND ad.CatAutorizacionDocumentosId =3 --SBGE 10/04/2025 Solo se requieren visualizar los acuerdos autorizados
            --AND ad.CatAutorizacionDocumentosId NOT IN (4,8,9)
			----AND CONVERT(Date,ad.fechaAutoriza) <=@pi_FechaAutorizacionFin 
			----AND CONVERT(Date,ad.fechaAutoriza) >=@pi_FechaAutorizacionIni
			AND CONVERT(Date,ad.fechaAlta) <=@pi_FechaAutorizacionFin ------------SBGE 07/04/2025 Task 23093 Solicitan que la busqueda sea por fecha del acuerdo, también se puede usar FechaAuto de tablas SintesisAcuerdoAsuntos y DeterminacionesJudiciales 
			AND CONVERT(Date,ad.fechaAlta) >=@pi_FechaAutorizacionIni ------------SBGE 07/04/2025 Task 23093 Solicitan que la busqueda sea por fecha del acuerdo
--			AND (ISNULL(@pi_AsuntoNeunId,1) = iif(@pi_AsuntoNeunId is not null, ad.AsuntoNeunId,1))
		AND nep.TipoNotificacion IN (1, 3, 5, 6, 11, 12, 14 ) 

		SELECT 
		COUNT(Parte) AS COUNTNotificadas
		,AsuntoNeunId
		,AsuntoId
		,SintesisOrden
		into #TempPersonasNotificadas
		FROM #TMP_TABLE
		WHERE FechaNotificacion IS NOT NULL
		GROUP BY AsuntoNeunId,AsuntoId,SintesisOrden

		SELECT COUNT(Parte) AS COUNTPARTE,
		 SUM(IIF(TieneArchivo=0 OR FechaNotificacion is null,0,1)) AS ConAcuse,
		 --CASE FechaNotificacion is null then 0 else 1 END)
        Asignados = SUM(IIF(ActuarioId is null or ActuarioId =10273, 0, 1)),
		AsuntoNeunId
		,AsuntoId
		,SintesisOrden
		,STRING_AGG(convert(nvarchar(MAX), concat(Nombre,' ', APaterno,' ',AMaterno) ), ', ') AS Nombres
		into #TempCantNotificaciones
		FROM #TMP_TABLE
		group by 
		 AsuntoNeunId
		,AsuntoId
		,SintesisOrden

		SELECT 	a.AsuntoAlias As No_Exp
                ,a.CatTipoAsuntoId as CatTipoAsuntoId
				,cto.Descripcion As TipoAsuntoDescripcion
				,ad.NombreArchivo+ ad.ExtensionDocumento as NombreArchivo
				,ISNULL(CONVERT(VARCHAR(10),ad.FechaAlta,103),'') as FechaAuto_F
				,FechaAutoriza = ad.FechaAutoriza
				,DATEDIFF(DD,ad.FechaAutoriza, GETDATE()) AS Transcurrido
				, ISNULL(tmpCN.COUNTPARTE,0) AS Notificados   -- Deberia ser por notificar
				,ISNULL(ConAcuse,0) AS ConAcuse
				--,CONVERT(VARCHAR(50), 'Pendiente') as Estado
--				,IIF(COUNTPARTE=ConAcuse,'Notificados','Pendiente') as Estado
                ,CASE 
					WHEN ISNULL(tmpCN.Asignados,0) < ISNULL(tmpCN.COUNTPARTE,0) THEN 'Sin asignar' 
					WHEN ISNULL(tmpCN.Asignados,0) = ISNULL(((SELECT COUNT(TP1.COUNTNotificadas) FROM #TempPersonasNotificadas TP1 WHERE TP1.AsuntoNeunId = ad.AsuntoNeunId AND TP1.SintesisOrden = ad.SintesisOrden)),0) THEN 
					CASE 
						WHEN ISNULL(ConAcuse, 0) = 0 THEN 'Notificados'
						ELSE 'Pendiente'
					END
                    ELSE 'Pendiente'
				 END as Estado
--				,IIF(ISNULL(tmpCN.COUNTPARTE,0)=ISNULL(ConAcuse,0),'Notificados','Pendiente') as Estado
				,IIF(sa.StatusReg=1, sa.Sintesis, '') as Sintesis
				,a.AsuntoNeunId
				,ad.TipoCuaderno
                ,dbo.funRecuperaCatalogoDependienteDescripcion(527, ad.TipoCuaderno) as TipoCuadernoDesc
                --,p.Secretario as SecretarioPId
				, (SELECT TOP 1 p.Secretario FROM Promociones p with(nolock) where p.AsuntoNeunId = ad.AsuntoNeunId AND p.AsuntoId = ad.AsuntoId AND p.SintesisOrden = ad.SintesisOrden and p.StatusReg =1) as SecretarioPId
				,sa.UsuarioCaptura
				,ad.asuntoDocumentoId
				,sa.SintesisOrden
				,tmpCN.Nombres AS NombresPartes
				,(select CatalogoElementoDescripcion from CatalogosElementosDescripcion with(nolock) where CatalogoElementoDescripcionID = ad.CatContenidoId) as Contenido
--				,(select CatalogoPromocionDescripcion from CatPromocion with(nolock) where CatalogoPromocionId = ad.CatContenidoId) as Contenido
				,ad.CatContenidoId As ContenidoId
				,a.NumeroAlias
--				,Isnull(tmpac.CountActuarios,0) as CountActuarios
                ,ISNULL(tmpCN.Asignados,0) as Asignados
				,a.TipoProcedimiento as TipoProcedimiento
				,sa.FechaAuto
				,ada.SintesisIA
				,ISNULL((select  TOP 1 CO.NombreOficial
                       from AsuntosRelacionados AR WITH(NOLOCK)
                       INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
                       INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
                       WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = ad.AsuntoNeunId ORDER BY AR.IdAsuntoRela DESC),'') as OrigenPromocion
		INTO #TempActuaria 
		FROM 
		 AsuntosDocumentos ad WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		INNER JOIN CatOrganismos ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId
		INNER JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN CatPlantillas cp WITH (NOLOCK) ON cp.CatPlantillaId = ad.CatPlantillaId  and cp.StatusReg =1
		LEFT JOIN tbx_CatTiposAsunto ta WITH (NOLOCK) ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId AND ad.TipoCuaderno = ta.CuadernoId and ta.Status =1
		LEFT JOIN SintesisAcuerdoAsunto sa  WITH(NOLOCK) on sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden and sa.StatusReg =1 --- Se relaciona para obtener la fecha de captura 
		LEFT JOIN #TempCantNotificaciones tmpCN WITH(NOLOCK) ON tmpCN.AsuntoNeunId=	 ad.AsuntoNeunId AND tmpCN.AsuntoId=ad.AsuntoId AND tmpCN.SintesisOrden=ad.SintesisOrden
		LEFT JOIN SISE3.AsuntosDocumentosAdicional ada WITH(NOLOCK) ON A.AsuntoNeunId = ada.AsuntoNeunId AND ad.AsuntoDocumentoId = ada.AsuntoDocumentoId
--		--LEFT JOIN #TMP_Actuario tmpAc ON tmpAc.AsuntoNeunId=ad.AsuntoNeunId AND tmpAc.AsuntoId=ad.AsuntoId AND tmpAc.SintesisOrden=ad.SintesisOrden
		--LEFT JOIN Promociones p WITH(NOLOCK) ON p.AsuntoNeunId = ad.AsuntoNeunId AND p.AsuntoId = ad.AsuntoId AND p.SintesisOrden = ad.SintesisOrden and p.StatusReg =1
        WHERE 
		ad.StatusReg=1 and ct.StatusReg =1 and cto.StatusReg =1
		AND ad.CatAutorizacionDocumentosId =3 --SBGE 10/04/2025 Solo se requieren visualizar los acuerdos autorizados
        --AND ad.CatAutorizacionDocumentosId NOT IN (4,8,9)
        AND a.CatOrganismoId = @pi_CatOrganismoId
		AND  CONVERT(Date,ad.FechaAlta) <=@pi_FechaAutorizacionFin AND CONVERT(Date,ad.FechaAlta) >=@pi_FechaAutorizacionIni 
		-----AND  CONVERT(Date,ad.fechaAutoriza) <=@pi_FechaAutorizacionFin AND CONVERT(Date,ad.fechaAutoriza) >=@pi_FechaAutorizacionIni 
--		AND (ISNULL(@pi_AsuntoNeunId,1) = iif(@pi_AsuntoNeunId is not null, ad.AsuntoNeunId,1))


		 SELECT *
		 FROM #TempActuaria
		 
			drop table #TMP_TABLE
			drop table #TempCantNotificaciones
			drop table #TempActuaria
			drop table #TempPersonasNotificadas
--			drop table #TMP_Actuario

END;
