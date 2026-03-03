SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--
-- =============================================
-- Author:		Saul Garcia
-- Create date: 23/01/2024
-- Objetivo: Carga el detalle de una promoción electrónica seleccionada en el detalle de promoción
-- SISE3.[pcConsultaRutaXModuloGUID] '15E95855-A03B-43FF-AD01-9AD3C7DDDE2E',2,'acuerdo'

-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcConsultaRutaXModuloGUID]
(
@pi_GuidDocumento UNIQUEIDENTIFIER,
@pi_TipoModulo INT, --1 Promocion 2 Acuerdo
@pi_TipoArchivo VARCHAR(50)
)

 

AS
BEGIN
	SET NOCOUNT ON
	IF @pi_TipoModulo = 1 
	BEGIN 
		SELECT 'WIP'		
	END 
	IF @pi_TipoModulo = 2
	BEGIN 
		IF(LOWER(@pi_TipoArchivo) = 'acuerdo')
        BEGIN
            SELECT 
                ad.AsuntoDocumentoId
                ,ad.AsuntoNeunId
                ,ad.AsuntoID
                ,a.CatOrganismoId
                ,a.AsuntoAlias AS No_Exp
                ,ad.SintesisOrden
                ,dj.NombreArchivo AS NombreArchivo
                ,ad.TipoCuaderno
                ,dbo.funRecuperaCatalogoDependienteDescripcion(527,ad.TipoCuaderno) AS NombreTipoCuaderno
                ,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
                ,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
                ,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
                ,FechaAutoriza = ad.FechaAutoriza
                ,FechaPreAutoriza = ad.FechaPreAutoriza
                ,FechaCancela = ad.FechaCancela
                ,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
                ,userNameSecretario = s.UserName --dbo.fnx_getUserName(p.Secretario)
                ,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
                        ELSE '' END As FechaRecibido_F
                ,ISNULL(CONVERT(VARCHAR(10),ad.FechaAlta,103),'') AS FechaAuto_F
                ,IIF(LEN(rc.sRuta ) = 0, rcd.sRuta, rc.sRuta) AS sRuta
                , CONCAT(IIF(LEN(rc.sRuta ) = 0, rcd.sRuta, rc.sRuta),'\',a.CatorganismoId,'\', dj.NombreArchivo) AS RutaCompleta---Ajuste 
                --, CONCAT(rc.sRuta,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
                ,ad.Firmado
            FROM AsuntosDocumentos ad WITH(NOLOCK) 
            JOIN Asuntos a WITH(NOLOCK) 
                ON a.AsuntoNeunId= ad.AsuntoNeunId
            JOIN DeterminacionesJudiciales dj WITH(NOLOCK) 
                ON ad.AsuntoNeunId = dj.AsuntoNeunId 
                AND ad.SintesisOrden=dj.SintesisOrden
            LEFT JOIN Promociones p WITH(NOLOCK) 
                ON ad.AsuntoNeunId = p.AsuntoNeunId 
                AND ad.AsuntoDocumentoId=p.AsuntoDocumentoId 
                AND p.StatusReg=ad.StatusReg
            JOIN CatOrganismos ct WITH(NOLOCK) 
                ON a.CatOrganismoId =ct.CatOrganismoId
            JOIN CatTiposAsunto cto WITH (NOLOCK) 
                ON a.CatTipoAsuntoId = cto.CatTipoAsuntoId
            LEFT JOIN PromocionArchivos pa WITH(NOLOCK) 
                ON pa.AsuntoNeunId=p.AsuntoNeunId 
                AND pa.NumeroOrden=p.NumeroOrden 
                AND pa.NumeroRegistro=p.NumeroRegistro
                AND pa.YearPromocion=p.YearPromocion 
                AND pa.StatusArchivo=1 
                AND pa.ClaseAnexo = 0
            LEFT JOIN CAT_RutasChunk rc ON rc.kId = ad.TipoRuta
            LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
            LEFT JOIN CAT_RutasChunk rcd
                ON rcd.iGrupo = 1
                AND rcd.iEscritura = 1
            WHERE ad.uGuidDocumento = @pi_GuidDocumento		  
                AND ad.StatusReg IN (1,2)
        END
        ELSE IF(LOWER(@pi_TipoArchivo) = 'oficio')
        BEGIN
            SELECT 
                ad.AsuntoDocumentoId
                ,ad.AsuntoNeunId
                ,ad.AsuntoID
                ,a.CatOrganismoId
                ,a.AsuntoAlias AS No_Exp
                ,ad.SintesisOrden
                ,CONCAT(eo.NombreArchivo, eo.ExtensionDocumento) NombreArchivo
                ,ad.TipoCuaderno
                ,dbo.funRecuperaCatalogoDependienteDescripcion(527,ad.TipoCuaderno) AS NombreTipoCuaderno
                ,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
                ,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
                ,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
                ,FechaAutoriza = ad.FechaAutoriza
                ,FechaPreAutoriza = ad.FechaPreAutoriza
                ,FechaCancela = ad.FechaCancela
                ,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
                ,userNameSecretario = s.UserName --dbo.fnx_getUserName(p.Secretario)
                ,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
                        ELSE '' END As FechaRecibido_F
                ,ISNULL(CONVERT(VARCHAR(10),ad.FechaAlta,103),'') AS FechaAuto_F
                ,IIF(LEN(rc.sRuta ) = 0, rcd.sRuta, rc.sRuta) AS sRuta
                , CONCAT(IIF(LEN(rc.sRuta ) = 0, rcd.sRuta, rc.sRuta),'\',a.CatorganismoId,'\', CONCAT(eo.NombreArchivo, eo.ExtensionDocumento)) AS RutaCompleta---Ajuste 
                --, CONCAT(rc.sRuta,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
                ,eo.Firmado
            FROM EstadoOficio eo WITH(NOLOCK)
            JOIN AsuntosDocumentos ad WITH(NOLOCK)
                ON eo.AsuntoDocumentoId = ad.AsuntoDocumentoId
                AND eo.AsuntoNeunId = ad.AsuntoNeunId
            JOIN Asuntos a WITH(NOLOCK) 
                ON a.AsuntoNeunId= ad.AsuntoNeunId
            LEFT JOIN Promociones p WITH(NOLOCK) 
                ON ad.AsuntoNeunId = p.AsuntoNeunId 
                AND ad.AsuntoDocumentoId=p.AsuntoDocumentoId 
                AND p.StatusReg=ad.StatusReg
            JOIN CatOrganismos ct WITH(NOLOCK) 
                ON a.CatOrganismoId =ct.CatOrganismoId
            JOIN CatTiposAsunto cto WITH (NOLOCK) 
                ON a.CatTipoAsuntoId = cto.CatTipoAsuntoId
            LEFT JOIN PromocionArchivos pa WITH(NOLOCK) 
                ON pa.AsuntoNeunId=p.AsuntoNeunId 
                AND pa.NumeroOrden=p.NumeroOrden 
                AND pa.NumeroRegistro=p.NumeroRegistro
                AND pa.YearPromocion=p.YearPromocion 
                AND pa.StatusArchivo=1 
                AND pa.ClaseAnexo = 0
            LEFT JOIN CAT_RutasChunk rc ON rc.kId = ad.TipoRuta
            LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
            LEFT JOIN CAT_RutasChunk rcd
                ON rcd.iGrupo = 1
                AND rcd.iEscritura = 1
            WHERE eo.uGuid = @pi_GuidDocumento		  
                AND eo.Estatus = 1
        END
	END 


	SET NOCOUNT OFF
END
