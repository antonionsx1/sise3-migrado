USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcReporteIncidentalDGAJ]    Script Date: 29/04/2025 02:05:18 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================          
-- Author:  JSM        
-- Create date: 05/03/2025         
-- Description: DGAJ Libro Control incidental   
-- Modificción: 29042025 JSM Se comenta tipo de contenido en Promociones
-- Modificción: 06052025 JRE Se coloca de forma correcta la condicion de fechas de consulta
-- Modificación: 30052025 JRE Se regresa nombre del quejoso referente a la tarea 23127
-- Modificación: 05062025 JRE Se regresa la propiedad idAsuntoRela referente a la tarea 23728
-- =============================================          
          
ALTER   PROCEDURE [SISE3].[pcReporteIncidentalDGAJ] 

  @pi_CatOrganismoId As Int          
 ,@pi_FechaConsultaIni As DateTime          
 ,@pi_FechaConsultaFin As DateTime          
         
AS          
BEGIN          
         
  SET NOCOUNT ON; 

CREATE TABLE #Asuntos
(
 [TipoAsunto][VARCHAR](100) NULL,
 [TipoProcedimiento][VARCHAR](100) NULL,
 [AsuntoAliasAJ][VARCHAR](50) NULL,
 [AsuntoNeunIdAJ][BIGINT] NULL, 
 [FechaRecepcionDGAJ][DATETIME] NULL, 
 [AsuntoAliasOrg][VARCHAR](50) NULL,
 [AsuntoNeunIdOrg][BIGINT] NULL,
 [EstadoIdOrg][SMALLINT] NULL,
 [EstadoOrg][VARCHAR](100) NULL,
 [CirIdOrg][SMALLINT] NULL,
 [CircuitoOrg][VARCHAR](100) NULL,
 [CorIdOrg][INT] NULL,
 [OrganoOrg][VARCHAR](400) NULL,
 [IdAsuntoRela][INT] NULL,
)   

CREATE TABLE #Personas( 
[AsuntoNeunId] [bigint] NULL, 
[PersonaId] [bigint] NULL, 
[Nombre] [varchar](500) NULL,
[Cargo] [varchar](500) NULL,
)

CREATE TABLE #ValoresAJ( 
[AsuntoNeunId] [bigint] NULL, 
[PersonaId] [bigint] NULL, 
[TipoAsuntoId] [int] NULL, 
[Valor] [varchar](MAX) NULL, 
[NoBloque][INT]NULL,
[CatTipoCatalogoAsuntoId][INT] NULL,
[CatCatalogoAsuntoId][INT] NULL,
[AsuntoDetalleId][bigint]NULL)

CREATE TABLE #ValoresOrg( 
[AsuntoNeunId] [bigint] NULL, 
[PersonaId] [bigint] NULL, 
[TipoAsuntoId] [int] NULL, 
[Valor] [varchar](MAX) NULL, 
[NoBloque][INT]NULL,
[CatTipoCatalogoAsuntoId][INT] NULL,
[CatCatalogoAsuntoId][INT] NULL,
[AsuntoDetalleId][bigint]NULL)


--SE INSERTA UNIVERSO DE ASUNTOS POR ÓRGANO Y PERIODO
            /*******************************************************************************************/
            Insert into #Asuntos(TipoAsunto,TipoProcedimiento,AsuntoAliasAJ,AsuntoNeunIdAJ,FechaRecepcionDGAJ
             ,AsuntoAliasOrg,AsuntoNeunIdOrg ,EstadoIdOrg,EstadoOrg,CirIdOrg,CircuitoOrg,CorIdOrg,OrganoOrg,IdAsuntoRela)
            
            SELECT
		          CTA.Descripcion 
		         ,(SELECT CatalogoElementoDescripcion FROM CatalogosElementosDescripcion CTED WITH(NOLOCK)
				   WHERE CTED.CatalogoElementoDescripcionID = A.CatTipoProcedimiento AND CTED.StatusRegistro = 1)         
                 ,A.AsuntoAlias
                 ,A.AsuntoNeunid   
		         ,ADF.ValorCampoAsunto
                 ,AOrg.AsuntoAlias
                 ,AOrg.AsuntoNeunId
                 ,(SELECT CE.CatEstadoId FROM CatOrganismos CO
				   INNER JOIN CatEstados CE ON CO.CatEstadosId =  CE.CatEstadoId
				   WHERE CatOrganismoId = AOrg.CatOrganismoId)
                 ,(SELECT CE.Nombre FROM CatOrganismos CO
				   INNER JOIN CatEstados CE ON CO.CatEstadosId =  CE.CatEstadoId
				   WHERE CatOrganismoId = AOrg.CatOrganismoId)
                 ,(SELECT CC.CatCircuitoId FROM CatOrganismos CO
				   INNER JOIN CatCircuitos CC ON CO.CatCircuitoId =  CC.CatCircuitoId
				   WHERE CatOrganismoId = AOrg.CatOrganismoId)
                 ,(SELECT CC.Nombre FROM CatOrganismos CO
				   INNER JOIN CatCircuitos CC ON CO.CatCircuitoId =  CC.CatCircuitoId
				   WHERE CatOrganismoId = AOrg.CatOrganismoId)
                 ,AOrg.CatOrganismoId	
                 ,AOrg.CatOrganismo
				 ,AR.IdAsuntoRela
            FROM Asuntos A WITH(NOLOCK)          
			INNER JOIN CatTiposAsunto CTA ON A.CatTipoAsuntoId = CTA.CatTipoAsuntoId          
			INNER JOIN AsuntosDetalleFechas ADF WITH(NOLOCK) ON A.AsuntoNeunId = ADF.AsuntoNeunId AND ADF.StatusReg = 1 AND ADF.TipoAsuntoId = 27057        
			LEFT JOIN AsuntosRelacionados AR WITH(NOLOCK) ON A.AsuntoNeunid = AR.AsuntoNeunIdDest AND AR.Status =1
			CROSS APPLY SISE3.fnExpediente(AR.AsuntoNeunIdOrg) AOrg
			WHERE A.CatOrganismoId = @pi_CatOrganismoId 
			AND (ADF.ValorCampoAsunto >=  cast(@pi_FechaConsultaIni as date) and 
			     ADF.ValorCampoAsunto < dateadd(day,1,cast(@pi_FechaConsultaFin as date)))
			AND A.StatusReg =1
			AND EXISTS (SELECT  1  FROM promociones p WITH(NOLOCK)
                        WHERE p.asuntoneunid =  A.AsuntoNeunId AND p.TipoCuaderno = 5647 
                        AND p.StatusReg = 1 --AND p.TipoContenido IN (6799,6804,6817,68181)
                        )

            CREATE INDEX MiIndex#Asuntos ON #Asuntos (AsuntoNeunIdAJ,AsuntoAliasAJ);
			/*******************************************************************************************/
--SE INSERTA UNIVERSO DE PERSONAS POR ÓRGANO Y PERIODO
			/*******************************************************************************************/	
            WITH CTE AS(
			SELECT AsuntoNeunId, PersonaId, NombreQuejoso, Cargo, AsuntoAliasAJ, ROW_NUMBER() OVER (PARTITION BY AsuntoNeunId, AsuntoAliasAJ ORDER BY FechaAlta ASC) AS rn FROM (
													SELECT  
														CASE
															WHEN   PA.CatCaracterPersonaAsuntoId IN(616) THEN PAU.ServidorPublico
															WHEN   PA.CatCaracterPersonaAsuntoId IN (12,13,48,54,60,71,87) THEN COALESCE( PA.Nombre, '')+ ' '
																    + COALESCE(PA.APaterno,'')+' '+COALESCE(PA.AMaterno,'')
														END as NombreQuejoso
														, PA.FechaAlta, PAU.Cargo, PA.AsuntoNeunId, PA.PersonaId, A.AsuntoAliasAJ
													FROM #Asuntos A
													LEFT JOIN PersonasAsunto PA WITH(NOLOCK) ON PA.AsuntoNeunId= A.AsuntoNeunIdAJ
													LEFT JOIN PersonasAsuntoUGIRA PAU WITH(NOLOCK) ON PAU.PersonaId=PA.PersonaId
													WHERE PA.StatusReg=1  
													) AS SQ
			WHERE SQ.NombreQuejoso IS NOT NULL)

			INSERT INTO #Personas (AsuntoNeunId,PersonaId, Nombre, Cargo)

			SELECT AsuntoNeunId, PersonaId, NombreQuejoso, Cargo
			FROM CTE WHERE rn = 1;

			CREATE INDEX MiIndex#Personas ON #Personas (AsuntoNeunId,PersonaId)
			/*******************************************************************************************/	
				
--SE INSERTA UNIVERSO DE CAMPOS DE CAPTURA POR ÓRGANO Y PERIODO
			/*******************************************************************************************/	
            Insert into #ValoresAJ(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            
			SELECT DISTINCT a.AsuntoNeunIdAJ, adde.TipoAsuntoId, adde.Contenido, adde.NoBloque,adde.AsuntoDetalleDescripcionId
            FROM #Asuntos a 
            INNER JOIN AsuntosDetalleDescripcion adde  with(nolock) on a.AsuntoNeunIdAJ = adde.AsuntoNeunId
            where
            adde.TipoAsuntoId in (27102,27076,27089,27094,27114,27074)
            and adde.StatusReg = 1

            Insert into #ValoresAJ(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            Select distinct a.AsuntoNeunIdAJ, adf.TipoAsuntoId, convert(varchar(10),adf.ValorCampoAsunto,103) as ValorCampoAsunto, ADF.NoBloque, adf.AsuntoDetalleFechasId
            From #Asuntos a             
            Inner Join AsuntosDetalleFechas adf with(nolock) on A.AsuntoNeunIdAJ = adf.AsuntoNeunId 
            Where                                    
            adf.TipoAsuntoId in (27091,27092,27095,27096,27109,27098,27099,27110,27101,27112,27113,27115,27068)                                                                       
            And adf.StatusReg = 1
				
                        
			CREATE INDEX MiIndex#ValoresAJ ON #ValoresAJ (AsuntoNeunId,TipoAsuntoId)
			/*******************************************************************************************/	
            
			/*******************************************************************************************/	
            Insert into #ValoresOrg(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            Select distinct a.AsuntoNeunIdOrg, adf.TipoAsuntoId, convert(varchar(10),adf.ValorCampoAsunto,103) as ValorCampoAsunto, ADF.NoBloque, adf.AsuntoDetalleFechasId
            From #Asuntos a             
            Inner Join AsuntosDetalleFechas adf with(nolock) on A.AsuntoNeunIdOrg = adf.AsuntoNeunId 
            Where                                    
            adf.TipoAsuntoId in (4708,4712,4716,4720,4722,4726,17648,17650,4724,4728,4737,4752,10412,10413,10416,10419,4756,4759,4760,4774)                                                                        
            And adf.StatusReg = 1

            Insert into #ValoresOrg (AsuntoNeunId, TipoAsuntoId,CatTipoCatalogoAsuntoId,CatCatalogoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            select distinct a.AsuntoNeunIdOrg, adc.TipoAsuntoId, adc.CatTipoCatalogoAsuntoId, adc.CatCatalogoAsuntoId,
            ced.CatalogoElementoDescripcion, adc.NoBloque , adc.AsuntoDetalleCatalogosId
            from #Asuntos a 
            inner join AsuntosDetalleCatalogos adc with(nolock) on a.AsuntoNeunIdOrg = adc.AsuntosNeunId
            inner join CatalogosElementosDescripcion ced with(nolock) on adc.CatCatalogoAsuntoId = ced.CatalogoElementoDescripcionID
            where 
            adc.StatusReg = 1 
            and adc.TipoAsuntoId in (4709,4717,4733,10414,4753,10420,4761)
            and adc.CatTipoCatalogoAsuntoId <> 389

            Insert into #ValoresOrg (AsuntoNeunId, TipoAsuntoId,CatTipoCatalogoAsuntoId,CatCatalogoAsuntoId, Valor, NoBloque)
            select distinct a.AsuntoNeunIdOrg, adc.TipoAsuntoId, adc.CatTipoCatalogoAsuntoId, adc.CatCatalogoAsuntoId,
            co.NombreOficial, adc.NoBloque 
            from #Asuntos a 
            inner join AsuntosDetalleCatalogos adc  with(nolock) on a.AsuntoNeunIdOrg = adc.AsuntosNeunId
            inner join CatOrganismos co on co.CatOrganismoId =  adc.CatCatalogoAsuntoId
            where 
            adc.StatusReg = 1 
            and adc.TipoAsuntoId in (4714,4739,10417)
            and adc.CatTipoCatalogoAsuntoId = 389


            Insert into #ValoresOrg(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            SELECT DISTINCT a.AsuntoNeunIdOrg, adde.TipoAsuntoId, adde.Contenido, adde.NoBloque,adde.AsuntoDetalleDescripcionId
            FROM #Asuntos a 
            INNER JOIN AsuntosDetalleDescripcion adde  with(nolock) on a.AsuntoNeunIdOrg = adde.AsuntoNeunId
            where
            adde.TipoAsuntoId in (4715,4751,10418)
            and adde.StatusReg = 1
				
                        
			CREATE INDEX MiIndex#ValoresOrg ON #ValoresOrg (AsuntoNeunId,TipoAsuntoId)
            /*******************************************************************************************/	      
			

 SELECT 
 ASU.TipoAsunto
 ,ASU.TipoProcedimiento
 ,ASU.AsuntoAliasAJ As ExpedienteAJ
 ,ASU.AsuntoNeunIdAJ As NEUNAJ
 ,ASU.AsuntoAliasOrg As ExpedienteOrg
 ,ASU.AsuntoNeunIdOrg As NeunOrg
 ,PE.Nombre AS NombreQuejosoAJ
 ,PE.Cargo AS CargoQuejosoAJ
 ,ASU.EstadoIdOrg
 ,ASU.EstadoOrg
 ,ASU.CirIdOrg
 ,ASU.CircuitoOrg
 ,ASU.CorIdOrg
 ,ASU.OrganoOrg
 ,ActRecEspAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27102 ORDER BY NoBloque)
 ,PresicionActRecEspAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27076 ORDER BY NoBloque)
 ,convert(varchar(10),ASU.FechaRecepcionDGAJ,103) as FechaRecepcionDGAJ
,FenchaSusProvOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4708 ORDER BY NoBloque)
,SentidoSusProvOrg =(SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4709	
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))

 ,EfectosSusProvAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27089 ORDER BY NoBloque)
 --RecursoQueja 1-b
 ,FechaInterQuejavsSusProvOrg =  (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4712 ORDER BY NoBloque)
 ,TccRecQvsSusProvOrg =  (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4714 ORDER BY NoBloque)
 ,NoTocaOrg =  (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4715  ORDER BY NoBloque)
 ,FechaEjecQvsSusProvOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4716  ORDER BY NoBloque)
 ,SentidoQvsSusProvOrg =  (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4717
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))
--Fin-RecursoQueja 1-b
 ,FechaVencimientoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27091 ORDER BY NoBloque)
 ,FechaRemisionAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27092 ORDER BY NoBloque)
--AUDIENCIA ANCIDENTAL
 ,FechaAudIncOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4720  ORDER BY NoBloque)
 ,FechaAudIncDifOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4722  ORDER BY NoBloque)
 ,FechaCelAudIncOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4726  ORDER BY NoBloque)
 ,FechaAudIncSinEfectOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 17648  ORDER BY NoBloque)
 ,FechaAudIncCancelOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 17650  ORDER BY NoBloque)
 ,FechaAudIncDif2Org = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4724  ORDER BY NoBloque)
 ,FechaCelAudIncAFOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4728  ORDER BY NoBloque)
--FIN AUDIENCIA ANCIDENTAL          
 ,SentidoSuspDefvOrg =  (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4733
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))

 ,EfectosSusDefAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27094 ORDER BY NoBloque)
 ,FechaNotSusDefAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27095 ORDER BY NoBloque)
 ,FechaVenInterRRincAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27096 ORDER BY NoBloque)
 ,FechaRemRRIncAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27109 ORDER BY NoBloque)
 ,FechaInterRevvsSusDefOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4737  ORDER BY NoBloque)
 ,TccRecvsSusDefOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4739  ORDER BY NoBloque)
 ,NoTocaIncRevOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4751  ORDER BY NoBloque)
 ,FechaEjecRevvsSusPOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4752  ORDER BY NoBloque)
 ,SentidoRevvsSusPOrg =  (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4753
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))

 ,FechaCelAudIncSusOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10412  ORDER BY NoBloque)
 ,FechaResolIncOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10413  ORDER BY NoBloque)
 ,SentidoResolIncOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10414  ORDER BY NoBloque)
 ,FechaNotIncEDSusAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27098 ORDER BY NoBloque)
 ,FechaVenQvsIncAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27099 ORDER BY NoBloque)
 ,FechaRemQvsIncAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27110 ORDER BY NoBloque)
 ,FechaInterQOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10416  ORDER BY NoBloque)
 ,TccRQOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10417  ORDER BY NoBloque)
 ,NoTocaRQOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10418  ORDER BY NoBloque)
 ,FechaEjecQOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10419  ORDER BY NoBloque)
 ,SentidoQOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 10420  ORDER BY NoBloque)
 ,FechaInterVSOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId =  4756  ORDER BY NoBloque)
 ,FechaAudVSOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4759  ORDER BY NoBloque)
 ,FechaResVSOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4760  ORDER BY NoBloque)
 ,SentidoResVSOrg =  (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4761
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))


 ,FechaNotIncVSAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27101 ORDER BY NoBloque)
 ,FechaReqInnominadoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27112 ORDER BY NoBloque)
 ,FechaVencimientoReqInnominadoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27113 ORDER BY NoBloque)
 ,DescripcionAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27114 ORDER BY NoBloque)
 ,FechaAtencionReqInnominadoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27115 ORDER BY NoBloque)
 ,FechaRemisionArchivoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4774 ORDER BY NoBloque)
 ,FechaRemisionArchivoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27068 ORDER BY NoBloque)
 ,ObservacionesAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27074 ORDER BY NoBloque)
 ,Secretario = [SISE3].[fnObtieneSecretarioDGAJ](ASU.AsuntoNeunIdAJ,5647)             
 ,ASU.IdAsuntoRela  
FROM #Asuntos ASU
 LEFT JOIN  #Personas PE ON ASU.AsuntoNeunIdAJ = PE.AsuntoNeunId
 ORDER BY ASU.FechaRecepcionDGAJ


IF OBJECT_ID('tempdb..#Asuntos') IS NOT NULL 
DROP TABLE #Asuntos 

IF OBJECT_ID('tempdb..#Personas') IS NOT NULL 
DROP TABLE #Personas

IF OBJECT_ID('tempdb..#ValoresAJ') IS NOT NULL 
DROP TABLE #ValoresAJ

IF OBJECT_ID('tempdb..#ValoresOrg') IS NOT NULL 
DROP TABLE #ValoresOrg

  SET NOCOUNT OFF; 
END