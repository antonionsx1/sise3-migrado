SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE [SISE_NEW]
--GO
--/****** Object:  StoredProcedure [dbo].[uspx_VerCaptura]    Script Date: 22/02/2024 01:04:11 p. m. ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO


-- =======================================================================================================================================
-- Author:		GGHH
-- Create date: 22/02/2024
-- Description:	Obtiene los datos especificos de la captura por Parte
-- Example(S):	SISE3.pcVerCaptura 30315607, 171521933
-- =======================================================================================================================================
CREATE OR ALTER PROCEDURE SISE3.pcVerCaptura
	@AsuntoNeunId BIGINT,
	@PersonaId BIGINT = NULL
AS
BEGIN
	BEGIN TRY
		DECLARE @TipoAsuntoId int;  
		DECLARE @TiposAsuntoAgenda Identificadores;   
		DECLARE @Existe int;  
		DECLARE @pi_PersonaId [PersonasAsuntosSel_type]
		INSERT INTO @pi_PersonaId(PersonaId)
		SELECT PersonaId 
		FROM PersonasAsunto 
		WHERE AsuntoNeunId = @AsuntoNeunId  
		AND PersonaId = CASE WHEN @PersonaId IS NULL THEN PersonaId ELSE @PersonaId END 
		AND StatusReg = 1

		SET @TipoAsuntoId =(SELECT CatTipoAsuntoId FROM Asuntos WITH(NOLOCK) WHERE AsuntoNeunId = @AsuntoNeunId); 

		INSERT INTO  @TiposAsuntoAgenda  
		 SELECT distinct TipoAsuntoId from MapeoTiposAsunto WHERE CatTipoAsuntoId=@TipoAsuntoId  
		 SELECT * INTO #tmpConsulta 
		 FROM
			(/*OPCIONES*/
			SELECT DISTINCT   
				adf.TipoAsuntoId  
				,Valor = CONVERT(VARCHAR(10),adf.OpcionCampoAsunto)
				,adf.NoBloque     
				,0 as PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion
				,c.Orden
				,c.PadreOrden
				,NombreParte = ''
			FROM AsuntosDetalleOpciones adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)  
			UNION        
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				,Valor = CONVERT(VARCHAR(10),adf.OpcionCampoAsunto) 
				,adf.NoBloque   
				,padf.PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion 
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntoNeunId,padf.PersonaId)
			FROM AsuntosDetalleOpciones adf WITH(NOLOCK)  
			INNER JOIN PersonasAsuntosDetalleOpciones padf WITH(NOLOCK)  ON padf.AsuntoNeunId = adf.AsuntoNeunId  
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleOpcionesId = adf.AsuntoDetalleOpcionesId  
				AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (SELECT * FROM @pi_PersonaId)  
			AND adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)
			UNION
			/* CATALOGOS */
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				,Valor = dbo.fnx_getDescripcionCatalogo(adf.CatTipoCatalogoAsuntoId , adf.CatCatalogoAsuntoId )
				,adf.NoBloque   
				,0 as PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion 
				,c.Orden
				,c.PadreOrden
				,NombreParte = ''
			FROM AsuntosDetalleCatalogos adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntosNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId in (SELECT TipoAsuntoId FROM CamposPropiedades WHERE TipoPropiedadid = 2
									 UNION
									 SELECT distinct TipoAsuntoId from MapeoTiposAsunto WHERE CatTipoAsuntoId=@tipoAsuntoId)  
			UNION  
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				,Valor = dbo.fnx_getDescripcionCatalogo(adf.CatTipoCatalogoAsuntoId , adf.CatCatalogoAsuntoId )
				,adf.NoBloque   
				,padf.PersonaId   
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion 
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntosNeunId,padf.PersonaId)
			FROM AsuntosDetalleCatalogos adf WITH(NOLOCK)  
			INNER JOIN PersonasAsuntosDetalleCatalogos padf WITH(NOLOCK) ON padf.AsuntoNeunId = adf.AsuntosNeunId  
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleCatalogosId = adf.AsuntoDetalleCatalogosId  
				AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntosNeunId = @AsuntoNeunId    
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (select * from @pi_PersonaId)  
			AND	adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2  
										 UNION
										 SELECT distinct TipoAsuntoId from MapeoTiposAsunto WHERE CatTipoAsuntoId=@tipoAsuntoId)  

			UNION
			/* FECHAS */
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				,Valor = CONVERT (VARCHAR(10),adf.ValorCampoAsunto,103) 
				,adf.NoBloque   
				,0 as PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion
				,c.Orden
				,c.PadreOrden 
				,NombreParte = ''
			FROM AsuntosDetalleFechas adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId     
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId IN (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2  
									 UNION
									 SELECT id FROM @TiposAsuntoAgenda)  
			AND adf.ValorCampoAsunto > '1899-12-30 00:00:00.000'  
			UNION  
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				,Valor = CONVERT (VARCHAR(10),adf.ValorCampoAsunto,103) 
				,adf.NoBloque   
				,padf.PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion  
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntoNeunId,padf.PersonaId)
			FROM AsuntosDetalleFechas adf WITH(NOLOCK)  
			INNER JOIN PersonasAsuntosDetalleFechas padf WITH(NOLOCK) ON padf.AsuntoNeunId = adf.AsuntoNeunId 
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleFechasId = adf.AsuntoDetalleFechasId  
				AND padf.StatusReg = 1
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId  
			WHERE adf.AsuntoNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (select * from @pi_PersonaId)  
			AND adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2  
										 UNION  
										SELECT id FROM @TiposAsuntoAgenda)  
			AND adf.ValorCampoAsunto > '1899-12-30 00:00:00.000'  
			UNION
			/* NUMERO */
			SELECT DISTINCT   
				adf.TipoAsuntoId  
				,Valor = CONVERT(VARCHAR(15),adf.NumeroCampoAsunto)
				,adf.NoBloque   
				,0 as PersonaId 
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion   
				,c.Orden
				,c.PadreOrden
				,NombreParte = ''
			FROM AsuntosDetalleNumeros adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId  
			WHERE adf.AsuntosNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)  
			UNION 
			SELECT DISTINCT   
				adf.TipoAsuntoId  
				,Valor = CONVERT(VARCHAR(15),adf.NumeroCampoAsunto) 
				,adf.NoBloque   
				,padf.PersonaId   
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion  
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntosNeunId,padf.PersonaId)
			FROM AsuntosDetalleNumeros adf WITH(NOLOCK)  
			INNER JOIN PersonasAsuntosDetalleNumeros padf WITH(NOLOCK)  
			ON padf.AsuntoNeunId = adf.AsuntosNeunId  
			AND padf.AsuntoID = adf.AsuntoId  
			AND padf.AsuntoDetalleNumerosId = adf.AsuntoDetalleNumerosId  
			AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId  
			WHERE adf.AsuntosNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (select * from @pi_PersonaId)  
			AND adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)  
			UNION
			/* DESCRIPCION */
			SELECT DISTINCT   
				adf.TipoAsuntoId  
				,adf.Contenido  
				,adf.NoBloque 
				,0 as PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion 
				,c.Orden
				,c.PadreOrden
				,NombreParte = ''
			FROM AsuntosDetalleDescripcion adf WITH(NOLOCK) 
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId 
			WHERE adf.AsuntoNeunId = @AsuntoNeunId  
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)  
			UNION  
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				,adf.Contenido  
				,adf.NoBloque   
				,padf.PersonaId   
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion 
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntoNeunId,padf.PersonaId)
			FROM AsuntosDetalleDescripcion adf WITH(NOLOCK)  
			INNER JOIN PersonasAsuntoDetalleDescripcion padf WITH(NOLOCK)  
			ON padf.AsuntoNeunId = adf.AsuntoNeunId  
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleDescripcionId = adf.AsuntoDetalleDescripcionId  
				AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (select * from @pi_PersonaId)  
			AND adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2) 
		)tbx 
		
		
		SELECT * FROM #tmpConsulta
		UNION 
		SELECT	0 
				,'No tiene captura'
				,0
				,t.PersonaId   
				,0
				,''
				,0
				,''
				,0
				,1
				,NombreParte = dbo.fnx_getPersonaNombre(@AsuntoNeunId,t.PersonaId)
		FROM @pi_PersonaId t
		WHERE t.PersonaId NOT IN (SELECT tmp.PersonaId FROM #tmpConsulta tmp)

		IF OBJECT_ID('tempdb..#tmpConsulta') IS NOT NULL
			DROP TABLE #tmpConsulta
	END TRY
	BEGIN CATCH 
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION; 
		EXECUTE usp_GetErrorInfo; 
		 
	END CATCH
END

