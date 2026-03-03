SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** 22/08/2023                 ******/
/****** Proyecto: SISE3       ******/
/****** Autor: Christian Araujo - MS  ******/
/****** Objetivo: Carga de pantalla promociones uniendo Promociones, Promociones electrónicas ******/
/****** Demandas electrónicas y Comunicaciones oficiales******/
/****** EXEC SISE3.[pcTableroPromociones] 1494, 1000,1,0,  '2024-01-25', '2024-01-31' ,NULL,NULL,'','',0,0,NULL,NULL,NULL *****/

CREATE OR ALTER PROCEDURE [SISE3].[pcTableroPromociones] (
--DECLARE
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA EL TAMAÑO DE PAGINACIÓN DE REGISTROS  
	@pi_TamanoPagina INT = NULL,
	--REPRESENTA EL NUMERO DE PÁGINA DE LA PAGINACIÓN
	@pi_NumeroPagina INT,
	-- REPRESENTA EL IDENTIFICADOR DEL EXPEDIENTE - PUEDE LLEGAR NULA
	@pi_AsuntoNeunId BIGINT = NULL,
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATE = NULL,
	-- REPRESENTA EL IDENTITICADOR DEL EMPLEADO - PUEDE LLEGAR NULA
	@pi_UsuariId INT = NULL,
	-- REPRESENTA LA BUSQUEDA DE PROMOCIONES CON(1) o SIN ACUERTO(0) - PUEDE LLEGAR NULA
	@pi_SinConAcuerdo BIT = NULL,
	-- Recibe valor para búsqueda en los campos de texto, PUEDE SER NULO
	@pi_Texto VARCHAR(MAX) = NULL,
	-- Recibe valor para ordenamiento de la página, PUEDE SER NULO, si es nulo ordena por fecha, de lo contrario por el campo recibido
	@pi_OrdenarPor VARCHAR(128) = NULL,
	-- Recibe configuración de ordenamiento Ascendente o Descendente? 1=Descendente 0=Ascendente
	@pi_TipoOrden INT = NULL,
	--Recibe parámetro del tipo de filtro 0=VerTodas, 1=Sin Captura, 2=Capturadas, 4=Asignadas
	@pi_FiltroTipo INT = 0,
	--Recibe origen id
	@pi_Origen VARCHAR(50) =NULL,
	--Recibe Asignado id
	@pi_Asignado BIGINT =NULL,
	--Recibe Capturo id
	@pi_Capturo VARCHAR(250) =NULL
	)
AS

	/*SET @pi_CatOrganismoId = 1532	 --1010--661--1494 Con origen OCC -- 1532 CON IO
	SET @pi_FechaPresentacionIni = '01/01/2021'
	SET @pi_FechaPresentacionFin = '01/01/2023'
	SET @pi_TamanoPagina  = 1000
	SET @pi_NumeroPagina = 1
	SET @pi_Texto = 'Pri'
	SET @pi_OrdenarPor = 'Secretario'
	SET @pi_TipoOrden = 0
	SET @pi_FiltroTipo = 0*/
	--Declaro variables que se utilizan en el select final
	DECLARE @TOTAL AS INT
	DECLARE @SinCaptura INT
	DECLARE @Capturadas INT
	DECLARE @Asignadas INT

	DECLARE @UserName VARCHAR(250) 
	
	--LIMPIO VARIABLE DE ORDER BY PARA REMOVER ESPACIOS EN BLANCO
	IF @pi_OrdenarPor IS NOT NULL
	BEGIN
		SET @pi_OrdenarPor = ltrim(rtrim(@pi_OrdenarPor))
	END
	-- SI LA FECHA INICIAL ES NULA, SE ASIGNA EL VALOR DEL DÍA
	IF @pi_FechaPresentacionIni IS NULL
	BEGIN
		SET @pi_FechaPresentacionIni = convert(date,getdate())
	END
	-- SI LA FECHA FIN ES NULA SE ASIGNA EL VALOR DE LA FECHA DE INICIO 
	IF @pi_FechaPresentacionFin IS NULL
	BEGIN
		SET @pi_FechaPresentacionFin = ISNULL(@pi_FechaPresentacionFin,@pi_FechaPresentacionIni)
	END

	--Validar Filtros existentes
	IF @pi_FiltroTipo NOT IN (1,2,4)
	BEGIN
		SET @pi_FiltroTipo = 0
	END

	--Obtener el UserName por medio del EmpleadoId
	IF @pi_Capturo IS NOT NULL
	BEGIN
		SET @UserName = (Select top 1 UserName from CatEmpleados where EmpleadoId=convert(bigint,trim(@pi_Capturo)))
	END


	DECLARE @Promociones SISE3.Promociones_type
	/***** PROMOCIONES ****/
	INSERT INTO @Promociones
	SELECT *
	FROM (
	SELECT	No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,
			a.TipoProcedimiento,
			--Validar con Gemma
			c.Cuaderno,
			--etl.TipoCuadernoDesc as Cuaderno,
			p.NumeroRegistro,
			o.sNombreOrigenPromocion OrigenPromocion,
			SecretarioNombre = SISE3.ConcatenarNombres(s.Nombre,s.ApellidoPaterno,s.ApellidoMaterno),
			SecretarioId = p.Secretario,
			s.UserName,
			Mesa = p.Mesa,
			(p.FechaPresentacion+ p.HoraPresentacion) as FechaPresentacion,
			TipoPromociones = CASE p.ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END,
			Contenido = ISNULL(cp.CatalogoPromocionDescripcion,''),
			Promovente = ISNULL(
				CASE 
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid = 1 THEN SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid <> 1 THEN pas.DenominacionDeAutoridad
					WHEN ISNULL(p.ClasePromovente,1) =2 THEN SISE3.ConcatenarNombres(pr.Nombre, pr.APaterno,pr.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) =3 THEN SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 4 THEN ajo.AJONombre
					END,''),
			IdPromovente = ISNULL(
				CASE ISNULL(p.ClasePromovente,1) 
					WHEN 1 THEN pas.PersonaId
					WHEN 2 THEN pr.PromoventeId
					WHEN 3 THEN ea.EmpleadoId
					WHEN 4 THEN ajo.AJOId
					END,''),
			ClasePromoventeDescripcion = CASE ISNULL(ClasePromovente,1) 
				WHEN 1 THEN 'Partes'
				WHEN 2 THEN 'Promovente'
				WHEN 3 THEN 'Autoridad Judicial'
				WHEN 4 THEN  'Autoridad judicial'
				ELSE ''
				END,
			NumeroCopias = ISNULL(p.NumeroCopias,0),
			NumeroAnexos = ISNULL(p.NumeroAnexos,0),
			Registrada = 1,
			ConArchivo = IIF(pa.AsuntoNeunId IS NULL, IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0),1),
			EsDemanda = 0,
			OrigenPromocionId = p.OrigenPromocion,
			Folio = 0,
			EsPromocionE = IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0),
			ad.CatAutorizacionDocumentosId,
			pa.NombreArchivo,
			Origen = IIF(p.OrigenPromocion IN (6,14,22,5,15,29),p.OrigenPromocion,0),
			NombreOrigen = CASE ISNULL(p.OrigenPromocion,0) 
				WHEN 0 THEN 'Promoción Física'
				WHEN 6 THEN 'Promoción Electrónica'
				WHEN 5 THEN  'Demanda Electrónica'
				WHEN 29 THEN  'Comunicación Oficial'
				WHEN 14 THEN 'Promoción Electrónica de Interconexión'
				WHEN 22 THEN 'Promoción Electrónica de Interconexión entre Órganos Jurisdiccionales'				
				WHEN 15 THEN  'Demanda Electrónica Interconexión'				
				ELSE ''
				END,
			Fojas = (SELECT TOP 1 Fojas
						From PromocionArchivos pa2 
						where pa2.AsuntoNeunId = p.AsuntoNeunId
						AND pa2.CatOrganismoId = p.CatOrganismoId 
						AND pa2.NumeroOrden = p.NumeroOrden
						--AND pa2.Origen = p.OrigenPromocion 
						AND pa2.YearPromocion = p.YearPromocion
						AND pa2.StatusArchivo in (-1,1)-----27/11/2023 Gemma commenta que se devuelva el numero de fojas sin importar el estado del archivo (-1 pendiente y 1 activo)
						AND pa2.ClaseAnexo = 0),
			p.NumeroOrden, 
			un.UserName as UsuarioCaptura,
			p.CatOrganismoId,
			p.YearPromocion,
			NULL kIdElectronica,
			p.fechaAlta as FechaCaptura,
			a.NumeroAlias, 
			SISE3.fnEstadoAutorizacion(ad.AsuntoDocumentoId, ad.CatAutorizacionDocumentosId) as EstadoAutorizacion
			,NULL NombreOficial
            ,c.CuadernoId
	FROM Promociones p WITH(NOLOCK) 
	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
	--Validar con Gemma
	--INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL 
        --ON ETL.TipoCuadernoId = p.TipoCuaderno AND etl.TipoAsuntoId = a.CatTipoAsuntoId
	--LEFT JOIN tbx_CatTiposAsunto tac ON ETL.TipoCuadernoId = tac.CuadernoId AND ETL.TipoAsuntoId = tac.CatTipoAsuntoId
	LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId AND p.AsuntoId = tac.CatTipoAsuntoId
	LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
	--fin validar con Gemma
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion	
	LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId
												AND pa.CatOrganismoId = p.CatOrganismoId 
												AND pa.NumeroOrden = p.NumeroOrden
												AND pa.Origen = p.OrigenPromocion 
												AND pa.YearPromocion = p.YearPromocion
												AND pa.StatusArchivo IN (1)
												AND pa.ClaseAnexo = 0
	LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
	LEFT JOIN CatPromocion cp WITH(NOLOCK) ON cp.CatalogoPromocionId = p.TipoContenido
	LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1
	LEFT JOIN Promovente pr ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 and pr.AsuntoNeunId = p.AsuntoNeunId
	LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
	LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId
	LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
	LEFT JOIN AsuntosDocumentos ad on ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId
	LEFT JOIN CatEmpleados un  WITH(NOLOCK) ON un.EmpleadoId = p.RegistroEmpleadoId
	WHERE  p.StatusReg = 1
	AND p.CatOrganismoId = @pi_CatOrganismoId
	--AND (@pi_FechaPresentacionIni IS NULL OR CONVERT(DATE,p.FechaPresentacion) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
	AND (CONVERT(DATE,p.FechaPresentacion) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
	)tbl
	WHERE tbl.No = 1

	/***** PROMOCIONES ELECTRÓNICAS ****/
	INSERT INTO @Promociones (AsuntoNeunId, Expediente, CatTipoAsunto, CatTipoAsuntoId, TipoProcedimiento/*, 
		NumeroRegistro*/, OrigenPromocion, FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente, 
		OrigenPromocionId, Folio, EsPromocionE, Origen,kIdElectronica, NombreOficial, NombreOrigen)
	SELECT	p.fkIdAsuntoNeun,		a.AsuntoAlias,		a.CatTipoAsunto, a.CatTipoAsuntoId,	a.TipoProcedimiento/*,
			p.kIdPromocion*/,			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, 6, p.kIdPromocion, co.NombreOficial, 'Promoción Electrónica'
	FROM dbo.JL_MOV_Promocion AS p WITH (nolock) 
	CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a				
	LEFT JOIN	JL_REL_PromocionSISE ps with(nolock) ON p.kIdPromocion = ps.fkIdPromocion 
        and p.fkIdAsuntoNeun = ps.AsuntoNeunId and p.fkIdOrgano = ps.CatOrganismoId
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 30, 29, IIF(p.fkIdOrigen = 22,22,5))
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
    LEFT JOIN IOJ_MOV_SolicitudInterconexion si ON P.kIdPromocion = si.dFolioRespuesta
	LEFT JOIN CatOrganismos co ON co.CatOrganismoId = si.fkIdOrgano
	WHERE ps.kIdPromocionSISE IS NULL
    AND P.fkIdOrigen != 22
	AND a.AsuntoNeunId = p.fkIdAsuntoNeun
	AND a.CatOrganismoId = p.fkIdOrgano
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId

	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
	
	/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ****/
	INSERT INTO @Promociones (AsuntoNeunId, Expediente, CatTipoAsunto, CatTipoAsuntoId, TipoProcedimiento/*, 
		NumeroRegistro*/, OrigenPromocion, FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente,
		OrigenPromocionId, Folio, EsPromocionE, NombreOficial, Origen,kIdElectronica, NombreOrigen/*, EstadoAcuerdo*/)
	SELECT	p.fkIdAsuntoNeun,		a.AsuntoAlias,		a.CatTipoAsunto, a.CatTipoAsuntoId,	a.TipoProcedimiento/*,
			p.kIdPromocion*/,			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, co.NombreOficial, 14, p.kiIdFolio, 'Promoción Electrónica de Interconexión'/*, 
			SISE3.fnEstadoAutorizacion(ad.AsuntoDocumentoId, ad.CatAutorizacionDocumentosId) as EstadoAutorizacion*/
	FROM dbo.ICOIJ_MOV_Promocion AS p WITH (nolock) 
	CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
	LEFT JOIN ICOIJ_REL_PromocionSISE ps with(nolock) ON p.kIdPromocion = ps.fkIdPromocion
        AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 14
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	LEFT JOIN AsuntosDocumentos ad on ad.AsuntoNeunId = p.fkIdAsuntoNeun
    LEFT JOIN ICOIJ_REL_DemandaPromocionSolicitud dps on dps.fkiIdFolio = p.kiIdFolio
	LEFT JOIN CatOrganismos co ON dps.iOIJ = co.CatOrganismoId
	WHERE ps.kIdPromocionSISE IS NULL
	AND a.AsuntoNeunId = p.fkIdAsuntoNeun
	AND a.CatOrganismoId = p.fkIdOrgano
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
	
	/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES SIN EXPEDIENTE ****/
	INSERT INTO @Promociones (AsuntoNeunId, 
		/*NumeroRegistro,*/ OrigenPromocion, FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente,
		OrigenPromocionId, Folio, EsPromocionE, Origen,kIdElectronica, NombreOrigen, NombreOficial)
	SELECT	p.fkIdAsuntoNeun,
			/*p.kIdPromocion,*/			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, 22, p.kiIdFolio, 'Promoción Electrónica de Interconexión entre Órganos Jurisdiccionales'
            ,c.NombreOficial
	FROM IOJ_MOV_PromocionOJ AS p WITH (nolock) 
	LEFT JOIN  IOJ_REL_PromocionSISE ps with(nolock) ON p.kiIdFolio = ps.fkIdPromocion 
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 22
    LEFT JOIN IOJ_MOV_SolicitudInterconexion si ON P.kiIdFolio = si.dFolioRespuesta
    LEFT JOIN CatOrganismos c ON si.fkIdOrgano = c.CatOrganismoId
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	WHERE ps.fkIdPromocion IS NULL
    AND P.fkIdOrigen = 22
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)-- Modificó SBGE el día 16/08/2016 se modificó para poder consultar un solo día (fecha inicio y fin iguales)

    /***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES CON EXPEDIENTE ****/
	INSERT INTO @Promociones (AsuntoNeunId, Expediente, CatTipoAsunto, CatTipoAsuntoId,TipoProcedimiento,
		/*NumeroRegistro,*/ OrigenPromocion, FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente,
		OrigenPromocionId, Folio, EsPromocionE, Origen,kIdElectronica, NombreOrigen, NombreOficial)
    SELECT	p.fkIdAsuntoNeun, a.AsuntoAlias,		a.CatTipoAsunto, a.CatTipoAsuntoId,	a.TipoProcedimiento,
			/*p.kIdPromocion,*/			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, 22, p.kIdPromocion, 'Promoción Electrónica de Interconexión entre Órganos Jurisdiccionales'
            ,c.NombreOficial
    FROM JL_MOV_Promocion p
    CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
    LEFT JOIN  JL_REL_PromocionSISE ps with(nolock) ON p.kIdPromocion = ps.fkIdPromocion 
    LEFT JOIN IOJ_MOV_SolicitudInterconexion si ON p.kIdPromocion = si.dFolioRespuesta
    LEFT JOIN CatOrganismos c ON si.fkIdOrgano = c.CatOrganismoId
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 22
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	WHERE ps.fkIdPromocion IS NULL
    AND p.fkIdOrigen = 22
	AND p.fkIdEstatus = 1
	AND p.fkIdOrgano = @pi_CatOrganismoId
	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)

	/***** DEMANDAS ELECTRÓNICAS ****/
	INSERT INTO @Promociones(OrigenPromocion,FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente,
		OrigenPromocionId, Folio, EsPromocionE, Origen,kIdElectronica, NombreOrigen)
	SELECT DISTINCT	o.sNombreOrigenPromocion,p.fFechaAlta,0,1,1
	,SISE3.ConcatenarNombres(ISNULL(u.sNombre,p.sPromoventeNombre),ISNULL(u.sApellidoPaterno,''),ISNULL(u.sApellidoMaterno,'')),
			p.fkIdOrigen, p.kIdDemanda, 1, 5, p.kIdDemanda, 'Demanda Electrónica'
	FROM JL_MOV_Demanda AS p WITH (nolock) 
	INNER JOIN JLOCCSISE_MOV_EnLinea AS e ON e.fkIdDemandaJL = p.kIdDemanda
	INNER JOIN JL_REL_DemandaArchivo da with(nolock) on p.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
	INNER JOIN  dbo.JL_MOV_Archivo AS arc ON arc.kIdArchivo = da.fkIdArchivo and arc.fkIdEstatus = 1	
	LEFT JOIN dbo.JL_REL_DemandaSISE rdem WITH (nolock) on rdem.fkIdDemanda = p.kIdDemanda
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 29, 29,5)
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
	WHERE coe.fkIdDemanda IS NULL
	AND rdem.fkIdDemanda IS NULL
	AND p.fkIdEstatus = 1
	AND e.fkIdNeunSISE IS NULL
	AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)-- Modificó SBGE el día 16/08/2016 se modificó para poder consultar un solo día (fecha inicio y fin iguales)
	
	
	/***** DEMANDAS ELECTRÓNICAS INTERCONEXIÓN ****/
	INSERT INTO @Promociones(OrigenPromocion,FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente,
		OrigenPromocionId, Folio, EsPromocionE, Origen,kIdElectronica, NombreOrigen)
	SELECT DISTINCT	o.sNombreOrigenPromocion,p.fFechaAlta,0,1,1,SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
		p.fkIdOrigen, p.kiIdFolio, 1, 15, p.kiIdFolio, 'Demanda Electrónica Interconexión'
	FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
	INNER JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
	INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
	LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = p.kIdDemanda 
	LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 5
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
	WHERE coe.fkIdDemanda IS NULL
	AND irdem.fkIdDemanda IS NULL
	AND p.fkIdEstatus = 1 
	AND e.fkIdNeunSISE IS NULL
	AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
	AND p.fkIdOrigen = 37

	/***** COMUNICACIONES OFICIALES ****/
	INSERT INTO @Promociones(OrigenPromocion,FechaPresentacion, Registrada,
		ConArchivo, EsDemanda, Promovente,
		OrigenPromocionId, Folio, EsPromocionE, Origen,kIdElectronica, NombreOficial, NombreOrigen
		--,Expediente, CatTipoAsunto, CatTipoAsuntoId, TipoProcedimiento
		)
	--SELECT DISTINCT	o.sNombreOrigenPromocion,p.fFechaAlta,0,0,1,SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
	--			p.fkIdOrigen, p.kiIdFolio, 1, 29, p.kiIdFolio, 'Comunicación Oficial'
	--FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
	--INNER JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
	--INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
	--LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 29
	--LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	--LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
	--WHERE coe.fkIdDemanda IS NOT NULL
	--AND p.fkIdEstatus = 1 
	--AND e.fkIdNeunSISE IS NULL
	--AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	--AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
	SELECT DISTINCT	ori.sNombreOrigenPromocion,dem.fFechaAlta,0,1,1,SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
				dem.fkIdOrigen, dem.kIdDemanda, 1, 29, dem.kIdDemanda, co.NombreOficial, 'Comunicación Oficial'
				--,a.AsuntoAlias as Expediente, a.CatTipoAsunto as CatTipoAsunto, a.CatTipoAsuntoId,
				--a.TipoProcedimiento as TipoProcedimiento
	FROM JLOCCSISE_MOV_EnLinea p with(nolock)
	LEFT JOIN JL_MOV_Demanda dem with(nolock) on p.fkIdDemandaJL = dem.kIdDemanda
	LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on  dem.kIdDemanda = coe.fkIdDemanda
	--CROSS APPLY SISE3.fnExpediente(coe.OrigenAsuntoNeunId) a
	LEFT JOIN JL_REL_DemandaSISE ps with(nolock) ON p.fkIdDemandaJL = ps.fkIdDemanda 
	LEFT JOIN SISE3.CAT_OrigenPromocion  ori ON  ori.kIdOrigenPromocion	= 29
	LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = dem.fkIdUsuario
	LEFT JOIN CatOrganismos co ON coe.OrigenCatOrganismoId = co.CatOrganismoId
	WHERE coe.fkIdDemanda IS NOT NULL
	AND p.fkIdEstatus = 1 
	AND ps.fkIdDemanda IS NULL
	AND p.fkIdOrganoOCC = @pi_CatOrganismoId
	AND	(@pi_FechaPresentacionIni IS NULL OR CAST( dem.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)



IF @pi_Texto<> ''
BEGIN

	--Se obtiene el conteo de los registros según estado de Captura y Asignación
	SET @TOTAL = (
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
					   [Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
				       [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
					   [CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias))) 
				FROM @Promociones 
				WHERE  CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura,Mesa,NombreOrigen,NombreOficial,TipoProcedimiento) like '%'+trim(@pi_Texto)+'%' 
				AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				)
	SET @SinCaptura = ( --Todas las electronicas
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
					   [Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
				       [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
					   [CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias))) 
				FROM @Promociones 
				WHERE [SISE3].[fnEstatusPromocion] (NULL, [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica])= 1
				AND CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura,Mesa,NombreOrigen,NombreOficial,TipoProcedimiento) like '%'+trim(@pi_Texto)+'%'
				AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				)  
	SET @Capturadas = (
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
					   [Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
				       [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
					   [CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias))) 
				FROM @Promociones 
				where  [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId, [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) = 2
				AND [NombreArchivo] IS NULL
				AND CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura,Mesa,NombreOrigen,NombreOficial,TipoProcedimiento) like '%'+trim(@pi_Texto)+'%'
				AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				)
	SET @Asignadas = (
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
					   [Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
				       [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
					   [CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias))) 
				FROM @Promociones 
				WHERE [SISE3].[fnEstatusPromocion] (NULL , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) = 4
				AND CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura,Mesa,NombreOrigen,NombreOficial,TipoProcedimiento) like '%'+trim(@pi_Texto)+'%'
				AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				)
				

	SELECT @TOTAL AS TOTAL, @SinCaptura AS SinCaptura, @Capturadas AS Capturadas, @Asignadas as Asignadas

	
	IF @pi_FiltroTipo = 0
	BEGIN
		--Se obtiene el conteo de los registros según estado de Captura y Asignación
/*	SET @TOTAL = (
				SELECT COUNT(1) 
				FROM @Promociones 
				WHERE CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura) like '%'+trim(@pi_Texto)+'%'
				)
	SET @SinCaptura = (
				SELECT ISNULL(SUM(Convert(int,EsPromocionE)),0)
				FROM @Promociones 
				WHERE EsPromocionE = 1
				AND CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura) like '%'+trim(@pi_Texto)+'%')
	SET @Capturadas = (
				SELECT COUNT (EsPromocionE) 
				FROM @Promociones 
				where EsPromocionE = 0 
				AND [NombreArchivo] IS NULL
				AND CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura) like '%'+trim(@pi_Texto)+'%')
	SET @Asignadas = (
				SELECT COUNT(1) 
				FROM @Promociones 
				WHERE EsPromocionE = 0 
				AND [NombreArchivo] IS NOT NULL 
				AND CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura) like '%'+trim(@pi_Texto)+'%')


	SELECT @TOTAL AS TOTAL, @SinCaptura AS SinCaptura, @Capturadas AS Capturadas, @Asignadas as Asignadas
	*/

		--Se devuelve select final para mostrar datos en Grid de promociones
		SELECT [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName]
		,[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],
		[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], Origen, NombreOrigen
		, Fojas,NumeroOrden, @TOTAL AS TOTAL, @SinCaptura AS SinCaptura, 
		@Capturadas AS Capturadas, @Asignadas as Asignadas, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) AS EstatusPromocion, UsuarioCaptura, FechaCaptura, [CatOrganismoId], 
		[YearPromocion], IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) AS NumeroAlias, 
		EstadoAcuerdo, kIdElectronica, NombreOficial, CuadernoId
		FROM @Promociones
		where CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura,Mesa,NombreOrigen,NombreOficial,TipoProcedimiento) like '%'+trim(@pi_Texto)+'%'
		AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
		AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
		AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)

		GROUP BY [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], 
		[SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
		[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],
		[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) , UsuarioCaptura, FechaCaptura, [CatOrganismoId], 
		[YearPromocion],IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias), EstadoAcuerdo, kIdElectronica, NombreOficial, CuadernoId
		ORDER BY 
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 0 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END ASC,
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 1 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 0 THEN NumeroRegistro END  ASC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 1 THEN NumeroRegistro END DESC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 0 THEN OrigenPromocion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 1 THEN OrigenPromocion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 0 THEN Secretario END ASC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 1 THEN Secretario END DESC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 0 THEN FechaPresentacion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 1 THEN FechaPresentacion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 0 THEN TipoContenido END ASC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 1 THEN TipoContenido END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 0 THEN Promovente END ASC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 1 THEN Promovente END DESC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 0 THEN NumeroCopias END ASC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 1 THEN NumeroCopias END DESC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 0 THEN NumeroAnexos END ASC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 1 THEN NumeroAnexos END DESC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 0 THEN UsuarioCaptura END ASC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 1 THEN UsuarioCaptura END DESC,
			CASE WHEN @pi_OrdenarPor IS NULL THEN FechaPresentacion END
		OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
		FETCH NEXT iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)   ROWS ONLY
	END
	ELSE
	BEGIN
		

		--Se devuelve select final para mostrar datos en Grid de promociones
		SELECT [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName]
		,[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],
		[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], Origen, NombreOrigen
		, Fojas,NumeroOrden , @TOTAL AS TOTAL, 
		@SinCaptura AS SinCaptura, @Capturadas AS Capturadas, @Asignadas as Asignadas, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) AS EstatusPromocion, UsuarioCaptura, FechaCaptura, [CatOrganismoId] ,[YearPromocion],
		IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) AS NumeroAlias, EstadoAcuerdo, kIdElectronica, NombreOficial, CuadernoId
		FROM @Promociones
		where /*[No] is not null
		and*/ CONCAT(Expediente, CatTipoAsunto,TipoContenido, Cuaderno, NumeroRegistro, OrigenPromocion, SecretarioUserName, Promovente, UsuarioCaptura,Mesa,NombreOrigen,NombreOficial,TipoProcedimiento) like '%'+trim(@pi_Texto)+'%'
		AND [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) = @pi_FiltroTipo
		AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
		AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
		AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)

		GROUP BY [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido]
,
		[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],
		[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura, FechaCaptura, [CatOrganismoId], 
		[YearPromocion],IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) ,EstadoAcuerdo, kIdElectronica, NombreOficial, CuadernoId
		ORDER BY 
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 0 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END ASC,
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 1 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 0 THEN NumeroRegistro END  ASC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 1 THEN NumeroRegistro END DESC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 0 THEN OrigenPromocion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 1 THEN OrigenPromocion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 0 THEN Secretario END ASC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 1 THEN Secretario END DESC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 0 THEN FechaPresentacion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 1 THEN FechaPresentacion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 0 THEN TipoContenido END ASC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 1 THEN TipoContenido END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 0 THEN Promovente END ASC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 1 THEN Promovente END DESC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 0 THEN NumeroCopias END ASC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 1 THEN NumeroCopias END DESC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 0 THEN NumeroAnexos END ASC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 1 THEN NumeroAnexos END DESC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 0 THEN UsuarioCaptura END ASC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 1 THEN UsuarioCaptura END DESC,
			CASE WHEN @pi_OrdenarPor IS NULL THEN FechaPresentacion END
		OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
		FETCH NEXT iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)   ROWS ONLY
	END
	
END
ELSE
BEGIN
	

	--Se obtiene el conteo de los registros según estado de Captura y Asignación
	SET @TOTAL = (SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion]
,[TipoPromociones],[TipoContenido],
		[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
		[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias,EstadoAcuerdo))) 
				FROM @Promociones
				WHERE IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				)
				

	SET @SinCaptura = ( --Todas las electronicas
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
						[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
						[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
						[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias,EstadoAcuerdo))) 
				FROM @Promociones 
				WHERE  
				IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				AND [SISE3].[fnEstatusPromocion] (NULL, [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica])= 1
				)

	SET @Capturadas = (
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
				[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
				[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
				[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias,EstadoAcuerdo))) 
				FROM @Promociones 
				where  
				 IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				AND [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId, [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) = 2)

	SET @Asignadas = (
				SELECT COUNT(DISTINCT (CONCAT([No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],
				[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
				[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
				[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, NumeroAlias,EstadoAcuerdo))) 
				FROM @Promociones 
				WHERE ([NombreArchivo] IS NOT NULL OR [OrigenPromocionId] IN (6,14,22,5,15,29))
				AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
				AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
				AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)
				AND [SISE3].[fnEstatusPromocion] (NULL , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) = 4)
				
	SELECT @TOTAL AS TOTAL, @SinCaptura AS SinCaptura, @Capturadas AS Capturadas, @Asignadas as Asignadas

	IF @pi_FiltroTipo = 0
	BEGIN
		--Se devuelve select final para mostrar datos en Grid de promociones
		SELECT [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario],[SecretarioUserName],
		[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],
		[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], Origen, NombreOrigen
		, Fojas,NumeroOrden, @TOTAL AS TOTAL, @SinCaptura AS SinCaptura, @Capturadas AS Capturadas, @Asignadas as Asignadas, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) AS EstatusPromocion, UsuarioCaptura,
		[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) AS NumeroAlias,EstadoAcuerdo, NombreOficial, CuadernoId
		FROM @Promociones
		where IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
		AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
		AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)

		GROUP BY [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido]
,
		[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) ,UsuarioCaptura,
		[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias),EstadoAcuerdo, NombreOficial, CuadernoId
		ORDER BY 
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 0 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END ASC,
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 1 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 0 THEN NumeroRegistro END  ASC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 1 THEN NumeroRegistro END DESC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 0 THEN OrigenPromocion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 1 THEN OrigenPromocion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 0 THEN Secretario END ASC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 1 THEN Secretario END DESC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 0 THEN FechaPresentacion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 1 THEN FechaPresentacion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 0 THEN TipoContenido END ASC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 1 THEN TipoContenido END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 0 THEN Promovente END ASC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 1 THEN Promovente END DESC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 0 THEN NumeroCopias END ASC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 1 THEN NumeroCopias END DESC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 0 THEN NumeroAnexos END ASC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 1 THEN NumeroAnexos END DESC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 0 THEN UsuarioCaptura END ASC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 1 THEN UsuarioCaptura END DESC,
			CASE WHEN @pi_OrdenarPor IS NULL THEN FechaPresentacion END
		OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
		FETCH NEXT iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)   ROWS ONLY
	END
	ELSE
	BEGIN
		--Se devuelve select final para mostrar datos en Grid de promociones
		SELECT [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],
		[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido],[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],
		[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],[CatAutorizacionDocumentosId], Origen,NombreOrigen
		, Fojas,NumeroOrden, @TOTAL AS TOTAL, @SinCaptura AS SinCaptura, 
		@Capturadas AS Capturadas, @Asignadas as Asignadas, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) AS EstatusPromocion,UsuarioCaptura,
		[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) AS NumeroAlias,EstadoAcuerdo, NombreOficial, CuadernoId
		FROM @Promociones
		WHERE [SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) = @pi_FiltroTipo
		AND IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',[OrigenPromocion])=IIF(TRIM(ISNULL(@pi_Origen,'')) ='','',@pi_Origen)
		AND IIF(ISNULL(@pi_Asignado,0) =0,0,[IdSecretario])=IIF(ISNULL(@pi_Asignado,0) =0,0,@pi_Asignado)
		AND IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',[UsuarioCaptura])=IIF(TRIM(ISNULL(@pi_Capturo,'')) ='','',@UserName)

		GROUP BY [No], [AsuntoNeunId], [Expediente],[CatTipoAsunto], CatTipoAsuntoId,[TipoProcedimiento],[Cuaderno],[NumeroRegistro],[OrigenPromocion],[Secretario],[IdSecretario], [SecretarioUserName],[Mesa],[FechaPresentacion],[TipoPromociones],[TipoContenido]
,
		[Promovente],[IdPromovente],[ClasePromovente],[NumeroCopias],[NumeroAnexos],[Registrada],[ConArchivo],[EsDemanda],[OrigenPromocionId],[Folio],[EsPromocionE],
		[CatAutorizacionDocumentosId], [Origen], NombreOrigen, Fojas,NumeroOrden, 
		[SISE3].[fnEstatusPromocion] (CatAutorizacionDocumentosId , [EsPromocionE], [NombreArchivo], [Origen] ,[kIdElectronica]) , UsuarioCaptura,
		[CatOrganismoId],[YearPromocion],[kIdElectronica], FechaCaptura, IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias) ,EstadoAcuerdo, NombreOficial, CuadernoId
		ORDER BY 
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 0 THEN IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)  END ASC,
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 1 THEN  IIF(NumeroAlias IS NULL, [dbo].[fnAliasaNumero] (Expediente), NumeroAlias)   END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 0 THEN NumeroRegistro END  ASC,
			CASE WHEN @pi_OrdenarPor= 'Promoción' and @pi_TipoOrden = 1 THEN NumeroRegistro END DESC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 0 THEN OrigenPromocion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 1 THEN OrigenPromocion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 0 THEN Secretario END ASC,
			CASE WHEN @pi_OrdenarPor= 'Secretario'and @pi_TipoOrden = 1 THEN Secretario END DESC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 0 THEN FechaPresentacion END ASC,
			CASE WHEN @pi_OrdenarPor= 'Fecha'and @pi_TipoOrden = 1 THEN FechaPresentacion END DESC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 0 THEN TipoContenido END ASC,
			CASE WHEN @pi_OrdenarPor= 'Contenido'and @pi_TipoOrden = 1 THEN TipoContenido END DESC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 0 THEN Promovente END ASC,
			CASE WHEN @pi_OrdenarPor= 'Promovente'and @pi_TipoOrden = 1 THEN Promovente END DESC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 0 THEN NumeroCopias END ASC,
			CASE WHEN @pi_OrdenarPor= 'Copias'and @pi_TipoOrden = 1 THEN NumeroCopias END DESC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 0 THEN NumeroAnexos END ASC,
			CASE WHEN @pi_OrdenarPor= 'Anexos'and @pi_TipoOrden = 1 THEN NumeroAnexos END DESC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 0 THEN UsuarioCaptura END ASC,
			CASE WHEN @pi_OrdenarPor= 'Capturo'and @pi_TipoOrden = 1 THEN UsuarioCaptura END DESC,
			CASE WHEN @pi_OrdenarPor IS NULL THEN FechaPresentacion END
		OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
		FETCH NEXT iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)  ROWS ONLY
	END
END;
