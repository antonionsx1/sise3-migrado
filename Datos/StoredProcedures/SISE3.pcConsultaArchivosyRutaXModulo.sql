SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Christian Araujo - MS
-- Alter date: 02/11/09
-- Objetivo: Carga el detalle de una promoción electrónica seleccionada en el detalle de promoción
-- EXEC SISE3.pcConsultaPromocionArchivosyRuta 30301133, 1,2023,4
      --  SISE3.[pcConsultaArchivosyRutaXModulo] 36068560,0,0,180,0,3,1, 1
	  --  SISE3.[pcConsultaArchivosyRutaXModulo] 23035824,2024,329,1494,22,1,null; 
      --  SISE3.[pcConsultaArchivosyRutaXModulo] 30315797,2024,1260,1494,4,1,null,NULL;
	  --  EXEC SISE3.[pcConsultaArchivosyRutaXModulo] 30327826,2024,null,180,3,1,NULL,null
-- Modificación: LAGS, 05 Julio del 2024, Se agrega información para contenido Promoción. 
-- =============================================

ALTER PROCEDURE [SISE3].[pcConsultaArchivosyRutaXModulo]
(
@pi_AsuntoNeunId BIGINT ,
@pi_YearPromocion INT = NULL, 
@pi_NumeroOrden INT= NULL,  --
@pi_catIdOrganismo INT,
@pi_Origen INT = NULL, 
@pi_TipoModulo INT, --1 Promocion 2 Acuerdo/Determinaciones 3 Acuse/Notificaciones 5 Documentos/Archivo
@pi_AsuntoDocumentoId INT = NULL,
@pi_SintesisOrden INT = NULL,
@pi_ModuloSise varchar(20) = NULL
)

 
AS
BEGIN
	SET NOCOUNT ON
	IF @pi_TipoModulo = 1 
	BEGIN 

		IF @pi_Origen IN (0,4,7)
		BEGIN
			SELECT  NombreClase = CASE ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END				  
				   --,ac.DESCRIPCION + ' - ' + ISNULL(cp.CatalogoPromocionDescripcion,'') AS DescripcionAnexo
				   ,CASE pa.ClaseAnexo WHEN NULL THEN ac.DESCRIPCION + ' - ' + ISNULL(cp.CatalogoPromocionDescripcion,'')
							WHEN 0 THEN ac.DESCRIPCION + ' - ' + ISNULL(cp.CatalogoPromocionDescripcion,'') 
							ELSE ac.DESCRIPCION END AS DescripcionAnexo
				   ,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				   ,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				   ,Pa.NombreArchivo
				   ,pa.PromoFileIdentificador as guidDocumento
				   ,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',[Promociones].CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				   ,0 EsElectronica
				   ,pa.Firmado
				   ,[Promociones].NumeroOrden
				   ,Promociones.NumeroRegistro
				   ,Promociones.YearPromocion
			FROM [dbo].[Promociones] WITH(NOLOCK) 
			LEFT JOIN CatPromocion cp WITH(NOLOCK) ON cp.CatalogoPromocionId = TipoContenido
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
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = Promociones.AsuntoNeunId
                AND hist.YearPromocion = Promociones.YearPromocion
                AND hist.NumeroOrden = Promociones.NumeroOrden
                AND hist.CatOrganismoId = Promociones.CatOrganismoId 
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK)
				ON ad.AsuntoNeunId= Promociones.AsuntoNeunId
				AND ad.AsuntoDocumentoId = Promociones.AsuntoDocumentoId
			WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
				  AND (@pi_YearPromocion IS NULL OR [Promociones].YearPromocion= ISNULL(@pi_YearPromocion,[Promociones].YearPromocion)) 
				  AND Pa.NombreArchivo IS NOT NULL		  
				  AND [Promociones].CatOrganismoId=@pi_catIdOrganismo 
				  AND [Promociones].StatusReg in (1,2)
				  AND (@pi_NumeroOrden IS NULL OR [Promociones].NumeroOrden= ISNULL(@pi_NumeroOrden,[Promociones].NumeroOrden))
				  AND (@pi_AsuntoDocumentoId IS NULL OR ad.AsuntoDocumentoId=ISNULL(@pi_AsuntoDocumentoId, ad.AsuntoDocumentoId))
				  
				  AND (@pi_SintesisOrden IS NULL OR Promociones.SintesisOrden=ISNULL(@pi_SintesisOrden, Promociones.SintesisOrden))
		END
		ELSE IF @pi_Origen = 6
		BEGIN
			SELECT	NombreClase = 'Pendiente'  --ARCHIVOS EN TABLAS ELECTRÓNICAS
					,null AS DescripcionAnexo
					,EsPromocion = 1
					,rc.sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					, CONCAT(rc.sRuta,'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,null as guidDocumento
					,null as Firmado
					,null NumeroOrden
					,null NumeroRegistro
					,null YearPromocion
			FROM JL_MOV_Promocion pr 
			LEFT JOIN JL_REL_PromocionArchivo pa ON pr.kIdPromocion = pa.fkIdPromocion
			LEFT JOIN JL_MOV_Archivo  moa ON moa.kIdArchivo = pa.fkIdArchivo
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
            WHERE pr.kIdPromocion = @pi_AsuntoNeunId
				  AND pr.fkIdEstatus = 1
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
			UNION -- UNION A TABLA RELACIONADA PARA NO TRAER MÁS DE OTROS ORGANISMOS
			SELECT	NombreClase = 'Pendiente'
					,null AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rcb.sRuta,rc.sRuta) sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					, CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,null as guidDocumento
					,null as Firmado
					,ps.NumeroOrden
					,null as NumeroRegistro
					,ps.YearPromocion
			FROM JL_MOV_Promocion pr 
			LEFT JOIN JL_REL_PromocionArchivo pa ON pr.kIdPromocion = pa.fkIdPromocion
			LEFT JOIN JL_MOV_Archivo  moa ON moa.kIdArchivo = pa.fkIdArchivo
			LEFT JOIN JL_REL_PromocionSISE ps with(nolock) ON pr.kIdPromocion = ps.fkIdPromocion and pr.fkIdAsuntoNeun = ps.AsuntoNeunId and pr.fkIdOrgano = ps.CatOrganismoId
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = ps.AsuntoNeunId
                AND hist.YearPromocion = ps.YearPromocion
                AND hist.NumeroOrden = ps.NumeroOrden
                AND hist.CatOrganismoId = ps.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE ps.AsuntoNeunId=@pi_AsuntoNeunId
				  AND ps.NumeroOrden=ISNULL(@pi_NumeroOrden,ps.NumeroOrden)
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
				  AND pr.fkIdEstatus = 1
			UNION -- ANEXOS
			SELECT
				NombreClase = 'Pendiente'
				,ac.DESCRIPCION AS DescripcionAnexo
				,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				,Pa.NombreArchivo
				,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',pa.CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				,0 EsElectronica
				,pa.PromoFileIdentificador as guidDocumento
				,pa.Firmado
				,pa.NumeroOrden
				,pa.NumeroRegistro
				,pa.YearPromocion
			FROM PromocionArchivos pa 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = pa.DescripcionAnexo 
				AND ac.Catalogo = 17
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = pa.AsuntoNeunId
                AND hist.YearPromocion = pa.YearPromocion
                AND hist.NumeroOrden = pa.NumeroOrden
                AND hist.CatOrganismoId = pa.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE pa.AsuntoNeunId = @pi_AsuntoNeunId
			AND pa.CatOrganismoId = @pi_catIdOrganismo
			AND pa.NumeroOrden = ISNULL(@pi_NumeroOrden,pa.NumeroOrden)
			--AND pa.YearPromocion = @pi_YearPromocion 
			AND pa.StatusArchivo = 1
		END
		ELSE IF @pi_Origen = 14
		BEGIN
			SELECT	NombreClase = 'Pendiente'
					,null AS DescripcionAnexo
					,EsPromocion = 1
					,rc.sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					, CONCAT(rc.sRuta,'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,NULL as guidDocumento
					,null as Firmado
					,null as NumeroOrden
					,null as NumeroRegistro
					,null YearPromocion
			FROM ICOIJ_MOV_Promocion pr 
			LEFT JOIN ICOIJ_MOV_Archivo moa ON moa.kiIdFolio = pr.kiIdFolio
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 20 AND rc.iEscritura = 1
			WHERE (pr.kiIdFolio = @pi_AsuntoNeunId)
				  AND pr.fkIdEstatus = 1
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
			UNION
			SELECT	NombreClase = 'Pendiente'
					,null AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rcb.sRuta,rc.sRuta) sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					, CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,NULL as guidDocumento
					,null as Firmado
					,ps.NumeroOrden
					,null NumeroRegistro
					,ps.YearPromocion
			FROM ICOIJ_MOV_Promocion pr 
			LEFT JOIN ICOIJ_MOV_Archivo moa ON moa.kiIdFolio = pr.kiIdFolio
			--LEFT JOIN ICOIJ_REL_PromocionSISE ps with(nolock) ON pr.kIdPromocion = ps.fkIdPromocion AND ps.AsuntoNeunId = pr.fkIdAsuntoNeun AND ps.CatOrganismoId = pr.fkIdOrgano
			LEFT JOIN ICOIJ_REL_PromocionSISE ps with(nolock) ON CASE WHEN LEN(ps.fkIdPromocion) <= 6 THEN pr.kIdPromocion ELSE pr.kiIdFolio END = ps.fkIdPromocion AND ps.AsuntoNeunId = pr.fkIdAsuntoNeun AND ps.CatOrganismoId = pr.fkIdOrgano
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = ps.AsuntoNeunId
                AND hist.YearPromocion = ps.YearPromocion
                AND hist.NumeroOrden = ps.NumeroOrden
                AND hist.CatOrganismoId = ps.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 20 AND rc.iEscritura = 1
			WHERE (ps.AsuntoNeunId=@pi_AsuntoNeunId)
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
				  AND ps.NumeroOrden=ISNULL(@pi_NumeroOrden,ps.NumeroOrden)
				  AND pr.fkIdEstatus = 1
			UNION
			SELECT
				NombreClase = 'Pendiente'
				,ac.DESCRIPCION AS DescripcionAnexo
				,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				,Pa.NombreArchivo
				,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',pa.CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				,0 EsElectronica
				,pa.PromoFileIdentificador as guidDocumento
				,pa.Firmado
				,pa.NumeroOrden
				,pa.NumeroRegistro
				,pa.YearPromocion
			FROM PromocionArchivos pa 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = pa.DescripcionAnexo 
				AND ac.Catalogo = 17
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = pa.AsuntoNeunId
                AND hist.YearPromocion = pa.YearPromocion
                AND hist.NumeroOrden = pa.NumeroOrden
                AND hist.CatOrganismoId = pa.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE pa.AsuntoNeunId = @pi_AsuntoNeunId
			AND pa.CatOrganismoId = @pi_catIdOrganismo
			AND pa.NumeroOrden =ISNULL(@pi_NumeroOrden,pa.NumeroOrden)
			--AND pa.YearPromocion = @pi_YearPromocion 
			AND pa.StatusArchivo = 1
		END
		ELSE IF @pi_Origen IN (22,30)
		BEGIN
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,rc.sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,null as guidDocumento
					, CONCAT(rc.sRuta,'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,null as Firmado
					,null as NumeroOrden
					,null NumeroRegistro
					,null YearPromocion
			FROM IOJ_MOV_PromocionOJ pr 
			LEFT JOIN IOJ_REL_PromocionArchivoOJ ar ON  ar.fkIdPromocion = pr.kiIdFolio
            LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = ar.fkIdArchivo
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
			WHERE (pr.kiIdFolio = @pi_AsuntoNeunId)
				  AND pr.fkIdEstatus = 1
				  AND pr.fkIdOrgano = @pi_catIdOrganismo                  
			UNION
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rcb.sRuta,rc.sRuta) sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,null as guidDocumento
					, CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,null as Firmado
					,ps.NumeroOrden
					,null NumeroRegistro
					,ps.YearPromocion
			FROM IOJ_MOV_PromocionOJ pr 
			LEFT JOIN IOJ_REL_PromocionSISE ps with(nolock) ON pr.kiIdFolio = ps.fkIdPromocion 
            LEFT JOIN IOJ_REL_PromocionArchivoOJ ar ON  ar.fkIdPromocion = pr.kiIdFolio
            LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = ar.fkIdArchivo
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = ps.AsuntoNeunId
                AND hist.YearPromocion = ps.YearPromocion
                AND hist.NumeroOrden = ps.NumeroOrden
                AND hist.CatOrganismoId = ps.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE (ps.AsuntoNeunId=@pi_AsuntoNeunId)
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
				  AND ps.NumeroOrden=ISNULL(@pi_NumeroOrden,ps.NumeroOrden)
				  AND pr.fkIdEstatus = 1
			UNION
            --ARCHIVOS IOJ CON EXPEDIENTE
            SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,rc.sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,null as guidDocumento
					, CONCAT(rc.sRuta,'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,null Firmado
					,null NumeroOrden
					,null NumeroREgistro
					,null YearPromocion
			FROM JL_MOV_Promocion pr 
			LEFT JOIN JL_REL_PromocionArchivo da with(nolock) on pr.kIdPromocion=da.fkIdPromocion AND da.fkIdEstatus = 1
            LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = da.fkIdArchivo
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
           	WHERE (pr.kIdPromocion = @pi_AsuntoNeunId)
				  AND pr.fkIdEstatus = 1
				  AND pr.fkIdOrgano = @pi_catIdOrganismo                  
			UNION
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rcb.sRuta,rc.sRuta) sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,null as guidDocumento
					, CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',[pr].fkIdOrgano,'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,1 EsElectronica
					,null as Firmado
					,ps.NumeroOrden
					,null NumeroRegistro
					,ps.YearPromocion
			FROM JL_MOV_Promocion pr 
			LEFT JOIN JL_REL_PromocionSISE ps with(nolock) ON pr.kIdPromocion = ps.fkIdPromocion 
            LEFT JOIN JL_REL_PromocionArchivo da with(nolock) on pr.kIdPromocion=da.fkIdPromocion AND da.fkIdEstatus = 1
            LEFT JOIN JL_MOV_Archivo moa ON moa.kIdArchivo = da.fkIdArchivo
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = ps.AsuntoNeunId
                AND hist.YearPromocion = ps.YearPromocion
                AND hist.NumeroOrden = ps.NumeroOrden
                AND hist.CatOrganismoId = ps.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE (ps.AsuntoNeunId=@pi_AsuntoNeunId)
				  AND pr.fkIdOrgano = @pi_catIdOrganismo
				  AND ps.NumeroOrden=ISNULL(@pi_NumeroOrden,ps.NumeroOrden)
				  AND pr.fkIdEstatus = 1

            --FIN IOJ CON EXPEDIENTE
			UNION
			SELECT
				NombreClase = 'Pendiente'
				,ac.DESCRIPCION AS DescripcionAnexo
				,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				,Pa.NombreArchivo
				,pa.PromoFileIdentificador as guidDocumento
				,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',pa.CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				,0 EsElectronica
				,pa.Firmado
				,pa.NumeroOrden
				,pa.NumeroRegistro
				,pa.YearPromocion
			FROM PromocionArchivos pa 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = pa.DescripcionAnexo 
				AND ac.Catalogo = 17
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 AND rc.iEscritura = 1 
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = pa.AsuntoNeunId
                AND hist.YearPromocion = pa.YearPromocion
                AND hist.NumeroOrden = pa.NumeroOrden
                AND hist.CatOrganismoId = pa.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE pa.AsuntoNeunId = @pi_AsuntoNeunId
			AND pa.CatOrganismoId = @pi_catIdOrganismo
			AND pa.NumeroOrden = ISNULL(@pi_NumeroOrden,pa.NumeroOrden)
			--AND pa.YearPromocion = @pi_YearPromocion 
			AND pa.StatusArchivo = 1
		END
		ELSE IF @pi_Origen IN (5,31)
		BEGIN
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,rc.sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,null as guidDocumento
					, CONCAT(rc.sRuta,'\',IIF(moa.fkIdOrigen != 7, ISNULL([d].fkIdOCC,[d].fkIdOrgano), LEFT(moa.sNombreArchivo, 4)),'\'
					, moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,EsBoletaOCC = IIF(moa.fkIdOrigen != 7, 0, 1)
					,1 EsElectronica
					,null Firmado
					,null NumeroOrden
					,null NumeroRegistro
					,null YearPromocion
			FROM JL_MOV_Demanda d 
			LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on d.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
			LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
			WHERE d.kIdDemanda = @pi_AsuntoNeunId
				  AND d.fkIdEstatus = 1
				  --AND d.fkIdOrgano = @pi_catIdOrganismo
			UNION
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rcb.sRuta,rc.sRuta) sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,null as guidDocumento
					,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',IIF(moa.fkIdOrigen != 7, ISNULL([d].fkIdOCC,[d].fkIdOrgano), LEFT(moa.sNombreArchivo, 4)),'\'
					, moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,EsBoletaOCC = IIF(moa.fkIdOrigen != 7, 0, 1)
					,1 EsElectronica
					,null as Firmado
					,rdem.NumeroOrden
					,null NumeroRegistro
					,rdem.YearPromocion
			FROM JL_MOV_Demanda d 
			LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on d.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
			LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1	
			LEFT JOIN JL_REL_DemandaSISE rdem WITH (nolock) on rdem.fkIdDemanda = d.kIdDemanda
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = rdem.AsuntoNeunId
                AND hist.YearPromocion = rdem.YearPromocion
                AND hist.NumeroOrden = rdem.NumeroOrden
                AND hist.CatOrganismoId = rdem.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE rdem.AsuntoNeunId = @pi_AsuntoNeunId
				  AND rdem.CatOrganismoId=@pi_catIdOrganismo
				  AND rdem.NumeroOrden = ISNULL(@pi_NumeroOrden,rdem.NumeroOrden)
				  AND d.fkIdEstatus = 1
			UNION
			SELECT
				NombreClase = 'Pendiente'
				,ac.DESCRIPCION AS DescripcionAnexo --descripcion
				,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				,Pa.NombreArchivo
				,pa.PromoFileIdentificador as guidDocumento
				,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',pa.CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				,EsBoletaOCC = 0
				,0 EsElectronica
				,pa.Firmado
				,pa.NumeroOrden
				,null NumeroRegistro
				,pa.YearPromocion
			FROM PromocionArchivos pa 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = pa.DescripcionAnexo 
				AND ac.Catalogo = 17
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = pa.AsuntoNeunId
                AND hist.YearPromocion = pa.YearPromocion
                AND hist.NumeroOrden = pa.NumeroOrden
                AND hist.CatOrganismoId = pa.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE pa.AsuntoNeunId = @pi_AsuntoNeunId
			AND pa.CatOrganismoId = @pi_catIdOrganismo
			AND (@pi_NumeroOrden IS NULL OR pa.NumeroOrden = ISNULL(@pi_NumeroOrden,pa.NumeroOrden))
			--AND pa.YearPromocion = @pi_YearPromocion 
			AND pa.StatusArchivo = 1
		END
		ELSE IF @pi_Origen = 15
		BEGIN
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,rc.sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,CONCAT(rc.sRuta,'\',IIF(moa.fkIdOrigen != 7, ISNULL([d].fkIdOCC,[d].fkIdOrgano), LEFT(moa.sNombreArchivo, 4)),'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,EsBoletaOCC = IIF(moa.fkIdOrigen != 7, 0, 1)
					,1 EsElectronica
					,null guidDocumento
					,null Firmado
					,null NumeroOrden
					,null NumeroRegistro
					,null YearPromocion
			FROM ICOIJ_MOV_Demanda d 
			LEFT JOIN  dbo.ICOIJ_MOV_Archivo AS moa ON d.kiIdFolio = moa.kiIdFolio AND moa.fkIdEstatus = 1
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
			WHERE (d.kiIdFolio = @pi_AsuntoNeunId)
				  AND d.fkIdEstatus = 1
				  --AND d.fkIdOrgano = @pi_catIdOrganismo
			UNION
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rcb.sRuta,rc.sRuta) sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',IIF(moa.fkIdOrigen != 7, ISNULL([d].fkIdOCC,[d].fkIdOrgano), LEFT(moa.sNombreArchivo, 4)),'\', moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,EsBoletaOCC = IIF(moa.fkIdOrigen != 7, 0, 1)
					,1 EsElectronica
					,NULL as guidDocumento
					,null as Firmado
					,irdem.NumeroOrden
					,null NumeroRegistro
					,irdem.YearPromocion
			FROM ICOIJ_MOV_Demanda d 
			LEFT JOIN  dbo.ICOIJ_MOV_Archivo AS moa ON d.kiIdFolio = moa.kiIdFolio AND moa.fkIdEstatus = 1
			LEFT JOIN dbo.ICOIJ_REL_DemandaSISE irdem WITH (NOLOCK) ON irdem.fkIdDemanda = d.kIdDemanda
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 9 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = irdem.AsuntoNeunId
                AND hist.YearPromocion = irdem.YearPromocion
                AND hist.NumeroOrden = irdem.NumeroOrden
                AND hist.CatOrganismoId = irdem.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE (irdem.AsuntoNeunId = @pi_AsuntoNeunId)
				 AND irdem.CatOrganismoId=@pi_catIdOrganismo
				  AND irdem.NumeroOrden=ISNULL(@pi_NumeroOrden,irdem.NumeroOrden)
				  AND d.fkIdEstatus = 1
				  --AND d.fkIdOrgano = @pi_catIdOrganismo
			UNION
			SELECT
				NombreClase = 'Pendiente'
				,ac.DESCRIPCION AS DescripcionAnexo
				,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				,Pa.NombreArchivo
				,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',pa.CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				,EsBoletaOCC = 0
				,0 EsElectronica
				,pa.PromoFileIdentificador as guidDocumento
				,pa.Firmado
				,pa.NumeroOrden
				,null NumeroRegistro
				,pa.YearPromocion
			FROM PromocionArchivos pa 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = pa.DescripcionAnexo 
				AND ac.Catalogo = 17
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 AND rc.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = pa.AsuntoNeunId
                AND hist.YearPromocion = pa.YearPromocion
                AND hist.NumeroOrden = pa.NumeroOrden
                AND hist.CatOrganismoId = pa.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE pa.AsuntoNeunId = @pi_AsuntoNeunId
			AND pa.CatOrganismoId = @pi_catIdOrganismo
			AND pa.NumeroOrden = ISNULL(@pi_NumeroOrden,pa.NumeroOrden)
			--AND pa.YearPromocion = @pi_YearPromocion 
			AND pa.StatusArchivo = 1
		END
		ELSE IF @pi_Origen = 29
		BEGIN
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,IIF(moa.iTipoArchivo = 27,rc.sRuta,rcb.sRuta) as sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,CONCAT(IIF(moa.iTipoArchivo = 27,rc.sRuta,rcb.sRuta),'\',IIF(moa.iTipoArchivo = 27, coe.OrigenCatOrganismoId, LEFT(moa.sNombreArchivo, 4)),'\'
					,moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste
					,EsBoletaOCC = IIF(moa.iTipoArchivo = 27, 0, 1)
					,1 EsElectronica
					,null guidDocumento
					,null Firmado
					,null NumeroOrden
					,null NumeroRegistro
					,null YearPromocion
			FROM JL_MOV_Demanda d 
			LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on d.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
			LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on  d.kIdDemanda = coe.fkIdDemanda
			LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1	
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 16 AND rc.iEscritura = 1
            LEFT JOIN CAT_RutasChunk rcb ON rcb.iGrupo = 9 AND rcb.iEscritura = 1
			WHERE (d.kIdDemanda = @pi_AsuntoNeunId)
				  AND d.fkIdEstatus = 1
				  --AND d.fkIdOrgano = @pi_catIdOrganismo
			UNION
			SELECT	NombreClase = 'Pendiente'
					,NULL AS DescripcionAnexo
					,EsPromocion = 1
					,ISNULL(rc2.sRuta,IIF(moa.iTipoArchivo = 27,rc.sRuta,rcb.sRuta)) as sRuta
					,moa.sNombreArchivo+moa.sExtension NombreArchivo
					,CONCAT(ISNULL(rc2.sRuta,IIF(moa.iTipoArchivo = 27,rc.sRuta,rcb.sRuta)),'\',IIF(moa.iTipoArchivo = 27, coe.OrigenCatOrganismoId, LEFT(moa.sNombreArchivo, 4)),'\'
					, moa.sNombreArchivo,moa.sExtension) AS RutaCompleta---Ajuste 
					,EsBoletaOCC = IIF(moa.iTipoArchivo = 27, 0, 1)
					,1 EsElectronica
					,NULL as guidDocumento
					,null as Firmado
					,ps.NumeroOrden
					,null NumeroRegistro
					,ps.YearPromocion
			FROM JL_MOV_Demanda d 
			LEFT JOIN JL_REL_DemandaArchivo da with(nolock) on d.kIdDemanda=da.fkIdDemanda AND da.fkIdEstatus = 1
			LEFT JOIN ComunicacionesOficialesEnviadas coe with(nolock) on  d.kIdDemanda = coe.fkIdDemanda
			LEFT JOIN JL_REL_DemandaSISE ps with(nolock) ON d.kIdDemanda = ps.fkIdDemanda 
			LEFT JOIN  dbo.JL_MOV_Archivo AS moa ON moa.kIdArchivo = da.fkIdArchivo and moa.fkIdEstatus = 1	
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 16 AND rc.iEscritura = 1
            LEFT JOIN CAT_RutasChunk rcb ON rcb.iGrupo = 9 AND rcb.iEscritura = 1
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = ps.AsuntoNeunId
                AND hist.YearPromocion = ps.YearPromocion
                AND hist.NumeroOrden = ps.NumeroOrden
                AND hist.CatOrganismoId = ps.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rc2 
				ON rc2.kId = hist.idRuta
			WHERE (ps.AsuntoNeunId = @pi_AsuntoNeunId)
				 AND ps.CatOrganismoId=@pi_catIdOrganismo
				 AND ps.NumeroOrden=ISNULL(@pi_NumeroOrden,ps.NumeroOrden)
				  AND d.fkIdEstatus = 1
				  --AND d.fkIdOrgano = @pi_catIdOrganismo
			UNION
			SELECT
				NombreClase = 'Pendiente'
				,ac.DESCRIPCION AS DescripcionAnexo
				,EsPromocion = CASE pa.ClaseAnexo WHEN NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,ISNULL(rcb.sRuta,rc.sRuta) sRuta
				,Pa.NombreArchivo
				,CONCAT(ISNULL(rcb.sRuta,rc.sRuta),'\',pa.CatorganismoId,'\', Pa.NombreArchivo) AS RutaCompleta---Ajuste 
				,EsBoletaOCC = 0
				,0 EsElectronica
				,pa.PromoFileIdentificador as guidDocumento
				,pa.Firmado
				,pa.NumeroOrden
				,pa.NumeroRegistro
				,pa.YearPromocion
			FROM PromocionArchivos pa 
			LEFT JOIN viCatalogos ac WITH(NOLOCK) 
				ON ac.ID = pa.DescripcionAnexo 
				AND ac.Catalogo = 17
			JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 AND rc.iEscritura = 1 
            LEFT JOIN SISE3.REL_ArchivosRutaHistorica hist WITH(NOLOCK)
                ON hist.AsuntoNeunId = pa.AsuntoNeunId
                AND hist.YearPromocion = pa.YearPromocion
                AND hist.NumeroOrden = pa.NumeroOrden
                AND hist.CatOrganismoId = pa.CatOrganismoId
            LEFT JOIN CAT_RutasChunk rcb 
				ON rcb.kId = hist.idRuta
			WHERE pa.AsuntoNeunId = @pi_AsuntoNeunId
			AND pa.CatOrganismoId = @pi_catIdOrganismo
			AND pa.NumeroOrden = ISNULL(@pi_NumeroOrden,pa.NumeroOrden)
			--AND pa.YearPromocion = @pi_YearPromocion 
			AND pa.StatusArchivo = 1
		END
	END 
	IF @pi_TipoModulo = 2
	BEGIN 
		DECLARE @sRuta VARCHAR(255)
		DECLARE	@tRutasChunk AS TABLE (
				KId INT,	
				iGrupo INT, 
				sDescripcion VARCHAR(500),
				iTipoArchivo INT,
				sTipoArchivoDesc VARCHAR(500),
				sRuta VARCHAR(500),	
				iEscritura INT)
		INSERT @tRutasChunk(KId,iGrupo,sDescripcion,iTipoArchivo,sTipoArchivoDesc,sRuta,iEscritura)
		EXEC [SISE3].[pcRutasChunkXModulo] 'Trámite' 

		SET @sRuta = (SELECT TOP 1 sRuta FROM @tRutasChunk)

		/****/
		CREATE TABLE #TmpDocDJ(
		AsuntoDocumentoId int null,
		AsuntoNeunId bigint null,
		AsuntoID int null,
		CatOrganismoId int null,
		AsuntoAlias varchar(50) null, 
		SintesisOrden int null,
		NombreArchivo varchar(100) null,
		TipoCuaderno int null,
		NombreTipoCuaderno varchar(100) null,
		EmpleadoCancela varchar(150) null,
		EmpleadoAutoriza varchar(150) null,
		EmpleadoPreAutoriza varchar(150) null,
		FechaAutoriza datetime null,
		FechaPreAutoriza datetime null,
		FechaCancela datetime null,
		userNameCapDJ varchar(100) null,
		userNameSecretario varchar(100) null,
		FechaRecibido_F varchar(20) null,
	    FechaAuto_F varchar(10) null,
		sRuta VARCHAR(500) null,
		RutaCompleta varchar(200) null,
		GuidDocumento uniqueidentifier null,
		IdTabla bigint null,
		Contenido int null
		)
		/*****/

		INSERT INTO #TmpDocDJ
	    SELECT DISTINCT * FROM (


             SELECT 
			 ad.AsuntoDocumentoId
			,ad.AsuntoNeunId
			,ad.AsuntoID
			,a.CatOrganismoId
			,a.AsuntoAlias AS No_Exp
			,ad.SintesisOrden
			,(ad.NombreArchivo+ad.ExtensionDocumento) as NombreArchivo
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
			,CASE WHEN rc.sRuta IS NULL OR rc.sRuta = ''  THEN @sRuta ELSE rc.sRuta END AS sRuta
            ,CONCAT(CASE WHEN rc.sRuta IS NULL OR rc.sRuta = ''  THEN @sRuta ELSE rc.sRuta END ,'\',a.CatorganismoId,'\', IIF(ad.Firmado=1,dj.NombreArchivo,CONCAT(ad.NombreArchivo, ad.ExtensionDocumento))) AS RutaCompleta---Ajuste 
			,ad.uGuidDocumento GuidDocumento
			,0 as IdTabla
			,ISNULL(DJ.Contenido,ad.CatContenidoId) AS Contenido
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
        LEFT JOIN DeterminacionesJudiciales dj
            ON dj.AsuntoNeunId = ad.AsuntoNeunId
            AND dj.CatOrganismoId = a.CatOrganismoId
            AND dj.SintesisOrden = ad.SintesisOrden
		LEFT JOIN CAT_RutasChunk rc ON rc.kId = ad.TipoRuta
		LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
		WHERE ad.AsuntoNeunId=@pi_AsuntoNeunId 
			AND ad.NombreArchivo IS NOT NULL  
			AND ad.StatusReg IN (1,2)
			AND (ad.AsuntoDocumentoId=@pi_AsuntoDocumentoId
			     OR ad.SintesisOrden = @pi_SintesisOrden)

UNION ALL

             SELECT 
			 0 as AsuntoDocumentoId
			,dj.AsuntoNeunId
			,dj.AsuntoID
			,a.CatOrganismoId
			,a.AsuntoAlias AS No_Exp
			,dj.SintesisOrden
			,NombreArchivo = ISNULL(dj.NombreArchivo,'')
			,dj.TipoCuaderno
			,dbo.funRecuperaCatalogoDependienteDescripcion(527,dj.TipoCuaderno) AS NombreTipoCuaderno
			,EmpleadoCancela = ''
			,EmpleadoAutoriza = ''
			,EmpleadoPreAutoriza = ''
			,FechaAutoriza = ''
			,FechaPreAutoriza = ''
			,FechaCancela = ''
			,userNameCapDJ =dbo.fnx_getUserName(dj.UsuarioCaptura)
			,userNameSecretario =dbo.fnx_getUserName(dj.SecretarioPId) --dbo.fnx_getUserName(p.Secretario)
			--,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
			--		ELSE '' END As FechaRecibido_F
			,'' As FechaRecibido_F
			,ISNULL(CONVERT(VARCHAR(10),dj.FechaAuto,103),'') AS FechaAuto_F
			,CASE WHEN rc.sRuta IS NULL OR rc.sRuta = ''  THEN @sRuta ELSE rc.sRuta END AS sRuta
			,CONCAT(CASE WHEN rc.sRuta IS NULL OR rc.sRuta = ''  THEN @sRuta ELSE rc.sRuta END ,'\',a.CatorganismoId,'\', dj.NombreArchivo) AS RutaCompleta---Ajuste 
			,NULL AS GuidDocumento
			,dj.DJId as IdTabla
			,DJ.Contenido
		FROM DeterminacionesJudiciales dj
	JOIN Asuntos a WITH(NOLOCK) 
			ON a.AsuntoNeunId= dj.AsuntoNeunId
		LEFT JOIN Promociones p WITH(NOLOCK) 
			ON A.AsuntoNeunId = p.AsuntoNeunId 
			AND dj.SintesisOrden= p.SintesisOrden
			AND p.StatusReg=dj.StatusReg
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
		LEFT JOIN [SISE3].[REL_ArchivosRuta] RAR WITH(NOLOCK) 
		      ON dj.AsuntoNeunId = RAR.AsuntoNeunId
			  AND dj.DJId = RAR.fkIdTabla
        LEFT JOIN CAT_RutasChunk rc  ON  RAR.fkIdRuta = kId
		--rc.iGrupo = 1 AND rc.iEscritura = 1
		LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
		WHERE dj.AsuntoNeunId=@pi_AsuntoNeunId 
		and dj.StatusReg =1
			AND dj.SintesisOrden=@pi_SintesisOrden
			AND NOT EXISTS (SELECT 1 FROM AsuntosDocumentos ad
			WHERE ad.AsuntoNeunId =dj.AsuntoNeunId and ad.SintesisOrden = dj.SintesisOrden)
			) as x

	    IF(@pi_ModuloSise <> 'sentencia' AND @pi_ModuloSise IS NOT NULL AND (SELECT COUNT(*) FROM #TmpDocDJ WHERE Contenido =3969) >= 1)
		BEGIN
		SELECT * FROM #TmpDocDJ
		WHERE Contenido not in (3969)
		END ELSE
		BEGIN 
		SELECT * FROM #TmpDocDJ
		END

	END 
    IF @pi_TipoModulo = 3
    BEGIN
		CREATE TABLE #NotTemp (sRuta VARCHAR(200), NombreArchivo VARCHAR(100), RutaCompleta VARCHAR(250), IdTabla INT)

		INSERT INTO #NotTemp
        SELECT
             rc.sRuta 
            ,nea.NombreArchivo
            ,CONCAT(rc.sRuta,'\',ne.CatOrganismoId,'\', nea.NombreArchivo) AS RutaCompleta
			,nea.ArchivoId as IdTabla
        FROM NotificacionElectronica_Archivos nea        
        INNER JOIN NotificacionElectronica_Personas nep
            ON nea.NotElecId = nep.NotElecId
        INNER JOIN  NotificacionElectronica ne
            ON ne.AsuntoNeunId = nep.AsuntoNeunId
            AND ne.NumeroOrden = nep.NumeroOrden
            AND ne.SintesisOrden = nep.SintesisOrden
        INNER JOIN CAT_RutasChunk rc
            ON rc.iGrupo = 3 and iEscritura = 1
        WHERE nep.AsuntoNeunId = @pi_AsuntoNeunId
        AND ne.CatOrganismoId = @pi_catIdOrganismo
        AND nep.SintesisOrden = @pi_SintesisOrden

		IF NOT EXISTS(SELECT 1 FROM #NotTemp)
		BEGIN
			INSERT INTO #NotTemp
			SELECT rc.sRuta 
				, nep.AcuseRecibido AS NombreArchivo
				, CONCAT(rc.sRuta,'\',ne.CatOrganismoId,'\', nep.AcuseRecibido) AS RutaCompleta
				, 1 as IdTabla
			FROM NotificacionElectronica_Personas nep
			INNER JOIN  NotificacionElectronica ne
			ON ne.AsuntoNeunId = nep.AsuntoNeunId
				AND ne.NumeroOrden = nep.NumeroOrden
				AND ne.SintesisOrden = nep.SintesisOrden
			INNER JOIN CAT_RutasChunk rc
				ON rc.iGrupo = 3 and iEscritura = 1
			WHERE nep.AsuntoNeunId = @pi_AsuntoNeunId
				AND nep.SintesisOrden = @pi_SintesisOrden
		END

		SELECT * FROM #NotTemp
		DROP TABLE #NotTemp
    END
	--NUEVO MODULO
	 IF @pi_TipoModulo = 5
    BEGIN
		CREATE TABLE #docTemp (sRuta VARCHAR(200), NombreArchivo VARCHAR(100), RutaCompleta VARCHAR(250))

		INSERT INTO #docTemp
        SELECT 
             rc.sRuta 
            ,doca.NombreArchivo
            ,CONCAT(rc.sRuta,'\',@pi_catIdOrganismo,'\', doca.NombreArchivo) AS RutaCompleta
        FROM DocumentoArchivos doca WITH(NOLOCK)
        INNER JOIN CAT_RutasChunk rc WITH(NOLOCK)
            ON rc.iTipoArchivo = 67 AND iEscritura = 1
        WHERE doca.AsuntoNeunId = @pi_AsuntoNeunId
		AND doca.Orden = @pi_NumeroOrden
		AND doca.TipoDocumentoId = @pi_AsuntoDocumentoId
		
		SELECT * FROM #docTemp
		DROP TABLE #docTemp
    END

	SET NOCOUNT OFF
END