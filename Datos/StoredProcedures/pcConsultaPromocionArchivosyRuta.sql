-- =============================================
-- Author:		Christian Araujo - MS
-- Alter date: 02/11/09
-- Objetivo: Carga el detalle de una promoción electrónica seleccionada en el detalle de promoción
-- EXEC SISE3.pcConsultaPromocionArchivosyRuta 30301133, 1,2023,4
-- =============================================
ALTER PROCEDURE [SISE3].[pcConsultaPromocionArchivosyRuta]
(
@pi_AsuntoNeunId [bigint] ,
@pi_AsuntoID [int], 
@pi_YearPromocion [int], 
--@pi_NumeroOrden [int], 
@pi_catIdOrganismo [int]
--@pi_NumeroRegistro [int]
)

AS
BEGIN
		SET NOCOUNT ON
	
		SELECT [Promociones].[CatOrganismoId]
				  ,[Promociones].[YearPromocion]
				  ,[Promociones].[NumeroOrden]
				  ,[Promociones].[AsuntoNeunId]
				  ,[Promociones].[AsuntoId]
				  ,AsuntoAlias= (Select AsuntoAlias from Asuntos with(nolock) where AsuntoId=@pi_AsuntoID and AsuntoNeunId=@pi_AsuntoNeunId and CatOrganismoId=@pi_catIdOrganismo)
				  ,[Promociones].[SintesisOrden]
				  ,[Promociones].[UsuidFESE]
				  ,[Promociones].[OrigenPromocion]
				  ,[Promociones].[TipoCuaderno]				  
				  ,dbo.funRecuperaCatalogoDependienteDescripcion(495,TipoCuaderno) as NombreTipoCuaderno
				  ,[Promociones].[NumeroRegistro]
				  ,[Promociones].[FechaPresentacion]		
				 ,Convert(Char(5), [Promociones].[HoraPresentacion], 108) as HoraPresentacion
				  ,[Promociones].[ClasePromocion]
				  ,NombreClase = CASE ClasePromocion WHEN  '1' THEN 'Escrito' ELSE 'Oficio' END				  
				  ,[Promociones].[ClasePromovente]
				  ,[Promociones].[TipoPromovente]
				  ,dbo.funNombreParte(TipoPromovente,isnull(ClasePromovente,1)) as nombreParte
				  ,[Promociones].[TipoContenido]
				  ,[Promociones].[Contenido]
				  ,isnull([Promociones].NumeroCopias,0) as NumeroCopias
				  ,isnull([Promociones].NumeroAnexos,0) as NumeroAnexos				 
				  ,[Promociones].[FechaEntrega]
				  ,[Promociones].[PersonaRecibe]
				  ,[Promociones].[Secretario]
				  ,[Promociones].[FechaAlta]
				  ,[Promociones].[RegistroEmpleadoId]
				  ,[Promociones].[StatusReg]
				  ,[Promociones].[FechaAcuerdo]
				  ,[Promociones].[PromocionVisible]
				  ,[Promociones].[PromocionAutorizaVisible]				
				  ,isnull([Promociones].EstadoPromocion,0) as EstadoPromocion					  
				 ,Pa.ObservacionesArchivo
				  ,CONVERT(varchar,Pa.FechaAlta,103) as FechaRecepcionDocumento 
				  ,CONVERT(varchar,Pa.FechaAlta,108) as HoraRecepcionDocumento
				  ,Pa.ClaseAnexo
				  ,Pa.DescripcionAnexo
				  ,Pa.CaracterAnexo
				  ,isnull(Pa.Consecutivo,0) as Consecutivo				  
				  ,isnull(Pa.EstatusArchivo,0) as EstatusArchivo
				  ,isnull([Promociones].NumeroTomos,0) as NumeroTomos
				  ,isnull([Promociones].NumeroFojasTomos,0) as NumeroFojasTomos
				  ,[Promociones].Observaciones
				  ,isnull([Promociones].audiencia,0)as audiencia
				  ,AmbosCuadernos=CASE [Promociones].[TipoCuaderno]	 WHEN  '13918' THEN 1 ELSE 0 END --SBGE 02/10/2015 Se recupera el cuaderno para saber si es AmbosCuadernos de Amparo Indirecto
				  ,Mesa
			   ,ArchivoInmodificable=
					CASE (select count(1) from MOV_ExpElectronicoCatalogos where asuntoneunid=[Promociones].[AsuntoNeunId] and sintesisorden=isnull([Promociones].[SintesisOrden],0) and kidCamposexpElectronico=4 and bestatus=1)-- 4 es ArchivoInmodificable
					WHEN  0 THEN 0 else 1 end
				, EsPromocion = CASE pa.ClaseAnexo when NULL THEN 1 WHEN 0 THEN 1 ELSE 0 END
				,rc.sRuta
				, Pa.NombreArchivo
				, CONCAT(rc.sRuta,'\',Pa.NombreArchivo) AS RutaCompleta
			  FROM [dbo].[Promociones] WITH(NOLOCK) 
			  LEFT JOIN PromocionArchivos Pa WITH(NOLOCK) on Pa.AsuntoId=Promociones.AsuntoId and Pa.AsuntoNeunId=Promociones.AsuntoNeunId and Pa.NumeroOrden=Promociones.NumeroOrden and Pa.NumeroRegistro=Promociones.NumeroRegistro
			  and Pa.YearPromocion=Promociones.YearPromocion and Pa.StatusArchivo=1 and Pa.DescripcionAnexo=5031
			  JOIN CAT_RutasChunk rc ON rc.iGrupo = 2 and rc.iEscritura = 1 
			  WHERE [Promociones].AsuntoNeunId=@pi_AsuntoNeunId 
			  and [Promociones].AsuntoID=@pi_AsuntoID 
			  and [Promociones].YearPromocion=@pi_YearPromocion --and [Promociones].NumeroOrden=@pi_NumeroOrden 
			  and Pa.NombreArchivo IS NOT NULL
			  --and [Promociones].NumeroRegistro=@pi_NumeroRegistro 			  
			  and [Promociones].CatOrganismoId=@pi_catIdOrganismo and [Promociones].StatusReg in (1,2)
			  
			
	
		SET NOCOUNT OFF
	END
