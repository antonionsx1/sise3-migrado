SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Proyecto: SISE3
-- Autor: Sergio Orozco - MS
-- Alter Date: 11/01/2024
-- Objetivo: Carga el detalle de notificaciones electrónicas en detalle de actuaría
-- Alter Date: 23/04/2024 - RRJ
-- Objetivo: Agregar al resultado de la consulta el valor de NotElecId y completar la relacion del valor TieneCOE
-- EXEC SISE3.pcTableroDetalleNotificaciones 180, 0, 0, 36068236, 1, NULL, NULL, null, 0, NULL, NULL, NULL, 12
-- EXEC SISE3.pcTableroDetalleNotificaciones 1494, 1000, 1, 36068250, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
-- Modificación: LAGS, 18.06.2024 Se agregaron los campos FechaUsuarioAsigno y AsignoPersona.
-- Notas: 
--      Pendiente de agregar las notificaciones a Autoridades Judiciales y Promoventes, no existen en la tabla
--          Se propone generar una vista donde se incluyan los datos de las notificaciones a Autoridades Judiciales y Promoventes
--          y se incluya en la consulta de este SP
--      Pendiente filtrar por ese tipo de parte o tipo de figura
-- @pi_CatOrganismoId = 180
-- @pi_TamanoPagina = 1000
-- @pi_NumeroPagina = 1
-- @pi_AsuntoNeunId = 30315469
-- @pi_AsuntoDocumentoID = 1
-- @pi_Texto = NULL
-- @pi_OrdenarPor = NULL
-- @pi_TipoOrden = NULL
-- @pi_FiltroTipo = NULL
-- @pi_FiltroTipoParteID = NULL
-- @pi_FiltroTipoNotificacionID = NULL
-- @pi_FiltroActuarioID = NULL
-- @pi_primeraCarga = 0
-- Modificación LAGS, 10.10.2024, Se agrega validación para mostrar Citatorio y Fecha Citatorio
-- Modificación LAGS, 04.11.2024, Se agrega validación para folio en Anexos y SISE3.EstadoOficio para que no se repitan registros.
-- Modificación LAGS, 15.11.2024, se agrega validación tipo de area 5 "Zona".
-- Modificación LAGS, 15.11.2024, Se agrega validación para SISE3.EstadoOficio, estatus = 1. 
-- Modificación LAGS, 10.01.2025, Se agrega validación para DomicilioPartes, esto para evitar registros de Promovente repetidos. 
-- Modificación LAGS, 24.01.2025, se agrega campo "DescripcionTipoConstancia" para consulta, asi como validación para Constancia Automatica.
-- Modificación ALV, 26.02.2025, se agrega campo "FechaGeneracionNotifElect" para consulta.
-- Modificación ALV, 10.03.2025, se agrega el TipoNotificacion 2 para saber cuando es "Cúmplase".
-- Modificación LAGS, 18.03.2025, se agrega campo "ActuarioId"
-- Modificación JARR/JSM, 25.03.2025, se agregan campos OrganoParteId], [EstadoSolicitudIOJ], [SolicitudInterconexion
-- Modificación ARS: 26.03.2025, se agregó el tipo de notificación interconexión AJ 
-- Modificación AGA: 19.05.2025, Se modifico de algunas consultas nep.StatusReg = 1 por nep.StatusReg IN(1,2)
-- ===================================================

ALTER PROCEDURE [SISE3].[pcTableroDetalleNotificaciones]
    (
    @pi_CatOrganismoId INT,						-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
    @pi_TamanoPagina INT = NULL,				-- REPRESENTA EL TAMAÑO DE LA PÁGINA DE LA PAGINACIÓN
    @pi_NumeroPagina INT,						-- REPRESENTA EL NUMERO DE PÁGINA DE LA PAGINACIÓN
    @pi_AsuntoNeunId BIGINT,					-- REPRESENTA EL IDENTIFICADOR DEL EXPEDIENTE
    @pi_AsuntoDocumentoID INT= NULL,				-- REPRESENTA EL IDENTIFICADOR DEL DOCUMENTO
    @pi_Texto VARCHAR(MAX) = NULL,				-- REPRESENTA EL TEXTO A BUSCAR EN EL EXPEDIENTE
    @pi_OrdenarPor VARCHAR(128) = NULL,			-- Recibe valor para ordenamiento de la página, PUEDE SER NULO, si es nulo ordena por fecha, de lo contrario por el campo recibido
    @pi_TipoOrden INT = NULL,					-- Recibe configuración de ordenamiento Ascendente o Descendente? 1=Descendente 0=Ascendente    
    @pi_FiltroTipo INT = 0 ,					-- Recibe parámetro del tipo de filtro		-- Estado opciones, 0=VerTodas, 1=Pendiente, 2=En Proceso, 3=Notificados    
    @pi_FiltroTipoParteID INT = NULL,			-- Recibe parámetro del tipo de parte 1=Partes, 2=Promoventes, 3=Autoridades Judiciales
    @pi_FiltroTipoNotificacionID INT = NULL,	-- Recibe parámetro del tipo de notificación
    @pi_FiltroActuarioID BIGINT = NULL,			-- Recibe parámetro del id de empleado actuario
    @pi_primeraCarga INT = 0,					-- Es la primera carga de tablero o no 0=No, 1=Si
	@pi_SintesisOrden INT= NULL                  -- REPRESENTA LA SINTESIS ORDEN DE LA DETERMINACIÓN (NUEVO)
)
AS
BEGIN
	--Declara variables de conteos
	DECLARE @Todos              INT
	DECLARE @Notificados        INT
	DECLARE @Pendientes         INT
	DECLARE @EnProceso          INT
	DECLARE @pagina             INT
	DECLARE @totalPaginas       INT
	DECLARE @totalRegistros     INT
	--DECLARE @SintesisOrden		INT 

    --Limpiar variables de entrada
    IF @pi_TamanoPagina IS NULL
    BEGIN
		SET @pi_TamanoPagina = 0
        SET @pi_NumeroPagina = iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)
    END
    IF @pi_Texto IS NOT NULL
	BEGIN
		SET @pi_Texto = LTRIM(RTRIM(@pi_Texto))
    END
    IF @pi_OrdenarPor IS NOT NULL
	BEGIN
		SET @pi_OrdenarPor = LTRIM(RTRIM(@pi_OrdenarPor))
    END
    --Validar Filtros existentes
    IF @pi_FiltroTipo IS NULL
    BEGIN
		SET @pi_FiltroTipo = 0
    END
	IF @pi_TipoOrden IS NULL
	BEGIN
		SET @pi_TipoOrden = 0
	END
	IF @pi_FiltroTipo NOT IN (0,1,2,3)
	BEGIN
		SET @pi_FiltroTipo = 0
	END
	IF @pi_FiltroTipoParteID IS NULL
	BEGIN
		SET @pi_FiltroTipoParteID = 0
	END
	IF @pi_FiltroTipoNotificacionID IS NULL
	BEGIN
		SET @pi_FiltroTipoNotificacionID = 0
	END
	IF @pi_FiltroActuarioID IS NULL
	BEGIN
		SET @pi_FiltroActuarioID = 0
	END
	IF @pi_primeraCarga IS NULL
	BEGIN
		SET @pi_primeraCarga = 0
	END

	IF(@pi_AsuntoDocumentoId IS NOT NULL AND  @pi_SintesisOrden is not null)
	BEGIN 
		SELECT
			IIF(ad.NombreDocumento is null,dj.NombreArchivo ,ad.NombreDocumento) as NombreArchivo
            ,IIF(ad.FechaAutoriza is null, (DATEDIFF(DD,dj.FechaPublicacion, GETDATE())) , (DATEDIFF(DD,ad.FechaAutoriza, GETDATE())) ) AS Transcurrido
            ,a.AsuntoAlias as No_Exp
            ,cto.Descripcion As TipoAsuntoDescripcion
            ,dbo.funRecuperaCatalogoDependienteDescripcion(527, dj.TipoCuaderno) as TipoCuaderno
            , a.TipoProcedimiento as TipoProcedimiento
		FROM DeterminacionesJudiciales dj WITH(NOLOCK)
		LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON dj.AsuntoNeunId = ad.AsuntoNeunId and dj.SintesisOrden=ad.SintesisOrden
        CROSS APPLY SISE3.fnExpediente(dj.AsuntoNeunId) a
        JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
        WHERE 
		   dj.AsuntoNeunId = @pi_AsuntoNeunId
           --AND ad.AsuntoDocumentoID = @pi_AsuntoDocumentoID
		   AND ( ad.AsuntoDocumentoId=ISNULL(@pi_AsuntoDocumentoID, ad.AsuntoDocumentoId)
			      OR dj.SintesisOrden=ISNULL(@pi_SintesisOrden, dj.SintesisOrden))
		   AND dj.StatusReg = 1
	END ELSE
	BEGIN
		SELECT 
			IIF(ad.NombreDocumento is null,dj.NombreArchivo ,ad.NombreDocumento) as NombreArchivo
			,IIF(ad.FechaAutoriza is null, (DATEDIFF(DD,dj.FechaPublicacion, GETDATE())) , (DATEDIFF(DD,ad.FechaAutoriza, GETDATE())) ) AS Transcurrido
			,a.AsuntoAlias as No_Exp
			,cto.Descripcion As TipoAsuntoDescripcion
			,dbo.funRecuperaCatalogoDependienteDescripcion(527, dj.TipoCuaderno) as TipoCuaderno
			, a.TipoProcedimiento as TipoProcedimiento
		FROM DeterminacionesJudiciales dj WITH(NOLOCK)
		LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) ON dj.AsuntoNeunId = ad.AsuntoNeunId and dj.SintesisOrden=ad.SintesisOrden
		CROSS APPLY SISE3.fnExpediente(dj.AsuntoNeunId) a
		JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
        WHERE 
		   dj.AsuntoNeunId = @pi_AsuntoNeunId
           --AND ad.AsuntoDocumentoID = @pi_AsuntoDocumentoID
		   AND (@pi_AsuntoDocumentoID IS NULL OR ad.AsuntoDocumentoId=ISNULL(@pi_AsuntoDocumentoID, ad.AsuntoDocumentoId))
			AND (@pi_SintesisOrden IS NULL OR dj.SintesisOrden=ISNULL(@pi_SintesisOrden, dj.SintesisOrden))
			AND dj.StatusReg = 1
    END

	IF(@pi_SintesisOrden IS NULL AND @pi_AsuntoDocumentoID IS NOT NULL)
	BEGIN
		SELECT 
		     @pi_SintesisOrden = SintesisOrden
        FROM AsuntosDocumentos ad WITH(NOLOCK) 
        WHERE 
		    ad.AsuntoNeunId = @pi_AsuntoNeunId
            AND ad.AsuntoDocumentoID = @pi_AsuntoDocumentoID
	END
	
	---- INCORPORACION DE PROMOVENTES A LA RELACION CON NOTIFICACIONES ----
    SELECT * 
    INTO #TMP_NOTIFICACIONESPARTES
    FROM (
		SELECT 
			ROW_NUMBER() OVER(PARTITION BY ne.AsuntoNeunId, nep.PersonaId ORDER BY ne.Fechaalta DESC) AS Num
			, nep.PersonaId, NULL AS PromoventeId , nep.TipoConstanciaId, nep.FechaNotificacion, nep.ActuarioId, nep.TipoNotificacion
			, nep.NotElecId, nep.AsuntoId, nep.AsuntoNeunId, nep.SintesisOrden, nep.StatusReg
			, pas.CatTipoPersonaId, pas.Nombre, pas.APaterno, pas.AMaterno, pas.AsuntoId AS AsuntoParteId, pas.PersonaId AS PersonaParteId
			, pas.CatCaracterPersonaAsuntoId, pas.DenominacionDeAutoridad
			, nea.IdUsuarioAsigno, nea.FechaUsuarioAsigno, nep.DescripcionTipoConstancia, nep.FechaGeneroNotificacion, po.catOrganismoId as OrganoParteId
		FROM NotificacionElectronica_Personas nep WITH(NOLOCK)
		INNER JOIN NotificacionElectronica ne WITH(NOLOCK) ON ne.AsuntoNeunId = nep.AsuntoNeunId AND ne.SintesisOrden = nep.SintesisOrden
		INNER JOIN PersonasAsunto  pas WITH(NOLOCK) ON   nep.AsuntoNeunId = pas.AsuntoNeunId AND nep.PersonaId = pas.PersonaId
		LEFT JOIN NotificacionElectronica_AsignaActuario nea WITH(NOLOCK)
		ON nep.AsuntoNeunId = nea.AsuntoNeunId AND nep.SintesisOrden = nea.SintesisOrden AND nep.NotElecId = nea.NotElecId
		LEFT JOIN PersonasOrganismo po ON pas.PersonaId = po.PersonaId
		WHERE 
			ne.AsuntoNeunId = @pi_AsuntoNeunId
			AND ne.SintesisOrden =  @pi_SintesisOrden --@SintesisOrden 
			AND nep.AsuntoNeunId = @pi_AsuntoNeunId 
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
			, nea.IdUsuarioAsigno,nea.FechaUsuarioAsigno, nep.DescripcionTipoConstancia, nep.FechaGeneroNotificacion, 0 as OrganoParteId
		FROM NotificacionElectronica_Personas nep WITH(NOLOCK)
		INNER JOIN NotificacionElectronica ne WITH(NOLOCK) ON ne.AsuntoNeunId = nep.AsuntoNeunId AND ne.SintesisOrden = nep.SintesisOrden
		INNER JOIN promovente  prm WITH(NOLOCK) ON   nep.AsuntoNeunId = prm.AsuntoNeunId AND nep.PromoventeId = prm.PromoventeId
		LEFT JOIN NotificacionElectronica_AsignaActuario nea WITH(NOLOCK)
		ON nep.AsuntoNeunId = nea.AsuntoNeunId AND nep.SintesisOrden = nea.SintesisOrden AND nep.NotElecId = nea.NotElecId
		WHERE 
			ne.AsuntoNeunId = @pi_AsuntoNeunId
			AND ne.SintesisOrden = @pi_SintesisOrden --@SintesisOrden 
			AND nep.AsuntoNeunId = @pi_AsuntoNeunId
			AND nep.StatusReg IN(1,2) --AGA
		) AS Notificaciones
    WHERE Notificaciones.Num = 1

	---- CONSULTAR ARCHIVOS DE NOTIFICACIONES --
    SELECT Max(ArchivoId) ArchivoId, NotElecId, STRING_AGG(NombreArchivo, '|') AS NombresArchivos
    INTO #TMP_ARCHIVOS

    FROM NotificacionElectronica_Archivos NEA with (nolock)
		LEFT JOIN SISE3.Mov_AcuseNotificacion MAN WITH(NOLOCK) ON NEA.ArchivoId=MAN.fkArchivoId AND MAN.tipoAcuseId in (5726,5731,5732)
		AND MAN.iEstatusReg = 1 
    WHERE 
		NotElecId IN (SELECT NotElecId FROM #TMP_NOTIFICACIONESPARTES)
	    AND StatusReg = 1
    GROUP BY NotElecId
	---- CONSULTAR ARCHIVOS DE NOTIFICACIONES PARA PSL--
	UNION
	SELECT 1 AS ArchivoId , NotElecId, STRING_AGG(AcuseRecibido, '|') AS NombresArchivos
	FROM NotificacionElectronica_Personas WITH(NOLOCK)
	WHERE AsuntoNeunId = @pi_AsuntoNeunId
		AND NotElecId IN (SELECT NotElecId FROM #TMP_NOTIFICACIONESPARTES)
		AND SintesisOrden = @pi_SintesisOrden
		AND StatusReg IN( 1,2)  ---AGA
		AND AcuseRecibido IS NOT NULL
	GROUP BY NotElecId


	---- CONSULTAR ACUSE ELECTRONICO COE --
	SELECT 
			NotElecId, COUNT(NEA.ArchivoId) AS tieneAcuseCoe
	INTO #TMP_ACUSEELECTRONICOCOE
	FROM NotificacionElectronica_Archivos NEA WITH(NOLOCK)
	INNER JOIN SISE3.Mov_AcuseNotificacion MAN WITH(NOLOCK) ON NEA.ArchivoId=MAN.fkArchivoId
	WHERE 
		NEA.NotElecId IN (SELECT NotElecId FROM #TMP_NOTIFICACIONESPARTES)
		AND NEA.StatusReg = 1 AND MAN.tipoAcuseId IN (25230,25231,1440,25232,673,1246,3169)--CARTA ROGATORIA - DESPACHO - EXHORTO - REQUISITORIA
		AND MAN.iEstatusReg=1
	GROUP BY NotElecId 


	/*****************************************************************************************************************/
	-- Crear una funcion para calcular el estado 
	-- Pendiente es que no tiene ningun tipo de notificacion y no se ha trabajo 
	-- Pendiente es cuando no tiene asignado en actuarioID nullo o 10273 y no tiene fecha de notificacion 
	-- En Proceso es que Tiene un actuario y no tiene acuse o el tipo de acuse no es "verde" (segun analisis) o valido
	-- notificado es que cuenta archivo y tipo de acuse es un acuse valido
	/*****************************************************************************************************************/

	-- Si existe un actuario, es porque esta asignado la notificacion 
	-- tabla de notificaciones con joins se inserta a #TMP_NOTIFICACIONES
	CREATE TABLE #TMP_NOTIFICACIONESBIS(
		AsuntoNeunId BIGINT NULL,
		SintesisOrden INT NULL,
		TipoParte INT NULL, 
		Parte VARCHAR(500) NULL,
		ParteID INT NULL,
		PromoventeId  INT NULL,
		notiElect BIGINT NULL,
		usuarioRegistro  VARCHAR(50) NULL,
		DomicilioParte VARCHAR(500) NULL,
		Caracter VARCHAR(100) NULL,
		TipoConstanciaId  INT NULL,
		EstadoId  INT NULL,
		EstadoDescripcion VARCHAR(100) NULL,
		EstadoFecha DATETIME  NULL,
		Tipo VARCHAR(100) NULL,
		TipoId  INT NULL,
		AsignoFecha DATETIME NULL,
		AsignoPersona  VARCHAR(100) NULL,
		AsignadoActuario  VARCHAR(100) NULL,
		AsignadoZona  VARCHAR(100) NULL,
		archivoAcuse  VARCHAR(500) NULL,
		ActuarioId INT NULL,
		NotElecId BIGINT NULL,
		TieneCOE INT NULL,
		AsuntoNEUNCOE  BIGINT NULL,
		TipoComunicacionCOE  INT NULL,
		Folio  INT NULL,
		NombreArchivo  VARCHAR(100) NULL,
		Guid uniqueidentifier NULL,
		OficioFirmado bit NULL,
		tieneAcuseCoe  INT NULL,
		OficioCancelado BIT NULL,
		DescripcionConstancia Varchar(50) null,
		FechaGeneracionNotifElect DATETIME  NULL,
		OrigenPromocion varchar(250),
		OrganoParteId INT NULL
	)
	
	IF(@pi_AsuntoDocumentoId IS NOT NULL AND  @pi_SintesisOrden is not null)
	BEGIN 
		INSERT INTO #TMP_NOTIFICACIONESBIS
        SELECT
			nepp.AsuntoNeunId
			,nepp.SintesisOrden
            ,1 --as TipoParte
            ,CASE
                WHEN nepp.CatTipoPersonaId = 1 THEN CONCAT(nepp.Nombre,' ', nepp.APaterno, ' ', nepp.AMaterno)
                WHEN nepp.CatTipoPersonaId = 2 AND nepp.Nombre = '' THEN nepp.DenominacionDeAutoridad
                ELSE nepp.Nombre
            END --AS Parte
            , nepp.PersonaId --as ParteID
            , nepp.PromoventeId
			, 0 --AS notiElect  --uap.fkIdPersonaAsunto AS notiElect
			,NULL --'Con usuario PSL' --cat.sUserName as usuarioRegistro
            , IIF(dom.ParteId is not NULL, CONCAT(dom.TipoVialidadId, ' ',dom.NombreVialidad,' ', dom.NumeroExterior, ' INT ', dom.NumeroInterior, ' ', dom.TipoAsentamientoId, ' ',' ', dom.CP, ' ', dom.MunicipioId, ' ', dom.EstadoId), 'Domicilio no registrado')
            , IIF(nepp.PersonaId IS NULL AND nepp.PromoventeId IS NOT NULL, 'PROMOVENTE', cpa.Descripcion) --AS Caracter
            ,nepp.TipoConstanciaId
            ,CASE
                 --WHEN ( nepp.FechaNotificacion IS NULL) THEN 1
				 WHEN (nepp.DescripcionTipoConstancia IS NOT NULL AND nepp.FechaNotificacion IS NOT NULL ) THEN 3
				 WHEN (nepp.FechaNotificacion IS NULL AND nepp.TipoConstanciaId NOT IN ('5726','5731','5732')) THEN 1
                -- En Proceso es que Tiene un actuario y no tiene acuse Entonces debe ser "Tipo de Acuse"
                 WHEN (nepp.TipoConstanciaId in ('5726','5731','5732') OR t_nea.ArchivoId IS NULL) THEN 2 --SBGE 12/07/2024 Se quitó Exhorto) 
                -- Notificado es que cuenta conAcuse y ser de tipo de acuse valido (verde)
                -- No debe ser por presencia de archivo, sino por tipo de acuse Verde o valido (confirmar con abogados)
--                WHEN nep.ActuarioId IS NOT NULL AND (nep.TipoConstanciaId is not null and nep.TipoConstanciaId not in ('5726','5732','5736'))
                -- Se remueve tipo constancia notificacion por lista. 5736
                --WHEN nepp.ActuarioId IS NOT NULL AND (nepp.TipoConstanciaId is not null and nepp.TipoConstanciaId not in ('5726','5731','5732','1440'))
				WHEN nepp.ActuarioId IS NOT NULL AND (nepp.TipoConstanciaId is not null and nepp.TipoConstanciaId not in ('5726','5731','5732'))--SBGE 12/07/2024 Se quitó Exhorto
                    AND t_nea.ArchivoId IS NOT NULL THEN 3
                ELSE NULL
            END --as EstadoId
            ,ctn.DESCRIPCION --as EstadoDescripcion
            --,nepp.FechaNotificacion --as EstadoFecha
			,CASE WHEN nepp.FechaNotificacion IS NULL THEN (SELECT fFechaNotificacionCitatorio FROM SISE3.Mov_AcuseNotificacion MAN with(nolock) WHERE MAN.fkArchivoId = t_nea.ArchivoId) ELSE nepp.FechaNotificacion END as FechaNotificacion
            ,cnt.sDescripcionCorta --as Tipo --tipo de notificacion
            ,nepp.TipoNotificacion --as TipoId
			--,CONVERT(VARCHAR(10), nepp.FechaUsuarioAsigno, 103) + ' '  + convert(VARCHAR(8),  nepp.FechaUsuarioAsigno, 14) as AsignoFecha
			,nepp.FechaUsuarioAsigno --as AsignoFecha
			,CASE	
				WHEN nepp.IdUsuarioAsigno IS NOT NULL
					THEN CONCAT(emp1.UserName, ' - ' ,emp1.Nombre, ' ', emp1.ApellidoPaterno, ' ', emp1.ApellidoMaterno)
				ELSE 'Sin asignar'
			END --as AsignoPersona
            ,CASE 
                WHEN nepp.ActuarioId <> 10273 
                    THEN CONCAT(emp.Nombre, ' ', emp.ApellidoPaterno, ' ', emp.ApellidoMaterno)
                WHEN  @pi_CatOrganismoId = 1011
                    THEN CONCAT(emp.Nombre, ' ', emp.ApellidoPaterno, ' ', emp.ApellidoMaterno)
                ELSE NULL
            END --as AsignadoActuario
            ,ar.Nombre --as AsignadoZona
            ,t_nea.NombresArchivos -- as archivoAcuse
            ,nepp.ActuarioId
            ,nepp.NotElecId
            ,COALESCE(rncoe.iStatusReg, 0) --as TieneCOE
            ,rncoe.fkIdAsuntoNEUNCOE --AS AsuntoNEUNCOE
            ,adc.CatCatalogoAsuntoId --AS TipoComunicacionCOE
            ,ax.Folio
            ,CONCAT(eo.NombreArchivo, eo.ExtensionDocumento) --AS NombreArchivo
            ,eo.uGuid --AS Guid
			,eo.Firmado --AS OficioFirmado
			,COALESCE(t_aec.tieneAcuseCoe, 0) --as tieneAcuseCoe
			, CASE WHEN banx.BitacoraAnexoId IS NULL THEN 0 ELSE 1 END -- AS OficioCancelado
			,nepp.DescripcionTipoConstancia
			,nepp.FechaGeneroNotificacion
				,(select  TOP 1 ISNULL(CO.NombreOficial ,'') 
			from AsuntosRelacionados AR WITH(NOLOCK)
            INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
            INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
            INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
        WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = ad.AsuntoNeunId ORDER BY FechaOrigen) as OrigenPromocion
		, nepp.OrganoParteId
        --INTO #TMP_NOTIFICACIONES
        FROM DeterminacionesJudiciales ad WITH(NOLOCK)
		LEFT JOIN AsuntosDocumentos ads WITH(NOLOCK) on ad.AsuntoNeunId = ads.AsuntoNeunId and ad.SintesisOrden = ads.SintesisOrden
		-- se hace join para lograr cruce con CatCaracterPersonaAsunto
		CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		INNER JOIN #TMP_NOTIFICACIONESPARTES nepp ON ad.AsuntoID=nepp.AsuntoId AND ad.AsuntoNeunId=nepp.AsuntoNeunId AND  ad.SintesisOrden = nepp.SintesisOrden
		-- Join para obtener COE
		LEFT JOIN SISE3.REL_NotificacionCOE rncoe WITH(NOLOCK) ON rncoe.iStatusReg = 1 AND nepp.NotElecId = rncoe.fkIdNotElecId
		-- Join para Tipo Comunucacion cuando existe COE
		LEFT JOIN dbo.AsuntosDetalleCatalogos adc WITH(NOLOCK) ON adc.AsuntosNeunId = rncoe.fkIdAsuntoNEUNCOE AND adc.StatusReg = 1 AND adc.TipoAsuntoId = 1287
		-- Join para obtener Caracter
		LEFT JOIN dbo.CatCaracterPersonaAsunto	cpa WITH(NOLOCK) ON nepp.CatCaracterPersonaAsuntoId = cpa.CatCaracterPersonaAsuntoId and cpa.CatTipoAsuntoId = a.CatTipoAsuntoId
		-- Join para obtener Zona de actuario
		LEFT JOIN dbo.Areas ar WITH(NOLOCK) on ar.EmpleadoId = nepp.ActuarioId and ar.StatusReg=1 AND ad.CatOrganismoId = ar.CatOrganismoId AND ar.fkidtipoarea = 5
		-- Trae descripcion de tipo de notificacion
		LEFT JOIN dbo.CatNotificaciones cnt WITH(NOLOCK) on cnt.kIdCatNotificaciones = nepp.TipoNotificacion
		-- Join para obtener nombre de actuario
		LEFT JOIN dbo.CatEmpleados emp WITH(NOLOCK) on emp.EmpleadoId = nepp.ActuarioId
		--- 14.06.2024 LAGS
		LEFT JOIN dbo.CatEmpleados emp1 WITH(NOLOCK) on emp1.EmpleadoId = nepp.IdUsuarioAsigno
		-- Join para obtener tipo de persona
		LEFT JOIN dbo.CatTiposPersona ctp WITH(NOLOCK) on nepp.CatTipoPersonaId = ctp.CatTipoPersonaId
        -- Join para catalogo de tipo de acuse
            LEFT JOIN 
            (
                SELECT ID, DESCRIPCION, Elementos
                FROM  viCatalogos a with(nolock) INNER JOIN Catalogos b with(nolock) ON a.Catalogo = b.CatalogoId 
                WHERE CatalogoPadre = 6867 AND
                CatalogoPadre > 0
            ) ctn on ctn.ID = nepp.TipoConstanciaId
            -- Join para obtener nombre de archivo
            -- LEFT JOIN NotificacionElectronica_Archivos nea ON nepp.NotElecId = nea.NotElecId
            LEFT JOIN #TMP_ARCHIVOS t_nea ON nepp.NotElecId = t_nea.NotElecId
            LEFT JOIN dbo.DomicilioPartes dom WITH(NOLOCK) ON nepp.PersonaId = dom.ParteId AND dom.parteid > 0 AND dom.StatusRegistro = 1
            LEFT JOIN Anexos ax WITH(NOLOCK) ON nepp.PersonaId = ax.AnexoParteId AND ads.AsuntoDocumentoId = ax.AsuntoDocumentoId AND ax.AnexoTipoId IN (1, 6)
            LEFT JOIN SISE3.EstadoOficio eo WITH(NOLOCK) ON nepp.AsuntoNeunId = eo.AsuntoNeunId AND ax.AnexoId = eo.AnexoId and ax.folio = eo.folio and eo.Estatus = 1
			--left join JL_REL_UsuarioAsuntoPersona uap on nepp.AsuntoNeunId = uap.fkIdAsuntoNeun and nepp.PersonaId = uap.fkIdPersonaAsunto
			--left join JL_CAT_Usuario cat on uap.fkIdUsuario = cat.kIdUsuario
			LEFT JOIN #TMP_ACUSEELECTRONICOCOE t_aec ON nepp.NotElecId = t_aec.NotElecId
			LEFT JOIN tbx_BitacoraAnexo banx ON ax.Folio = banx.Folio AND banx.OrganismoId = @pi_CatOrganismoId AND banx.AnexoTipoId IN (1, 6) AND ax.Año = banx.Anio AND banx.Activo = 1
        WHERE ad.StatusReg IN (1,2)
        AND nepp.StatusReg IN(1,2) --AGA
            --Filtra solo notificaciones para actuaría
		    AND nepp.TipoNotificacion IN (1, 2, 3, 5, 6, 11, 12, 14 ) 
        AND ad.AsuntoNeunId = @pi_AsuntoNeunId
        --AND ad.AsuntoDocumentoID = @pi_AsuntoDocumentoID
		AND ( ads.AsuntoDocumentoId=ISNULL(@pi_AsuntoDocumentoId, ads.AsuntoDocumentoId)
			      OR ad.SintesisOrden=ISNULL(@pi_SintesisOrden, ad.SintesisOrden))
	END
	ELSE
		BEGIN
		insert into #TMP_NOTIFICACIONESBIS
        SELECT
			nepp.AsuntoNeunId
			,nepp.SintesisOrden
            ,1 --as TipoParte
           , CASE
                WHEN nepp.CatTipoPersonaId = 1 THEN CONCAT(nepp.Nombre,' ', nepp.APaterno, ' ', nepp.AMaterno)
                WHEN nepp.CatTipoPersonaId = 2 AND nepp.Nombre = '' THEN nepp.DenominacionDeAutoridad
                ELSE nepp.Nombre
            END --AS Parte
            , nepp.PersonaId --as ParteID
            , nepp.PromoventeId
			, 0 --AS notiElect  --uap.fkIdPersonaAsunto AS notiElect
			, NULL --'Con usuario PSL' --cat.sUserName as usuarioRegistro
            , IIF(dom.ParteId is not NULL, CONCAT(dom.TipoVialidadId, ' ',dom.NombreVialidad,' ', dom.NumeroExterior, ' INT ', dom.NumeroInterior, ' ', dom.TipoAsentamientoId, ' ',' ', dom.CP, ' ', dom.MunicipioId, ' ', dom.EstadoId), 'Domicilio no registrado')
            , IIF(nepp.PersonaId IS NULL AND nepp.PromoventeId IS NOT NULL, 'PROMOVENTE', cpa.Descripcion) --AS Caracter
            , nepp.TipoConstanciaId
            , CASE
				 WHEN (nepp.DescripcionTipoConstancia IS NOT NULL AND nepp.FechaNotificacion IS NOT NULL ) THEN 3
                 WHEN ( nepp.FechaNotificacion IS NULL) THEN 1
                -- En Proceso es que Tiene un actuario y no tiene acuse Entonces debe ser "Tipo de Acuse"
                 WHEN (nepp.TipoConstanciaId in ('5726','5731','5732') OR t_nea.ArchivoId IS NULL ) THEN 2 --SBGE 12/07/2024 Se quitó Exhorto) 
                -- Notificado es que cuenta conAcuse y ser de tipo de acuse valido (verde)
                -- No debe ser por presencia de archivo, sino por tipo de acuse Verde o valido (confirmar con abogados)
--                WHEN nep.ActuarioId IS NOT NULL AND (nep.TipoConstanciaId is not null and nep.TipoConstanciaId not in ('5726','5732','5736'))
                -- Se remueve tipo constancia notificacion por lista. 5736
                --WHEN nepp.ActuarioId IS NOT NULL AND (nepp.TipoConstanciaId is not null and nepp.TipoConstanciaId not in ('5726','5731','5732','1440'))
				WHEN nepp.ActuarioId IS NOT NULL AND (nepp.TipoConstanciaId is not null and nepp.TipoConstanciaId not in ('5726','5731','5732'))--SBGE 12/07/2024 Se quitó Exhorto
                    AND t_nea.ArchivoId IS NOT NULL THEN 3
                ELSE NULL
            END --as EstadoId
            ,ctn.DESCRIPCION --as EstadoDescripcion
            ,nepp.FechaNotificacion --as EstadoFecha
            ,cnt.sDescripcionCorta --as Tipo --tipo de notificacion
            ,nepp.TipoNotificacion --as TipoId
			--,CONVERT(VARCHAR(10), nepp.FechaUsuarioAsigno, 103) + ' '  + convert(VARCHAR(8),  nepp.FechaUsuarioAsigno, 14) as AsignoFecha
			,nepp.FechaUsuarioAsigno --as AsignoFecha
			,CASE	
				WHEN nepp.IdUsuarioAsigno IS NOT NULL
					THEN CONCAT(emp1.UserName, ' - ' ,emp1.Nombre, ' ', emp1.ApellidoPaterno, ' ', emp1.ApellidoMaterno)
				ELSE 'Sin asignar'
			END --as AsignoPersona
            ,CASE 
                WHEN nepp.ActuarioId <> 10273 
                    THEN CONCAT(emp.Nombre, ' ', emp.ApellidoPaterno, ' ', emp.ApellidoMaterno)
                WHEN  @pi_CatOrganismoId = 1011
                    THEN CONCAT(emp.Nombre, ' ', emp.ApellidoPaterno, ' ', emp.ApellidoMaterno)
                ELSE NULL
            END --as AsignadoActuario
            ,ar.Nombre --as AsignadoZona
            ,t_nea.NombresArchivos --as archivoAcuse
            ,nepp.ActuarioId
            ,nepp.NotElecId
            ,COALESCE(rncoe.iStatusReg, 0) --as TieneCOE
            ,rncoe.fkIdAsuntoNEUNCOE --AS AsuntoNEUNCOE
            ,adc.CatCatalogoAsuntoId --AS TipoComunicacionCOE
            ,ax.Folio
            ,CONCAT(eo.NombreArchivo, eo.ExtensionDocumento) --AS NombreArchivo
            ,eo.uGuid --AS Guid
			,eo.Firmado --AS OficioFirmado
			,COALESCE(t_aec.tieneAcuseCoe, 0) --as tieneAcuseCoe
			, CASE WHEN banx.BitacoraAnexoId IS NULL THEN 0 ELSE 1 END -- AS OficioCancelado
			,nepp.DescripcionTipoConstancia
			,nepp.FechaGeneroNotificacion
			,(SELECT  TOP 1 ISNULL(CO.NombreOficial ,'') 
				FROM AsuntosRelacionados AR WITH(NOLOCK)
					INNER JOIN ASUNTOS A WITH(NOLOCK) ON AR.AsuntoNeunIdOrg = A.AsuntoNeunId
					INNER JOIN CatOrganismos CO WITH(NOLOCK) ON A.CatOrganismoId = CO.CatOrganismoId
					INNER JOIN CatTipoOrganismos CTO WITH(NOLOCK) ON CO.CatTipoOrganismoId = CTO.CatTipoOrganismoId
				WHERE AR.Status=1 and A.StatusReg= 1 AND CO.StatusReg =1 AND AR.AsuntoNeunIdDest = ad.AsuntoNeunId ORDER BY FechaOrigen) as OrigenPromocion			
			, nepp.OrganoParteId
        --INTO #TMP_NOTIFICACIONES
        FROM DeterminacionesJudiciales ad WITH(NOLOCK)
		     left join AsuntosDocumentos ads WITH(NOLOCK) on ad.AsuntoNeunId = ads.AsuntoNeunId and ad.SintesisOrden = ads.SintesisOrden
            -- se hace join para lograr cruce con CatCaracterPersonaAsunto
            CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
            INNER JOIN #TMP_NOTIFICACIONESPARTES nepp ON ad.AsuntoID=nepp.AsuntoId AND ad.AsuntoNeunId=nepp.AsuntoNeunId AND  ad.SintesisOrden = nepp.SintesisOrden
            -- Join para obtener COE
            LEFT JOIN SISE3.REL_NotificacionCOE rncoe WITH(NOLOCK) ON rncoe.iStatusReg = 1 AND nepp.NotElecId = rncoe.fkIdNotElecId
            -- Join para Tipo Comunucacion cuando existe COE
            LEFT JOIN dbo.AsuntosDetalleCatalogos adc WITH(NOLOCK) ON adc.AsuntosNeunId = rncoe.fkIdAsuntoNEUNCOE AND adc.StatusReg = 1 AND adc.TipoAsuntoId = 1287
            -- Join para obtener Caracter
            LEFT join dbo.CatCaracterPersonaAsunto	cpa WITH(NOLOCK) ON nepp.CatCaracterPersonaAsuntoId = cpa.CatCaracterPersonaAsuntoId and cpa.CatTipoAsuntoId = a.CatTipoAsuntoId
            -- Join para obtener Zona de actuario
            LEFT join dbo.Areas ar WITH(NOLOCK) on ar.EmpleadoId = nepp.ActuarioId and ar.StatusReg=1 AND ad.CatOrganismoId = ar.CatOrganismoId
            -- Trae descripcion de tipo de notificacion
            LEFT join dbo.CatNotificaciones cnt WITH(NOLOCK) on cnt.kIdCatNotificaciones = nepp.TipoNotificacion
            -- Join para obtener nombre de actuario
            LEFT join dbo.CatEmpleados emp WITH(NOLOCK) on emp.EmpleadoId = nepp.ActuarioId
			--- 14.06.2024 LAGS
			LEFT join dbo.CatEmpleados emp1 WITH(NOLOCK) on emp1.EmpleadoId = nepp.IdUsuarioAsigno
            -- Join para obtener tipo de persona
            LEFT join dbo.CatTiposPersona ctp WITH(NOLOCK) on nepp.CatTipoPersonaId = ctp.CatTipoPersonaId
            -- Join para catalogo de tipo de acuse
            LEFT join 
            (
                SELECT      ID
                    ,DESCRIPCION
                    ,Elementos
                FROM  viCatalogos a with(nolock) INNER JOIN Catalogos b with(nolock) ON a.Catalogo = b.CatalogoId 
                WHERE CatalogoPadre = 6867 AND
                CatalogoPadre > 0
            ) ctn on ctn.ID = nepp.TipoConstanciaId
            -- Join para obtener nombre de archivo
            -- LEFT JOIN NotificacionElectronica_Archivos nea ON nepp.NotElecId = nea.NotElecId
            LEFT JOIN #TMP_ARCHIVOS t_nea ON nepp.NotElecId = t_nea.NotElecId
            LEFT JOIN dbo.DomicilioPartes dom WITH(NOLOCK) ON nepp.PersonaId = dom.ParteId AND dom.parteid > 0 AND dom.StatusRegistro = 1
            LEFT JOIN Anexos ax WITH(NOLOCK) ON nepp.PersonaId = ax.AnexoParteId AND ads.AsuntoDocumentoId = ax.AsuntoDocumentoId AND ax.AnexoTipoId IN (1, 6)
            LEFT JOIN SISE3.EstadoOficio eo WITH(NOLOCK) ON nepp.AsuntoNeunId = eo.AsuntoNeunId AND ax.AnexoId = eo.AnexoId and ax.folio = eo.folio and eo.Estatus = 1
			--left join JL_REL_UsuarioAsuntoPersona uap on nepp.AsuntoNeunId = uap.fkIdAsuntoNeun and nepp.PersonaId = uap.fkIdPersonaAsunto
			--left join JL_CAT_Usuario cat on uap.fkIdUsuario = cat.kIdUsuario
			LEFT JOIN #TMP_ACUSEELECTRONICOCOE t_aec ON nepp.NotElecId = t_aec.NotElecId
			LEFT JOIN tbx_BitacoraAnexo banx ON ax.Folio = banx.Folio AND banx.OrganismoId = @pi_CatOrganismoId AND banx.AnexoTipoId IN (1, 6) AND ax.Año = banx.Anio AND banx.Activo = 1
        WHERE ad.StatusReg IN (1,2)
        AND nepp.StatusReg=1
            --Filtra solo notificaciones para actuaría
		    AND nepp.TipoNotificacion IN (1, 2, 3, 5, 6, 11, 12, 14 ) 
        AND ad.AsuntoNeunId = @pi_AsuntoNeunId
        --AND ad.AsuntoDocumentoID = @pi_AsuntoDocumentoID
		AND (@pi_AsuntoDocumentoId IS NULL OR ads.AsuntoDocumentoId=ISNULL(@pi_AsuntoDocumentoId, ads.AsuntoDocumentoId))
		AND (@pi_SintesisOrden IS NULL OR ad.SintesisOrden=ISNULL(@pi_SintesisOrden, ad.SintesisOrden))
		
    END

	/********************************************************************/
	/********CONSULTA PARA NOTIFICACIONES DE INTERCONEXIÓN***************/
	SELECT 
	    NBIS.AsuntoNeunId,
		NBIS.SintesisOrden,
		NBIS.TipoParte, 
		NBIS.Parte,
		NBIS.ParteID,
		NBIS.PromoventeId,
		NBIS.notiElect,
		NBIS.usuarioRegistro,
		NBIS.DomicilioParte,
		NBIS.Caracter,
		NBIS.TipoConstanciaId,
		NBIS.EstadoId,
		NBIS.EstadoDescripcion,
		NBIS.EstadoFecha,
		NBIS.Tipo,
		NBIS.TipoId,
		NBIS.AsignoFecha,
		NBIS.AsignoPersona,
		NBIS.AsignadoActuario,
		NBIS.AsignadoZona,
		NBIS.archivoAcuse,
		NBIS.ActuarioId,
		NBIS.NotElecId,
		NBIS.TieneCOE,
		NBIS.AsuntoNEUNCOE,
		NBIS.TipoComunicacionCOE,
		NBIS.Folio,
		NBIS.NombreArchivo,
		NBIS.Guid,
		NBIS.OficioFirmado,
		NBIS.tieneAcuseCoe,
		NBIS.OficioCancelado,
		NBIS.DescripcionConstancia,
		NBIS.FechaGeneracionNotifElect,
		NBIS.OrigenPromocion,
		NBIS.OrganoParteId,
		SN.statusSolicitud AS EstadoSolicitudIOJ,
		SN.fkIdSolicitud AS SolicitudInterconexion
		INTO #TMP_NOTIFICACIONES
	FROM #TMP_NOTIFICACIONESBIS NBIS
	LEFT JOIN [SISE3].[IOJ_Solicitud_Notificacion] SN WITH(NOLOCK) ON NBIS.NotElecId = SN.fkIdNotificacion AND SN.statusReg = 1
	/********************************************************************/

	/********************************************************************/
	/********ACTUALIZACION USUARIO JL***************/
	UPDATE N
	SET N.usuarioRegistro = U.sUserName
	FROM #TMP_NOTIFICACIONES N
	LEFT JOIN JL_REL_UsuarioAsuntoPersona RU 
		ON N.AsuntoNeunId = RU.fkIdAsuntoNeun AND N.ParteID = RU.fkIdPersonaAsunto 
			AND RU.fkIdEstatus = 1 AND RU.bConsultaNotE = 1
	INNER JOIN JL_CAT_Usuario U ON RU.fkIdUsuario = U.kIdUsuario 
		AND U.bActivo = 1 AND U.fkIdEstatus = 1
	WHERE RU.kIdUsuarioExpedienteParte IS NOT NULL
	/********************************************************************/

   -- Crea tabla temporal para filtrar notificaciones
    SELECT 
	      [AsuntoNeunid],
	      [SintesisOrden],
          [TipoParte],
          [Parte],
          [ParteId],
          [PromoventeId],
          [DomicilioParte],
          [Caracter],
          [EstadoId],
          [TipoConstanciaId] as TipoDeAcuse,
          CASE WHEN EstadoId = 1 THEN 'Pendiente'
              WHEN EstadoId = 2 THEN [EstadoDescripcion]
              WHEN EstadoId = 3 THEN 'Notificado'
              ELSE NULL
          END as Estado,
          [EstadoFecha],
          [Tipo],
          [TipoId],
          [AsignoPersona],
          [AsignoFecha],
          [AsignadoActuario],
          [AsignadoZona],
          [archivoAcuse],
		  [ActuarioId],
          [NotElecId],
          [TieneCOE],
          [AsuntoNEUNCOE],
          [TipoComunicacionCOE],
          [Folio],
          [NombreArchivo],
	      [notiElect],
	      [usuarioRegistro],
          [Guid],
	      [OficioFirmado],
	      [tieneAcuseCoe],
		  [OficioCancelado],
		  [DescripcionConstancia],
		  [FechaGeneracionNotifElect],
		  [OrigenPromocion],
		  [OrganoParteId],
		  [EstadoSolicitudIOJ],
		  [SolicitudInterconexion]
    INTO #TMP_NOTIFICACIONES_FILTRADAS
    FROM #TMP_NOTIFICACIONES
    WHERE  
        (
            TRIM(ISNULL(@pi_Texto, '')) = ''
            OR CONCAT(Parte, Caracter, EstadoDescripcion, Tipo, TipoID, AsignoPersona, AsignadoActuario, AsignadoZona, archivoAcuse) LIKE '%' + TRIM(ISNULL(@pi_Texto, '')) + '%'
        )
        AND 
		(
            -- 1=Partes, 2=Promoventes, 3=Autoridades Judiciales
            (@pi_FiltroTipoParteID = 0 AND 1 = 1)
            OR (@pi_FiltroTipoParteID = TipoParte)
        )
        AND 
		(
            (@pi_FiltroTipoNotificacionID = 0 AND 1 = 1)
            OR (@pi_FiltroTipoNotificacionID = TipoId )
        )
        AND 
		(
            (@pi_FiltroActuarioID = 0 AND 1 = 1)
            OR (@pi_FiltroActuarioID = ActuarioId )
        )

-- Obtiene conteos de tabla filtrada
    SELECT @Todos = COUNT(*) from #TMP_NOTIFICACIONES_FILTRADAS
    SELECT @Notificados = COUNT(*) from #TMP_NOTIFICACIONES_FILTRADAS where Estado = 'Notificado'
    SELECT @Pendientes = COUNT(*) from #TMP_NOTIFICACIONES_FILTRADAS where Estado = 'Pendiente'	
    SELECT @EnProceso = COUNT(*) from #TMP_NOTIFICACIONES_FILTRADAS where Estado not in  ('Notificado', 'Pendiente')
    SELECT @pagina = @pi_NumeroPagina
    SELECT @totalPaginas = CEILING(CAST(@Todos as FLOAT) / iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina))
    SELECT @totalRegistros = @Todos


    SELECT 
        @Todos as Vertodo, 
        @Pendientes as Pendiente, 
        @EnProceso as EnProceso, 
        @Notificados as Notificados,
        @pagina as pagina,
        @totalPaginas as totalPaginas,
        @totalRegistros as totalRegistros

    -- Regresa dataset filtrado y con orden aplicado
    SELECT * 
	FROM #TMP_NOTIFICACIONES_FILTRADAS
    WHERE 
         (
            (@pi_FiltroTipo = 0 AND 1 = 1)
            OR (@pi_FiltroTipo = 1 AND Estado = 'Pendiente')
            OR (@pi_FiltroTipo = 2 AND Estado NOT IN ('Pendiente', 'Notificado'))
            OR (@pi_FiltroTipo = 3 AND Estado = 'Notificado')
        )
    ORDER BY 
  			CASE WHEN (@pi_OrdenarPor= 'Parte' and @pi_TipoOrden = 0) THEN Parte END ASC,
			CASE WHEN (@pi_OrdenarPor= 'Parte' and @pi_TipoOrden = 1) THEN Parte END DESC,
  			CASE WHEN (@pi_OrdenarPor= 'Estado' and @pi_TipoOrden = 0) THEN EstadoId END ASC,
			CASE WHEN (@pi_OrdenarPor= 'Estado' and @pi_TipoOrden = 1) THEN EstadoId END DESC,
  			CASE WHEN (@pi_OrdenarPor= 'Tipo' and @pi_TipoOrden = 0) THEN Tipo END ASC,
			CASE WHEN (@pi_OrdenarPor= 'Tipo' and @pi_TipoOrden = 1) THEN Tipo END DESC,
  			CASE WHEN (@pi_OrdenarPor= 'AsignoPersona' and @pi_TipoOrden = 0) THEN AsignoPersona END ASC,
			CASE WHEN (@pi_OrdenarPor= 'AsignoPersona' and @pi_TipoOrden = 1) THEN AsignoPersona END DESC,
  			CASE WHEN (@pi_OrdenarPor= 'AsignadoActuario' and @pi_TipoOrden = 0) THEN AsignadoActuario END ASC,
			CASE WHEN (@pi_OrdenarPor= 'AsignadoActuario' and @pi_TipoOrden = 1) THEN AsignadoActuario END DESC,
  			CASE WHEN (@pi_OrdenarPor= 'ArchivoAcuse' and @pi_TipoOrden = 0) THEN ArchivoAcuse END ASC,
			CASE WHEN (@pi_OrdenarPor= 'ArchivoAcuse' and @pi_TipoOrden = 1) THEN ArchivoAcuse END DESC,
	    	CASE WHEN (@pi_OrdenarPor not in('Parte','Estado','Tipo','ActuarioAsigno','ArchivoAcuse')) THEN EstadoId END ASC, 
            CASE WHEN (@pi_OrdenarPor not in('Parte','Estado','Tipo','ActuarioAsigno','ArchivoAcuse')) THEN EstadoFecha END ASC,
			-- En primera carga ordenar por estados y despues por fecha
            CASE WHEN (@pi_primeraCarga = 1) THEN EstadoId END ASC,
            CASE WHEN (@pi_primeraCarga = 1) THEN EstadoFecha END ASC
				OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
			FETCH NEXT IIF(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)  ROWS ONLY

	-- Limpia tablas temporales
    DROP TABLE #TMP_NOTIFICACIONESPARTES
    DROP TABLE #TMP_ARCHIVOS
    DROP TABLE #TMP_NOTIFICACIONES
    DROP TABLE #TMP_NOTIFICACIONES_FILTRADAS
	DROP TABLE #TMP_ACUSEELECTRONICOCOE
END
