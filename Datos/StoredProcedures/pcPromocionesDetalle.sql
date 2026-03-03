USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcPromocionesDetalle]    Script Date: 12/1/2023 6:22:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [SISE3].[pcPromocionesDetalle] (
--DECLARE
	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA EL IDENTIFICADOR DEL EXPEDIENTE - PUEDE LLEGAR NULA
	@pi_AsuntoNeunId BIGINT ,
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATE = NULL,
	-- REPRESENTA EL IDENTITICADOR DEL EMPLEADO - PUEDE LLEGAR NULA
	@pi_UsuariId INT = NULL,
	-- REPRESENTA LA BUSQUEDA DE PROMOCIONES CON(1) o SIN ACUERTO(0) - PUEDE LLEGAR NULA
	@pi_SinConAcuerdo BIT = NULL,
	-- Recibe valor para búsqueda en los campos de texto, PUEDE SER NULO
	--Recibe Número de Query a ejecutar
    @pi_Query INT
	)
AS

/*	SET @pi_CatOrganismoId = 1532	 --1010--661--1494 Con origen OCC -- 1532 CON IO
	SET @pi_FechaPresentacionIni = '01/01/2018'
	SET @pi_FechaPresentacionFin = '01/01/2020'
    SET @pi_Query = 1*/
	-- SI LA FECHA INICIAL ES NULA, SE ASIGNA EL VALOR DEL DÍA
	IF @pi_FechaPresentacionIni = NULL
	BEGIN
		SET @pi_FechaPresentacionIni = convert(date,getdate())
	END
	-- SI LA FECHA FIN ES NULA SE ASIGNA EL VALOR DE LA FECHA DE INICIO 
	IF @pi_FechaPresentacionFin = NULL
	BEGIN
		SET @pi_FechaPresentacionFin = ISNULL(@pi_FechaPresentacionFin,@pi_FechaPresentacionIni)
	END
	
	IF @pi_Query = 1
	BEGIN
		/***** PROMOCIONES ELECTRÓNICAS ****/
		SELECT	p.fkIdAsuntoNeun,		a.AsuntoAlias,		a.CatTipoAsunto,	a.TipoProcedimiento,
			p.kIdPromocion,			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, 1
		FROM dbo.JL_MOV_Promocion AS p WITH (nolock) 
		CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a				
		LEFT JOIN	JL_REL_PromocionSISE ps with(nolock) ON p.kIdPromocion = ps.fkIdPromocion and p.fkIdAsuntoNeun = ps.AsuntoNeunId and p.fkIdOrgano = ps.CatOrganismoId
		LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 30, 29,5)
		LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
		WHERE ps.kIdPromocionSISE IS NULL
		AND a.AsuntoNeunId = p.fkIdAsuntoNeun
		AND a.CatOrganismoId = p.fkIdOrgano
		AND p.fkIdEstatus = 1
		AND p.fkIdOrgano = @pi_CatOrganismoId
		AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
    END
	IF @pi_Query = 2
    BEGIN
        /***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ****/
        SELECT	p.fkIdAsuntoNeun,		a.AsuntoAlias,		a.CatTipoAsunto,	a.TipoProcedimiento,
			p.kIdPromocion,			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, 2
	    FROM dbo.ICOIJ_MOV_Promocion AS p WITH (nolock) 
	    CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
	    LEFT JOIN ICOIJ_REL_PromocionSISE ps with(nolock) ON p.kiIdFolio = ps.fkIdPromocion AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
	    LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 14
	    LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	    LEFT JOIN AsuntosDocumentos ad on ad.AsuntoNeunId = p.fkIdAsuntoNeun
	    WHERE ps.kIdPromocionSISE IS NULL
	    AND a.AsuntoNeunId = p.fkIdAsuntoNeun
	    AND a.CatOrganismoId = p.fkIdOrgano
	    AND p.fkIdEstatus = 1
	    AND p.fkIdOrgano = @pi_CatOrganismoId
	    AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
    END
    IF @pi_Query = 3
    BEGIN
        /***** PROMOCIONES ELECTRÓNICAS DE INTERCONEXIÓN ENTRE ORGANOS JURISDICCIONALES ****/
        SELECT	p.fkIdAsuntoNeun,		a.AsuntoAlias,		a.CatTipoAsunto,	a.TipoProcedimiento,
			p.kIdPromocion,			o.sNombreOrigenPromocion,		p.fFechaAlta,		0,
			1,						0,					SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdPromocion, 1, 3
	    FROM IOJ_MOV_PromocionOJ AS p WITH (nolock) 
	    CROSS APPLY SISE3.fnExpediente(p.fkIdAsuntoNeun) a
	    LEFT JOIN  IOJ_REL_PromocionSISE ps with(nolock) ON p.kiIdFolio = ps.fkIdPromocion AND ps.AsuntoNeunId = p.fkIdAsuntoNeun AND ps.CatOrganismoId = p.fkIdOrgano
	    LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 14
	    LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	    WHERE ps.fkIdPromocion IS NULL
	    AND a.AsuntoNeunId = p.fkIdAsuntoNeun
	    AND a.CatOrganismoId = p.fkIdOrgano
	    AND p.fkIdEstatus = 1
	    AND p.fkIdOrgano = @pi_CatOrganismoId
	    AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
    END
    IF @pi_Query = 4
    BEGIN
        /***** DEMANDAS ELECTRÓNICAS ****/
        SELECT DISTINCT	o.sNombreOrigenPromocion,p.fFechaAlta,0,1,1,SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
			p.fkIdOrigen, p.kIdDemanda, 0, 4
	    FROM JL_MOV_Demanda AS p WITH (nolock) 
	    INNER JOIN JLOCCSISE_MOV_EnLinea AS e ON e.fkIdDemandaJL = p.kIdDemanda
	    INNER JOIN JL_REL_DemandaArchivo da with(nolock) on p.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
	    INNER JOIN  dbo.JL_MOV_Archivo AS arc ON arc.kIdArchivo = da.fkIdArchivo and arc.fkIdEstatus = 1	
	    LEFT JOIN dbo.JL_REL_DemandaSISE rdem WITH (nolock) on rdem.fkIdDemanda = p.kIdDemanda and rdem.AsuntoNeunId = p.fkIdAsuntoNeun and rdem.CatOrganismoId = p.fkIdOrgano
	    LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= IIF(p.fkIdOrigen = 29, 29,5)
	    LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	    LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
	    WHERE coe.fkIdDemanda IS NULL
	    AND rdem.fkIdDemanda IS NULL
	    AND p.fkIdEstatus = 1
	    AND e.fkIdNeunSISE IS NULL
	    AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	    AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
    END
    IF @pi_Query = 5
    BEGIN
        /***** DEMANDAS ELECTRÓNICAS INTERCONEXIÓN ****/
        SELECT DISTINCT	o.sNombreOrigenPromocion,p.fFechaAlta,0,1,1,SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
		p.fkIdOrigen, p.kiIdFolio, 0, 5
	    FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
	    INNER JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
	    INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
	    LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = p.kIdDemanda and irdem.AsuntoNeunId = p.fkIdAsuntoNeun and irdem.CatOrganismoId = p.fkIdOrgano
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
    END
    IF @pi_Query = 6
    BEGIN
        /***** COMUNICACIONES OFICIALES ****/
        SELECT DISTINCT	o.sNombreOrigenPromocion,p.fFechaAlta,0,1,1,SISE3.ConcatenarNombres(u.sNombre,u.sApellidoPaterno,u.sApellidoMaterno),
				p.fkIdOrigen, p.kiIdFolio, 0, 6
	    FROM ICOIJ_MOV_Demanda AS p WITH (nolock) 
	    INNER JOIN ICOIJOCCSISE_MOV_EnLinea AS e ON e.fkiIdFolio = p.kIdDemanda 
	    INNER JOIN  dbo.ICOIJ_MOV_Archivo AS arc ON p.kiIdFolio = arc.kiIdFolio AND arc.fkIdEstatus = 1
	    LEFT JOIN SISE3.CAT_OrigenPromocion  o ON  o.kIdOrigenPromocion	= 29
	    LEFT JOIN JL_CAT_Usuario u ON u.kIdUsuario = p.fkIdUsuario
	    LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on p.kIdDemanda = coe.fkIdDemanda 
	    WHERE coe.fkIdDemanda IS NOT NULL
	    AND p.fkIdEstatus = 1 
	    AND e.fkIdNeunSISE IS NULL
	    AND e.fkIdOrganoOCC = @pi_CatOrganismoId
	    AND	(@pi_FechaPresentacionIni IS NULL OR CAST( p.fFechaAlta AS DATE) BETWEEN @pi_FechaPresentacionIni AND @pi_FechaPresentacionFin)
    END
GO

