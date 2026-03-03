USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcConsultaArchivosyRutaXModulo]    Script Date: 12/1/2023 6:14:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--SISE3.pcConsultaPromocionArchivosyRuta 30312375,1,2023,1494
-- =============================================
-- Author:		Christian Araujo - MS
-- Alter date: 02/11/09
-- Objetivo: Carga el detalle de una promoción electrónica seleccionada en el detalle de promoción
-- EXEC SISE3.pcConsultaPromocionArchivosyRuta 30301133, 1,2023,4
      --  SISE3.[pcConsultaArchivosyRutaXModulo] 30312388,2023,111,1494,4,1,null;
	  --  SISE3.[pcConsultaArchivosyRutaXModulo] 30313649,null,null,null,null,null,2; 
-- =============================================
CREATE PROCEDURE [SISE3].[pcConsultaArchivosyRutaXModulo]
(
@pi_AsuntoNeunId BIGINT ,
@pi_YearPromocion INT NULL, 
@pi_NumeroOrden INT NULL,  --
@pi_catIdOrganismo INT,
@pi_Origen INT NULL, 
@pi_TipoModulo INT, --1 Promocion 2 Acuerdo
@pi_AsuntoDocumentoId INT NULL
)

 

AS
BEGIN
	SET NOCOUNT ON
	IF @pi_TipoModulo = 1 
	BEGIN 

		IF @pi_Origen = 0
		BEGIN
			SELECT  NombreClase = CASE ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END				  
				   ,ac.DESCRIPCION AS DescripcionAnexo
				   ,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				   ,rc.sRuta
				   ,Pa.NombreArchivo
				   ,CONCAT(rc.sRuta,'\',[Promociones].CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
			FROM [dbo].[Promociones] WITH(NOLOCK) 
			LEFT JOIN PromocionArchivos Pa WITH(NOLOCK) 
				ON Pa.AsuntoId=Promociones.AsuntoId 
				AND Pa.AsuntoNeunId=Promociones.AsuntoNeunId 
				AND Pa.NumeroOrden=Promociones.NumeroOrden 
				AND Pa.NumeroRegistro=Promociones.NumeroRegistro
				AND Pa.YearPromocion=Promociones.YearPromocion 
				AND Pa.StatusArchivo=1
				-- AND Pa.DescripcionAnexo=5031
			JOIN CAT_RutasChunk rc 
				ON rc.iGrupo = 2 AND rc.iEscritura = 1 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = Pa.DescripcionAnexo 
				AND ac.Catalogo = 17 
			LEFT JOIN CatalogosElementosTiposAsunto bc  WITH(NOLOCK) 
				ON ac.Catalogo = bc.CatalogoId 
				AND ac.ID = bc.CatalogoElementoIdNew 
				AND ac.Catalogo = 17 
				AND bc.CatTipoAsuntoId = 1 
				AND bc.StatusRegistro = 1 
				AND ac.CatalogoPadre > 0   
			WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
				  AND [Promociones].YearPromocion=@pi_YearPromocion 
				  AND [Promociones].NumeroOrden=@pi_NumeroOrden 
				  AND Pa.NombreArchivo IS NOT NULL		  
				  AND [Promociones].CatOrganismoId=@pi_catIdOrganismo 
				  AND [Promociones].StatusReg in (1,2)
		END
		IF @pi_Origen = 6
		BEGIN
			SELECT	NombreClase = 'Pendiente'
					,DescripcionAnexo =  null
					,EsPromocion = 1 
					,rc.sRuta
					,moa.sNombreArchivo
					, CONCAT(rc.sRuta,'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
			FROM JL_MOV_Promocion pr 
			LEFT JOIN JL_REL_PromocionArchivo pa ON pr.kIdPromocion = pa.fkIdPromocion
			LEFT JOIN JL_MOV_Archivo  moa ON moa.kIdArchivo = pa.fkIdArchivo
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 and rc.iEscritura = 1 
			WHERE pr.kIdPromocion = @pi_AsuntoNeunId
				  AND pr.fkIdEstatus = 1
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
		END				
	END 
	IF @pi_TipoModulo = 2
	BEGIN 
		SELECT 
			 ad.AsuntoDocumentoId
			,ad.AsuntoNeunId
			,ad.AsuntoID
			,a.CatOrganismoId
			,a.AsuntoAlias AS No_Exp
			,ad.SintesisOrden
			,ad.NombreArchivo
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
			,rc.sRuta
			, CONCAT(rc.sRuta,'\',a.CatorganismoId,'\', CONCAT(ad.NombreArchivo, ad.ExtensionDocumento)) AS RutaCompleta---Ajuste 
			--, CONCAT(rc.sRuta,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
		FROM AsuntosDocumentos ad WITH(NOLOCK) 
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
		LEFT JOIN CAT_RutasChunk rc 
			ON rc.iGrupo = 1 
			AND rc.iEscritura = 1
		LEFT JOIN CatEmpleados s WITH(NOLOCK) 
			ON s.EmpleadoId = p.Secretario
		WHERE ad.AsuntoNeunId=@pi_AsuntoNeunId 
			AND ad.NombreArchivo IS NOT NULL
			AND ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId 			  
			AND ad.StatusReg IN (1,2)
	END 


	SET NOCOUNT OFF
END
GO

