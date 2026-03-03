USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcVerCapturaGeneral]    Script Date: 22/05/2025 12:24:43 p. m. ******/
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
-- Example(S):	SISE3.pcVerCapturaGeneral 30328556, 171521933
-- Modificación: JSM 03/07/2024 Se crea versión que devuelve captura general para todas las partes solo por neun
-- Modificación: SBGE 04/10/2024 Se recupera el cuaderno y se regresa en el campo Valor del registro que trae el AsuntoId, para el caso
--				 de Amparo Indirecto solo se regresa Principal y en el Front según lo que selecciona (Principal/Incidenta) es lo que se muestra
-- Modificación: SBGE 01/03/2025 se utiliza los campos PadreDescripcion y NombreParte para recuperar el asuntoalias y nombre de organo origen de un expediente de DGAJ
--				 Además, se regresa el asuntoNeunidOrigen en un campo nuevo ya que los demas que se reciben son int y se requiere que el campo sea bigint, todo esto para no regresar varias columnas en null
-- exec [SISE3].[pcVerCapturaGeneral] 36072277
-- =======================================================================================================================================
ALTER   PROCEDURE [SISE3].[pcVerCapturaGeneral]
	@AsuntoNeunId BIGINT
AS
BEGIN
	BEGIN TRY
	DECLARE @Cuaderno VARCHAR(300)
	SET @Cuaderno=(select  dbo.fn_ObtieneDescripcionCuadernoOficialiaSel(@AsuntoNeunId) )

	--OBTENEMOS INFORMACION ASUNTO ORIGEN
	DECLARE @AsuntoNeunIdOrigen BIGINT=0
	DECLARE @AsuntoAliasOrigen VARCHAR(50)=''
	DECLARE @NombreOrganoOrigen VARCHAR(400)=''
	DECLARE @CatTipoAsuntoIdDGAJ INT
	DECLARE @NombreTipoAsuntOrigen VARCHAR(100)=''
	DECLARE @CatTipoProcedimientoId INT
	DECLARE @CatTipoProcedimiento VARCHAR(100)=''
	
	SELECT @CatTipoAsuntoIdDGAJ=CatTipoAsuntoId,
		   @CatTipoProcedimientoId  = CatTipoProcedimiento	
	FROM Asuntos WHERE AsuntoNeunId=@AsuntoNeunId 

	IF(@CatTipoProcedimientoId > 0)
	BEGIN 
		SELECT @CatTipoProcedimiento = CatalogoElementoDescripcion FROM CatalogosElementosDescripcion WHERE CatalogoElementoDescripcionID = @CatTipoProcedimientoId
	END 

	IF @CatTipoAsuntoIdDGAJ=141--Representación Contenciosa
	BEGIN
		SELECT @AsuntoNeunIdOrigen=ar.AsuntoNeunIdOrg,
		@AsuntoAliasOrigen=ao.AsuntoAlias,
		@NombreOrganoOrigen=co.NombreOficial,
		@NombreTipoAsuntOrigen=cta.descripcion
		FROM AsuntosRelacionados ar WITH(NOLOCK)
		LEFT JOIN Asuntos ao WITH(NOLOCK) ON ao.AsuntoNeunId=ar.AsuntoNeunIdOrg 
		LEFT JOIN CatOrganismos co WITH(NOLOCK) ON co.CatOrganismoId=ao.CatOrganismoId
		LEFT JOIN CatTiposAsunto cta WITH(NOLOCK) ON cta.CatTipoAsuntoId=ao.CatTipoAsuntoId
		WHERE ar.AsuntoNeunIdDest=@AsuntoNeunId AND ar.Status=1
	END




IF ((SELECT A.CatTipoAsuntoId FROM Asuntos A WITH(NOLOCK) WHERE A.AsuntoNeunId =@AsuntoNeunId) <> 2)
BEGIN
	DECLARE @AsuntoId INT,
			@CatTipoAsuntoId INT

	SELECT @AsuntoId = AsuntoId,
			@CatTipoAsuntoId = CatTipoAsuntoId
	FROM Asuntos WITH(NOLOCK) 
	WHERE AsuntoNeunId = @AsuntoNeunId
--/////////////////////// TABLAS TEMPORALES
SELECT * 
INTO #TMPADO
FROM AsuntosDetalleOpciones WITH(NOLOCK)
WHERE AsuntoNeunId = @AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPPADO
FROM PersonasAsuntosDetalleOpciones WITH(NOLOCK)
WHERE AsuntoNeunId = @AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPADC
FROM AsuntosDetalleCatalogos WITH(NOLOCK)
WHERE AsuntosNeunId =@AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPPADC
FROM PersonasAsuntosDetalleCatalogos  WITH(NOLOCK)
WHERE AsuntoNeunId =@AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPADF
FROM AsuntosDetalleFechas  WITH(NOLOCK)
WHERE AsuntoNeunId= @AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPPADF
FROM PersonasAsuntosDetalleFechas  WITH(NOLOCK)
WHERE AsuntoNeunId=@AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPADD
FROM AsuntosDetalleDescripcion  WITH(NOLOCK)
WHERE AsuntoNeunId=@AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPPADD
FROM PersonasAsuntoDetalleDescripcion  WITH(NOLOCK)
WHERE AsuntoNeunId=@AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPADN
FROM AsuntosDetalleNumeros  WITH(NOLOCK)
WHERE AsuntosNeunId=@AsuntoNeunId AND StatusReg=1

SELECT * 
INTO #TMPPADN
FROM PersonasAsuntosDetalleNumeros  WITH(NOLOCK)
WHERE AsuntoNeunId=@AsuntoNeunId AND StatusReg=1

--///////////////////////
        DECLARE @TipoAsuntoId int;  
		DECLARE @TiposAsuntoAgenda Identificadores;   
		DECLARE @Existe int;  
		DECLARE @TotalPersonas int;
		DECLARE @pi_PersonaId [PersonasAsuntosSel_type]
		INSERT INTO @pi_PersonaId(PersonaId)
		SELECT PersonaId 
		FROM PersonasAsunto WITH(NOLOCK)
		WHERE AsuntoNeunId = @AsuntoNeunId  
		--AND PersonaId = CASE WHEN @PersonaId IS NULL THEN PersonaId ELSE @PersonaId END 
		AND StatusReg = 1

		SET @TipoAsuntoId =(SELECT CatTipoAsuntoId FROM Asuntos WITH(NOLOCK) WHERE AsuntoNeunId = @AsuntoNeunId); 
		 
		INSERT INTO  @TiposAsuntoAgenda  
		 SELECT distinct TipoAsuntoId from MapeoTiposAsunto WITH(NOLOCK) WHERE CatTipoAsuntoId=@TipoAsuntoId  
		 SELECT *,@AsuntoId AsuntoId INTO #tmpConsulta 
		 FROM
			(/*OPCIONES*/
			SELECT DISTINCT   
				adf.TipoAsuntoId  
				--,Valor = CONVERT(VARCHAR(10),adf.OpcionCampoAsunto)
				,IIF(OpcionCampoAsunto = 1,'Si','No') as Valor
				,adf.NoBloque     
				,0 as PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion
				,c.Orden
				,c.PadreOrden
				,NombreParte = ''
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId) 
				,0 as AsuntoNeunIdOrigen
			FROM #TMPADO adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)  
			UNION        
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				--,Valor = CONVERT(VARCHAR(10),adf.OpcionCampoAsunto) 
				,IIF(OpcionCampoAsunto = 1,'Si','No') as Valor
				,adf.NoBloque   
				,padf.PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion 
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntoNeunId,padf.PersonaId)
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId) 
				,0 as AsuntoNeunIdOrigen
			FROM #TMPADO adf WITH(NOLOCK)  
			INNER JOIN #TMPPADO padf WITH(NOLOCK)  ON padf.AsuntoNeunId = adf.AsuntoNeunId  
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleOpcionesId = adf.AsuntoDetalleOpcionesId  
				AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId
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
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen
			FROM #TMPADC adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntosNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid = 2
									 UNION
									 SELECT distinct TipoAsuntoId from MapeoTiposAsunto WITH(NOLOCK) WHERE CatTipoAsuntoId=@tipoAsuntoId)  
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
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen
			FROM #TMPADC adf WITH(NOLOCK)  
			INNER JOIN #TMPPADC padf WITH(NOLOCK) ON padf.AsuntoNeunId = adf.AsuntosNeunId  
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleCatalogosId = adf.AsuntoDetalleCatalogosId  
				AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntosNeunId = @AsuntoNeunId    
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (select * from @pi_PersonaId)  
			AND	adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2  
										 UNION
										 SELECT distinct TipoAsuntoId from MapeoTiposAsunto WITH(NOLOCK) WHERE CatTipoAsuntoId=@tipoAsuntoId)  

			UNION
			/* FECHAS */
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				--,Valor = CONVERT (VARCHAR(10),adf.ValorCampoAsunto,103) 
				,CASE WHEN C.CampoTipoId = 2 THEN CONVERT (VARCHAR(10),adf.ValorCampoAsunto,103) 
				      WHEN C.CampoTipoId = 9 THEN  CONVERT(VARCHAR, CAST(adf.ValorCampoAsunto AS TIME), 108)
					  ELSE '' END AS Valor
				,adf.NoBloque   
				,0 as PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion
				,c.Orden
				,c.PadreOrden 
				,NombreParte = ''
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen 
			FROM #TMPADF adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId     
			AND adf.StatusReg = 1  
			AND adf.TipoAsuntoId IN (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2  
									 UNION
									 SELECT id FROM @TiposAsuntoAgenda)  
			AND adf.ValorCampoAsunto > '1899-12-30 00:00:00.000'  
			UNION  
			SELECT DISTINCT 
				adf.TipoAsuntoId  
				--,Valor = CONVERT (VARCHAR(10),adf.ValorCampoAsunto,103) 
				,CASE WHEN C.CampoTipoId = 2 THEN CONVERT (VARCHAR(10),adf.ValorCampoAsunto,103) 
				      WHEN C.CampoTipoId = 9 THEN  CONVERT(VARCHAR, CAST(adf.ValorCampoAsunto AS TIME), 108)
					  ELSE '' END AS Valor
				,adf.NoBloque   
				,padf.PersonaId  
				,c.CampoDatosGenerales
				,c.Descripcion
				,c.Padre 
				,c.PadreDescripcion  
				,c.Orden
				,c.PadreOrden
				,NombreParte = dbo.fnx_getPersonaNombre(adf.AsuntoNeunId,padf.PersonaId)
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen 
			FROM #TMPADF adf WITH(NOLOCK)  
			INNER JOIN #TMPPADF padf WITH(NOLOCK) ON padf.AsuntoNeunId = adf.AsuntoNeunId 
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
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen 
			FROM #TMPADN adf WITH(NOLOCK)  
			INNER JOIN uvix_Campos c WITH(NOLOCK)ON adf.TipoAsuntoId = c.TipoAsuntoId  
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
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen 
			FROM #TMPADN adf WITH(NOLOCK)  
			INNER JOIN #TMPPADN padf WITH(NOLOCK)  
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
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen 
			FROM #TMPADD adf WITH(NOLOCK) 
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId 
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
				,sPadre = [SISE3].[fnConcatenaPadresCampo](adf.TipoAsuntoId)
				,0 as AsuntoNeunIdOrigen
			FROM #TMPADD adf WITH(NOLOCK)  
			INNER JOIN #TMPPADD padf WITH(NOLOCK)  
			ON padf.AsuntoNeunId = adf.AsuntoNeunId  
				AND padf.AsuntoID = adf.AsuntoId  
				AND padf.AsuntoDetalleDescripcionId = adf.AsuntoDetalleDescripcionId  
				AND padf.StatusReg = 1 
			INNER JOIN uvix_Campos c WITH(NOLOCK) ON adf.TipoAsuntoId = c.TipoAsuntoId
			WHERE adf.AsuntoNeunId = @AsuntoNeunId   
			AND adf.StatusReg = 1  
			AND padf.PersonaId in (select * from @pi_PersonaId)  
			AND adf.TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2) 
		)tbx 
--------------------------------------------------------------------------------
CREATE TABLE #Datosfinal(
TipoAsuntoId INT NULL,
Valor VARCHAR(MAX) NULL,
NoBloque INT NULL,
PersonaId INT NULL,
CampoDatosGenerales INT NULL,
Descripcion  VARCHAR(MAX) NULL,
Padre  INT NULL,
PadreDescripcion  VARCHAR(MAX) NULL,
Orden  INT NULL,
PadreOrden  INT NULL,
NombreParte   VARCHAR(MAX) NULL,
sPadre VARCHAR(50) NULL,
AsuntoId INT NULL
,AsuntoNeunIdOrigen BIGINT NULL
--,AsuntoAliasOrigen VARCHAR(50) NULL
--,NombreOrganoOrigen VARCHAR(400) NULL
,TipoProcedimiento VARCHAR(100)
)

DECLARE @PersonasTable TABLE(
id smallint identity(1,1) not null,
idParte int not null
)

        INSERT INTO @PersonasTable
        SELECT * FROM @pi_PersonaId

		SET @TotalPersonas = (SELECT COUNT(*) FROM @pi_PersonaId)

		select TipoAsuntoId, COUNT(TipoAsuntoId) as Total
		INTO #TMPTipoAsuntoId
		FROM #tmpConsulta
		where TipoAsuntoId not in (SELECT TipoAsuntoId FROM CamposPropiedades WITH(NOLOCK) WHERE TipoPropiedadid=2)
		GROUP BY TipoAsuntoId
        HAVING COUNT(DISTINCT PersonaId) < @TotalPersonas

IF  not EXISTS (SELECT * FROM #tmpConsulta WHERE PersonaId IN (SELECT PersonaId FROM @pi_PersonaId))
BEGIN
INSERT INTO #Datosfinal (TipoAsuntoId, Valor, NoBloque, PersonaId, CampoDatosGenerales, Descripcion,
Padre, PadreDescripcion, Orden,PadreOrden, NombreParte, sPadre, AsuntoId ,AsuntoNeunIdOrigen ,TipoProcedimiento)
SELECT DISTINCT * FROM (		
		SELECT 
		TipoAsuntoId
		,Valor	
        ,NoBloque	
        ,0 as PersonaId	
        ,CampoDatosGenerales	
        ,Descripcion	
		,Padre	
        ,PadreDescripcion	
        ,Orden	
        ,PadreOrden	
        ,'' as NombreParte
		,sPadre
		,@AsuntoId AsuntoId
		,0 as AsuntoNeunIdOrigen --,'',''
		,'' CatTipoProcedimiento
		FROM #tmpConsulta
		WHERE TipoAsuntoId NOT IN (SELECT DISTINCT TipoAsuntoId FROM #TMPTipoAsuntoId)
		UNION 
		SELECT	0 
				,'No tiene captura'
				,0
				,0 --t.PersonaId   
				,0
				,''
				,0
				,''
				,0
				,1
				,''  --NombreParte = dbo.fnx_getPersonaNombre(@AsuntoNeunId,t.PersonaId)
				,''
				,@AsuntoId
				,0 as AsuntoNeunIdOrigen --,'',''
				,''
		FROM @pi_PersonaId t
		WHERE t.PersonaId NOT IN (SELECT tmp.PersonaId FROM #tmpConsulta tmp)
) AS X
END ELSE
BEGIN
INSERT INTO #Datosfinal (TipoAsuntoId, Valor, NoBloque, PersonaId, CampoDatosGenerales, Descripcion,
Padre, PadreDescripcion, Orden,PadreOrden, NombreParte, sPadre, AsuntoId ,AsuntoNeunIdOrigen ,TipoProcedimiento)
SELECT DISTINCT * FROM (		
		SELECT 
		TipoAsuntoId
		,Valor	
        ,NoBloque	
        ,0 as PersonaId	
        ,CampoDatosGenerales	
        ,Descripcion	
		,Padre	
        ,PadreDescripcion	
        ,Orden	
        ,PadreOrden	
        ,'' as NombreParte
		,sPadre
		,@AsuntoId AsuntoId
		,0 as AsuntoNeunIdOrigen 
		,'' as TipoProcedimiento
		FROM #tmpConsulta
		WHERE TipoAsuntoId NOT IN (SELECT DISTINCT TipoAsuntoId FROM #TMPTipoAsuntoId)
) AS X
END


DECLARE @I INT
SET @I =1
PRINT @I
WHILE (@I <= @TotalPersonas)
BEGIN

--SELECT idParte FROM @PersonasTable where id = @I

        INSERT INTO #Datosfinal (TipoAsuntoId, Valor, NoBloque, PersonaId, CampoDatosGenerales, Descripcion,
		Padre, PadreDescripcion, Orden,PadreOrden, NombreParte, sPadre, AsuntoId ,AsuntoNeunIdOrigen ,TipoProcedimiento)
		SELECT *,'' FROM #tmpConsulta
		WHERE TipoAsuntoId  IN (SELECT DISTINCT TipoAsuntoId FROM #TMPTipoAsuntoId)
		AND PersonaId = (SELECT idParte FROM @PersonasTable where id = @I)

set @I = @I+1
END




INSERT #Datosfinal (TipoAsuntoId, AsuntoId, Valor,AsuntoNeunIdOrigen,PadreDescripcion,NombreParte,sPadre, TipoProcedimiento)
VALUES(@CatTipoAsuntoId, @AsuntoId, @Cuaderno, @AsuntoNeunIdOrigen, @AsuntoAliasOrigen, @NombreOrganoOrigen,@NombreTipoAsuntOrigen, @CatTipoProcedimiento)



select * from #Datosfinal
order by PersonaId, Padre


		IF OBJECT_ID('tempdb..#tmpConsulta') IS NOT NULL
			DROP TABLE #tmpConsulta
        IF OBJECT_ID('tempdb..#TMPTipoAsuntoId') IS NOT NULL
			DROP TABLE #TMPTipoAsuntoId

        IF OBJECT_ID('tempdb..#TMPADO') IS NOT NULL
			DROP TABLE #TMPADO
        IF OBJECT_ID('tempdb..#TMPPADO') IS NOT NULL
			DROP TABLE #TMPPADO

        IF OBJECT_ID('tempdb..#TMPADC') IS NOT NULL
			DROP TABLE #TMPADC
        IF OBJECT_ID('tempdb..#TMPPADC') IS NOT NULL
			DROP TABLE #TMPPADC

        IF OBJECT_ID('tempdb..#TMPADF') IS NOT NULL
			DROP TABLE #TMPADF
        IF OBJECT_ID('tempdb..#TMPPADF') IS NOT NULL
			DROP TABLE #TMPPADF
 
         IF OBJECT_ID('tempdb..#TMPADD') IS NOT NULL
			DROP TABLE #TMPADD
        IF OBJECT_ID('tempdb..#TMPPADD') IS NOT NULL
			DROP TABLE #TMPPADD

         IF OBJECT_ID('tempdb..#TMPADN') IS NOT NULL
			DROP TABLE #TMPADN
        IF OBJECT_ID('tempdb..#TMPPADN') IS NOT NULL
			DROP TABLE #TMPPADN 

         IF OBJECT_ID('tempdb..#Datosfinal') IS NOT NULL
			DROP TABLE #Datosfinal 

 
END ELSE
BEGIN 

exec [SISE3].[pcVerCapturaGeneral_CP] @AsuntoNeunId

END

 


	END TRY
	BEGIN CATCH 
		IF @@TRANCOUNT > 0  
			ROLLBACK TRANSACTION; 
		EXECUTE usp_GetErrorInfo; 
		 
	END CATCH
END

