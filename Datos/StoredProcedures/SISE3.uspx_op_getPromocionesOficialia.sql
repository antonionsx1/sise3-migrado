SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 24/04/2013
-- Description:	Obtener las promociones de un organismo en una fecha determinada para oficialia
-- Procedimientos SISE:	usp_Promociones_Lista_LFT_Sel Si @pi_UsuariId es no nulo
--						usp_Promociones_ListaRango_Sel Si @pi_FechaPresentacionFin es no nulo
--						usp_Promociones_Lista_Sel Si no se cumple ninguna de las anteriores
-- [SISE3].[uspx_op_getPromocionesOficialia]

-- =============================================
CREATE procedure [SISE3].[uspx_op_getPromocionesOficialia]
(
    @pi_CatOrganismoId INT,
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE
	@pi_FechaPresentacionIni DATETIME,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATETIME,
	-- REPRESENTA EL IDENTITICADOR DEL EMPLEADO - PUEDE LLEGAR NULA
	@pi_UsuariId int)
AS
BEGIN
--IF object_id('tempdb..#tmpPromociones') IS NOT NULL
--		DROP TABLE #tmpPromociones;
--	SELECT   
--		Expediente = a.AsuntoAlias   
--		,OCC = a.NumeroOCC  
--		,TipoAsuntoDescripcion = cto.Descripcion   
--		,CatTipoAsuntoId = cto.CatTipoAsuntoId  
--		,p.[AsuntoNeunId]  
--		,p.[NumeroOrden]  
--		,p.[CatOrganismoId]  
--		,p.[YearPromocion]  
--		,p.[NumeroRegistro]  
--		,SintesisOrden = ISNULL(p.[SintesisOrden],0)  
--		,TipoPromocion = ClasePromocion  
--		,TipoPromocionDescripcion = CASE ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END   
--		,FechaPresentacion = CONVERT(DATETIME,p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END)
--		,p.[HoraPresentacion]  
--		,p.TipoCuaderno  
--		,p.ClasePromocion  
--		,TipoCuadernoDescripcion = dbo.funRecuperaCatalogoDepENDienteDescripcion(495,TipoCuaderno)  
--		,ParteId = p.TipoPromovente  
--		,ClasePromovente = p.ClasePromovente  
--		,ParteDescripcion = dbo.funNombreParte(TipoPromovente,ISNULL(ClasePromovente,1))  
--		,TipoContenidoId = p.TipoContenido  
--		,TipoContenidoDescripcion = (SELECT CatalogoPromocionDescripcion FROM CatPromocion WITH(NOLOCK) WHERE CatalogoPromocionId=TipoContenido)  
--		,p.[Contenido]  
--		,Copias = ISNULL(p.[NumeroCopias],0)  
--		,Anexos = ISNULL(p.[NumeroAnexos],0)  
--		,EstadoPromocion = ISNULL(p.[EstadoPromocion],0)  
--		,pa.NombreArchivo  
--		,EstatusArchivo = ISNULL(pa.EstatusArchivo,0)  
--		,p.AsuntoDocumentoId  
--		,Mesa = dbo.fnx_getValorPorNeunPorDescripcion(p.AsuntoNeunId,'Mesa')
--		,SecretarioId = CASE WHEN p.Secretario=0 THEN  dbo.fnx_getIdCatalogoPorNeunPorDescripcion(p.AsuntoNeunId,'Secretario') ELSE p.Secretario END   
--		,SecretarioDescripcion = CASE WHEN p.Secretario=0 THEN dbo.fnx_getValorPorNeunPorDescripcion(p.AsuntoNeunId,'Secretario') ELSE dbo.FNOBTIENEEMPLEADO(p.Secretario) END  
--		,p.IPUsuario  
--		,ct.CatTipoOrganismoId  
--		,p.OrigenPromocion  
--		,p.RegistroEmpleadoId
--		,ta.Color, ta.NombreCorto 
--		,NumeroAlias = CONVERT(BIGINT,a.NumeroAlias)
--		,userNameSecretario = CASE WHEN p.Secretario=0 THEN dbo.fnx_getUserName(dbo.fnx_getIdCatalogoPorNeunPorDescripcion(p.AsuntoNeunId,'Secretario')) ELSE dbo.fnx_getUserName(p.Secretario) END  
--		,FechaPresentacion_F = ISNULL(CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion))
--			ELSE '' END,'')
--		,p.Observaciones
--		,RutaArchivoNAS = ISNULL(pa.RutaArchivoNAS,0)
--	FROM Promociones p WITH(NOLOCK)  
--	JOIN Asuntos a WITH(NOLOCK) on a.AsuntoNeunId= p.AsuntoNeunId  
--	JOIN CatOrganismos  ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId  
--	JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId  
--	LEFT JOIN PromocionArchivos pa WITH(NOLOCK) on pa.AsuntoNeunId=p.AsuntoNeunId and pa.NumeroOrden=p.NumeroOrden and pa.NumeroRegistro=p.NumeroRegistro  
--	and pa.YearPromocion=p.YearPromocion and pa.StatusArchivo=1  
--	LEFT JOIN tbx_CatTiposAsunto ta ON cto.CatTipoAsuntoId = ta.CatTipoAsuntoId AND p.TipoCuaderno = ta.CuadernoId
--	WHERE p.StatusReg=1   
--	AND p.CatOrganismoId=@pi_CatOrganismoId  
--	AND p.RegistroEmpleadoId = ISNULL(@pi_UsuariId,p.RegistroEmpleadoId)
--	AND CONVERT(DATE,p.FechaPresentacion) BETWEEN CONVERT(DATE,@pi_FechaPresentacionIni) AND  ISNULL(CONVERT(DATE,@pi_FechaPresentacionFin),CONVERT(DATE,@pi_FechaPresentacionIni))
	

SELECT TOP 1000
    p.OrigenPromocion,
    Expediente =  (
    SELECT   STUFF((
        SELECT ', {"AsuntoAlias":"' + v.AsuntoAlias +
               '", "AsuntoNeunId":"' + CAST(v.AsuntoNeunId AS NVARCHAR(10)) +
               '", "CatOrganismoId":"' + CAST(p.CatOrganismoId AS NVARCHAR(10)) +
               '", "CatTipoAsuntoId":"' + CAST(v.CatTipoAsuntoId AS NVARCHAR(10)) +
               '", "CatTipoAsunto":"' + cto.Descripcion +
			   '", "Estado":"' + CAST(p.ClasePromovente AS NVARCHAR(10))  + 
               '", "NombreCorto":"' + ta.NombreCorto + '"}'
        FROM (
            SELECT DISTINCT TOP 1
                v.AsuntoAlias,
                v.AsuntoNeunId,
                p.CatOrganismoId,
                v.CatTipoAsuntoId,
				cto.Descripcion,
				p.ClasePromovente,
				ta.NombreCorto
            FROM Asuntos v
            WHERE v.AsuntoAlias = a.AsuntoAlias
        ) v
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '')  AS Expediente
) ,
    a.NumeroOCC AS OCC,
    a.AsuntoAlias,
    p.AsuntoNeunId,
	p.OrigenPromocion,
    p.NumeroOrden,
    p.CatOrganismoId,
    p.YearPromocion,
    p.NumeroRegistro,
    ISNULL(p.SintesisOrden, 0) AS SintesisOrden,
    ClasePromocion AS TipoPromocion,
    CASE ClasePromocion WHEN '1' THEN 'Escrito' ELSE 'Oficio' END AS TipoPromocionDescripcion,
    CONVERT(DATETIME, p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END) AS FechaPresentacion,
    p.HoraPresentacion,
    p.TipoCuaderno,
    p.ClasePromocion,
    dbo.funRecuperaCatalogoDepENDienteDescripcion(495, TipoCuaderno) AS TipoCuadernoDescripcion,
    p.TipoPromovente AS ParteId,
    p.ClasePromovente AS ClasePromovente,
    dbo.funNombreParte(TipoPromovente, ISNULL(ClasePromovente, 1)) AS ParteDescripcion,
    p.TipoContenido AS TipoContenidoId,
    (SELECT CatalogoPromocionDescripcion FROM CatPromocion WITH (NOLOCK) WHERE CatalogoPromocionId = p.TipoContenido) AS TipoContenidoDescripcion,
    p.Contenido,
    ISNULL(p.NumeroCopias, 0) AS Copias,
    ISNULL(p.NumeroAnexos, 0) AS Anexos,
    ISNULL(p.EstadoPromocion, 0) AS EstadoPromocion,
    pa.NombreArchivo,
    ISNULL(pa.EstatusArchivo, 0) AS EstatusArchivo,
    p.AsuntoDocumentoId,
    dbo.fnx_getValorPorNeunPorDescripcion(p.AsuntoNeunId, 'Mesa') AS Mesa,
    CASE WHEN p.Secretario = 0 THEN dbo.fnx_getIdCatalogoPorNeunPorDescripcion(p.AsuntoNeunId, 'Secretario') ELSE p.Secretario END AS SecretarioId,
    CASE WHEN p.Secretario = 0 THEN dbo.fnx_getValorPorNeunPorDescripcion(p.AsuntoNeunId, 'Secretario') ELSE dbo.FNOBTIENEEMPLEADO(p.Secretario) END AS SecretarioDescripcion,
    p.IPUsuario,   
    p.OrigenPromocion,
    p.RegistroEmpleadoId,
    ta.Color,
    ta.NombreCorto,
	cto.Descripcion AS CatTipoAsunto,
    CONVERT(BIGINT, a.NumeroAlias) AS NumeroAlias,
    CASE WHEN p.Secretario = 0 THEN dbo.fnx_getUserName(dbo.fnx_getIdCatalogoPorNeunPorDescripcion(p.AsuntoNeunId, 'Secretario')) ELSE dbo.fnx_getUserName(p.Secretario) END AS userNameSecretario,
    ISNULL(CONVERT(VARCHAR(10), p.FechaPresentacion, 103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5), CONVERT(TIME, p.HoraPresentacion)) ELSE '' END, '') AS FechaPresentacion_F,
    p.Observaciones,
    ISNULL(pa.RutaArchivoNAS, 0) AS RutaArchivoNAS
FROM Promociones p WITH (NOLOCK)
JOIN Asuntos a WITH (NOLOCK) ON a.AsuntoNeunId = p.AsuntoNeunId
JOIN CatTiposAsunto cto WITH (NOLOCK) ON a.CatTipoAsuntoId = cto.CatTipoAsuntoId
LEFT JOIN PromocionArchivos pa WITH (NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId
    AND pa.NumeroOrden = p.NumeroOrden
    AND pa.NumeroRegistro = p.NumeroRegistro
    AND pa.YearPromocion = p.YearPromocion
    AND pa.StatusArchivo = 1
LEFT JOIN tbx_CatTiposAsunto ta ON cto.CatTipoAsuntoId = ta.CatTipoAsuntoId
    AND p.TipoCuaderno = ta.CuadernoId
END
