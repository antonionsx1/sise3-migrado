SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** 26/12/2023                 ******/
/****** Proyecto: SISE3       ******/
/****** Autor: Saúl García  ******/
/****** Objetivo: Carga el detalle de una promoción electrónica seleccionada en el detalle de una promoción electrónica******/
/****** EXEC SISE3.pcDetallePromocionElectronicaTablero 0, 0,1,5,0,0,2016859 ******/


CREATE OR ALTER PROCEDURE [SISE3].[pcDetallePromocionElectronicaTablero] (
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
	@pi_YearPromocion INT = NULL
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
		@pFolio BIGINT,
		@Archivos VARCHAR(MAX),
        @pi_ConExpediente BIT

		SET @pFolio  = 0;

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

	IF(@pi_Origen = 6)
	BEGIN
		
		SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo, moa.sExtension ,'"}'), ','),']')
		FROM JL_REL_PromocionSISE ps with(nolock) 
		LEFT JOIN JL_REL_PromocionArchivo pa ON ps.fkIdPromocion = pa.fkIdPromocion
		LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = pa.fkIdArchivo
		WHERE ps.AsuntoNeunId = @pi_AsuntoNeunId
		AND ps.CatOrganismoId = @pi_CatOrganismoId
		AND ps.YearPromocion = @pi_YearPromocion
        AND ps.NumeroOrden = @pi_NumeroOrden
		AND moa.fkIdEstatus = 1

		SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,--Nuevo
			a.TipoProcedimiento,
			a.TipoProcedimientoId, --Nuevo
			a.NumeroOCC as OCC,
			--c.Cuaderno,
			c.Cuaderno as Cuaderno,
			--c.CuadernoId, ---Nuevo
			c.CuadernoId as CuadernoId,
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
			ConArchivo = IIF(moa.sNombreArchivo IS NULL, 0,1),
			EsDemanda = IIF(@origen IN (5,15),1,0),
			OrigenPromocionId = p.OrigenPromocion,
			ps.fkIdPromocion AS Folio,
			EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
			ad.CatAutorizacionDocumentosId,
			moa.sNombreArchivo+moa.sExtension NombreArchivo,
			Origen = 0,
			--Fojas=Isnull(pa.Fojas,0),
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
			,FechaAlta=rel.fFechaAlta
			,PromoventeRegistro = SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno)
			,@Archivos Archivos
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
		--Validar con Gemma
		-- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL ON ETL.TipoCuadernoId = p.TipoCuaderno 
		LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId and tac.CatTipoAsuntoId = a.CatTipoAsuntoId			
		LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
		--fin validar con Gemma
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion
		LEFT JOIN JL_REL_PromocionSISE ps with(nolock) ON p.AsuntoNeunId = ps.AsuntoNeunId 
													   AND p.CatOrganismoId = ps.CatOrganismoId
													   AND p.YearPromocion = ps.YearPromocion
                                                       AND p.NumeroOrden = ps.NumeroOrden
		LEFT JOIN dbo.JL_MOV_Promocion rel ON ps.fkIdPromocion = rel.kIdPromocion AND ps.OrigenPromocion != 22
		LEFT JOIN JL_REL_PromocionArchivo pa ON ps.fkIdPromocion = pa.fkIdPromocion
		LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = pa.fkIdArchivo
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
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = rel.fkIdUsuario
		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden
	END
	ELSE IF (@pi_Origen = 14)
	BEGIN
		
		SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo, moa.sExtension ,'"}'), ','),']')
		FROM ICOIJ_REL_PromocionSISE ps with(nolock) 
		LEFT JOIN ICOIJ_MOV_Promocion pro ON pro.kIdPromocion = ps.fkIdPromocion
		LEFT JOIN ICOIJ_MOV_Archivo moa ON moa.kiIdFolio = pro.kiIdFolio
		WHERE ps.AsuntoNeunId = @pi_AsuntoNeunId 
		AND ps.CatOrganismoId = @pi_CatOrganismoId
		AND ps.YearPromocion = @pi_YearPromocion
        AND ps.NumeroOrden = @pi_NumeroOrden
		AND moa.fkIdEstatus = 1
		
		SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,--Nuevo
			a.TipoProcedimiento,
			a.TipoProcedimientoId, --Nuevo
			a.NumeroOCC as OCC,
			c.Cuaderno,
			-- etl.TipoCuadernoDesc as Cuaderno,
			c.CuadernoId, ---Nuevo
			-- etl.TipoCuadernoId as CuadernoId,
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
			ConArchivo = IIF(moa.sNombreArchivo IS NULL, 0,1),
			EsDemanda = IIF(@origen IN (5,15),1,0),
			OrigenPromocionId = p.OrigenPromocion,
			ps.fkIdPromocion AS Folio,
			EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
			ad.CatAutorizacionDocumentosId,
			moa.sNombreArchivo+moa.sExtension NombreArchivo,
			Origen = 0,
			--Fojas=Isnull(pa.Fojas,0),
			Fojas = (SELECT TOP 1 CONVERT(smallint, Fojas) 
						From PromocionArchivos pa2 
						where pa2.AsuntoNeunId = p.AsuntoNeunId
						AND pa2.CatOrganismoId = p.CatOrganismoId 
						AND pa2.NumeroOrden = p.NumeroOrden
						--AND pa2.Origen = p.OrigenPromocion 
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
			,FechaAlta=rel.fFechaAlta
			,PromoventeRegistro = co.NombreOficial
			,@Archivos Archivos
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
		--Validar con Gemma
		-- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL ON ETL.TipoCuadernoId = p.TipoCuaderno 
		LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId  and tac.CatTipoAsuntoId = a.CatTipoAsuntoId	
		LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
		--fin validar con Gemma
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion
		LEFT JOIN ICOIJ_REL_PromocionSISE ps with(nolock) ON ps.AsuntoNeunId = p.AsuntoNeunId 
														  AND ps.CatOrganismoId = p.CatOrganismoId
														  AND ps.YearPromocion = p.YearPromocion
                                                          AND ps.NumeroOrden = p.NumeroOrden
		LEFT JOIN dbo.ICOIJ_MOV_Promocion rel ON rel.kIdPromocion = ps.fkIdPromocion
		LEFT JOIN ICOIJ_MOV_Promocion pro ON pro.kIdPromocion = ps.fkIdPromocion
		LEFT JOIN ICOIJ_MOV_Archivo moa ON moa.kiIdFolio = pro.kiIdFolio
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
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = rel.fkIdUsuario
        LEFT JOIN ICOIJ_REL_DemandaPromocionSolicitud dps on dps.fkiIdFolio = pro.kiIdFolio
	    LEFT JOIN CatOrganismos co ON dps.iOIJ = co.CatOrganismoId
		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden
	END
	ELSE IF(@pi_Origen = 22)
	BEGIN		

        SELECT @pi_ConExpediente = IIF(pr.kIdPromocion IS NOT NULL, 1, 0)
        FROM IOJ_REL_PromocionSISE ps with(nolock)
        LEFT JOIN JL_MOV_Promocion pr ON pr.kIdPromocion = ps.fkIdPromocion
       	WHERE ps.AsuntoNeunId = @pi_AsuntoNeunId 
		AND ps.CatOrganismoId = @pi_CatOrganismoId
		AND ps.YearPromocion = @pi_YearPromocion
        AND ps.NumeroOrden = @pi_NumeroOrden
		
        SET @pi_ConExpediente = ISNULL(@pi_ConExpediente, 1)

        IF(@pi_ConExpediente = 0)
        BEGIN
            SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo ,moa.sExtension ,'"}'), ','),']')
            FROM IOJ_REL_PromocionSISE ps with(nolock)
            LEFT JOIN IOJ_MOV_PromocionOJ pr 
                ON pr.kiIdFolio = ps.fkIdPromocion
            LEFT JOIN IOJ_REL_PromocionArchivoOJ ar 
                ON ar.fkIdPromocion = pr.kiIdFolio
            LEFT JOIN JL_MOV_Archivo moa 
                ON moa.kIdArchivo = ar.fkIdArchivo
            WHERE ps.AsuntoNeunId = @pi_AsuntoNeunId 
            AND ps.CatOrganismoId = @pi_CatOrganismoId
            AND ps.YearPromocion = @pi_YearPromocion
            AND ps.NumeroOrden = @pi_NumeroOrden
            AND moa.fkIdEstatus = 1

            SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
                p.AsuntoNeunId, 
                a.AsuntoAlias Expediente,
                a.CatTipoAsunto,
                a.CatTipoAsuntoId,--Nuevo
                a.TipoProcedimiento,
                a.TipoProcedimientoId, --Nuevo
                a.NumeroOCC as OCC,
                c.Cuaderno,
                -- etl.TipoCuadernoDesc as Cuaderno,
                c.CuadernoId, ---Nuevo
                -- etl.TipoCuadernoId as CuadernoId,
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
                ConArchivo = IIF(ISNULL(moa.sNombreArchivo,moa2.sNombreArchivo) IS NULL, 0,1),
                EsDemanda = IIF(@origen IN (5,15),1,0),
                OrigenPromocionId = p.OrigenPromocion,
                rel.kiIdFolio AS Folio,
                EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
                ad.CatAutorizacionDocumentosId,
                ISNULL(moa.sNombreArchivo,moa2.sNombreArchivo)+ISNULL(moa.sExtension,moa2.sExtension) NombreArchivo,
                Origen = 0,
                --Fojas=Isnull(pa.Fojas,0),
                Fojas = (SELECT TOP 1 CONVERT(smallint, Fojas) 
                            From PromocionArchivos pa2 
                            where pa2.AsuntoNeunId = p.AsuntoNeunId
                            AND pa2.CatOrganismoId = p.CatOrganismoId 
                            AND pa2.NumeroOrden = p.NumeroOrden
                            --AND pa2.Origen = p.OrigenPromocion 
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
                ,FechaAlta=rel.fFechaAlta
                ,PromoventeRegistro = co.NombreOficial
                ,@Archivos Archivos
            FROM Promociones p WITH(NOLOCK) 
            CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
            --INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
            --Validar con Gemma
            -- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL ON ETL.TipoCuadernoId = p.TipoCuaderno  AND etl.TipoAsuntoId = a.AsuntoId
            LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId and tac.CatTipoAsuntoId = a.CatTipoAsuntoId	
            LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
            --fin validar con Gemma
            LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion
            LEFT JOIN IOJ_REL_PromocionSISE ps with(nolock) ON ps.AsuntoNeunId = p.AsuntoNeunId 
                                                            AND ps.CatOrganismoId = p.CatOrganismoId
                                                            AND ps.YearPromocion = p.YearPromocion
                                                            AND ps.NumeroOrden = p.NumeroOrden
            LEFT JOIN dbo.IOJ_MOV_PromocionOJ rel ON rel.kiIdFolio = ps.fkIdPromocion
            LEFT JOIN IOJ_REL_PromocionArchivoOJ ar ON ar.fkIdPromocion = ps.fkIdPromocion
            LEFT JOIN IOJ_MOV_Archivo moa ON moa.kIdArchivo = ar.fkIdArchivo
            LEFT JOIN IOJ_MOV_PromocionOJ pr2 ON pr2.kiIdFolio = ps.fkIdPromocion
            LEFT JOIN IOJ_REL_PromocionArchivoOJ ar2 ON ar2.fkIdPromocion = pr2.kiIdFolio
            LEFT JOIN JL_MOV_Archivo moa2 ON moa2.kIdArchivo = ar2.fkIdArchivo
            LEFT JOIN CatPromocion cp WITH(NOLOCK) ON cp.CatalogoPromocionId = p.TipoContenido
            LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1
            LEFT JOIN Promovente pr ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 
            LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
            LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
            LEFT JOIN AsuntosDocumentos ad on ad.AsuntoNeunId = p.AsuntoNeunId and p.AsuntoDocumentoId = ad.AsuntoDocumentoId
            LEFT JOIN viCatalogos tipoPromovente ON pr.Tipo = tipoPromovente.ID /*and tipoPromovente.Catalogo=170*/
            LEFT JOIN CatCaracterPersonaAsunto ccpa ON ccpa.CatCaracterPersonaAsuntoId = pas.CatCaracterPersonaAsuntoId
            LEFT JOIN CatTiposPersona ctp ON ctp.CatTipoPersonaId = pas.CatTipoPersonaId
            LEFT JOIN CatOrganismos cat ON p.CatOrganismoId = cat.CatOrganismoId
            LEFT JOIN SISE3.PromocionPromoventeParte ppp ON ppp.StatusReg = 1 AND ppp.CatOrganismoId = p.CatOrganismoId AND ppp.AsuntoNeunId = p.AsuntoNeunId AND ppp.NumeroOrden = p.NumeroOrden
            and ppp.PromoventeId = p.TipoPromovente
            LEFT JOIN PersonasAsunto paspr ON paspr.PersonaId = ppp.PersonaId 
            LEFT JOIN CatCaracterPersonaAsunto ccpapr ON ccpapr.CatCaracterPersonaAsuntoId = paspr.CatCaracterPersonaAsuntoId
            LEFT JOIN CatTiposPersona ctppr ON ctppr.CatTipoPersonaId = paspr.CatTipoPersonaId 
            LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = rel.fkIdUsuario
            LEFT JOIN IOJ_MOV_SolicitudInterconexion si ON rel.kiIdFolio = si.dFolioRespuesta
            LEFT JOIN CatOrganismos co ON si.fkIdOrgano = co.CatOrganismoId
            WHERE  p.StatusReg = 1
            AND p.CatOrganismoId = @pi_CatOrganismoId
            AND p.AsuntoNeunID = @pi_AsuntoNeunId
            AND p.YearPromocion = @pi_YearPromocion
            AND p.NumeroOrden = @pi_NumeroOrden
        END
        ELSE
        BEGIN

            SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo, moa.sExtension ,'"}'), ','),']')
            FROM JL_REL_PromocionSISE ps with(nolock) 
            LEFT JOIN JL_REL_PromocionArchivo pa ON ps.fkIdPromocion = pa.fkIdPromocion
            LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = pa.fkIdArchivo
            WHERE ps.AsuntoNeunId = @pi_AsuntoNeunId
            AND ps.CatOrganismoId = @pi_CatOrganismoId
            AND ps.YearPromocion = @pi_YearPromocion
            AND ps.NumeroOrden = @pi_NumeroOrden
            AND moa.fkIdEstatus = 1

            SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
                p.AsuntoNeunId, 
                a.AsuntoAlias Expediente,
                a.CatTipoAsunto,
                a.CatTipoAsuntoId,--Nuevo
                a.TipoProcedimiento,
                a.TipoProcedimientoId, --Nuevo
                a.NumeroOCC as OCC,
                --c.Cuaderno,
                c.Cuaderno as Cuaderno,
                --c.CuadernoId, ---Nuevo
                c.CuadernoId as CuadernoId,
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
                ConArchivo = IIF(moa.sNombreArchivo IS NULL, 0,1),
                EsDemanda = IIF(@origen IN (5,15),1,0),
                OrigenPromocionId = p.OrigenPromocion,
                ps.fkIdPromocion AS Folio,
                EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
                ad.CatAutorizacionDocumentosId,
                moa.sNombreArchivo+moa.sExtension NombreArchivo,
                Origen = 0,
                --Fojas=Isnull(pa.Fojas,0),
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
                ,FechaAlta=rel.fFechaAlta
                ,PromoventeRegistro = co.NombreOficial
                ,@Archivos Archivos
            FROM Promociones p WITH(NOLOCK) 
            CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
            --INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
            --Validar con Gemma
            -- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL ON ETL.TipoCuadernoId = p.TipoCuaderno 
            LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId and tac.CatTipoAsuntoId = a.CatTipoAsuntoId			 
            LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
            --fin validar con Gemma
            LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion
            LEFT JOIN JL_REL_PromocionSISE ps with(nolock) ON ps.AsuntoNeunId = p.AsuntoNeunId 
                                                            AND ps.CatOrganismoId = p.CatOrganismoId
                                                            AND ps.YearPromocion = p.YearPromocion
                                                            AND ps.NumeroOrden = p.NumeroOrden
            LEFT JOIN dbo.JL_MOV_Promocion rel ON ps.fkIdPromocion = rel.kIdPromocion AND ps.OrigenPromocion = 22
            LEFT JOIN JL_REL_PromocionArchivo pa ON ps.fkIdPromocion = pa.fkIdPromocion
            LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = pa.fkIdArchivo
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
            LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = rel.fkIdUsuario
            LEFT JOIN IOJ_MOV_SolicitudInterconexion si ON rel.kIdPromocion = si.dFolioRespuesta
            LEFT JOIN CatOrganismos co ON si.fkIdOrgano = co.CatOrganismoId
            WHERE  p.StatusReg = 1
            AND p.CatOrganismoId = @pi_CatOrganismoId
            AND p.AsuntoNeunID = @pi_AsuntoNeunId
            AND p.YearPromocion = @pi_YearPromocion
            AND p.NumeroOrden = @pi_NumeroOrden
        END

	END
	ELSE IF(@pi_Origen = 5)
	BEGIN

		SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo, moa.sExtension ,'"}'), ','),']')
		FROM JL_REL_DemandaSISE rdem WITH (nolock)
		LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on rdem.fkIdDemanda=da.fkIdDemanda 
														AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1
		WHERE rdem.AsuntoNeunId = @pi_AsuntoNeunId
		AND rdem.CatOrganismoId = @pi_CatOrganismoId
		AND rdem.YearPromocion = @pi_YearPromocion
        AND rdem.NumeroOrden = @pi_NumeroOrden
		AND moa.fkIdEstatus = 1

		SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,--Nuevo
			a.TipoProcedimiento,
			a.TipoProcedimientoId, --Nuevo
			a.NumeroOCC as OCC,
			c.Cuaderno,
			-- etl.TipoCuadernoDesc as Cuaderno,
			c.CuadernoId, ---Nuevo
			-- etl.TipoCuadernoId as CuadernoId,
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
				CASE 
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid = 1 THEN SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid <> 1 THEN pas.DenominacionDeAutoridad
					WHEN ISNULL(p.ClasePromovente,1) =2 THEN SISE3.ConcatenarNombres(pr.Nombre, pr.APaterno,pr.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) =3 THEN SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 4 THEN ajo.AJONombre
					END,''),
			PromoventeApellidoPaterno = '',
			PromoventeApellidoMaterno = '',
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
			ConArchivo = IIF(moa.sNombreArchivo IS NULL, 0,1),
			EsDemanda = IIF(@origen IN (5,15),1,0),
			OrigenPromocionId = p.OrigenPromocion,
			rdem.fkIdDemanda AS Folio,
			EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
			ad.CatAutorizacionDocumentosId,
			moa.sNombreArchivo+moa.sExtension NombreArchivo,
			Origen = 0,
			--Fojas=Isnull(pa.Fojas,0),
			Fojas = (SELECT TOP 1 CONVERT(smallint, Fojas) 
						From PromocionArchivos pa2 
						where pa2.AsuntoNeunId = p.AsuntoNeunId
						AND pa2.CatOrganismoId = p.CatOrganismoId 
						AND pa2.NumeroOrden = p.NumeroOrden
						--AND pa2.Origen = p.OrigenPromocion 
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
			,FechaAlta=mdem.fFechaAlta
			,PromoventeRegistro = mdem.sPromoventeNombre
			,occ.BoletaOCC as BoletaOCC
			,@Archivos Archivos
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
		--Validar con Gemma
		-- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL 
		-- 	ON ETL.TipoCuadernoId = p.TipoCuaderno AND etl.TipoAsuntoId = a.CatTipoAsuntoId
		LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId and tac.CatTipoAsuntoId = a.CatTipoAsuntoId	
		LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
		--fin validar con Gemma
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion			
		LEFT JOIN JL_REL_DemandaSISE rdem WITH (nolock) on rdem.AsuntoNeunId = p.AsuntoNeunId
														AND rdem.CatOrganismoId = p.CatOrganismoId
														AND rdem.YearPromocion = p.YearPromocion
														AND rdem.NumeroOrden = p.NumeroOrden
		LEFT JOIN JL_MOV_Demanda mdem ON mdem.fkIdEstatus = 1 AND mdem.kIdDemanda = rdem.fkIdDemanda
		LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on rdem.fkIdDemanda=da.fkIdDemanda 
														AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1	
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
		LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId
		LEFT JOIN (SELECT arc2.sNombreArchivo + arc2.sExtension BoletaOCC
				   ,d2.kIdDemanda
					FROM JL_MOV_Demanda d2 WITH(nolock) 
					INNER JOIN dbo.JL_REL_DemandaArchivo AS da2 WITH(nolock) 
						ON d2.kIdDemanda = da2.fkIdDemanda and da2.fkIdEstatus=1
					INNER JOIN dbo.JL_MOV_Archivo AS arc2  WITH(nolock) 
						ON arc2.kIdArchivo = da2.fkIdArchivo AND  arc2.fkIdEstatus=1 
						AND arc2.fkIdOrigen = 7
					WHERE d2.fkIdEstatus=1) AS occ
				ON occ.kIdDemanda = mdem.kIdDemanda
		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden
	END
	ELSE IF(@pi_Origen = 15)
	BEGIN

		SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo, moa.sExtension ,'"}'), ','),']')
		FROM dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK)
		LEFT JOIN ICOIJ_MOV_Demanda d ON d.kIdDemanda = irdem.fkIdDemanda
		LEFT JOIN  dbo.ICOIJ_MOV_Archivo AS moa ON d.kiIdFolio = moa.kiIdFolio 
												AND moa.fkIdEstatus = 1
		WHERE irdem.AsuntoNeunId = @pi_AsuntoNeunId
		AND irdem.CatOrganismoId = @pi_CatOrganismoId
		AND irdem.YearPromocion = @pi_YearPromocion
        AND irdem.NumeroOrden = @pi_NumeroOrden
		AND moa.fkIdEstatus = 1

		SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,--Nuevo
			a.TipoProcedimiento,
			a.TipoProcedimientoId, --Nuevo
			a.NumeroOCC as OCC,
			c.Cuaderno,
			-- etl.TipoCuadernoDesc as Cuaderno,
			c.CuadernoId, ---Nuevo
			-- etl.TipoCuadernoId as CuadernoId,
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
			ConArchivo = IIF(moa.sNombreArchivo IS NULL, 0,1),
			EsDemanda = IIF(@origen IN (5,15),1,0),
			OrigenPromocionId = p.OrigenPromocion,
			irdem.fkIdDemanda AS Folio,
			EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
			ad.CatAutorizacionDocumentosId,
			moa.sNombreArchivo+moa.sExtension NombreArchivo,
			Origen = 0,
			--Fojas=Isnull(pa.Fojas,0),
			Fojas = (SELECT TOP 1 CONVERT(smallint, Fojas) 
						From PromocionArchivos pa2 
						where pa2.AsuntoNeunId = p.AsuntoNeunId
						AND pa2.CatOrganismoId = p.CatOrganismoId 
						AND pa2.NumeroOrden = p.NumeroOrden
						--AND pa2.Origen = p.OrigenPromocion 
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
			,FechaAlta=d.fFechaAlta
			,PromoventeRegistro = d.sPromoventeNombre
			,occ.BoletaOCC as BoletaOCC
			,@Archivos Archivos
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
		--Validar con Gemma
		-- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL 
		-- 	ON ETL.TipoCuadernoId = p.TipoCuaderno AND etl.TipoAsuntoId = a.CatTipoAsuntoId
		LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId and tac.CatTipoAsuntoId = a.CatTipoAsuntoId	
		LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
		--fin validar con Gemma
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion	
		LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.AsuntoNeunId = p.AsuntoNeunId
																AND irdem.CatOrganismoId = p.CatOrganismoId
																AND irdem.YearPromocion = p.YearPromocion
                                                                AND irdem.NumeroOrden = p.NumeroOrden
		LEFT JOIN ICOIJ_MOV_Demanda d ON d.kIdDemanda = irdem.fkIdDemanda
		LEFT JOIN  dbo.ICOIJ_MOV_Archivo AS moa ON d.kiIdFolio = moa.kiIdFolio 
												AND moa.fkIdEstatus = 1
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
		LEFT JOIN (SELECT arc2.sNombreArchivo + arc2.sExtension BoletaOCC
				   ,d2.kIdDemanda
					FROM ICOIJ_MOV_Demanda d2 WITH(nolock) 
					INNER JOIN dbo.JL_REL_DemandaArchivo AS da2 WITH(nolock) 
						ON d2.kIdDemanda = da2.fkIdDemanda and da2.fkIdEstatus=1
					INNER JOIN dbo.ICOIJ_MOV_Archivo AS arc2  WITH(nolock) 
						ON arc2.kIdArchivo = da2.fkIdArchivo AND  arc2.fkIdEstatus=1 
						AND arc2.fkIdOrigen = 7
					JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
					WHERE d2.fkIdEstatus=1) AS occ
				ON occ.kIdDemanda = d.kIdDemanda
		LEFT JOIN PersonasAsunto paspr ON paspr.PersonaId = ppp.PersonaId 
		LEFT JOIN CatCaracterPersonaAsunto ccpapr ON ccpapr.CatCaracterPersonaAsuntoId = paspr.CatCaracterPersonaAsuntoId
		LEFT JOIN CatTiposPersona ctppr ON ctppr.CatTipoPersonaId = paspr.CatTipoPersonaId 
		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden
	END
	ELSE IF (@pi_Origen = 29)
	BEGIN

		SELECT @Archivos = CONCAT ('[',STRING_AGG ( CONCAT('{"Archivo":"', moa.sNombreArchivo, moa.sExtension ,'"}'), ','),']')
		FROM JL_REL_DemandaSISE rdem WITH (nolock)
		LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on rdem.fkIdDemanda=da.fkIdDemanda 
														AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1
		WHERE rdem.AsuntoNeunId = @pi_AsuntoNeunId
		AND rdem.CatOrganismoId = @pi_CatOrganismoId
		AND rdem.YearPromocion = @pi_YearPromocion
        AND rdem.NumeroOrden = @pi_NumeroOrden
		AND moa.fkIdEstatus = 1

		SELECT	DISTINCT No = ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, p.CatOrganismoId,p.NumeroOrden,p.OrigenPromocion,p.YearPromocion ORDER BY p.FechaPresentacion),
			p.AsuntoNeunId, 
			a.AsuntoAlias Expediente,
			a.CatTipoAsunto,
			a.CatTipoAsuntoId,--Nuevo
			a.TipoProcedimiento,
			a.TipoProcedimientoId, --Nuevo
			a.NumeroOCC as OCC,
			c.Cuaderno,
			-- etl.TipoCuadernoDesc as Cuaderno,
			c.CuadernoId, ---Nuevo
			-- etl.TipoCuadernoId as CuadernoId,
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
			ConArchivo = IIF(moa.sNombreArchivo IS NULL, 0,1),
			EsDemanda = IIF(@origen IN (5,15),1,0),
			OrigenPromocionId = p.OrigenPromocion,
			rdem.fkIdDemanda AS Folio,
			EsPromocionE= IIF(@origen IN (6,14,22,5,15,29),1,0),
			ad.CatAutorizacionDocumentosId,
			moa.sNombreArchivo+moa.sExtension NombreArchivo,
			Origen = 0,
			--Fojas=Isnull(pa.Fojas,0),
			Fojas = (SELECT TOP 1 CONVERT(smallint, Fojas) 
						From PromocionArchivos pa2 
						where pa2.AsuntoNeunId = p.AsuntoNeunId
						AND pa2.CatOrganismoId = p.CatOrganismoId 
						AND pa2.NumeroOrden = p.NumeroOrden
						--AND pa2.Origen = p.OrigenPromocion 
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
			,FechaAlta=coe.FechaRegistro
			,occ.BoletaOCC BoletaOCC
			,PromoventeRegistro = co.NombreOficial
			,@Archivos Archivos
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--INNER JOIN tbx_CatCuadernos c WITH(NOLOCK) ON p.TipoCuaderno = c.CuadernoId
		--Validar con Gemma
		-- INNER JOIN ETL_Mapeo_ClasificacionCuaderno_TipoCuaderno_X_TipoAsuntoId ETL ON ETL.TipoCuadernoId = p.TipoCuaderno 
		LEFT JOIN tbx_CatTiposAsunto tac ON p.TipoCuaderno = tac.CuadernoId and tac.CatTipoAsuntoId = a.CatTipoAsuntoId	
		LEFT JOIN tbx_CatCuadernos c WITH(NOLOCK) ON c.CuadernoId = tac.CuadernoId
		--fin validar con Gemma
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON p.OrigenPromocion = o.kIdOrigenPromocion	
		LEFT JOIN JL_REL_DemandaSISE rdem WITH (nolock) on rdem.AsuntoNeunId = p.AsuntoNeunId
														AND rdem.CatOrganismoId = p.CatOrganismoId
														AND rdem.YearPromocion = p.YearPromocion
                                                        AND rdem.NumeroOrden = p.NumeroOrden
		LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on rdem.fkIdDemanda = coe.fkIdDemanda
		LEFT JOIN JL_MOV_Demanda dem with(nolock) on rdem.fkIdDemanda = dem.kIdDemanda
		LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on rdem.fkIdDemanda=da.fkIdDemanda 
														AND da.fkIdEstatus = 1
		LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1
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
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = dem.fkIdUsuario
        LEFT JOIN CatOrganismos co ON coe.OrigenCatOrganismoId = co.CatOrganismoId
		LEFT JOIN (SELECT arc2.sNombreArchivo + arc2.sExtension BoletaOCC
				   ,d2.kIdDemanda
					FROM JL_MOV_Demanda d2 WITH(nolock) 
					INNER JOIN dbo.JL_REL_DemandaArchivo AS da2 WITH(nolock) 
						ON d2.kIdDemanda = da2.fkIdDemanda and da2.fkIdEstatus=1
					INNER JOIN dbo.JL_MOV_Archivo AS arc2  WITH(nolock) 
						ON arc2.kIdArchivo = da2.fkIdArchivo AND  arc2.fkIdEstatus=1 
						AND arc2.iTipoArchivo != 27
					WHERE d2.fkIdEstatus=1) AS occ
				ON occ.kIdDemanda = dem.kIdDemanda
		WHERE  p.StatusReg = 1
		AND p.CatOrganismoId = @pi_CatOrganismoId
		AND p.AsuntoNeunID = @pi_AsuntoNeunId
		AND p.YearPromocion = @pi_YearPromocion
		AND p.NumeroOrden = @pi_NumeroOrden
	END

END
