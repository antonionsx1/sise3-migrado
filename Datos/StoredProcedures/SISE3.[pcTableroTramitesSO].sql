SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  02/10/2023
-- Alter date:  06/06/2024 - JSM Ajuste para reducción de tiempos
-- Description: Inserta y actualizar Asunto Documento 
-- Basado en:   uspx_tt_getTableroTramite
-- EXEC [SISE3].[pcTableroTramites]  180, 1000,1, null,'2023-12-05','2024-02-20',null, null, '', null, null ,0,31811,4,'',null
-- EXEC [SISE3].[pcTableroTramites] 1011, 1000,1, null,'2024-01-21','2024-05-28',null,null,''
-- EXEC [SISE3].[pcTableroTramitesSO] 180, '2025-01-19','2025-05-19'
-- Modificación JSM: 10/06/2024, Se crea versión sin contadores y sin ordenamiento
-- Modificación JSM: 20/06/2024,  Se condiciona que no salga en contenido: 3969	Sentencia
-- Modificación JSM: 27/06/2024,  Se adecua a fechas Nulas, trae todo
-- Modificación LAGS: 26.03.2024, se agrega validación para DJ statusreg = 1 en el contador de notificaciones. 
-- Modificación SBGE: 26/03/2025, Se muestra el organo para los promoventes de Autoridad Judicial. Solicitado por Carlos  Task 22900
-- Modificación ARS: 29/04/2025, Se actualizó la consulta para poder mostrar el estado de la solicitud de firma DG Task 4879
-- Modificación AGA: 19/05/2025, Se modifico de algunas consultas nep.StatusReg = 1 por nep.StatusReg IN(1,2)
-- Modificación JRE: 12/06/2025, Se actualiza la columna por la cual ordena los registros para retorno de nombre y expediente origen de asuntos juridicos tarea 23690
-- =============================================

ALTER PROCEDURE [SISE3].[pcTableroTramitesSO] 
    -- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATE = NULL, 
	-- REPRESENTA EL EMPLEADO QUE ESTA CONSULTANDO EL TABLERO 
	@pi_EmpleadoId BIGINT = NULL
AS
BEGIN

		DECLARE @Tramites SISE3.Tramites_type, @Tramites_Final SISE3.Tramites_type
		DECLARE @Promociones SISE3.Tramites_type
		DECLARE @FechaIniciaOperaciones DATE
		DECLARE @Pendientes BIT = 0
		DECLARE @MuestraSentencia BIT =0
	    /*********** VALIDACIÓN PARA ASUNTOS JURIDICOS ****************/
	    DECLARE @TipoOrganoAsuntosJuridicos BIT =0 
	    
	    IF (
	    (SELECT cto.CatTipoOrganismoId FROM CatOrganismos CO WITH(NOLOCK)
	    INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK)
	    ON CO.CatTipoOrganismoId =  CTO.CatTipoOrganismoId
	    WHERE CO.CatOrganismoId =  @pi_CatOrganismoId) = 33
	    )
	    BEGIN
	    SET @TipoOrganoAsuntosJuridicos = 1
	    END
	    /*********** VALIDACIÓN PARA ASUNTOS JURIDICOS ****************/

		/**************** GGHH - Cambio pendientes ************************/
		IF (@pi_FechaPresentacionFin IS NULL AND @pi_FechaPresentacionIni IS NULL)
		BEGIN
			SELECT @FechaIniciaOperaciones = FechaAlta 
			FROM  SISE3.ConfiguracionOrganismo
			WHERE CatOrganismoId = @pi_CatOrganismoId
		
			SET @FechaIniciaOperaciones = ISNULL(@FechaIniciaOperaciones,GETDATE())
			SET @pi_FechaPresentacionIni = ISNULL(@pi_FechaPresentacionIni,@FechaIniciaOperaciones)
			SET @pi_FechaPresentacionFin = ISNULL(@pi_FechaPresentacionFin,GETDATE())

			SET @Pendientes = 1
		END
		/**************** GGHH - FIN Cambio pendientes ************************/
 		 
          SELECT 
				p.AsuntoNeunId,
				p.ClasePromocion,
				p.ClasePromovente,
				p.EstadoPromocion,
				p.FechaPresentacion,
				p.HoraPresentacion,
				p.Mesa,
				p.NumeroAnexos,
				p.NumeroCopias,
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
				ad.CatPlantillaId,
				ad.SintesisOrden,
				ad.FechaAlta,
				ad.CatContenidoId,
				ad.NombreArchivo,
				ad.ExtensionDocumento,
				ad.CreadorId,
				ad.CatAutorizacionDocumentosId,
				ad.EmpleadoIdCancela,
				ad.EmpleadoIdAutoriza,
				ad.EmpleadoIdPreautoriza,
				ad.FechaAutoriza,
				ad.FechaPreAutoriza,
				ad.FechaCancela,
				ad.uGuidDocumento,
				ad.NombreDocumento,
				--adca.PreautorizadoSinFirma,
				--adca.FechaElaboracion,
				--adca.SintesisIA
				ad.Firmado
			INTO #PromosFiltradas
			FROM Promociones p WITH(NOLOCK)
			CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
			LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) on p.AsuntoNeunId = ad.AsuntoNeunId
								        AND ad.sintesisOrden = p.sintesisorden
										AND p.AsuntoId = ad.AsuntoID
										AND p.StatusReg=cast( ad.StatusReg as int)
										
          WHERE  p.StatusReg = 1
                 AND p.CatOrganismoId = @pi_CatOrganismoId
               AND (
                     (p.FechaPresentacion >= @pi_FechaPresentacionIni 
                     AND p.FechaPresentacion <= DATEADD(DAY,1,@pi_FechaPresentacionFin))
					 OR 
	                (ad.FechaAlta >= @pi_FechaPresentacionIni 
                    AND ad.FechaAlta <= DATEADD(DAY,1,@pi_FechaPresentacionFin))
				   )
          AND (@Pendientes = 0 OR (@Pendientes = 1 AND (ISNULL(ad.CatAutorizacionDocumentosId,0) <> 3 )))

          SELECT 
                 p.AsuntoNeunId,
                 p.ClasePromocion,
                 p.ClasePromovente,
                 p.EstadoPromocion,
                 p.FechaPresentacion,
                 p.HoraPresentacion,
                 Mesa = ISNULL(ar.Nombre, p.Mesa),
                 p.NumeroAnexos,
                 p.NumeroCopias,
                 p.NumeroOrden,
                 p.NumeroRegistro,
                 p.OrigenPromocion,
                 Secretario = ISNULL(ar.EmpleadoId, p.Secretario),
                 p.TipoContenido,
                 p.TipoCuaderno,
                 p.TipoPromovente,
                 p.YearPromocion,
                 p.AsuntoDocumentoId,
                 p.StatusReg,
                 p.AsuntoAlias,
                 p.CatTipoAsuntoId,
                 p.NumeroAlias,
                 p.TipoProcedimiento,
                 p.CatOrganismoId,
                 p.AsuntoId,
                 p.CatTipoAsunto,
                 p.CatPlantillaId,
                 p.SintesisOrden,
                 p.FechaAlta,
                 p.CatContenidoId,
                 p.NombreArchivo,
                 p.ExtensionDocumento,
                 p.CreadorId,
                 p.CatAutorizacionDocumentosId,
                 p.EmpleadoIdCancela,
                 p.EmpleadoIdAutoriza,
                 p.EmpleadoIdPreautoriza,
                 p.FechaAutoriza,
                 p.FechaPreAutoriza,
                 p.FechaCancela,
                 p.uGuidDocumento,
                 p.NombreDocumento,
                 adca.PreautorizadoSinFirma,
                 adca.FechaElaboracion,
                 adca.SintesisIA,
                 adca.SolicitaFirmaDG,
				 p.Firmado
                 INTO #Promociones
            FROM #PromosFiltradas p
             LEFT JOIN SISE3.Rel_PromocionArea rpa WITH (NOLOCK) ON 
                              rpa.AsuntoNeunId = p.AsuntoNeunId
                              AND rpa.CatOrganismoId = p.CatOrganismoId 
                              AND rpa.NumeroOrden = p.NumeroOrden
                              AND rpa.YearPromocion = p.YearPromocion
             LEFT JOIN Areas ar ON ar.AreaId = rpa.AreaId
             LEFT JOIN SISE3.AsuntosDocumentosAdicional adca WITH (NOLOCK) ON 
                              adca.AsuntoNeunId = p.AsuntoNeunId
                              AND adca.AsuntoDocumentoId = p.AsuntoDocumentoId;	
							  
		/* SE EJECUTA EL PRIMER SP QUE EXTRAE LA INFORMACION DE PROMOCIONES CON SU CORESPONDIENTE ACUERDO SI LO TIENE Y EL RESULTADO SE INSERTA EN LA TABLA TEMPORAL */
		/***** TRAMITES ****/
		INSERT INTO @Tramites
		([No_Exp], [TipoAsuntoDescripcion], [NumeroRegistro], [TipoPromocionDescripcion], [FechaRecibido], [NumeroOrden], [NombreTipoCuaderno],
		[Promovente],[TipoContenidoDescripcion], [Contenido], [Copias], [Anexos], [Estado], [Mesa], [SecretarioDescripcion], [FechaAuto], [Plantilla], 
		[AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], [NombreArchivo], [NombreCapDJ], [EstadoAutorizacion], [NumeroAlias], [ArchivoPromocion], 
		[NombreOrigen], [EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza], [FechaAutoriza], [FechaPreAutoriza], [FechaCancela], [userNameCapDJ], [userNameSecretario], [FechaRecibido_F],
		[FechaAuto_F],	[NombreDocumento], [YearPromocion], [TipoAsuntoId], [TipoCuadernoId], [NombreCorto] , [RutaArchivoNAS] , [Origen], 
		[SintesisOrden], [TipoProcedimiento], [secretarioId], [OrigenId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId],[GuidDocumento]
		,PromocionCompleta, EmpleadoAutorizaCompleto, EmpleadoPreAutorizaCompleto, EmpleadoCancelaCompleto, PreautorizadoSinFirma, FechaElaboracion, SintesisIA, SolicitaFirmaDG, Firmado)
		
		SELECT 
				p.AsuntoAlias As No_Exp
				,TipoAsuntoDescripcion = p.CatTipoAsunto
				,p.NumeroRegistro
				,TipoPromocionDescripcion = CASE p.ClasePromocion WHEN '1' THEN 'Escrito' ELSE 'Oficio' END       
				,CONVERT(DATETIME,p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END) As FechaRecibido
				,p.NumeroOrden
				,dbo.funRecuperaCatalogoDependienteDescripcion(527,p.TipoCuaderno) as NombreTipoCuaderno
				,Promovente = ISNULL(
				CASE WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid = 1 THEN SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid <> 1 THEN ISNULL(pas.DenominacionDeAutoridad,SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)) --ARS 02/04/2025 Bug 22842 Se hace un ajuste cuando el campo de Denominación es NULL
					WHEN ISNULL(p.ClasePromovente,1) = 2 THEN SISE3.ConcatenarNombres(pr.Nombre, pr.APaterno,pr.AMaterno)
					--WHEN ISNULL(p.ClasePromovente,1)  = 3 THEN SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno)
					WHEN ISNULL(p.ClasePromovente,1) =3 THEN  cto.NombreOficial-- SBGE 26/03/2025 Solicitado por Carlos  Task 22900
					WHEN ISNULL(p.ClasePromovente,1)  =4 THEN ajo.AJONombre
					END,'')
				--,TipoContenidoDescripcion = ISNULL((SELECT CatalogoPromocionDescripcion FROM CatPromocion with(nolock) where CatalogoPromocionId=p.TipoContenido),'')
				,TipoContenidoDescripcion = ISNULL(cpr.CatalogoPromocionDescripcion,'')
				--,(select CatalogoElementoDescripcion from CatalogosElementosDescripcion with(nolock) where CatalogoElementoDescripcionID = p.CatContenidoId) as Contenido
				,Contenido = con.CatalogoElementoDescripcion
				,ISNULL(p.[NumeroCopias],0) As Copias
				,ISNULL(p.[NumeroAnexos],0) As Anexos
				,isnull(dbo.fnDevuelveElementoCatalogo(p.EstadoPromocion),'Pendiente') as Estado        
				,Mesa = p.Mesa
				,SecretarioDescripcion =  SISE3.ConcatenarNombres(s.Nombre,s.ApellidoPaterno,s.ApellidoMaterno)
				,ISNULL(sa.FechaActualizacion,sa.FechaAlta) as FechaAuto
				,'' As Plantilla
				,p.AsuntoNeunId
				,p.CatTipoAsuntoId
				,p.AsuntoDocumentoId
				,p.NombreArchivo+ p.ExtensionDocumento as NombreArchivo
				,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(p.CreadorId)
				,p.CatAutorizacionDocumentosId as EstadoAutorizacion
				,p.NumeroAlias
				,pa.NombreArchivo as ArchivoPromocion
				,NombreOrigen = ISNULL(co.sNombreOrigenPromocion,'SIN ORIGEN')
				,EmpleadoCancela = dbo.fnx_getUserName(p.EmpleadoIdCancela)
				,EmpleadoAutoriza = dbo.fnx_getUserName(p.EmpleadoIdAutoriza)
				,EmpleadoPreAutoriza = dbo.fnx_getUserName(p.EmpleadoIdPreautoriza)
				,FechaAutoriza = p.FechaAutoriza
				,FechaPreAutoriza = p.FechaPreAutoriza
				,FechaCancela = p.FechaCancela
				,userNameCapDJ = dbo.fnx_getUserName(p.CreadorId)
				,userNameSecretario = s.UserName --dbo.fnx_getUserName(p.Secretario)
				,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
						ELSE '' END As FechaRecibido_F
				,ISNULL(CONVERT(VARCHAR(10),p.FechaAlta,103),'') as FechaAuto_F --Se quita "+365"
				,p.NombreDocumento
				,p.YearPromocion
				,TipoAsuntoId = p.CatTipoAsuntoId
				,TipoCuadernoId = p.TipoCuaderno
				,ta.nombreCorto
				,RutaArchivoNAS = ISNULL(pa.RutaArchivoNAS,0)
				,Origen = co.kIdOrigenPromocion
				--,sa.SintesisOrden
				,p.SintesisOrden --modificacion 
				,p.TipoProcedimiento
				,p.Secretario
				,p.OrigenPromocion
				,p.CreadorId
				,p.EmpleadoIdPreautoriza
				,p.EmpleadoIdAutoriza
				,p.EmpleadoIdCancela
				,p.uGuidDocumento GuidDocumento
				,CASE WHEN 
					pa.StatusArchivo <> 1 OR 
					pa.NombreArchivo IS NULL OR
					p.TipoPromovente IS NULL OR 
					p.TipoPromovente = 0 OR
					p.Secretario < 1 OR 
					p.Secretario IS NULL oR
					p.Mesa IS NULL  OR 
					LEN(p.Mesa) < 1
				THEN 0 
				ELSE 1 END
				,SISE3.ConcatenarNombres(cea.Nombre, cea.ApellidoPaterno, cea.ApellidoMaterno) as EmpleadoAutorizaCompleto
				,SISE3.ConcatenarNombres(cep.Nombre, cep.ApellidoPaterno, cep.ApellidoMaterno) as EmpleadoPreAutorizaCompleto
				,SISE3.ConcatenarNombres(cec.Nombre, cec.ApellidoPaterno, cec.ApellidoMaterno) as EmpleadoCancelaCompleto
				--,null
				--,null
				--,null
				,p.PreautorizadoSinFirma
				,p.FechaElaboracion
				,p.SintesisIA
				,p.SolicitaFirmaDG
				,p.Firmado
		FROM #Promociones p
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) on pa.AsuntoNeunId=p.AsuntoNeunId and pa.NumeroOrden=p.NumeroOrden and pa.NumeroRegistro=p.NumeroRegistro
				AND pa.YearPromocion=p.YearPromocion and pa.StatusArchivo=1 AND pa.ClaseAnexo = 0
		LEFT JOIN tbx_CatTiposAsunto ta ON p.CatTipoAsuntoId = ta.CatTipoAsuntoId AND p.TipoCuaderno = ta.CuadernoId and ta.Status=1
		LEFT JOIN PersonasAsunto pas WITH(NOLOCK) ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1 and pas.StatusReg =1
		LEFT JOIN Promovente pr WITH(NOLOCK) ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 and pr.AsuntoNeunId = p.AsuntoNeunId and pr.Estatus =1
		LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3 and aj.StatusReg =1
		LEFT JOIN CatEmpleados ea  ON ea.EmpleadoId = cast(aj.EmpleadoId as bigint) and ea.StatusRegistro=1
		LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
		LEFT JOIN CatEmpleados s ON s.EmpleadoId = p.Secretario and s.StatusRegistro=1
		LEFT JOIN SintesisAcuerdoAsunto sa  WITH(NOLOCK) on sa.AsuntoNeunId = p.AsuntoNeunId and sa.SintesisOrden = p.SintesisOrden and sa.StatusReg =1 --- Se relaciona para obtener la fecha de captura 
		LEFT JOIN SISE3.CAT_OrigenPromocion​ co on co.kIdOrigenPromocion = p.OrigenPromocion
		LEFT JOIN CatPromocion cpr ON cpr.CatalogoPromocionId=p.TipoContenido and cpr.StatusReg =1
		LEFT JOIN CatalogosElementosDescripcion con WITH(NOLOCK) ON con.CatalogoElementoDescripcionID = p.CatContenidoId and con.StatusRegistro =1
		LEFT JOIN CatEmpleados cea ON cea.EmpleadoId = p.EmpleadoIdAutoriza
		LEFT JOIN CatEmpleados cep ON cep.EmpleadoId = p.EmpleadoIdPreautoriza
		LEFT JOIN CatEmpleados cec ON cec.EmpleadoId = p.EmpleadoIdCancela
		LEFT JOIN CatOrganismos cto ON cto.CatOrganismoId=aj.CatOrganismoId and cto.StatusReg=1
		WHERE p.StatusReg=1
		AND p.CatOrganismoId=@pi_CatOrganismoId
		--AND (@Pendientes = 0 OR (@Pendientes = 1 AND (ISNULL(p.CatAutorizacionDocumentosId,0) <> 3 )))
		--AND [SISE3].[fnEstatusPromocion] (NULL , IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0), pa.NombreArchivo, p.OrigenPromocion, NULL) = 4
		--AND (CAST(p.FechaPresentacion AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE)
		--	 OR
		--	 CAST(p.FechaAlta AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE)
		--	)
		--OPTION (RECOMPILE)
        

		/* SE EJECUTA EL SEGUNDO SP QUE EXTRAE LA INFORMACION DE ACUERDO DE PROMOCIONES Y SE INSERTA EN LA TABLA TEMPORAL */
		--INSERT INTO @Tramites
		--([No_Exp], [TipoAsuntoDescripcion], [NumeroRegistro], [TipoPromocionDescripcion], [FechaRecibido], [NumeroOrden], [NombreTipoCuaderno],
		--[Promovente],[TipoContenidoDescripcion], [Contenido], [Copias], [Anexos], [Estado], [Mesa], [SecretarioDescripcion], [FechaAuto], [Plantilla], 
		--[AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], [NombreArchivo], [NombreCapDJ], [EstadoAutorizacion], [NumeroAlias], [ArchivoPromocion], 
		--[NombreOrigen], [EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza],[FechaAutoriza],[FechaPreAutoriza], [FechaCancela], [userNameCapDJ], [userNameSecretario], [FechaRecibido_F],
		--[FechaAuto_F],	[NombreDocumento], [YearPromocion], [TipoAsuntoId], [TipoCuadernoId], [NombreCorto] , [RutaArchivoNAS], [SintesisOrden], [TipoProcedimiento], [secretarioId],
		--[OrigenId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId],[GuidDocumento],
		--PromocionCompleta)
		--SELECT 
		--		p.AsuntoAlias As No_Exp
		--		,TipoAsuntoDescripcion = p.CatTipoAsunto
		--		,p.NumeroRegistro
		--		,TipoPromocionDescripcion = CASE ClasePromocion WHEN '1' THEN 'Escrito' ELSE 'Oficio' END       
		--		,CASE WHEN ISDATE(p.FechaPresentacion) = 1 THEN CONVERT(DATETIME,p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END) ELSE '' END  As FechaRecibido
		--		,p.NumeroOrden
		--		,dbo.funRecuperaCatalogoDependienteDescripcion(495,p.TipoCuaderno) as NombreTipoCuaderno
		--		,dbo.funNombreParte(TipoPromovente,isnull(ClasePromovente,1)) as Promovente
		--		,TipoContenidoDescripcion = ISNULL((SELECT CatalogoPromocionDescripcion FROM CatPromocion with(nolock) where CatalogoPromocionId=TipoContenido),'')
		--		,(select CatalogoElementoDescripcion from CatalogosElementosDescripcion with(nolock) where CatalogoElementoDescripcionID = p.CatContenidoId) as Contenido
		--		,ISNULL(p.[NumeroCopias],0) As Copias
		--		,ISNULL(p.[NumeroAnexos],0) As Anexos
		--		,isnull(dbo.fnDevuelveElementoCatalogo(p.EstadoPromocion),'Pendiente') as Estado        
		--		,Mesa = p.Mesa
		--		,SecretarioDescripcion =  SISE3.ConcatenarNombres(eas.Nombre,eas.ApellidoPaterno,eas.ApellidoMaterno)
		--		,sa.FechaAlta as FechaAuto
		--		,CAST(cp.CatPlantillaId AS VARCHAR(10)) + ' - ' + cp.NombrePlantilla As Plantilla
		--		,p.AsuntoNeunId
		--		,p.CatTipoAsuntoId
		--		,p.AsuntoDocumentoId
		--		,p.NombreArchivo+ p.ExtensionDocumento as NombreArchivo
		--		,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(p.CreadorId)
		--		,p.CatAutorizacionDocumentosId as EstadoAutorizacion
		--		,p.NumeroAlias
		--		,pa.NombreArchivo as ArchivoPromocion
		--		,NombreOrigen = ISNULL(co.sNombreOrigenPromocion,'SIN ORIGEN')
		--		,EmpleadoCancela = dbo.fnx_getUserName(p.EmpleadoIdCancela)
		--		,EmpleadoAutoriza = dbo.fnx_getUserName(p.EmpleadoIdAutoriza)
		--		,EmpleadoPreAutoriza = dbo.fnx_getUserName(p.EmpleadoIdPreautoriza)
		--		,FechaAutoriza = p.FechaAutoriza
		--		,FechaPreAutoriza = p.FechaPreAutoriza
		--		,FechaCancela = p.FechaCancela
		--		,userNameCapDJ = dbo.fnx_getUserName(p.CreadorId)
		--		,userNameSecretario = eas.UserName  --dbo.fnx_getUserName(p.Secretario)
		--		,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
		--		ELSE '' END As FechaRecibido_F
		--		,CONVERT(VARCHAR(10),p.FechaAlta,103) as FechaAuto_F
		--		,p.NombreDocumento
		--		,p.YearPromocion
		--		,TipoAsuntoId = p.CatTipoAsuntoId
		--		,TipoCuadernoId = p.TipoCuaderno
		--		,ta.nombreCorto
		--		,RutaArchivoNAS = ISNULL(pa.RutaArchivoNAS,0)
		--		,sa.SintesisOrden
		--		,p.TipoProcedimiento
		--		,p.secretario
		--		,p.OrigenPromocion
		--		,p.CreadorId
		--		,p.EmpleadoIdPreautoriza
		--		,p.EmpleadoIdAutoriza
		--		,p.EmpleadoIdCancela
		--		,p.uGuidDocumento GuidDocumento
		--		,CASE WHEN 
		--			p.TipoContenido < 1 OR 
		--			p.TipoContenido IS NULL OR
		--			pa.StatusArchivo <> 1 OR 
		--			p.TipoPromovente IS NULL OR 
		--			p.TipoPromovente = 0 
		--		THEN 0 
		--		ELSE 1 END
		--FROM #Promociones p WITH(NOLOCK)
		--LEFT JOIN PromocionArchivos pa WITH(NOLOCK) on pa.AsuntoNeunId=p.AsuntoNeunId and pa.NumeroOrden=p.NumeroOrden and pa.NumeroRegistro=p.NumeroRegistro
		--and pa.YearPromocion=p.YearPromocion and pa.StatusArchivo=1 AND pa.ClaseAnexo = 0
		--left join CatPlantillas cp ON cp.CatPlantillaId = p.CatPlantillaId
		--LEFT JOIN tbx_CatTiposAsunto ta ON p.CatTipoAsuntoId = ta.CatTipoAsuntoId AND p.TipoCuaderno = ta.CuadernoId
		--LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1
		--LEFT JOIN Promovente pr ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 and pr.AsuntoNeunId = p.AsuntoNeunId
		--LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
		--LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId
		--LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
		--LEFT JOIN CatEmpleados eas WITH(NOLOCK) ON eas.EmpleadoId = p.secretario
		--LEFT JOIN @Tramites ts ON  p.AsuntoNeunId= ts.AsuntoNeunId and p.NumeroRegistro = ts.NumeroRegistro
		--LEFT JOIN SintesisAcuerdoAsunto sa ON sa.AsuntoNeunId = p.AsuntoNeunId and sa.SintesisOrden = p.SintesisOrden
		--LEFT JOIN SISE3.CAT_OrigenPromocion​ co WITH(NOLOCK) on co.kIdOrigenPromocion = p.OrigenPromocion
		--WHERE p.StatusReg=1 
		--AND p.CatOrganismoId=@pi_CatOrganismoId
		--AND CAST(p.FechaAlta AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE)
		--AND ts.NumeroRegistro IS NULL
		----AND [SISE3].[fnEstatusPromocion] (NULL , IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0), pa.NombreArchivo, p.OrigenPromocion, NULL) = 4
		--ORDER BY 1
		
		/* SE ACTUALIZA EL CAMPO ORIGEN DE LA TEMPORAL PARA INDICAR QUE LA INFORMACION ES DE ACUERDOS SIN PROMOCIONES */
		UPDATE @Tramites 
		SET Origen = 'SIN ORIGEN'
		WHERE Origen IS NULL

		/*Temporal carga de catalogos de Tipos de Acuerdos*/
		CREATE TABLE #Catalogos (ID INT, Descripcion varchar (250), elementos int)
		INSERT INTO #Catalogos
		EXEC usp_catalogosSel 496, 0, 0

		/*Cargar Asuntos Documentos que no tienen promoción*/
		CREATE TABLE #MaxSec
		(AsuntoNeunId BIGINT, 
		Secretario INT,
		Mesa VARCHAR(100),
		Id int
		)
		SELECT a.AsuntoAlias 
		,cto.Descripcion As TipoAsuntoDescripcion
		,Mesa = dbo.fnx_getValorPorNeunPorDescripcion(a.AsuntoNeunId,'Mesa')
		,SecretarioDescripcion = dbo.fnx_getValorPorNeunPorDescripcion(a.AsuntoNeunId,'Secretario') 
		,a.AsuntoNeunId
		,a.AsuntoId
		,ad.AsuntoDocumentoId
		,ad.NombreArchivo+ ad.ExtensionDocumento as NombreArchivo
		,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(ad.CreadorId)
		,ad.CatAutorizacionDocumentosId as EstadoAutorizacion
		,a.NumeroAlias
		,ad.NombreArchivo as ArchivoPromocion
		,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
		,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
		,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
		,FechaAutoriza = ad.FechaAutoriza
		,FechaPreAutoriza = ad.FechaPreAutoriza
		,FechaCancela = ad.FechaCancela
		,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
		,CONVERT(VARCHAR(10),ad.FechaAlta,103) as FechaAuto_F
		,ad.NombreDocumento
		,TipoAsuntoId = cto.CatTipoAsuntoId
		,FechaRecibido = ad.FechaAlta
		,ad.SintesisOrden
		,a.TipoProcedimiento
		,ad.TipoCuaderno
		,dbo.funRecuperaCatalogoDependienteDescripcion(527,ad.TipoCuaderno) as NombreTipoCuaderno
		,p.OrigenPromocion
		,ad.CreadorId
		,ad.EmpleadoIdPreautoriza
		,ad.EmpleadoIdAutoriza
		,ad.EmpleadoIdCancela
		,ad.uGuidDocumento GuidDocumento
		--,ISNULL((SELECT Descripcion FROM #Catalogos with(nolock) where ID=ad.CatContenidoId),'') AS Contenido
		,ad.CatContenidoId
		,ta.NombreCorto
		,EmpleadoAutorizaCompleto = SISE3.[ObtieneNombreEmpleado]( ad.EmpleadoIdAutoriza, NULL)
		,EmpleadoPreAutorizaCompleto = SISE3.[ObtieneNombreEmpleado]( ad.EmpleadoIdPreautoriza, NULL)
		,EmpleadoCancelaCompleto = SISE3.[ObtieneNombreEmpleado]( ad.EmpleadoIdCancela, NULL)
		,ada.PreautorizadoSinFirma
		,ada.FechaElaboracion
		,ada.SintesisIA
		,ada.SolicitaFirmaDG
		,ad.Firmado
		INTO #TempSinPromocion
		FROM AsuntosDocumentos ad  WITH(NOLOCK)
		--JOIN Asuntos a WITH(NOLOCK) ON  a.AsuntoNeunId= ad.AsuntoNeunId
		CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		INNER JOIN CatOrganismos ct on a.CatOrganismoId =ct.CatOrganismoId
		INNER JOIN CatTiposAsunto cto on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN Promociones p WITH (NOLOCK) 
		ON a.AsuntoNeunId= p.AsuntoNeunId 
		--AND ad.AsuntoDocumentoId= p.AsuntoDocumentoId 
		AND ad.sintesisOrden = p.sintesisOrden
		and p.statusreg =1
		LEFT JOIN SintesisAcuerdoAsunto si  WITH(NOLOCK) ON si.AsuntoNeunId = ad.AsuntoNeunId and si.SintesisOrden = ad.SintesisOrden and si.statusreg =1
		LEFT JOIN SISE3.CAT_OrigenPromocion​ co on co.kIdOrigenPromocion = p.OrigenPromocion
		LEFT JOIN tbx_CatTiposAsunto ta ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId AND cast(ad.TipoCuaderno as int) = ta.CuadernoId  and ta.Status=1
		LEFT JOIN SISE3.AsuntosdocumentosAdicional ada WITH (NOLOCK) ON ada.AsuntoNeunId = ad.AsuntoNeunId
										AND ada.AsuntoDocumentoId = ad.AsuntoDocumentoId
		WHERE
		ad.StatusReg=1 AND CT.statusreg =1 and cto.statusreg =1
		AND a.CatOrganismoId=@pi_CatOrganismoId
		--AND ad.CatContenidoId not in (3969)
		AND ad.FechaAlta >= @pi_FechaPresentacionIni 
		and ad.FechaAlta <= DATEADD(DAY,1,@pi_FechaPresentacionFin)
		AND p.AsuntoDocumentoId IS NULL
		/**************** GGHH - Cambio pendientes ************************/
		AND (@Pendientes = 0 OR (@Pendientes = 1 AND (ISNULL(ad.CatAutorizacionDocumentosId,0) <> 3 )))
		/**************** GGHH - FIN Cambio pendientes ************************/

		SELECT AsuntoNeunId
		INTO #Asuntos
		FROM ( SELECT DISTINCT AsuntoNeunId FROM #TempSinPromocion ) tbl;

		WITH PromocionesOptimizada AS (
            SELECT 
                  p.AsuntoNeunId, 
                  p.Secretario,
                  p.Mesa,
                  p.FechaPresentacion,
                  p.FechaAlta,
                  ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId ORDER BY p.FechaPresentacion DESC, p.FechaAlta DESC) AS rn
            FROM Promociones p WITH(NOLOCK)
            INNER JOIN #Asuntos a ON p.AsuntoNeunId = a.AsuntoNeunId
                                   )
             INSERT INTO #MaxSec
                SELECT 
                      AsuntoNeunId, 
                      Secretario, 
                      Mesa,
	                  1 AS id
                FROM PromocionesOptimizada
                WHERE rn = 1;
				
		INSERT INTO @Tramites
			([No_Exp], [TipoAsuntoDescripcion] , [Mesa], [SecretarioDescripcion], [AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], 
			[NombreArchivo], [NombreCapDJ], [EstadoAutorizacion], [NumeroAlias], [ArchivoPromocion], 
			[EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza], [FechaAutoriza],[FechaPreAutoriza], [FechaCancela], [userNameCapDJ], 
			[FechaAuto_F],	[NombreDocumento], [TipoAsuntoId],FechaRecibido,[FechaAuto], [SintesisOrden],[TipoProcedimiento],TipoCuadernoId, NombreTipoCuaderno ,
			[secretarioId], [OrigenId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId], [GuidDocumento], Contenido,
			PromocionCompleta, [userNameSecretario],NombreCorto, EmpleadoAutorizaCompleto, EmpleadoPreAutorizaCompleto, EmpleadoCancelaCompleto, PreautorizadoSinFirma, FechaElaboracion, SintesisIA, SolicitaFirmaDG, Firmado)

		SELECT ad.AsuntoAlias 
		,ad.TipoAsuntoDescripcion
		,ISNULL(m.Mesa,ad.Mesa)
		,SecretarioDescripcion =  SISE3.ConcatenarNombres(eas.Nombre,eas.ApellidoPaterno,eas.ApellidoMaterno)
		,ad.AsuntoNeunId
		,ad.AsuntoId
		,ad.AsuntoDocumentoId
		,ad.NombreArchivo
		,ad.NombreCapDJ
		,ad.EstadoAutorizacion
		,ad.NumeroAlias
		,ad.NombreArchivo
		,ad.EmpleadoCancela 
		,ad.EmpleadoAutoriza 
		,ad.EmpleadoPreAutoriza 
		,ad.FechaAutoriza 
		,ad.FechaPreAutoriza 
		,ad.FechaCancela
		,ad.userNameCapDJ 
		,ad.FechaAuto_F
		,ad.NombreDocumento
		,ad.TipoAsuntoId
		,ad.FechaRecibido
		,ISNULL(sa.FechaActualizacion, sa.FechaAlta)
		,ad.SintesisOrden
		,ad.TipoProcedimiento
		,ad.TipoCuaderno
		,ad.NombreTipoCuaderno
		,m.Secretario
		,ad.OrigenPromocion
		,ad.CreadorId
		,ad.EmpleadoIdPreautoriza
		,ad.EmpleadoIdAutoriza
		,ad.EmpleadoIdCancela
		,ad.GuidDocumento
		,ISNULL(c.Descripcion,'') AS Contenido
		,1
		,eas.UserName
		,ad.NombreCorto
		,ad.EmpleadoAutorizaCompleto
		,ad.EmpleadoPreAutorizaCompleto
		,ad.EmpleadoCancelaCompleto
		,ad.PreautorizadoSinFirma
		,ad.FechaElaboracion
		,ad.SintesisIA
		,ad.SolicitaFirmaDG
		,ad.Firmado
		FROM #TempSinPromocion ad 
		LEFT JOIN #MaxSec m ON  m.AsuntoNeunId= ad.AsuntoNeunId AND m.id = 1
		LEFT JOIN CatEmpleados eas WITH(NOLOCK) ON eas.EmpleadoId = cast(m.Secretario as bigint) and eas.StatusRegistro=1
		LEFT JOIN SintesisAcuerdoAsunto sa ON sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden and sa.statusreg =1
		LEFT JOIN #Catalogos c ON c.ID = ad.CatContenidoId


		SELECT DISTINCT 
					p.No_Exp,
					p.TipoAsuntoDescripcion, 
					p.NombreOrigen,
					p.NumeroRegistro,
					p.NumeroOrden,
					p.ArchivoPromocion,
					p.FechaRecibido,
					TipoContenidoDescripcion = ISNULL(p.TipoContenidoDescripcion,''),
					SecretarioDescripcion = ISNULL(LTRIM(RTRIM(p.SecretarioDescripcion)),''),
					p.NombreTipoCuaderno,
					[Promovente] = ISNULL(LTRIM(RTRIM(REPLACE(p.[Promovente],'( ','('))),''),
					FechaAuto = p.FechaAuto,
					Plantilla = ISNULL(p.Plantilla,''),
					Mesa = ISNULL(p.Mesa,''),
					NombreCapDJ = ISNULL(LTRIM(RTRIM(p.NombreCapDJ)),''),
					NombreDocumento = ISNULL(p.NombreDocumento,''),
					ISNULL(p.EstadoAutorizacion,0)EstadoAutorizacion,
					ISNULL(cad.DescripcionAutorizacion,'')EstadoAutorizacionDescripcion,
					p.EmpleadoPreAutoriza,
					p.EmpleadoAutoriza,
					p.EmpleadoCancela,
					p.AsuntoNeunId,
					p.AsuntoId,
					p.AsuntoDocumentoId, 
					p.Origen,
					FechaPreAutoriza = p.FechaPreAutoriza, 
					FechaAutoriza = p.FechaAutoriza,
					FechaCancela = p.FechaCancela, 
					UserNameSecretario = LOWER(p.userNameSecretario),
					UserNameOficial = LOWER(p.userNameCapDJ),
					NumeroAlias = p.NumeroAlias,
					ISNULL(FechaRecibido_F,'')FechaRecibido_F ,
					ISNULL(FechaAuto_F,'')FechaAuto_F,
					ISNULL(NombreArchivo,'')NombreArchivo,
					OrigenCorto = CASE p.Origen WHEN  'SISE' THEN 'SISE' WHEN  'FESE' THEN 'FESE'  WHEN 'San Lazaro' THEN 'SL' WHEN  'VET' THEN 'VET' WHEN  'Oficialía de Partes Virtual' THEN 'OPV' WHEN  'Acuerdo sin Promociones' THEN 'S/P' ELSE 'S/O' END
					,p.YearPromocion
					,EmpleadoElimina = ISNULL(bap.Empleado,'')
					,UserNameElimina = ISNULL(bap.UserName,'')
					,FechaElimina = ISNULL(CONVERT (VARCHAR(15), bap.FechaAlta,103) + ' ' + CONVERT(VARCHAR(5),CONVERT(TIME,bap.FechaAlta)),'')
					, TipoAsuntoId
					,TipoCuadernoId
					,NombreCorto = ISNULL(NombreCorto,'')
					,RutaArchivoNAS
					,SintesisOrden
					,TipoProcedimiento
					,p.secretarioId
					,p.OrigenId
					,p.CapturoId
					,p.PreautorizoId
					,p.AutorizoId
					,p.CanceloId
					,p.Contenido
					,p.GuidDocumento
					,p.PromocionCompleta
					,Notificaciones = (	
                                   select count(1) 
								   from DeterminacionesJudiciales ad1 with(nolock)
                                   inner join (
                                                 SELECT * FROM (
                                                                SELECT 
																      ROW_NUMBER() OVER(PARTITION BY ne.AsuntoNeunId, nep.PersonaId ORDER BY ne.Fechaalta DESC) AS Num
                                                                      , nep.PersonaId, NULL AS PromoventeId , nep.TipoConstanciaId, nep.FechaNotificacion, nep.ActuarioId, nep.TipoNotificacion
                                                                      , nep.NotElecId, nep.AsuntoId, nep.AsuntoNeunId, nep.SintesisOrden, nep.StatusReg
                                                                      , pas.CatTipoPersonaId, pas.Nombre, pas.APaterno, pas.AMaterno, pas.AsuntoId AS AsuntoParteId, pas.PersonaId AS PersonaParteId
                                                                      , pas.CatCaracterPersonaAsuntoId, pas.DenominacionDeAutoridad
                                                                      , nea.IdUsuarioAsigno, nea.FechaUsuarioAsigno
                                                                FROM NotificacionElectronica_Personas nep WITH(NOLOCK)
                                                                INNER JOIN NotificacionElectronica ne WITH(NOLOCK) ON ne.AsuntoNeunId = nep.AsuntoNeunId AND ne.SintesisOrden = nep.SintesisOrden
                                                                INNER JOIN PersonasAsunto  pas WITH(NOLOCK) ON   nep.AsuntoNeunId = pas.AsuntoNeunId AND cast(nep.PersonaId as bigint) = pas.PersonaId
                                                                LEFT JOIN NotificacionElectronica_AsignaActuario nea WITH(NOLOCK)
                                                                ON nep.AsuntoNeunId = nea.AsuntoNeunId AND nep.SintesisOrden = nea.SintesisOrden AND nep.NotElecId = nea.NotElecId
                                                                WHERE ne.AsuntoNeunId = p.AsuntoNeunId
                                                                AND ne.SintesisOrden = p.SintesisOrden
                                                                AND nep.StatusReg IN(1,2) --AGA

                                                                UNION

                                                                SELECT 
																       ROW_NUMBER() OVER(PARTITION BY ne.AsuntoNeunId, prm.PromoventeId ORDER BY ne.Fechaalta DESC) AS Num
                                                                       , nep.PersonaId, prm.PromoventeId , nep.TipoConstanciaId, nep.FechaNotificacion, nep.ActuarioId, nep.TipoNotificacion
                                                                       , nep.NotElecId, nep.AsuntoId, nep.AsuntoNeunId, nep.SintesisOrden, nep.StatusReg
                                                                       , 1 AS CatTipoPersonaId
                                                                       , prm.Nombre, prm.APaterno, prm.AMaterno
                                                                       , prm.AsuntoId AS AsuntoParteId, prm.PersonaId AS PersonaParteId
                                                                       , NULL AS CatCaracterPersonaAsuntoId, NULL AS DenominacionDeAutoridad
  --                                                                   , nep.IdUsuarioAsigno,nep.FechaUsuarioAsigno
                                                                       , nea.IdUsuarioAsigno,nea.FechaUsuarioAsigno
                                                                FROM NotificacionElectronica_Personas nep WITH(NOLOCK)
                                                                INNER JOIN NotificacionElectronica ne WITH(NOLOCK) ON ne.AsuntoNeunId = nep.AsuntoNeunId AND ne.SintesisOrden = nep.SintesisOrden
                                                                INNER JOIN promovente  prm WITH(NOLOCK) ON   nep.AsuntoNeunId = prm.AsuntoNeunId AND nep.PromoventeId = prm.PromoventeId
                                                                LEFT JOIN NotificacionElectronica_AsignaActuario nea WITH(NOLOCK)
                                                                ON nep.AsuntoNeunId = nea.AsuntoNeunId AND nep.SintesisOrden = nea.SintesisOrden AND nep.NotElecId = nea.NotElecId
                                                                WHERE ne.AsuntoNeunId = p.AsuntoNeunId
                                                                AND ne.SintesisOrden = p.SintesisOrden
                                                                AND nep.StatusReg IN(1,2) --AGA

                                               ) AS Notificaciones
                                   WHERE Notificaciones.Num = 1) nepp on ad1.AsuntoNeunId = nepp.AsuntoNeunId and ad1.SintesisOrden=nepp.SintesisOrden and ad1.statusreg = 1
				             	 )
					,p.EmpleadoAutorizaCompleto
					,p.EmpleadoPreAutorizaCompleto
					,p.EmpleadoCancelaCompleto
					,p.PreautorizadoSinFirma
					,p.FechaElaboracion
					,p.SintesisIA
					,p.SolicitaFirmaDG
					,p.Firmado
				INTO #TramiteFinal
		FROM @Tramites p
		LEFT JOIN CatAutorizacionesDocumentos cad ON p.EstadoAutorizacion = cad.CatAutorizacionDocumentosId AND cad.StatusReg=1
		LEFT JOIN uvix_BitacoraAcuerdoPromocion bap WITH(NOLOCK) ON p.AsuntoNeunId = bap.AsuntoNeunId 
				AND p.NumeroOrden = bap.NumeroOrden
				AND p.YearPromocion = bap.YearPromocion
				AND bap.Operacion = 1
				AND bap.Status = 1


           SET @MuestraSentencia = ISNULL((select MostrarSentencia from SISE3.ConfiguracionOrganismo where Catorganismoid = @pi_CatOrganismoId),0)

			/* REGRESA LA INFORMACIÖN NECESARIA PARA EL TABLERO DE TRAMITE */
		IF (@TipoOrganoAsuntosJuridicos = 1)
	    BEGIN
			
			SELECT * FROM (
			SELECT 
					p.No_Exp,
					p.TipoAsuntoDescripcion, 
					ISNULL((select  TOP 1 ISNULL(CO.NombreOficial ,'') 
                       from AsuntosRelacionados AR WITH(NOLOCK)
                       INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
                       INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
                       INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
                       WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = p.AsuntoNeunId ORDER BY AR.IdAsuntoRela DESC),'') AS NombreOrigen,


					ISNULL((select  TOP 1 isnull( (A.AsuntoAlias + ' - ' + (SELECT X.Descripcion FROM CatTiposAsunto X WHERE X.CatTipoAsuntoId = A.CatTipoAsuntoId)),'')
                       from AsuntosRelacionados AR WITH(NOLOCK)
                       INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
                       INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
                       INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
                       WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = p.AsuntoNeunId ORDER BY AR.IdAsuntoRela DESC),'') as expedienteOrigen,

					p.NumeroRegistro,
					p.NumeroOrden,
					p.ArchivoPromocion,
					p.FechaRecibido,
					TipoContenidoDescripcion = ISNULL(p.TipoContenidoDescripcion,''),
					SecretarioDescripcion = ISNULL(LTRIM(RTRIM(p.SecretarioDescripcion)),''),
					p.NombreTipoCuaderno,
					Promovente = ISNULL(LTRIM(RTRIM(REPLACE(p.Promovente,'( ','('))),''),
					FechaAuto = p.FechaAuto,
					Plantilla = ISNULL(p.Plantilla,''),
					Mesa = ISNULL(p.Mesa,''),
					NombreCapDJ = ISNULL(LTRIM(RTRIM(p.NombreCapDJ)),''),
					NombreDocumento = ISNULL(p.NombreDocumento,''),
					p.EstadoAutorizacion,
					p.EstadoAutorizacionDescripcion,
					p.EmpleadoPreAutoriza,
					p.EmpleadoAutoriza,
					p.EmpleadoCancela,
					p.AsuntoNeunId,
					p.AsuntoId,
					p.AsuntoDocumentoId, 
					ISNULL((select  TOP 1 ISNULL(CO.CatOrganismoId ,0) 
                       from AsuntosRelacionados AR WITH(NOLOCK)
                       INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
                       INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
                       INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
                       WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = p.AsuntoNeunId ORDER BY FechaOrigen),'') AS Origen,
					FechaPreAutoriza,
					FechaAutoriza,
					FechaCancela ,
					UserNameSecretario ,
					UserNameOficial ,
					NumeroAlias ,
					--Cancela ,
					--Preautoriza ,
					--Autoriza ,
					FechaRecibido_F ,
					FechaAuto_F,
					NombreArchivo,
					OrigenCorto 
					,p.YearPromocion
					,EmpleadoElimina 
					,UserNameElimina 
					,FechaElimina 
					, TipoAsuntoId
					,TipoCuadernoId
					,NombreCorto
					,RutaArchivoNAS
					,Estado = 	IIF ((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL), 1,--Sin Acuerdo
									IIF (EstadoAutorizacion  IN (4,8,9),5, --Cancelados
										IIF (EstadoAutorizacion NOT IN (2,3,4,8,9) AND NOT((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL)), 2, --Con acuerdo
											IIF (EstadoAutorizacion  IN (2),3, -- Pre autorizados
												IIF (EstadoAutorizacion  IN (3),4,0))))) --Autorizados
					,SintesisOrden
					,TipoProcedimiento
					,[secretarioId]
					,ISNULL((select  TOP 1 ISNULL(CO.CatOrganismoId ,0) 
                       from AsuntosRelacionados AR WITH(NOLOCK)
                       INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
                       INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
                       INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
                       WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = p.AsuntoNeunId ORDER BY FechaOrigen),'') AS [OrigenId]
					,[CapturoId]
					,[PreautorizoId]
					,[AutorizoId]
					,[CanceloId]
					,CanceloCuenta = NULL-- SISE3.fnCuentaCancelacionesAcuerdo(p.AsuntoNeunId, p.AsuntoDocumentoID)
					,ISNULL(p.Contenido,'') AS Contenido
					,p.GuidDocumento
                    ,ISNULL(ofi.OficiosFirmados,0) OficiosFirmados
					,p.PromocionCompleta
					,Notificaciones
					,p.EmpleadoAutorizaCompleto
					,p.EmpleadoPreAutorizaCompleto
					,p.EmpleadoCancelaCompleto
					,p.PreautorizadoSinFirma
					,p.FechaElaboracion
					,p.SintesisIA
					,ISNULL(p.SolicitaFirmaDG, 0) SolicitaFirmaDG
					,[SISE3].[fnFechaVencimientoAJ](p.AsuntoNeunId,p.TipoCuadernoId,p.TipoContenidoDescripcion) AS FechaVencimiento
			        ,[SISE3].[fnFechaVencimientoAJ_V2](p.AsuntoNeunId,p.TipoCuadernoId,p.TipoContenidoDescripcion) AS DiasFechaVencimiento
					,p.Firmado
			FROM #TramiteFinal p
            LEFT JOIN (SELECT 
                    CASE 
                        WHEN COUNT(uGuid) = SUM(CONVERT(int, Firmado)) THEN 1
                        ELSE 0
                    END AS OficiosFirmados,
                    AsuntoDocumentoId,
                    AsuntoNeunId
                FROM 
                    SISE3.EstadoOficio
                WHERE
                    Estatus = 1
                GROUP BY
                    AsuntoDocumentoId,
                    AsuntoNeunId) AS ofi
            ON ofi.AsuntoDocumentoId = p.AsuntoDocumentoId
            AND ofi.AsuntoNeunId = p.AsuntoNeunId
			) AS X
			WHERE (@MuestraSentencia = 1 OR ( @MuestraSentencia = 0 AND X.Contenido <> 'Sentencia' ))
			AND (CAST(CONVERT(DATETIME,FechaAuto_F,103) AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE) 
			OR asuntoDocumentoId = 0)
		END
		ELSE
		BEGIN
			
			SELECT * FROM (
			SELECT 
					p.No_Exp,
					p.TipoAsuntoDescripcion, 
					ISNULL(p.NombreOrigen,'SIN ORIGEN') AS NombreOrigen,
					p.NumeroRegistro,
					p.NumeroOrden,
					p.ArchivoPromocion,
					p.FechaRecibido,
					TipoContenidoDescripcion = ISNULL(p.TipoContenidoDescripcion,''),
					SecretarioDescripcion = ISNULL(LTRIM(RTRIM(p.SecretarioDescripcion)),''),
					p.NombreTipoCuaderno,
					Promovente = ISNULL(LTRIM(RTRIM(REPLACE(p.Promovente,'( ','('))),''),
					FechaAuto = p.FechaAuto,
					Plantilla = ISNULL(p.Plantilla,''),
					Mesa = ISNULL(p.Mesa,''),
					NombreCapDJ = ISNULL(LTRIM(RTRIM(p.NombreCapDJ)),''),
					NombreDocumento = ISNULL(p.NombreDocumento,''),
					p.EstadoAutorizacion,
					p.EstadoAutorizacionDescripcion,
					p.EmpleadoPreAutoriza,
					p.EmpleadoAutoriza,
					p.EmpleadoCancela,
					p.AsuntoNeunId,
					p.AsuntoId,
					p.AsuntoDocumentoId, 
					p.Origen,
					FechaPreAutoriza,
					FechaAutoriza,
					FechaCancela ,
					UserNameSecretario ,
					UserNameOficial ,
					NumeroAlias ,
					--Cancela ,
					--Preautoriza ,
					--Autoriza ,
					FechaRecibido_F ,
					FechaAuto_F,
					NombreArchivo,
					OrigenCorto 
					,p.YearPromocion
					,EmpleadoElimina 
					,UserNameElimina 
					,FechaElimina 
					, TipoAsuntoId
					,TipoCuadernoId
					,NombreCorto
					,RutaArchivoNAS
					,Estado = 	IIF ((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL), 1,--Sin Acuerdo
									IIF (EstadoAutorizacion  IN (4,8,9),5, --Cancelados
										IIF (EstadoAutorizacion NOT IN (2,3,4,8,9) AND NOT((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL)), 2, --Con acuerdo
											IIF (EstadoAutorizacion  IN (2),3, -- Pre autorizados
												IIF (EstadoAutorizacion  IN (3),4,0))))) --Autorizados
					,SintesisOrden
					,TipoProcedimiento
					,[secretarioId]
					,[OrigenId]
					,[CapturoId]
					,[PreautorizoId]
					,[AutorizoId]
					,[CanceloId]
					,CanceloCuenta = NULL-- SISE3.fnCuentaCancelacionesAcuerdo(p.AsuntoNeunId, p.AsuntoDocumentoID)
					,ISNULL(p.Contenido,'') AS Contenido
					,p.GuidDocumento
                    ,ISNULL(ofi.OficiosFirmados,0) OficiosFirmados
					,p.PromocionCompleta
					,Notificaciones
					,p.EmpleadoAutorizaCompleto
					,p.EmpleadoPreAutorizaCompleto
					,p.EmpleadoCancelaCompleto
					,p.PreautorizadoSinFirma
					,p.FechaElaboracion
					,p.SintesisIA
					,p.SolicitaFirmaDG
					,p.Firmado
			FROM #TramiteFinal p
            LEFT JOIN (SELECT 
                    CASE 
                        WHEN COUNT(uGuid) = SUM(CONVERT(int, Firmado)) THEN 1
                        ELSE 0
                    END AS OficiosFirmados,
                    AsuntoDocumentoId,
                    AsuntoNeunId
                FROM 
                    SISE3.EstadoOficio
                WHERE
                    Estatus = 1
                GROUP BY
                    AsuntoDocumentoId,
                    AsuntoNeunId) AS ofi
            ON ofi.AsuntoDocumentoId = p.AsuntoDocumentoId
            AND ofi.AsuntoNeunId = p.AsuntoNeunId
			) AS X
			WHERE (@MuestraSentencia = 1 OR ( @MuestraSentencia = 0 AND X.Contenido <> 'Sentencia' ))
			AND (CAST(CONVERT(DATETIME,FechaAuto_F,103) AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE) 
			OR asuntoDocumentoId = 0)

        END



		FIN:
		IF OBJECT_ID('tempdb..#Asuntos') IS NOT NULL
			DROP TABLE #Asuntos
		IF OBJECT_ID('tempdb..#MaxSec') IS NOT NULL
			DROP TABLE #MaxSec
		IF OBJECT_ID('tempdb..#Catalogos') IS NOT NULL
			DROP TABLE #Catalogos
		IF OBJECT_ID('tempdb..#TempSinPromocion') IS NOT NULL
			DROP TABLE #TempSinPromocion
        IF OBJECT_ID('tempdb..#Promociones') IS NOT NULL
			DROP TABLE #Promociones
		IF OBJECT_ID('tempdb..#TramiteFinal') IS NOT NULL
			DROP TABLE #TramiteFinal
		IF OBJECT_ID('tempdb..#PromosFiltradas') IS NOT NULL
			DROP TABLE #PromosFiltradas
END