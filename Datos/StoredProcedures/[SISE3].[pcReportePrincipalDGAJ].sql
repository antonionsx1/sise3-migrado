USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcReportePrincipalDGAJ]    Script Date: 29/04/2025 02:07:05 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================          
-- Author:  JSM        
-- Create date: 03/03/2025         
-- Description: DGAJ Libro Control principal  
-- Modificción: 29042025 JSM Se comenta tipo de contenido en Promociones
-- Modificción: 30042025 JRE Se coloca correctamente la condicion de filtrado de fechas
-- Modificación: 30052025 JRE Se retorna nombre de quejoso referente a la tarea 23127
-- Modificación: 05062025 JRE Se regresa la propiedad idAsuntoRela referente a la tarea 23728
-- =============================================          
          
ALTER   PROCEDURE [SISE3].[pcReportePrincipalDGAJ] 

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
                        WHERE p.asuntoneunid =  A.AsuntoNeunId AND p.TipoCuaderno = 5645 
                        AND p.StatusReg = 1 --AND p.TipoContenido IN (6799,6819,6811)
                        )

            CREATE INDEX MiIndex#Asuntos ON #Asuntos (AsuntoNeunIdAJ,AsuntoAliasAJ);
			/*******************************************************************************************/
--SE INSERTA UNIVERSO DE PERSONAS POR ÓRGANO Y PERIODO
			/*******************************************************************************************/
            
			WITH CTE AS (
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
            adde.TipoAsuntoId in (27102,27076,27107,27074)
            and adde.StatusReg = 1

            Insert into #ValoresAJ(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            Select distinct a.AsuntoNeunIdAJ, adf.TipoAsuntoId, convert(varchar(10),adf.ValorCampoAsunto,103) as ValorCampoAsunto, ADF.NoBloque, adf.AsuntoDetalleFechasId
            From #Asuntos a             
            Inner Join AsuntosDetalleFechas adf with(nolock) on A.AsuntoNeunIdAJ = adf.AsuntoNeunId 
            Where                                    
            adf.TipoAsuntoId in (27079,27080,27082,27083,27103,27086,27105,27106,27108,27068)                                                                        
            And adf.StatusReg = 1
				
                        
			CREATE INDEX MiIndex#ValoresAJ ON #ValoresAJ (AsuntoNeunId,TipoAsuntoId)
			/*******************************************************************************************/	
            
			/*******************************************************************************************/	
            Insert into #ValoresOrg(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            Select distinct a.AsuntoNeunIdOrg, adf.TipoAsuntoId, convert(varchar(10),adf.ValorCampoAsunto,103) as ValorCampoAsunto, ADF.NoBloque, adf.AsuntoDetalleFechasId
            From #Asuntos a             
            Inner Join AsuntosDetalleFechas adf with(nolock) on A.AsuntoNeunIdOrg = adf.AsuntoNeunId 
            Where                                    
            adf.TipoAsuntoId in (4444,4456,4461,4407,8907,4562,4565,4570,15431,15433,15435,4587,4618,4623,4630,4646
			                    ,4676,4680,4679,4673,4774)                                                                        
            And adf.StatusReg = 1

            Insert into #ValoresOrg (AsuntoNeunId, TipoAsuntoId,CatTipoCatalogoAsuntoId,CatCatalogoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            select distinct a.AsuntoNeunIdOrg, adc.TipoAsuntoId, adc.CatTipoCatalogoAsuntoId, adc.CatCatalogoAsuntoId,
            ced.CatalogoElementoDescripcion, adc.NoBloque , adc.AsuntoDetalleCatalogosId
            from #Asuntos a 
            inner join AsuntosDetalleCatalogos adc with(nolock) on a.AsuntoNeunIdOrg = adc.AsuntosNeunId
            inner join CatalogosElementosDescripcion ced with(nolock) on adc.CatCatalogoAsuntoId = ced.CatalogoElementoDescripcionID
            where 
            adc.StatusReg = 1 
            and adc.TipoAsuntoId in (4445,4457,4462,4639,4626,4631,4681)
            and adc.CatTipoCatalogoAsuntoId <> 389

            Insert into #ValoresOrg (AsuntoNeunId, TipoAsuntoId,CatTipoCatalogoAsuntoId,CatCatalogoAsuntoId, Valor, NoBloque)
            select distinct a.AsuntoNeunIdOrg, adc.TipoAsuntoId, adc.CatTipoCatalogoAsuntoId, adc.CatCatalogoAsuntoId,
            co.NombreOficial, adc.NoBloque 
            from #Asuntos a 
            inner join AsuntosDetalleCatalogos adc  with(nolock) on a.AsuntoNeunIdOrg = adc.AsuntosNeunId
            inner join CatOrganismos co on co.CatOrganismoId =  adc.CatCatalogoAsuntoId
            where 
            adc.StatusReg = 1 
            and adc.TipoAsuntoId in (4459,4629,4677)
            and adc.CatTipoCatalogoAsuntoId = 389


            Insert into #ValoresOrg(AsuntoNeunId, TipoAsuntoId, Valor, NoBloque,AsuntoDetalleId)
            SELECT DISTINCT a.AsuntoNeunIdOrg, adde.TipoAsuntoId, adde.Contenido, adde.NoBloque,adde.AsuntoDetalleDescripcionId
            FROM #Asuntos a 
            INNER JOIN AsuntosDetalleDescripcion adde  with(nolock) on a.AsuntoNeunIdOrg = adde.AsuntoNeunId
            where
            adde.TipoAsuntoId in (4460,4408,4619,4678)
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
 ,FechaAdmisionJdoOrg =  CASE WHEN PATINDEX('%Admisi_n%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4445																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4444 ORDER BY NoBloque)
                     End  
 --RQvsResInic
 ,FechaInterposicionRecursoOrg =  CASE WHEN PATINDEX('%Queja%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4457																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4456 ORDER BY NoBloque)
                     End 
 ,TccReqOrg =  CASE WHEN PATINDEX('%Queja%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4457																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4459 ORDER BY NoBloque)
                     End 
 ,NoTocaOrg =  CASE WHEN PATINDEX('%Queja%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4457																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4460  ORDER BY NoBloque)
                     End 
 ,FechaResolucionOrg =  CASE WHEN PATINDEX('%Queja%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4457																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4461
																	ORDER BY cat.NoBloque
																	FOR XML PATH('')),1,1, ''))
                     End 
 ,SentidoResolucionOrg =  CASE WHEN PATINDEX('%Queja%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4457																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4462	
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))
                     End 
--finRQvsResInic 
,FenchaVencimientoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27079 ORDER BY NoBloque)
,FenchaRemisionAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27080 ORDER BY NoBloque)
--ResolucionFueraDeAudiencia
,FenchaEgresoAcuerdOrgo = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4407 ORDER BY NoBloque)
,FechaResIniOrg =  CASE WHEN (ISNULL((SELECT COUNT(*) FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4445 AND CatCatalogoAsuntoId IN (1236,2509,2496,1715,1775,84,4192,12510)),0))=0
					 Then ''
					 Else (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4444  ORDER BY NoBloque)
                     End 
,FenchaSobreseimientoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 8907 ORDER BY NoBloque)
--FinResolucionFueraDeAudiencia
--SentifoFueraDeAudiencia
,NoAcuerdoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4408 ORDER BY NoBloque)
,SentidoResIniOrg = (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4445	
																	And cat.CatCatalogoAsuntoId IN (1236,2509,2496,1715,1775,84,4192,12510)
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))
,FechaSobreseimientoDescOrg =  CASE WHEN (ISNULL((SELECT COUNT(*) FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 8907),0))=0
					        Then ''
					        Else 'Sobreseimiento fuera de audiencia'
                            End 
--FinSentifoFueraDeAudiencia
--AudienciaConstitucional
,FenchaAudConstOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4562 ORDER BY NoBloque)
,FenchaAudConstDiferimientoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4565 ORDER BY NoBloque)
,FenchaCelebraAudConstOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4570 ORDER BY NoBloque)
,FenchaAudConstSusOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 15431 ORDER BY NoBloque)
,FenchaAudConstSinEfectosOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 15433 ORDER BY NoBloque)
,FenchaAudConstCanceladaOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 15435 ORDER BY NoBloque)
--FinAudienciaConstitucional
--FechaSentidoSentencia
,FenchaSentenciaOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4587 ORDER BY NoBloque)
,SentidoSentenciaOrg = (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4639	
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))
--FinFechaSentidoSentencia
 ,FechaNotSentenciaAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27082 ORDER BY NoBloque)
 ,FechaVencimientoRecRevAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27083 ORDER BY NoBloque)
 ,FechaRemisionRecRevAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27103 ORDER BY NoBloque)
 ,InterRecRevOrg =  CASE WHEN PATINDEX('%Revisi_n%', (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4626																		
																	FOR XML PATH('')),1,1, ''))
																	)=0
					 Then ''
					 Else (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId =  ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4618  ORDER BY NoBloque)
                     End
 ,TccRecSenOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4629 ORDER BY NoBloque)
 ,NoExpAROrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4619 ORDER BY NoBloque)
 ,FechaEjecAROrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4630 ORDER BY NoBloque)
 ,SentidoEjecutoriaOrg = (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4631	
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))  
 
 ,FechaEjecEdoProcesalOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4623 ORDER BY NoBloque)
 ,FechaReqCumplimientoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4646 ORDER BY NoBloque)
 ,FechaVencimientoRQvsRqCumplimientoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27083 ORDER BY NoBloque)
 ,FechaRQvsRqCumplimientoAJ = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27086 ORDER BY NoBloque)
 ,FechaRemiImcTccOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4676 ORDER BY NoBloque)
 ,TccIncidenteOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4677 ORDER BY NoBloque)
 ,NoExpIncidenteOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4678 ORDER BY NoBloque)
 ,FechaInterIncvsdecCumplimientoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4679 ORDER BY NoBloque)
 ,FechaEjecIncofOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4680 ORDER BY NoBloque)
 ,SentidoEjecIncofOrg = (SELECT STUFF((SELECT TOP 10 ', '+ cat.valor
																	from  #ValoresOrg cat 
																	where cat.AsuntoNeunId = ASU.AsuntoNeunIdOrg
																	And cat.TipoAsuntoId = 4681	
																	ORDER BY cat.NoBloque,cat.AsuntoDetalleId
																	FOR XML PATH('')),1,1, ''))             

 ,FechaAutoCumplimientoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4673 ORDER BY NoBloque)
 ,FechaReqInnominadoAj = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27105 ORDER BY NoBloque)
 ,FechaVenReqInnominadoAj = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27106 ORDER BY NoBloque)
 ,DescripcionAj = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27107 ORDER BY NoBloque)
 ,FechaAtencionReqInnominadoAj = (SELECT TOP 1 Valor FROM #ValoresAJ WHERE AsuntoNeunId = ASU.AsuntoNeunIdAJ AND TipoAsuntoId = 27108 ORDER BY NoBloque)
 ,FechaRemisionArchivoOrg = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 4774 ORDER BY NoBloque)
 ,FechaRemisionArchivoAJ = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 27068 ORDER BY NoBloque)
 ,ObservacionesAJ = (SELECT TOP 1 Valor FROM #ValoresOrg WHERE AsuntoNeunId = ASU.AsuntoNeunIdOrg AND TipoAsuntoId = 27074 ORDER BY NoBloque)
 ,Secretario = [SISE3].[fnObtieneSecretarioDGAJ](ASU.AsuntoNeunIdAJ,5645)             
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
