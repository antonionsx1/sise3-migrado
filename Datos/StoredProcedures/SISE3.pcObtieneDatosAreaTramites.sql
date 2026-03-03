--Nuevo
-- =============================================
-- Author:  Martin Tovar
-- Alter date:  19/12/2024 - MTS Optimización en SP.
-- Description: Obtiene los datos para el dashboard Trámites 
-- Basado en:   SISE3.pcTableroTramites
-- EXEC [SISE3].[pcObtieneDatosAreaTramites]  147, '2024-06-07','2024-06-07'

-- =============================================

ALTER procedure [SISE3].[pcObtieneDatosAreaTramites]
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionIni DATE,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATE	

AS
BEGIN
		
		DECLARE @Tramites SISE3.Tramites_type
	
		--Cambios por SISE3.SP pcObtieneDatosAreaTramites
		DECLARE @FechaActual DATE
		DECLARE @MesesProcesarTipoAsunto INT
		DECLARE @MesesProcesarTiempoRevision INT
		DECLARE @PrimerDiaAnioActual DATETIME
		DECLARE @UltimoDiaAnioAnterior DATETIME
		DECLARE @PrimerDiaMesesProcesarTipoAsunto DATETIME
		DECLARE @UltimoDiaMesesProcesarTipoAsunto DATETIME
		DECLARE @PrimerDiaMesesProcesarTiempoRevision DATETIME
		DECLARE @UltimoDiaMesesProcesarTiempoRevision DATETIME
		DECLARE @pi_FechaPresentacionIni_Origen DATE

		SET @FechaActual = @pi_FechaPresentacionFin
		SET @MesesProcesarTipoAsunto = 11
		SET @MesesProcesarTiempoRevision = 12
		SET @PrimerDiaAnioActual = CONVERT(varchar,dateadd(year,datediff(year,0,@pi_FechaPresentacionFin)-0,0),23)
		SET	@PrimerDiaMesesProcesarTipoAsunto = CONVERT(varchar, DATEADD(MONTH, DATEDIFF(MONTH, 0, @pi_FechaPresentacionFin) - @MesesProcesarTipoAsunto, 0),23)                                                                
		SET	@UltimoDiaMesesProcesarTipoAsunto = CONVERT(DATETIME, CONVERT(varchar(11),DATEADD(MONTH, DATEDIFF(MONTH, -1, @pi_FechaPresentacionFin) -0, -1), 20) + ' 23:59:59')
		SET	@PrimerDiaMesesProcesarTiempoRevision = CONVERT(varchar, DATEADD(MONTH, DATEDIFF(MONTH, -1, @pi_FechaPresentacionFin) - @MesesProcesarTiempoRevision, 0), 23)
		SET	@UltimoDiaMesesProcesarTiempoRevision = CONVERT(DATETIME, CONVERT(varchar(11),DATEADD(MONTH, DATEDIFF(MONTH, -1, @pi_FechaPresentacionFin) -0, -1), 20) + ' 23:59:59')

		SET @pi_FechaPresentacionIni_Origen = @pi_FechaPresentacionIni
		SET @pi_FechaPresentacionIni = @PrimerDiaMesesProcesarTipoAsunto	
		
		--Agregar campos adicionales
		SELECT *
		INTO #Tramites
		FROM @Tramites
		
		ALTER TABLE #Tramites
		ADD FechaAlta_Promocion					DATETIME		NULL
		
		ALTER TABLE #Tramites
		ADD FechaActualiza_Promocion			DATETIME		NULL	

		ALTER TABLE #Tramites
		ADD FechaAutoriza_AsuntosDocumentos		DATETIME		NULL	

		ALTER TABLE #Tramites
		ADD FechaPreAutoriza_AsuntosDocumentos	DATETIME		NULL

		ALTER TABLE #Tramites
		ADD FechaAlta_SintesisAcuerdos			DATETIME		NULL

		ALTER TABLE #Tramites
		ADD FechaActualizacion_SintesisAcuerdos	DATETIME		NULL


			SELECT 
				p.AsuntoNeunId,
				p.ClasePromocion,
				p.ClasePromovente,
				p.EstadoPromocion,
				p.FechaPresentacion,
				p.HoraPresentacion,
				p.Mesa,
				p.NumeroOrden,
				p.NumeroRegistro,
				p.OrigenPromocion,
				p.Secretario,
				p.TipoContenido,
				p.TipoCuaderno,
				p.TipoPromovente,
				p.YearPromocion,
				p.AsuntoDocumentoId,
				p.StatusReg,
				a.AsuntoAlias,
				a.CatTipoAsuntoId,
				a.NumeroAlias,
				a.TipoProcedimiento,
				a.CatOrganismoId,
				a.AsuntoId,
				a.CatTipoAsunto,
				ad.SintesisOrden,
				ad.FechaAlta,
				ad.CatContenidoId,
				ad.CreadorId,
				ad.CatAutorizacionDocumentosId,
				ad.EmpleadoIdCancela,
				ad.EmpleadoIdAutoriza,
				ad.EmpleadoIdPreautoriza,
				ad.FechaAutoriza,
				ad.FechaPreAutoriza,
				ad.FechaCancela
				--
				,p.FechaAlta						AS FechaAlta_Promocion
				,p.FechaActualiza					AS FechaActualiza_Promocion
				,ad.FechaAutoriza					AS FechaAutoriza_AsuntosDocumentos
				,ad.FechaPreAutoriza				AS FechaPreAutoriza_AsuntosDocumentos
			INTO #Promociones
			FROM Promociones p WITH(NOLOCK)
			CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
			LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) on p.AsuntoNeunId = ad.AsuntoNeunId and ad.AsuntoDocumentoId=p.AsuntoDocumentoId AND p.AsuntoId = ad.AsuntoID AND p.StatusReg=ad.StatusReg
			WHERE p.StatusReg=1
			AND p.CatOrganismoId=@pi_CatOrganismoId
			AND (
		        (p.FechaPresentacion >= @pi_FechaPresentacionIni AND p.FechaPresentacion < DATEADD(DAY, 1, @pi_FechaPresentacionFin)) 
		        OR 
		        (ad.FechaAlta >= @pi_FechaPresentacionIni AND ad.FechaAlta < DATEADD(DAY, 1, @pi_FechaPresentacionFin))
			)
		;					
			

		/* SE EJECUTA EL PRIMER SP QUE EXTRAE LA INFORMACION DE PROMOCIONES CON SU CORESPONDIENTE ACUERDO SI LO TIENE Y EL RESULTADO SE INSERTA EN LA TABLA TEMPORAL */
		/***** TRAMITES ****/
		INSERT INTO #Tramites
		([No_Exp], [TipoAsuntoDescripcion], [NumeroRegistro], [TipoPromocionDescripcion], [FechaRecibido],
		[Estado], [Mesa], [SecretarioDescripcion], [FechaAuto], 
		[AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], [NombreCapDJ], [EstadoAutorizacion], 
		[EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza], [FechaAutoriza], [FechaPreAutoriza], [FechaCancela], [userNameCapDJ], [FechaRecibido_F],
		[FechaAuto_F], [TipoAsuntoId], 
		[secretarioId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId],[FechaAlta_Promocion]
		,FechaActualiza_Promocion
		,FechaAutoriza_AsuntosDocumentos
		,FechaPreAutoriza_AsuntosDocumentos
		,FechaAlta_SintesisAcuerdos
		,FechaActualizacion_SintesisAcuerdos
		,NOMBRECORTO
		)
		
		SELECT 
				p.AsuntoAlias As No_Exp
				,TipoAsuntoDescripcion = p.CatTipoAsunto
				,p.NumeroRegistro
				,TipoPromocionDescripcion = CASE p.ClasePromocion WHEN '1' THEN 'Escrito' ELSE 'Oficio' END       
				,CONVERT(DATETIME,p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END) As FechaRecibido
				,isnull(dbo.fnDevuelveElementoCatalogo(p.EstadoPromocion),'Pendiente') as Estado        
				,Mesa = p.Mesa
				,SecretarioDescripcion =  SISE3.ConcatenarNombres(s.Nombre,s.ApellidoPaterno,s.ApellidoMaterno)
				,ISNULL(sa.FechaActualizacion,sa.FechaAlta) as FechaAuto
				,p.AsuntoNeunId
				,p.CatTipoAsuntoId
				,p.AsuntoDocumentoId
				,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(ad.CreadorId)
				,ad.CatAutorizacionDocumentosId as EstadoAutorizacion
				,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
				,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
				,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
				,FechaAutoriza = ad.FechaAutoriza
				,FechaPreAutoriza = ad.FechaPreAutoriza
				,FechaCancela = ad.FechaCancela
				,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
				,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
						ELSE '' END As FechaRecibido_F
				,ISNULL(CONVERT(VARCHAR(10),ad.FechaAlta+365,103),'') as FechaAuto_F
				,TipoAsuntoId = p.CatTipoAsuntoId
				,p.Secretario
				,ad.CreadorId
				,ad.EmpleadoIdPreautoriza
				,ad.EmpleadoIdAutoriza
				,ad.EmpleadoIdCancela
				,p.FechaAlta_Promocion
				,p.FechaActualiza_Promocion
				--
				,ad.FechaAutoriza					AS FechaAutoriza_AsuntosDocumentos
				,ad.FechaPreAutoriza				AS FechaPreAutoriza_AsuntosDocumentos
				,sa.FechaAlta						AS FechaAlta_SintesisAcuerdos
				,sa.FechaActualizacion				AS FechaActualizacion_SintesisAcuerdos
				,ta.NOMBRECORTO
		FROM #Promociones p
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) on pa.AsuntoNeunId=p.AsuntoNeunId and pa.NumeroOrden=p.NumeroOrden and pa.NumeroRegistro=p.NumeroRegistro
				AND pa.YearPromocion=p.YearPromocion and pa.StatusArchivo=1 AND pa.ClaseAnexo = 0
		LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) on p.AsuntoNeunId = ad.AsuntoNeunId and ad.AsuntoDocumentoId=p.AsuntoDocumentoId AND p.AsuntoId = ad.AsuntoID AND p.StatusReg=ad.StatusReg
		--LEFT JOIN CatPlantillas cp ON cp.CatPlantillaId = ad.CatPlantillaId
		LEFT JOIN tbx_CatTiposAsunto ta ON p.CatTipoAsuntoId = ta.CatTipoAsuntoId AND p.TipoCuaderno = ta.CuadernoId
		LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
		LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
		LEFT JOIN SintesisAcuerdoAsunto sa  WITH(NOLOCK) on sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden --- Se relaciona para obtener la fecha de captura
		WHERE p.StatusReg=1
		AND p.CatOrganismoId=@pi_CatOrganismoId
		AND (
		    (p.FechaPresentacion >= @pi_FechaPresentacionIni AND p.FechaPresentacion < DATEADD(DAY, 1, @pi_FechaPresentacionFin)) 
		    OR 
		    (ad.FechaAlta >= @pi_FechaPresentacionIni AND ad.FechaAlta < DATEADD(DAY, 1, @pi_FechaPresentacionFin))
		)


		INSERT INTO #Tramites
			([No_Exp], [TipoAsuntoDescripcion] , [Mesa], [SecretarioDescripcion], [AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], 
			[NombreCapDJ], [EstadoAutorizacion],  
			[EmpleadoAutoriza], [EmpleadoPreAutoriza], [FechaAutoriza],[FechaPreAutoriza], [FechaCancela], [userNameCapDJ], 
			[FechaAuto_F],	[TipoAsuntoId],FechaRecibido,[FechaAuto], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId],[FechaAlta_Promocion]
			,FechaActualiza_Promocion
			,FechaAutoriza_AsuntosDocumentos
			,FechaPreAutoriza_AsuntosDocumentos
			,FechaAlta_SintesisAcuerdos
			,FechaActualizacion_SintesisAcuerdos
			,NOMBRECORTO
			)

		SELECT a.AsuntoAlias 
		,cto.Descripcion As TipoAsuntoDescripcion
		,Mesa = COALESCE(m.Mesa, dbo.fnx_getValorPorNeunPorDescripcion(a.AsuntoNeunId,'Mesa'),'')
		,SecretarioDescripcion =  ISNULL(LTRIM(SISE3.ConcatenarNombres(eas.Nombre,eas.ApellidoPaterno,eas.ApellidoMaterno)),'')
		,a.AsuntoNeunId
		,a.AsuntoId
		,ad.AsuntoDocumentoId
		,NombreCapDJ = ISNULL(LTRIM(RTRIM(dbo.FNOBTIENEEMPLEADO(ad.CreadorId))),'')
		,ISNULL(ad.CatAutorizacionDocumentosId, 0) as EstadoAutorizacion		
		,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
		,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
		,FechaAutoriza = ad.FechaAutoriza
		,FechaPreAutoriza = ad.FechaPreAutoriza
		,FechaCancela = ad.FechaCancela
		,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
		,CONVERT(VARCHAR(10),ad.FechaAlta,103) as FechaAuto_F
		,TipoAsuntoId = cto.CatTipoAsuntoId
		,FechaRecibido = ad.FechaAlta
		,FechaAuto = ISNULL(sa.FechaActualizacion, sa.FechaAlta)
		,ad.CreadorId
		,ad.EmpleadoIdPreautoriza
		,ad.EmpleadoIdAutoriza
		,ad.EmpleadoIdCancela
		,p.FechaAlta						AS FechaAlta_Promocion
		,p.FechaActualiza					AS FechaActualiza_Promocion
		--
		,ad.FechaAutoriza					AS FechaAutoriza_AsuntosDocumentos
		,ad.FechaPreAutoriza				AS FechaPreAutoriza_AsuntosDocumentos
		,sa.FechaAlta						FechaAlta_SintesisAcuerdos
		,sa.FechaActualizacion				FechaActualizacion_SintesisAcuerdos
		,ta.NOMBRECORTO
		FROM AsuntosDocumentos ad  WITH(NOLOCK)
		--JOIN Asuntos a WITH(NOLOCK) ON  a.AsuntoNeunId= ad.AsuntoNeunId
		CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN Promociones p WITH (NOLOCK) ON a.AsuntoNeunId= p.AsuntoNeunId AND ad.AsuntoDocumentoId= p.AsuntoDocumentoId
		LEFT JOIN SintesisAcuerdoAsunto sa ON sa.AsuntoNeunId = a.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden and sa.statusreg =1
		LEFT JOIN tbx_CatTiposAsunto ta ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId AND ad.TipoCuaderno = ta.CuadernoId
		OUTER APPLY (		
			SELECT *
			FROM ( 
				SELECT 
					pr2.AsuntoNeunId, 
					pr2.Secretario,
					pr2.Mesa,
					ROW_NUMBER() OVER (PARTITION BY pr2.AsuntoNeunId ORDER BY pr2.FechaPresentacion DESC) AS id
				FROM Promociones pr2
				WHERE pr2.AsuntoNeunId = a.AsuntoNeunId
			) t
			WHERE t.id = 1
		) m
		LEFT JOIN CatEmpleados eas WITH(NOLOCK) ON eas.EmpleadoId = m.Secretario
		WHERE 
		a.CatOrganismoId=@pi_CatOrganismoId
		AND ad.FechaAlta >= @pi_FechaPresentacionIni AND ad.FechaAlta < DATEADD(DAY, 1, @pi_FechaPresentacionFin)
		AND p.AsuntoDocumentoId IS NULL
		AND ad.StatusReg=1

		SELECT DISTINCT 
					p.No_Exp,
					p.TipoAsuntoDescripcion, 
					p.NumeroRegistro,
					p.FechaRecibido,
					SecretarioDescripcion,
					FechaAuto = p.FechaAuto,
					Mesa,
					NombreCapDJ,
					p.EstadoAutorizacion	EstadoAutorizacion,
					p.EmpleadoPreAutoriza,
					p.EmpleadoAutoriza,
					p.EmpleadoCancela,
					p.AsuntoNeunId,
					p.AsuntoId,
					p.AsuntoDocumentoId, 
					p.FechaPreAutoriza, 
					p.FechaAutoriza,
					p.FechaCancela, 
					ISNULL(FechaRecibido_F,'')FechaRecibido_F ,
					ISNULL(FechaAuto_F,'')FechaAuto_F
					,p.secretarioId
					,p.CapturoId
					,p.PreautorizoId
					,p.AutorizoId
					,p.FechaAlta_Promocion
					,p.FechaActualiza_Promocion
					--
					,p.FechaAutoriza_AsuntosDocumentos
					,p.FechaPreAutoriza_AsuntosDocumentos
					,p.FechaAlta_SintesisAcuerdos
					,p.FechaActualizacion_SintesisAcuerdos
					,p.NombreCorto
				INTO #TramiteFinal
		FROM #Tramites p

		--Crear indices
			CREATE INDEX ix_01 ON #TramiteFinal(AsuntoNeunId)
			CREATE INDEX ix_02 ON #TramiteFinal(PreautorizoId)
			CREATE INDEX ix_03 ON #TramiteFinal(AutorizoId)
			CREATE INDEX ix_04 ON #TramiteFinal(CapturoId)
		
			SELECT 
					p.No_Exp,
					p.TipoAsuntoDescripcion, 
					p.NumeroRegistro,
					p.FechaRecibido,
					SecretarioDescripcion = ISNULL(LTRIM(RTRIM(p.SecretarioDescripcion)),''),
					FechaAuto = p.FechaAuto,
					Mesa = ISNULL(p.Mesa,''),
					NombreCapDJ = ISNULL(LTRIM(RTRIM(p.NombreCapDJ)),''),
					p.EmpleadoPreAutoriza,
					p.EmpleadoAutoriza,
					p.EmpleadoCancela,
					p.AsuntoNeunId,
					p.AsuntoId,
					FechaPreAutoriza,
					FechaAutoriza,
					FechaCancela
					,p.NombreCorto
					,Estado = 	IIF ((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL), 1,--Sin Acuerdo
									IIF (EstadoAutorizacion  IN (4,8,9),5, --Cancelados
										IIF (EstadoAutorizacion NOT IN (2,3,4,8,9) AND NOT((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL)), 2, --Con acuerdo
											IIF (EstadoAutorizacion  IN (2),3, -- Pre autorizados
												IIF (EstadoAutorizacion  IN (3),4,0))))) --Autorizados
					,[secretarioId]
					,[CapturoId]
					,[PreautorizoId]
					,[AutorizoId]
				--Cambios por SISE3.SP pcObtieneDatosAreaTramites					
				,ISNULL(cj.EmpleadoId,cjad.EmpleadoId)								AS EmpleadoIdJuez
				,ISNULL(cj.Nombre,cjad.Nombre)										AS NombreJuez
				,ISNULL(cj.UserName,cjad.UserName)									AS UserNameJuez
				,ISNULL(cj.PuestoDescripcionAlterno,cjad.PuestoDescripcionAlterno)	AS PuestoDescripcionJuez
				,ISNULL(cj.AreaNombre,cjad.AreaNombre)								AS JuezAreaNombre
				,ISNULL(cs.AreaNombre,csad.AreaNombre)								AS SecretarioAreaNombre
				,ISNULL(cs.NombreCompleto,csad.NombreCompleto)						AS SecretarioNombreCompleto
				,ISNULL(cs.UserName,csad.UserName)									AS SecretarioUserName
				,ISNULL(cs.PuestoDescripcion,csad.PuestoDescripcion)				AS SecretarioPuestoDescripcion
				,ISNULL(coj.AreaNombre,cojad.AreaNombre)							AS OficialAreaNombre
				,ISNULL(coj.NombreCompleto,cojad.NombreCompleto)					AS OficialNombreCompleto
				,ISNULL(coj.UserName,cojad.UserName)								AS OficialUserName
				,ISNULL(coj.PuestoDescripcion,cojad.PuestoDescripcion)				AS OficialPuestoDescripcion
				--
				,CASE WHEN ISNULL(cj.AreaNombre,cjad.AreaNombre) = 'Autorizaciones' THEN 1 ELSE 0 END		AS FlgAutorizaOtrosUsuarios 
				,CASE WHEN ISNULL(cs.AreaNombre,csad.AreaNombre) = 'Preautorizaciones' THEN 1 ELSE 0 END	AS FlgPreautorizaOtrosUsuarios
				,CASE WHEN ISNULL(coj.AreaNombre,cojad.AreaNombre) = 'Elaboraciones' THEN 1 ELSE 0 END		AS FlgCapturaOtrosUsuarios
				--
                ,TRY_CONVERT(DATE,ISNULL(NULLIF(FechaRecibido_F,''), NULLIF(FechaAuto_F,'')),103) 			AS FechaProceso                    
				,p.FechaAlta_Promocion								AS FechaAlta_Promocion
				,p.FechaActualiza_Promocion							AS FechaActualiza_Promocion
                ,diff_capturo				= DATEDIFF(mi,COALESCE(p.FechaActualiza_Promocion, p.FechaAlta_Promocion, p.FechaActualizacion_SintesisAcuerdos, p.FechaAlta_SintesisAcuerdos), p.FechaActualizacion_SintesisAcuerdos)
                ,diff_preautorizo			= DATEDIFF(mi,COALESCE(p.FechaActualizacion_SintesisAcuerdos, p.FechaAlta_SintesisAcuerdos), p.FechaPreAutoriza_AsuntosDocumentos)
                ,diff_autorizo				= DATEDIFF(mi,p.FechaPreAutoriza_AsuntosDocumentos, p.FechaAutoriza_AsuntosDocumentos)
                ,diff_cancelo				= DATEDIFF(mi,p.FechaAuto, p.FechaCancela)
                ,cd.CatalogoDependienteDescripcion			AS CatalogoDependienteDescripcion
                --
				,p.FechaAutoriza_AsuntosDocumentos
				,p.FechaPreAutoriza_AsuntosDocumentos
				,p.FechaAlta_SintesisAcuerdos
				,p.FechaActualizacion_SintesisAcuerdos
				---
				,p.AsuntoDocumentoId
				---
			INTO #TramiteFinalDashboard
			FROM #TramiteFinal p
			LEFT JOIN (-- Secretario
				SELECT DISTINCT
					a.AreaId					AS AreaId
					,a.Nombre					AS AreaNombre
					,a.EmpleadoId				AS EmpleadoId
					,e.UserName					AS UserName
					,e.PuestoDescripcion		AS PuestoDescripcion
					,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS NombreCompleto
				FROM areas a WITH (NOLOCK)
				INNER JOIN uvix_Empleados e WITH (NOLOCK)
					ON e.EmpleadoId = a.EmpleadoId
				WHERE a.fkIdTipoArea = 2 
					and a.CatOrganismoId = @pi_CatOrganismoId
			) AS cs
				ON cs.EmpleadoId = p.PreautorizoId
			LEFT JOIN (-- Oficial judicial
				SELECT
					a.AreaId					AS AreaId
					,a.Nombre					AS AreaNombre
					,e.EmpleadoId				AS EmpleadoId
					,e.UserName					AS UserName
					,e.PuestoDescripcion		AS PuestoDescripcion
					,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS NombreCompleto
				FROM AreasEmpleados ae WITH (NOLOCK)
				INNER JOIN Areas a WITH (NOLOCK)
					ON a.AreaId = ae.AreaId
				INNER JOIN uvix_Empleados e WITH (NOLOCK)
					ON e.EmpleadoId = ae.EmpleadoId
				WHERE a.CatOrganismoId = @pi_CatOrganismoId
			) coj
				ON coj.EmpleadoId = p.CapturoId
			LEFT JOIN (-- Titular
				SELECT DISTINCT
					a.AreaId					AS AreaId
					,a.Nombre					AS AreaNombre
					,a.EmpleadoId				AS EmpleadoId
					,e.UserName					AS UserName
					,e.PuestoDescripcion		AS PuestoDescripcion
					,a.Descripcion				AS PuestoDescripcionAlterno
					,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS Nombre
				FROM areas a WITH (NOLOCK)
				INNER JOIN uvix_Empleados e WITH (NOLOCK)
					ON e.EmpleadoId = a.EmpleadoId
				WHERE a.fkIdTipoArea = 4
					and a.CatOrganismoId = @pi_CatOrganismoId
			) cj
				ON cj.EmpleadoId = p.AutorizoId
			--
			LEFT JOIN (--Otros Usuarios/Secretario/Preautorizaciones
				SELECT DISTINCT
					E.EmpleadoId				AS EmpleadoId
					,'Preautorizaciones'		AS AreaNombre
					,e.UserName					AS UserName
					,e.PuestoDescripcion		AS PuestoDescripcion
					,NULL						AS PuestoDescripcionAlterno
					,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS NombreCompleto
				FROM CatEmpleados E
				INNER JOIN sise3.REL_RolEmpleadoXOrganismo reo
					ON reo.IdCatEmpleado = E.EmpleadoId
				WHERE reo.IdOrganismo = @pi_CatOrganismoId
					AND reo.bStatus = 1
			) AS csad
				ON csad.EmpleadoId = p.PreautorizoId
			LEFT JOIN (--Otros Usuarios/Oficial judicial/Elaboraciones
				SELECT DISTINCT
					E.EmpleadoId				AS EmpleadoId
					,'Elaboraciones'			AS AreaNombre
					,e.UserName					AS UserName
					,e.PuestoDescripcion		AS PuestoDescripcion
					,NULL						AS PuestoDescripcionAlterno
					,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS NombreCompleto
				FROM CatEmpleados E
				INNER JOIN sise3.REL_RolEmpleadoXOrganismo reo
					ON reo.IdCatEmpleado = E.EmpleadoId
				WHERE reo.IdOrganismo = @pi_CatOrganismoId
					AND reo.bStatus = 1
			) AS cojad
				ON cojad.EmpleadoId = p.CapturoId
			LEFT JOIN (--Otros Usuarios/Titular/Autorizaciones
				SELECT DISTINCT
					E.EmpleadoId				AS EmpleadoId
					,'Autorizaciones'			AS AreaNombre
					,e.UserName					AS UserName
					,e.PuestoDescripcion		AS PuestoDescripcion
					,NULL						AS PuestoDescripcionAlterno
					,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS Nombre
				FROM CatEmpleados E
				INNER JOIN sise3.REL_RolEmpleadoXOrganismo reo
					ON reo.IdCatEmpleado = E.EmpleadoId
				WHERE reo.IdOrganismo = @pi_CatOrganismoId
					AND reo.bStatus = 1
			) AS cjad
				ON cjad.EmpleadoId = p.AutorizoId
			--
			OUTER APPLY (			
				SELECT 
					a.AsuntoNeunId 
					,ctp.CatalogoDependienteDescripcion
				FROM Asuntos a WITH(NOLOCK)
				CROSS APPLY(
					SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew, ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew)  
						,CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew 
						,ceta.CatTipoAsuntoId
						,cd.CatalogoDependienteDescripcion
					FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
					INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)  ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
					INNER JOIN CatalogosElementosTiposAsunto ceta with(nolock) on cd.CatalogoDependienteId=ceta.CatalogoId and cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
					WHERE cd.CatalogoDependienteId IN (464,124,208,1207,734,1933,1892)
						AND a.CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew
						AND a.CatTipoAsuntoId = ceta.CatTipoAsuntoId 			
				) ctp
				WHERE a.StatusReg = 1
					AND ctp.row = 1
					AND a.AsuntoNeunId = p.AsuntoNeunId
			) cd



	--Crear tabla Meses para relacionar los datos históricos
	CREATE TABLE #Meses (
		rid					INT				IDENTITY(1,1)
	    ,MesInicio			DATETIME
	    ,MesFin				DATETIME
	    ,Mes				VARCHAR(100)
	)
	-- Llenar la tabla con los valores de inicio y fin de cada mes
	WHILE @PrimerDiaMesesProcesarTipoAsunto <= @UltimoDiaMesesProcesarTipoAsunto
	BEGIN
	    INSERT INTO #Meses (MesInicio, MesFin, Mes)
	    VALUES (
	    	DATEADD(DAY, 1, EOMONTH(@PrimerDiaMesesProcesarTipoAsunto, -1))
	    	,EOMONTH(@PrimerDiaMesesProcesarTipoAsunto)
	    	,FORMAT(@PrimerDiaMesesProcesarTipoAsunto,'MMMM','es-mx')
		)
	    SET @PrimerDiaMesesProcesarTipoAsunto = DATEADD(MONTH, 1, @PrimerDiaMesesProcesarTipoAsunto)
	END

	
	
	--TT1
	SELECT DISTINCT
		e.EmpleadoId				AS EmpleadoId
		,'Secretario'				AS DescPuesto
		,SISE3.ConcatenarNombres(e.Nombre,e.ApellidoPaterno,e.ApellidoMaterno)		AS NombreCompleto
		,e.USERNAME					AS UserName
		,a.Nombre					AS NombreArea
		,e.JEFEID
		,SISE3.ConcatenarNombres(ej.Nombre,ej.ApellidoPaterno,ej.ApellidoMaterno)	AS Jefe
		,1							AS Orden
		,0							AS EsTitular
		,1							AS EsSecretario
		,0							AS EsOtrosUsuarios
	INTO #SecretariosOtros
	FROM Areas a WITH (NOLOCK)
	INNER JOIN uvix_Empleados e WITH (NOLOCK)
		ON e.EmpleadoId = a.EmpleadoId
	LEFT JOIN uvix_Empleados ej
		ON ej.EmpleadoId = e.JefeId
	WHERE a.CatOrganismoId = @pi_CatOrganismoId
		AND a.fkIdTipoArea  IN (2) 
		AND a.STATUSREG = 1
		
	--TT2
	--1/Resulset para datos Tarjeta
	--Datos de Secretario
	SELECT
		SecretarioAreaNombre				AS Mesa
		,PreautorizoId						AS UsuarioId
		,MAX(EmpleadoIdJuez)				AS Relacion
		,'Secretario'						AS DescPuesto
		,MAX(SecretarioNombreCompleto)		AS NombreCompleto
		,MAX(SecretarioUserName)			AS UserName
		,PromocionesHoyAcumulado	= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual THEN 1 ELSE 0 end),0)
		,PromocionesHoyTotal		= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual THEN 1 ELSE 0 end),0) + ISNULL(MAX(ac.SinAcuerdo),0) + ISNULL(MAX(ac.ConAcuerdo),0)
		,AcuerdosPorAnio			= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN 1 ELSE 0 end),0)
		,AcuerdosPorDiaPromedio		= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN 1 end),0) /
			CASE WHEN COUNT(DISTINCT CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN tf.FechaProceso END) > 0 THEN COUNT(DISTINCT CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN tf.FechaProceso END)
				ELSE 1
			END
		,TiempoPorAcuerdoPromedio	= ISNULL(AVG(CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN diff_preautorizo end),0)
		,1									AS Orden
		,0									AS EsTitular
		,1									AS EsSecretario
		,MAX(FlgPreautorizaOtrosUsuarios)	AS EsOtrosUsuarios
	INTO #Tarjeta
	FROM #TramiteFinalDashboard tf
	LEFT JOIN (
		SELECT
			Mesa
			,SinAcuerdo				= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (1) THEN 1 ELSE 0 END)
			,ConAcuerdo				= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (2) THEN 1 ELSE 0 END)
			,PreAutorizados			= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (3) THEN 1 ELSE 0 END)
			,Autorizados			= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (4) THEN 1 ELSE 0 END)
			,Cancelados				= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (5) THEN 1 ELSE 0 END)
		FROM #TramiteFinalDashboard
		WHERE SecretarioAreaNombre IS NULL
		GROUP BY Mesa
	) ac
		ON ac.Mesa = tf.SecretarioAreaNombre
	WHERE SecretarioAreaNombre IS NOT NULL
		AND Estado NOT IN (5)
	GROUP BY
		SecretarioAreaNombre
		,PreautorizoId
	UNION 
	--Datos de Oficial
	SELECT
		tf.OficialAreaNombre				AS Mesa
		,tf.CapturoId						AS UsuarioId
		,MAX(san.PreautorizoId)				AS Relacion
		,'Oficial'							AS DescPuesto
		,MAX(tf.OficialNombreCompleto)		AS NombreCompleto
		,MAX(tf.OficialUserName)			AS UserName
		,PromocionesHoyAcumulado 	= ISNULL(SUM(CASE WHEN tf.FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual THEN 1 ELSE 0 end),0)
		,PromocionesHoyTotal 		= ISNULL(SUM(CASE WHEN tf.FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual THEN 1 ELSE 0 end),0)
		,AcuerdosPorAnio			= ISNULL(SUM(CASE WHEN tf.FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN 1 ELSE 0 end),0)
		,AcuerdosPorDiaPromedio		= ISNULL(SUM(CASE WHEN tf.FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN 1 end),0) / 
			CASE WHEN COUNT(DISTINCT CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN tf.FechaProceso END) > 0 THEN COUNT(DISTINCT CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN tf.FechaProceso END)
				ELSE 1
			END
		,TiempoPorAcuerdoPromedio	= ISNULL(AVG(CASE WHEN tf.FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN diff_capturo end),0)
		,2									AS Orden
		,0									AS EsTitular
		,0									AS EsSecretario
		,MAX(FlgCapturaOtrosUsuarios)		AS EsOtrosUsuarios
	FROM #TramiteFinalDashboard tf
	LEFT JOIN (
		SELECT 
			SecretarioAreaNombre
			,MAX(PreautorizoId)					AS PreautorizoId
		FROM #TramiteFinalDashboard
		GROUP BY SecretarioAreaNombre
	) san
		ON san.SecretarioAreaNombre = tf.OficialAreaNombre
	WHERE tf.OficialAreaNombre IS NOT NULL
		AND Estado NOT IN (5)
	GROUP BY
		tf.OficialAreaNombre
		,tf.CapturoId	
	UNION
	--Datos de Titular
	SELECT
		JuezAreaNombre						AS Mesa
		,EmpleadoIdJuez						AS UsuarioId
		,NULL								AS Relacion
		,MAX(PuestoDescripcionJuez)			AS DescPuesto
		,MAX(NombreJuez)					AS NombreCompleto
		,MAX(UserNameJuez)					AS UserName
		,PromocionesHoyAcumulado	= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual THEN 1 ELSE 0 end),0)
		,PromocionesHoyTotal		= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (3,4) THEN 1 ELSE 0 end),0) + ISNULL(MAX(ac.PreAutorizados),0) + ISNULL(MAX(ac.Autorizados),0)
		,AcuerdosPorAnio			= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN 1 ELSE 0 end),0)
		,AcuerdosPorDiaPromedio		= ISNULL(SUM(CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN 1 end),0) / 
			CASE WHEN COUNT(DISTINCT CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN FechaProceso END) > 0 THEN ISNULL(COUNT(DISTINCT CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN FechaProceso END),1)
			ELSE 1
			END
		,TiempoPorAcuerdoPromedio	= ISNULL(AVG(CASE WHEN FechaProceso BETWEEN @PrimerDiaAnioActual AND @FechaActual THEN diff_autorizo end),0)
		,3									AS Orden
		,1									AS EsTitular
		,0									AS EsSecretario
		,MAX(FlgAutorizaOtrosUsuarios)		AS EsOtrosUsuarios
	FROM #TramiteFinalDashboard
	LEFT JOIN (
		SELECT
			SinAcuerdo				= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (1) THEN 1 ELSE 0 END)
			,ConAcuerdo				= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (2) THEN 1 ELSE 0 END)
			,PreAutorizados			= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (3) THEN 1 ELSE 0 END)
			,Autorizados			= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (4) THEN 1 ELSE 0 END)
			,Cancelados				= SUM(CASE WHEN FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual AND Estado IN (5) THEN 1 ELSE 0 END)
		FROM #TramiteFinalDashboard
		WHERE JuezAreaNombre IS NULL
	) ac
		ON 1=1
	WHERE JuezAreaNombre IS NOT NULL
		AND Estado NOT IN (5)
	GROUP BY
		JuezAreaNombre
		,EmpleadoIdJuez
	
SELECT 
	isnull(t.Mesa, a.NombreArea)					AS Mesa
	,isnull(t.UsuarioId, a.EmpleadoId)				AS UsuarioId
	,t.Relacion										AS Relacion
	,isnull(t.DescPuesto, a.DescPuesto)				AS DescPuesto
	,isnull(t.NombreCompleto, a.NombreCompleto)		AS NombreCompleto
	,isnull(t.UserName, a.UserName)					AS UserName
	,t.PromocionesHoyAcumulado
	,t.PromocionesHoyTotal
	,t.AcuerdosPorAnio
	,t.AcuerdosPorDiaPromedio
	,t.TiempoPorAcuerdoPromedio
	,isnull(t.Orden, a.Orden)						AS Orden
	,isnull(t.EsTitular, a.EsTitular)				AS EsTitular
	,isnull(t.EsSecretario, a.EsSecretario)			AS EsSecretario
	,isnull(t.EsOtrosUsuarios, a.EsOtrosUsuarios)	AS EsOtrosUsuarios
INTO #SecretariosOtros2 
FROM #SecretariosOtros a
FULL OUTER JOIN #Tarjeta t
	ON a.EmpleadoId = t.UsuarioId
ORDER BY 
		Mesa
		,Orden
		,UsuarioId

SELECT 
	Mesa
	,UsuarioId
	,ISNULL(Relacion,CASE WHEN DescPuesto = 'Oficial' AND Relacion IS NULL THEN (SELECT max(CASE WHEN DescPuesto = 'Secretario' THEN UsuarioId END ) FROM #SecretariosOtros2 t2 WHERE t2.Mesa = a.Mesa) END)	AS Relacion
	,DescPuesto
	,NombreCompleto
	,UserName
	,isnull(PromocionesHoyAcumulado,0)			AS PromocionesHoyAcumulado
	,isnull(PromocionesHoyTotal,0)				AS PromocionesHoyTotal
	,isnull(AcuerdosPorAnio,0)					AS AcuerdosPorAnio
	,isnull(AcuerdosPorDiaPromedio,0)			AS AcuerdosPorDiaPromedio
	,isnull(TiempoPorAcuerdoPromedio,0)			AS TiempoPorAcuerdoPromedio
	,Orden
	,EsTitular
	,EsSecretario
	,EsOtrosUsuarios
FROM #SecretariosOtros2 a
ORDER BY 
		Mesa
		,Orden
		,UsuarioId

	--1/Resulset para datos Tarjeta
		
	--2/Resulset para gráfica Tipo Asunto
	SELECT
		Mesa
		,UsuarioId
		,Relacion
		,TipoAsuntoDescripcion
		,TotalMes
		,MONTH(MesInicio)					AS NoMes
		,ms.Mes	
		,Orden
		,YEAR(MesInicio)					AS Anio
		,Autorizaciones
		,Preautorizaciones
		,Elaboraciones	
		,EsOtrosUsuarios
	FROM #Meses ms
	LEFT JOIN (
		--Datos de Secretario
		SELECT
			SecretarioAreaNombre				AS Mesa
			,PreautorizoId						AS UsuarioId
			,MAX(EmpleadoIdJuez)				AS Relacion
			,TipoAsuntoDescripcion				AS TipoAsuntoDescripcion
			,COUNT(*)							AS TotalMes
			,MONTH(FechaProceso)				AS NoMes
			,MAX(FORMAT(FechaProceso,'MMMM','es-mx'))		as Mes	
			,1									AS Orden
			,YEAR(FechaProceso)					AS Anio
			,0									AS Autorizaciones
			,MAX(FlgPreautorizaOtrosUsuarios)	AS Preautorizaciones
			,0									AS Elaboraciones	
			,MAX(CASE WHEN ISNULL(FlgAutorizaOtrosUsuarios,0) + ISNULL(FlgPreautorizaOtrosUsuarios,0) + ISNULL(FlgCapturaOtrosUsuarios,0) >= 1 THEN 1 ELSE 0 END) 		AS EsOtrosUsuarios
		FROM #TramiteFinalDashboard
		WHERE FechaProceso BETWEEN @PrimerDiaMesesProcesarTiempoRevision AND @FechaActual
			AND SecretarioAreaNombre IS NOT NULL
			AND Estado NOT IN (5)
		GROUP BY
			SecretarioAreaNombre
			,PreautorizoId
			,TipoAsuntoDescripcion
			,MONTH(FechaProceso)
			,YEAR(FechaProceso)
			
		UNION 
		--Datos de Oficial
		SELECT
			OficialAreaNombre					AS Mesa
			,CapturoId							AS UsuarioId
			,MAX(SecretarioId)					AS Relacion
			--,MAX(PreautorizoId)					AS Relacion
			,TipoAsuntoDescripcion				AS TipoAsuntoDescripcion
			,COUNT(*)							AS TotalMes
			,MONTH(FechaProceso)				AS NoMes
			,MAX(FORMAT(FechaProceso,'MMMM','es-mx'))		as Mes
			,2									AS Orden
			,YEAR(FechaProceso)					AS Anio
			,0							 		AS Autorizaciones
			,0									AS Preautorizaciones
			,MAX(FlgCapturaOtrosUsuarios)		AS Elaboraciones	
			,MAX(CASE WHEN ISNULL(FlgAutorizaOtrosUsuarios,0) + ISNULL(FlgPreautorizaOtrosUsuarios,0) + ISNULL(FlgCapturaOtrosUsuarios,0) >= 1 THEN 1 ELSE 0 END) 		AS EsOtrosUsuarios
		FROM #TramiteFinalDashboard
		WHERE FechaProceso BETWEEN @PrimerDiaMesesProcesarTiempoRevision AND @FechaActual
			AND OficialAreaNombre IS NOT NULL
			AND Estado NOT IN (5)
		GROUP BY
			OficialAreaNombre
			,CapturoId
			,TipoAsuntoDescripcion
			,MONTH(FechaProceso)
			,YEAR(FechaProceso)
	
		UNION
		--Datos de Titular
		SELECT
			JuezAreaNombre						AS Mesa
			,AutorizoId							AS UsuarioId
			,NULL								AS Relacion
			,TipoAsuntoDescripcion				AS TipoAsuntoDescripcion
			,COUNT(*)							AS TotalMes
			,MONTH(FechaProceso)				AS NoMes
			,MAX(FORMAT(FechaProceso,'MMMM','es-mx'))		as Mes
			,3									AS Orden
			,YEAR(FechaProceso)					AS Anio
			,MAX(FlgAutorizaOtrosUsuarios) 		AS Autorizaciones
			,0									AS Preautorizaciones
			,0									AS Elaboraciones	
			,MAX(CASE WHEN ISNULL(FlgAutorizaOtrosUsuarios,0) + ISNULL(FlgPreautorizaOtrosUsuarios,0) + ISNULL(FlgCapturaOtrosUsuarios,0) >= 1 THEN 1 ELSE 0 END) 		AS EsOtrosUsuarios
		FROM #TramiteFinalDashboard tf
		WHERE FechaProceso BETWEEN @PrimerDiaMesesProcesarTiempoRevision AND @FechaActual
			AND JuezAreaNombre IS NOT NULL
			AND Estado NOT IN (5)
		GROUP BY
			JuezAreaNombre
			,AutorizoId
			,TipoAsuntoDescripcion
			,MONTH(FechaProceso)
			,YEAR(FechaProceso)
	) dm
		ON dm.Mes = ms.Mes
	ORDER BY
		Mesa
		,Orden
		,UsuarioId
		,ms.Mes
		,TipoAsuntoDescripcion
	--2/Resulset para gráfica Tipo Asunto
	
					
	--4/Resulset para gráfica de velas
	SELECT
		No_Exp 
		,SecretarioDescripcion  
		,NombreCapDJ 
		,secretarioId   
		,EmpleadoIdJuez 
		,Mesa 
		,EmpleadoAutoriza 
		,SecretarioAreaNombre 
		,SecretarioNombreCompleto 
		,OficialAreaNombre 
		,OficialNombreCompleto 
		,JuezAreaNombre 
		,NombreJuez 
		,Estado
		,AsuntoId
		,NombreCorto
		,TipoAsuntoDescripcion
		,CatalogoDependienteDescripcion
		,NumeroRegistro
		--
		,FechaProceso
		,AsuntoNeunId
		,FechaAlta_Promocion
		,FechaActualiza_Promocion
		--
		,CapturoId
		,PreautorizoId
		,AutorizoId
		,FlgAutorizaOtrosUsuarios
		,FlgPreautorizaOtrosUsuarios
		,FlgCapturaOtrosUsuarios
		--
        ,OficialFechaInicial		= COALESCE(FechaActualiza_Promocion, FechaAlta_Promocion, FechaActualizacion_SintesisAcuerdos, FechaAlta_SintesisAcuerdos)
        ,OficialFechaFinal			= COALESCE(FechaActualizacion_SintesisAcuerdos, FechaAlta_SintesisAcuerdos)
        ,SecretarioFechaInicial		= COALESCE(FechaActualizacion_SintesisAcuerdos, FechaAlta_SintesisAcuerdos)
        ,SecretarioFechaFinal		= FechaPreAutoriza_AsuntosDocumentos
        ,TitularFechaInicial		= FechaPreAutoriza_AsuntosDocumentos
        ,TitularFechaFinal			= FechaAutoriza_AsuntosDocumentos
		--
		,diff_capturo
		,diff_preautorizo
		,diff_autorizo
		,diff_cancelo
		--
		,@pi_FechaPresentacionIni_Origen		AS FechaPresentacionIni_Origen
		,@FechaActual							AS FechaActual
		,@PrimerDiaAnioActual					AS PrimerDiaAnioActual
		,FechaAutoriza_AsuntosDocumentos
		,FechaPreAutoriza_AsuntosDocumentos
		,FechaActualiza_Promocion
		,FechaAlta_Promocion
		,FechaActualizacion_SintesisAcuerdos
		,FechaAlta_SintesisAcuerdos
		--
		,AsuntoDocumentoId
		--
	FROM #TramiteFinalDashboard 
	WHERE FechaProceso BETWEEN @pi_FechaPresentacionIni_Origen AND @FechaActual
		AND Estado NOT IN (5)
	--4/Resulset para gráfica de velas


				
		FIN:
		IF OBJECT_ID('tempdb..#Tramites') IS NOT NULL
			DROP TABLE #Tramites
		IF OBJECT_ID('tempdb..#MaxSec') IS NOT NULL
			DROP TABLE #MaxSec
		IF OBJECT_ID('tempdb..#Asuntos') IS NOT NULL
			DROP TABLE #Asuntos
		IF OBJECT_ID('tempdb..#Promociones') IS NOT NULL
			DROP TABLE #Promociones
		IF OBJECT_ID('tempdb..#TempSinPromocion') IS NOT NULL
			DROP TABLE #TempSinPromocion
		IF OBJECT_ID('tempdb..#TramiteFinal') IS NOT NULL
			DROP TABLE #TramiteFinal
		IF OBJECT_ID('tempdb..#TramiteFinalDashboard') IS NOT NULL
			DROP TABLE #TramiteFinalDashboard
		IF OBJECT_ID('tempdb..#Meses') IS NOT NULL
			DROP TABLE #Meses
		IF OBJECT_ID('tempdb..#SecretariosOtros') IS NOT NULL
			DROP TABLE #SecretariosOtros
		IF OBJECT_ID('tempdb..#SecretariosOtros2') IS NOT NULL
			DROP TABLE #SecretariosOtros2
		IF OBJECT_ID('tempdb..#Tarjeta') IS NOT NULL
			DROP TABLE #Tarjeta
		
			
END