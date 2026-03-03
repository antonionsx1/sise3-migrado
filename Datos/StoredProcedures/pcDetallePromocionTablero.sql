USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcDetallePromocionTablero]    Script Date: 12/1/2023 6:14:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** 22/08/2023                 ******/
/****** Proyecto: SISE3       ******/
/****** Autor: Christian Araujo - MS  ******/
/****** Objetivo: Carga el detalle de una promoción electrónica seleccionada en el detalle de promoción******/
/****** EXEC SISE3.pcDetallePromocionTablero 180, 30314167,6712,0,155,2023 ******/

CREATE PROCEDURE [SISE3].[pcDetallePromocionTablero] (
--DECLARE
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA EL IDENTIFICADOR DEL EXPEDIENTE 
	@pi_AsuntoNeunId BIGINT ,
	-- REPRESENTA EL IDENTITIFICADOR DEL EMPLEADO
	@pi_UsuariId INT ,
	-- Recibe el valor de el origen de la consulta 
	--0 Promoción física, 6 Promocion Electronica, 14 PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN, 
	--22 PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES, 5 DEMANDAS ELECTRÓNICAS, 15 DEMANDAS ELECTRÓNICAS INTERCONEXIÓN, 29 COMUNICACIONES OFICIALES
	@pi_Origen INT,
	--REPRESENTA EL NUMERO DE ORDEN NECESARIO PARA LA CONSULTA CUANDO EL ORIGEN ES CERO
	@pi_NumeroOrden INT = NULL,
	--REPRESENTA EL AÑO DE LA PROMOCIÓN NECESARIO PARA LA CONSULTA CUANDO EL ORIGEN ES CERO
	@pi_YearPromocion INT = NULL,
	--REPRESENTA LA LLAVE CUANDO LA PROMOCIÓN ES ELECTRÓNICA
	@pi_kIdElectronica BIGINT = NULL
	)
AS
BEGIN
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
	
	
	DECLARE @Anexos VARCHAR(MAX),
		@Origen INT, 
		@pFolio BIGINT

		SET @pFolio  = 0;

	IF @pi_Origen = 0
	BEGIN
		--SE CONSULTAN LOS DATOS DE LOS ANEXOS 
		SELECT 
			NombreArchivo,  
			TipoAnexo = TipoArchivo.DESCRIPCION,
			Caracter = CaracterArchivo.DESCRIPCION,
			Descripcion = DescripcionAnexo.DESCRIPCION,
			p.DescripcionAnexo,
			p.Fojas,
			p.ClaseAnexo,
			p.CaracterAnexo,
			p.Origen,
            p.Consecutivo
		INTO #tmpAnexos
		FROM PromocionArchivos p 
		LEFT JOIN viCatalogos TipoArchivo ON p.ClaseAnexo = TipoArchivo.ID AND TipoArchivo.Catalogo = 502
		LEFT JOIN viCatalogos CaracterArchivo ON p.CaracterAnexo = CaracterArchivo.ID  AND CaracterArchivo.Catalogo = 27
		LEFT JOIN viCatalogos DescripcionAnexo ON p.DescripcionAnexo = DescripcionAnexo.ID  AND DescripcionAnexo.Catalogo = 17
		WHERE  p.StatusArchivo = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden

		SET @Anexos = (
			SELECT *
			FROM #tmpAnexos
			WHERE ClaseAnexo <> 0
			FOR JSON AUTO
		)
		/*SE CONSULTA EL DETALLE DE LA PROMOCIÓN*/

		--SE OBTIENE EL DETALLE SI LA PROMOCION ES ELECTRÓNICA 
		SELECT @origen = p.OrigenPromocion
		FROM Promociones p
		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden

		IF(@Origen IN (5,6))
		BEGIN
			SELECT @pi_kIdElectronica = fkIdPromocion  
			FROM JL_REL_PromocionSISE
			WHERE YearPromocion = @pi_YearPromocion
			AND AsuntoNeunId = @pi_AsuntoNeunId
			AND CatOrganismoId = @pi_CatOrganismoId
			AND NumeroOrden = @pi_NumeroOrden

			SET @Origen = 1
			
			IF(@pi_kIdElectronica IS NULL)
			BEGIN			
				SELECT @pi_kIdElectronica = fkIdDemanda
				FROM JL_REL_DemandaSISE
				WHERE YearPromocion = @pi_YearPromocion
				AND AsuntoNeunId = @pi_AsuntoNeunId
				AND CatOrganismoId = @pi_CatOrganismoId
				AND NumeroOrden = @pi_NumeroOrden
				SET @Origen = 4
			END
		END
		ELSE IF(@Origen = 14)
		BEGIN
			SELECT @pi_kIdElectronica = fkIdPromocion  
			FROM ICOIJ_REL_PromocionSISE
			WHERE YearPromocion = @pi_YearPromocion
			AND AsuntoNeunId = @pi_AsuntoNeunId
			AND CatOrganismoId = @pi_CatOrganismoId
			AND NumeroOrden = @pi_NumeroOrden
			SET @Origen = 2
		END
		ELSE IF(@Origen = 22)
		BEGIN
			SELECT @pi_kIdElectronica = fkIdPromocion  
			FROM IOJ_REL_PromocionSISE
			WHERE YearPromocion = @pi_YearPromocion
			AND AsuntoNeunId = @pi_AsuntoNeunId
			AND CatOrganismoId = @pi_CatOrganismoId
			AND NumeroOrden = @pi_NumeroOrden
			SET @Origen = 3
		END

		SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
				p.AsuntoNeunId, 
				a.AsuntoAlias Expediente,
				a.CatTipoAsunto,
				a.CatTipoAsuntoId,--Nuevo
				a.TipoProcedimiento,
				a.TipoProcedimientoId, --Nuevo
				a.NumeroOCC as OCC,
				--c.Cuaderno,
				etl.TipoCuadernoDesc as Cuaderno,
				--c.CuadernoId, ---Nuevo
				etl.TipoCuadernoId as CuadernoId,
				convert(BIGINT,p.NumeroRegistro) AS NumeroRegistro,
				o.sNombreOrigenPromocion OrigenPromocion,
				SecretarioNombre = SISE3.[ObtieneNombreEmpleado](p.Secretario, 'Nombres'),
				SecretarioId = p.Secretario,
				UserName = SISE3.[ObtieneNombreEmpleado](p.Secretario, 'UserName'),
				Mesa = p.Mesa,
				p.FechaPresentacion,
				p.HoraPresentacion,
				TipoPromociones = CASE p.ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END,
				Contenido = ISNULL(cp.CatalogoPromocionDescripcion,''),
				cp.CatalogoPromocionId AS ContenidoId, --Nuevo
				TipoPromoventeId = ISNULL(p.ClasePromovente,1) , 
				PromoventeNombre = ISNULL(
					CASE ISNULL(p.ClasePromovente,1) 
						WHEN 1 THEN pas.Nombre
						WHEN 2 THEN pr.Nombre
						WHEN 3 THEN SISE3.[ObtieneNombreEmpleado](aj.EmpleadoId, 'Nombre')  
						WHEN 4 THEN SISE3.[ObtieneNombreEmpleado](ajo.AJOUsuario, 'Nombre') 
						END,''),
				PromoventeApellidoPaterno = ISNULL(
					CASE ISNULL(p.ClasePromovente,1) 
						WHEN 1 THEN pas.APaterno
						WHEN 2 THEN pr.APaterno
						WHEN 3 THEN SISE3.[ObtieneNombreEmpleado](aj.EmpleadoId, 'ApellidoPaterno')  
						WHEN 4 THEN SISE3.[ObtieneNombreEmpleado](ajo.AJOUsuario, 'ApellidoPaterno') 
						END,''),
				PromoventeApellidoMaterno = ISNULL(
					CASE ISNULL(p.ClasePromovente,1)
						WHEN 1 THEN pas.AMaterno
						WHEN 2 THEN pr.AMaterno
						WHEN 3 THEN SISE3.[ObtieneNombreEmpleado](aj.EmpleadoId, 'ApellidoMaterno')  
						WHEN 4 THEN SISE3.[ObtieneNombreEmpleado](ajo.AJOUsuario, 'ApellidoMaterno') 
						END,''),
				IdPromovente = ISNULL(
					CASE ISNULL(p.ClasePromovente,1) 
						WHEN 1 THEN p.TipoPromovente
						WHEN 2 THEN pr.PromoventeId
						WHEN 3 THEN aj.EmpleadoId
						WHEN 4 THEN ajo.AJOId
						END,''),
				DenominacionAutoridad = CASE WHEN ISNULL(p.ClasePromovente,1)  = 2 THEN ISNULL(paspr.DenominacionDeAutoridad,'') ELSE  ISNULL(pas.DenominacionDeAutoridad,'') END,
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
				ConArchivo = IIF(pa.AsuntoNeunId IS NULL, 0,1),
				EsDemanda = IIF(@origen = 4, 1, 0),
				OrigenPromocionId = p.OrigenPromocion,
				@pFolio AS Folio,
				EsPromocionE= IIF(@origen = 4, 1, 0),
				ad.CatAutorizacionDocumentosId,
				pa.NombreArchivo,
				Origen = 0,
				--Fojas=Isnull(pa.Fojas,0),
				Fojas = (SELECT Fojas 
							From PromocionArchivos pa2 
							where pa2.AsuntoNeunId = p.AsuntoNeunId
							AND pa2.CatOrganismoId = p.CatOrganismoId 
							AND pa2.NumeroOrden = p.NumeroOrden
							AND pa2.Origen = p.OrigenPromocion 
							AND pa2.YearPromocion = p.YearPromocion
							AND pa2.StatusArchivo in (-1,1)-----27/11/2023 Gemma commenta que se devuelva el numero de fojas sin importar el estado del archivo (-1 pendiente y 1 activo)
							AND pa2.ClaseAnexo = 0),
				p.NumeroOrden,
				TipoPromovente = TipoPromovente.DESCRIPCION,

				ParteAsociadaId = paspr.PersonaId, 
				ParteAsociadaNombre = paspr.Nombre, 
				ParteAsociadaApellidoPaterno = paspr.APaterno,
				ParteAsociadaApellidoMaterno = paspr.AMaterno,
				CaracterParteAsociadaPromovente = ccpapr.Descripcion,
				CaracterParteAsociadaId = paspr.CatCaracterPersonaAsuntoId,
				TipoPersonaParteAsociadaPromovente= ctppr.Descripcion,
				TipoParteAsociadaPromoventeId =  paspr.CatTipoPersonaId , 
				
				CaracterParte = ccpa.Descripcion,
				CaracterParteId = pas.CatCaracterPersonaAsuntoId, 
				TipoPersonaParte = ctp.Descripcion,
				TipoPersonaParteId = pas.CatTipoPersonaId,
				ParteNombre = pas.Nombre, 
				ParteApellidoPaterno = pas.APaterno,
				ParteApellidoMaterno = pas.AMaterno,
				Capturo = SISE3.[ObtieneNombreEmpleado](p.RegistroEmpleadoId, ''),
				FechaCaptura = p.FechaAlta,
				Anexos = @Anexos, 
				AutoridadJudicialId = aj.AutoridadJudicialId,
				AutoridadOrganismoId = aj.CatOrganismoId,
				p.CatOrganismoId,
				cat.NombreOficial as CatOrganismo
				,p.YearPromocion
				,CAST (CASE WHEN ad.NombreDocumento IS NULL THEN 0 ELSE 1 END AS BIT) AS ConAcuerdo
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
		--Validar con Gemma
		INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL ON ETL.TipoCuadernoId = p.TipoCuaderno 
		LEFT JOIN tbx_CatTiposAsunto tac ON ETL.TipoCuadernoId = tac.CuadernoId AND ETL.TipoAsuntoId = tac.CatTipoAsuntoId
		LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
		--fin validar con Gemma
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion	
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId
													AND pa.CatOrganismoId = p.CatOrganismoId 
													AND pa.NumeroOrden = p.NumeroOrden
													AND pa.Origen = p.OrigenPromocion 
													AND pa.YearPromocion = p.YearPromocion
													AND pa.StatusArchivo = 1-----27/11/2023 Gemma commenta que se devuelva el numero de fojas sin importar el estado del archivo
													AND pa.ClaseAnexo = 0
		LEFT JOIN CatPromocion cp WITH(NOLOCK) ON cp.CatalogoPromocionId = p.TipoContenido
		LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1
		LEFT JOIN Promovente pr ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 
		LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
		LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
		LEFT JOIN AsuntosDocumentos ad on ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId
		LEFT JOIN viCatalogos tipoPromovente ON pr.Tipo = tipoPromovente.ID
		LEFT JOIN CatCaracterPersonaAsunto ccpa ON ccpa.CatCaracterPersonaAsuntoId = pas.CatCaracterPersonaAsuntoId
		LEFT JOIN CatTiposPersona ctp ON ctp.CatTipoPersonaId = pas.CatTipoPersonaId
		LEFT JOIN CatOrganismos cat ON p.CatOrganismoId = cat.CatOrganismoId
		LEFT JOIN SISE3.PromocionPromoventeParte ppp ON ppp.StatusReg = 1 AND ppp.CatOrganismoId = p.CatOrganismoId AND ppp.AsuntoNeunId = p.AsuntoNeunId AND ppp.NumeroOrden = p.NumeroOrden
		and ppp.PromoventeId = p.TipoPromovente
		LEFT JOIN PersonasAsunto paspr ON paspr.PersonaId = ppp.PersonaId 
		LEFT JOIN CatCaracterPersonaAsunto ccpapr ON ccpapr.CatCaracterPersonaAsuntoId = paspr.CatCaracterPersonaAsuntoId
		LEFT JOIN CatTiposPersona ctppr ON ctppr.CatTipoPersonaId = paspr.CatTipoPersonaId 

		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden
		--AND (@pi_FechaPresentacionIni IS NULL OR CONVERT(DATE,p.FechaPresentacion) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
		--AND (CONVERT(DATE,p.FechaPresentacion) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)

		

		/* SI EXISTE LA CLAVE DE LA PROMOCIÓN ELECTRÓNICA LA CONSULTA*/
		IF(@pi_kIdElectronica IS NOT NULL)
		BEGIN
			EXEC [SISE3].[pcDetallePromocionTablero]  
				@pi_CatOrganismoId = @pi_CatOrganismoId,
				@pi_AsuntoNeunId = @pi_AsuntoNeunId,
				@pi_UsuariId = @pi_UsuariId,
				@pi_Origen = @Origen,
				@pi_kIdElectronica = @pi_kIdElectronica
		END
	END
	ELSE IF @pi_Origen = 6
	BEGIN
		/***** PROMOCIONES ELECTRÓNICAS ****/
		SELECT
			IIF(p.fkIdOrigen = 30, 'Promoción OCC','Promoción Electrónica') AS Tipo,
			p.fkIdAsuntoNeun AsuntoNeunId, a.AsuntoAlias as Expediente, a.CatTipoAsunto as CatTipoAsunto,a.CatTipoAsuntoId, 
			a.TipoProcedimiento as TipoProcedimiento, a.TipoProcedimientoId as TipoProcedimientoId,
			p.kIdPromocion NumeroRegistro, o.sNombreOrigenPromocion OrigenPromocion, p.fFechaAlta FechaPresentacion, 
			PromoventeNombre = u.sNombre , 
			PromoventeApellidoPaterno = u.sApellidoPaterno, 
			PromoventeApellidoMaterno = u.sApellidoMaterno,
			p.fkIdOrigen OrigenPromocionId, p.kIdPromocion Folio,ps.YearPromocion,
			COUNT(p.kIdPromocion) as TotalArchivos,
			CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', arc.sNombreArchivo, arc.sExtension ,'"}'), ','),']') Archivos
		FROM dbo.JL_MOV_Promocion AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a	
		LEFT JOIN JL_REL_PromocionArchivo da with(nolock) on p.kIdPromocion=da.fkIdPromocion AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS arc ON arc.kIdArchivo = da.fkIdArchivo and arc.fkIdEstatus = 1	
		LEFT JOIN	JL_REL_PromocionSISE ps with(nolock) ON p.kIdPromocion = ps.fkIdPromocion and p.fkIdAsuntoNeun = ps.AsuntoNeunId and p.fkIdOrgano = ps.CatOrganismoId
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 30, 29,5)
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		WHERE a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano
		AND p.kIdPromocion = @pi_kIdElectronica
		GROUP BY p.fkIdAsuntoNeun,		a.AsuntoAlias, 
				a.CatTipoAsunto, a.CatTipoAsuntoId,		
				a.TipoProcedimiento, a.TipoProcedimientoId,
				p.kIdPromocion,			o.sNombreOrigenPromocion, 
				p.fFechaAlta,			u.sNombre,
				u.sApellidoPaterno,		u.sApellidoMaterno,
				p.fkIdOrigen,			p.kIdPromocion
				,ps.YearPromocion
	END
	ELSE IF @pi_Origen = 14
	BEGIN
		/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ****/
		SELECT 	'Promoción Electrónica Interconexión' AS Tipo,
				p.fkIdAsuntoNeun as AsuntoNeunId, a.AsuntoAlias as Expediente, a.CatTipoAsunto as CatTipoAsunto, a.CatTipoAsuntoId,
				a.TipoProcedimiento as TipoProcedimiento,a.TipoProcedimientoId,
				p.kIdPromocion as NumeroRegistro, o.sNombreOrigenPromocion as OrigenPromocion, p.fFechaAlta as FechaPresentacion,
				PromoventeNombre = u.sNombre , 
				PromoventeApellidoPaterno = u.sApellidoPaterno, 
				PromoventeApellidoMaterno = u.sApellidoMaterno,
				p.fkIdOrigen as OrigenPromocionId, p.kIdPromocion as Folio,ps.YearPromocion,
				COUNT(p.kiIdFolio) as TotalArchivos,
				CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', arc.sNombreArchivo, arc.sExtension ,'"}'), ','),']') Archivos
		FROM dbo.ICOIJ_MOV_Promocion AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
		LEFT JOIN ICOIJ_REL_PromocionSISE ps with(nolock) ON p.kiIdFolio = ps.fkIdPromocion AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 14
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		LEFT JOIN ICOIJ_MOV_Archivo arc ON arc.kiIdFolio = p.kiIdFolio
		WHERE a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano
		AND p.fkIdEstatus = 1
		AND p.kiIdFolio = @pi_kIdElectronica
		GROUP BY p.fkIdAsuntoNeun,		a.AsuntoAlias, 
				a.CatTipoAsunto, a.CatTipoAsuntoId
				,a.TipoProcedimiento, a.TipoProcedimientoId, 
				p.kIdPromocion,			o.sNombreOrigenPromocion, 
				p.fFechaAlta,			u.sNombre,
				u.sApellidoPaterno,		u.sApellidoMaterno, 
				p.fkIdOrigen,ps.YearPromocion
	END
	ELSE IF @pi_Origen = 22
	BEGIN
		/***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES ****/
			SELECT  'Promoción Electrónica Interconexión OJ' AS Tipo,
				p.fkIdAsuntoNeun as AsuntoNeunId, a.AsuntoAlias as Expediente, a.CatTipoAsunto as CatTipoAsunto, a.CatTipoAsuntoId,
				a.TipoProcedimiento as TipoProcedimiento,a.TipoProcedimientoId,
				p.kIdPromocion as NumeroRegistro, o.sNombreOrigenPromocion as OrigenPromocion, p.fFechaAlta as FechaPresentacion,
				PromoventeNombre = u.sNombre , 
				PromoventeApellidoPaterno = u.sApellidoPaterno, 
				PromoventeApellidoMaterno = u.sApellidoMaterno,
				p.fkIdOrigen as OrigenPromocionId, p.kIdPromocion as Folio,ps.YearPromocion,
				COUNT(p.kiIdFolio) as TotalArchivos,
				CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', arc.sNombreArchivo, arc.sExtension ,'"}'), ','),']') Archivos
		FROM IOJ_MOV_PromocionOJ AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
		LEFT JOIN  IOJ_REL_PromocionSISE ps with(nolock) ON p.kiIdFolio = ps.fkIdPromocion AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 14
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		LEFT JOIN IOJ_REL_PromocionArchivoOJ ar ON ar.fkIdPromocion = p.kiIdFolio
		LEFT JOIN IOJ_MOV_Archivo arc ON arc.kIdArchivo = ar.fkIdArchivo
		WHERE a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano		
		AND p.kiIdFolio = @pi_kIdElectronica
		GROUP BY p.fkIdAsuntoNeun,		a.AsuntoAlias, 
				a.CatTipoAsunto,		a.CatTipoAsuntoId,
				a.TipoProcedimiento, a.TipoProcedimientoId,
				p.kIdPromocion,			o.sNombreOrigenPromocion, 
				p.fFechaAlta,			u.sNombre,
				u.sApellidoPaterno,		u.sApellidoMaterno,
				p.fkIdOrigen,ps.YearPromocion
	END
	ELSE IF @pi_Origen = 5
	BEGIN
		/***** DEMANDAS ELECTRÓNICAS ****/
		SELECT 
			IIF(p.fkIdOrigen = 29, 'Recurso o demanda OCC','Demanda Electrónica') AS Tipo,
			o.sNombreOrigenPromocion as OrigenPromocion,
			p.fFechaAlta as FechaPresentacion,
			PromoventeNombre = u.sNombre , 
			PromenventeApellidoPaterno = u.sApellidoPaterno, 
			PromoventeApellidoMaterno = u.sApellidoMaterno,
			p.fkIdOrigen as OrigenPromocionId, 
			p.kIdDemanda as Folio, 
			CAST(ISNULL(e.fkIdNumeroRegistroOCC,0) AS VARCHAR(150)) as OCC, 
			COUNT(p.kIdDemanda) as TotalArchivos,
			CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', arc.sNombreArchivo, arc.sExtension ,'"}'), ','),']') Archivos
		FROM JL_MOV_Demanda AS p WITH (nolock) 
		LEFT JOIN JLOCCSISE_MOV_EnLinea AS e ON e.fkIdDemandaJL = p.kIdDemanda
		LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on p.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS arc ON arc.kIdArchivo = da.fkIdArchivo and arc.fkIdEstatus = 1	
		LEFT JOIN dbo.JL_REL_DemandaSISE rdem WITH (nolock) on rdem.fkIdDemanda = p.kIdDemanda and rdem.AsuntoNeunId = p.fkIdAsuntoNeun and rdem.CatOrganismoId = p.fkIdOrgano
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 29, 29,5)
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
		WHERE coe.fkIdDemanda IS NULL		
		AND p.fkIdEstatus = 1
		AND p.kIdDemanda = @pi_kIdElectronica
		GROUP BY o.sNombreOrigenPromocion,  p.fFechaAlta,
				u.sNombre,					u.sApellidoPaterno,
				u.sApellidoMaterno,			p.fkIdOrigen, 
				p.kIdDemanda, 				e.fkIdNumeroRegistroOCC
	END
	ELSE IF @pi_Origen = 15
	BEGIN
		/***** DEMANDAS ELECTRÓNICAS INTERCONEXIÓN ****/
		SELECT	 
			'Demanda Electrónica Interconexión' AS Tipo,
			o.sNombreOrigenPromocion as OrigenPromocion,
			p.fFechaAlta as FechaPresentacion,
			PromoventeNombre = u.sNombre , 
			PromonventeApellidoPaterno = u.sApellidoPaterno, 
			PromoventeApellidoMaterno = u.sApellidoMaterno,
			p.fkIdOrigen as OrigenPromocionId, 
			p.kiIdFolio as Folio, 
			ISNULL(e.fkIdNumeroRegistroOCC,0) as OCC, 
			COUNT(p.kiIdFolio) as TotalArchivos,
			CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', arc.sNombreArchivo, arc.sExtension ,'"}'), ','),']') Archivos
		FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
		LEFT JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
		INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
		LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = p.kIdDemanda and irdem.AsuntoNeunId = p.fkIdAsuntoNeun and irdem.CatOrganismoId = p.fkIdOrgano
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 5
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
		WHERE p.fkIdEstatus = 1 
		AND p.fkIdOrigen = 37
		AND p.kiIdFolio = @pi_kIdElectronica
		GROUP BY o.sNombreOrigenPromocion,		p.fFechaAlta,
			u.sNombre,							u.sApellidoPaterno,
			u.sApellidoMaterno,					p.fkIdOrigen, 
			p.kiIdFolio,						e.fkIdNumeroRegistroOCC
	END 
	ELSE IF @pi_Origen = 29
	BEGIN
		/***** COMUNICACIONES OFICIALES ****/
		SELECT	 
			'Demanda Electrónica Comunicación Oficial' AS Tipo,
			o.sNombreOrigenPromocion as OrigenPromocion,
			p.fFechaAlta as FechaPresentacion,
			PromoventeNombre = u.sNombre , 
			PromenventeApellidoPaterno = u.sApellidoPaterno, 
			PromoventeApellidoMaterno = u.sApellidoMaterno,
			p.fkIdOrigen as OrigenPromocionId, 
			p.kiIdFolio as Folio, 
			ISNULL(e.fkIdNumeroRegistroOCC,0) as OCC, 
			COUNT(p.kiIdFolio) as TotalArchivos,
			CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', arc.sNombreArchivo, arc.sExtension ,'"}'), ','),']') Archivos
		FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
		LEFT JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
		INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
		LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = p.kIdDemanda and irdem.AsuntoNeunId = p.fkIdAsuntoNeun and irdem.CatOrganismoId = p.fkIdOrgano
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 5
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
		WHERE coe.fkIdDemanda IS NOT NULL
		AND p.fkIdEstatus = 1 
		AND e.fkIdNeunSISE IS NULL
		AND p.kiIdFolio = @pi_kIdElectronica
		GROUP BY o.sNombreOrigenPromocion,		p.fFechaAlta,
			u.sNombre,							u.sApellidoPaterno,
			u.sApellidoMaterno,					p.fkIdOrigen, 
			p.kiIdFolio,						e.fkIdNumeroRegistroOCC
	END
	ELSE
	BEGIN
		PRINT 'Tipo no registrado, verificar'
	END
END



GO

