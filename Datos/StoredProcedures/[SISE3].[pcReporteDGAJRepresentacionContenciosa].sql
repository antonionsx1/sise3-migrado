USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcReporteDGAJRepresentacionContenciosa]    Script Date: 03/04/2025 04:50:53 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		SBGE
-- Create date: 05/02/2025
-- Description:	Reporte por fecha de recepción de la DGAJ
-- exec [SISE3].[pcReporteDGAJRepresentacionContenciosa] 6036, '2025-01-18', '2025-02-18'
-- Modificación: JSM 18/03/2025 Se renombra columna Estado
-- =============================================
ALTER PROCEDURE [SISE3].[pcReporteDGAJRepresentacionContenciosa]  
	@pi_CatOrganismoId INT,
    @pi_FechaInicial DATE=NULL,
    @pi_FechaFinal DATE=NULL

AS

BEGIN

	BEGIN TRY

	DECLARE @ErrorMessage NVARCHAR(4000)
		   ,@ErrorSeverity INT
		   ,@ErrorState INT
		   			 

	
	DECLARE @FechaIngresoAsuntoDGAJ DATE 

	IF(@pi_FechaInicial IS NULL AND @pi_FechaFinal IS NULL)
	BEGIN
		SELECT @FechaIngresoAsuntoDGAJ = FechaAlta 
		FROM  SISE3.ConfiguracionOrganismo
		WHERE CatOrganismoId = @pi_CatOrganismoId

		SET @FechaIngresoAsuntoDGAJ = ISNULL(@FechaIngresoAsuntoDGAJ,GETDATE())

		SET @pi_FechaInicial = ISNULL(@pi_FechaInicial,@FechaIngresoAsuntoDGAJ)
		SET @pi_FechaFinal = ISNULL(@pi_FechaFinal,GETDATE())

	END
	    
	SELECT DISTINCT
	
	cta.Descripcion as TipoDeAsunto, 
	ced.CatalogoElementoDescripcion AS TipoDeProcedimiento,
	a.AsuntoAlias,a.AsuntoNeunId,
	p.TipoCuaderno
	--[SISE3].[fnObtieneEstadoTerminoPorAsuntoDGAJ](p.AsuntoNeunId,p.TipoCuaderno,p.TipoContenido) AS Estatus
	
	INTO #tmpReporte

	FROM Asuntos a WITH(NOLOCK)
	left join CatOrganismos co WITH(NOLOCK) ON co.CatOrganismoId=a.CatOrganismoId
	left join CatTipoOrganismos cto WITH(NOLOCK) ON cto.CatTipoOrganismoId=co.CatTipoOrganismoId
	left join CatTiposAsunto cta WITH(NOLOCK) ON cta.CatTipoAsuntoId=a.CatTipoAsuntoId
	left join CatalogosElementosDescripcion ced WITH(NOLOCK) ON ced.CatalogoElementoDescripcionID=a.CatTipoProcedimiento
	 join AsuntosDetalleFechas adf WITH(NOLOCK) ON adf.Asuntoneunid=a.AsuntoNeunId	
	left join Promociones p WITH(NOLOCK) ON  p.AsuntoNeunId=a.AsuntoNeunId
	
	WHERE a.CatOrganismoId=@pi_CatOrganismoId 
	AND a.StatusReg=1 
	AND p.StatusReg=1 
	AND adf.StatusReg=1 
	AND adf.TipoAsuntoId=27057 
	AND CONVERT(DATE,adf.ValorCampoAsunto) BETWEEN @pi_FechaInicial AND @pi_FechaFinal
	--AND p.TipoContenido in(6799,6804,6819,6817,6811,6818)
	ORDER BY a.AsuntoNeunId 


	select 
	tmp.TipoDeAsunto, 
	tmp.TipoDeProcedimiento,
	tmp.AsuntoAlias,
	tmp.AsuntoNeunId,
	tmp.TipoCuaderno,
	b.Etapa,
	b.Estado as Estatus
    from #tmpReporte tmp
	CROSS APPLY [SISE3].[fnObtieneEstadoTerminoDGAJ](tmp.AsuntoNeunId,tmp.TipoCuaderno) b

	
	--OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
	--FETCH NEXT IIF(@pi_TamanoPagina=0, 0x7ffffff, @pi_TamanoPagina) ROWS ONLY
	

	END TRY
	BEGIN CATCH
		SELECT
			@ErrorMessage = ERROR_MESSAGE()
		   ,@ErrorSeverity = ERROR_SEVERITY()
		   ,@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
END
