USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcConsultaOtrasPartesAsunto]    Script Date: 11/06/2025 04:05:41 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:      Oliver A. Martinez Estudillo
-- Create date: 02/06/2025
-- Description: Consulta otras partes y su tipo de notificación
-- EXEC [SISE3].[pcConsultaOtrasPartesAsunto] 36069822, null
-- EXEC [SISE3].[pcConsultaOtrasPartesAsunto] NULL, 1
-- =============================================
CREATE PROCEDURE [SISE3].[pcConsultaOtrasPartesAsunto]
    @pi_AsuntoNeunId BIGINT = NULL,
	@pi_PersonaId BIGINT = NULL      
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
		OPA.iPersonaId,
        OPA.AsuntoId,
        OPA.AsuntoNeunId,
        OPA.sNombre,
        OPA.sAPaterno,
        OPA.sAMaterno,
        OPA.CatTipoPersonaId,
        OPA.iSexo,
        OPA.iMayorEdad,
        OPA.CatTipoPersonaJuridicaId,
        OPA.sDenominacionDeAutoridad,
        OPA.ClasificaAutoridadGenericaId,
        OPA.iSujetoDerechoAgrario,
        OPA.iAceptaOponePublicarDatos,
        fFechaAceptaOponePublicarDatos = CONVERT(VARCHAR(10),OPA.fFechaAceptaOponePublicarDatos,103),
        OPA.fFechaAlta,
        OPA.fFechaBaja,
        OPA.StatusReg,
        OPA.iForaneo,
        OPA.iCatAutoridadId,
        OPA.iUsuarioCaptura,
        OPA.iEsParteGrupoVulnerable,
        OPA.iGrupoVulnerable,
        OPA.iEdadMenor,
        OPA.iHablaLengua,
        OPA.iLengua,
        OPA.iTraductor,
        OAA.iTipoNotificacionId,
		CONCAT(SISE3.ConcatenarNombres(sNombre, sAPaterno, sAMaterno), ' - OTRA PARTE') AS PersonaTipo,
		ISNULL(ctp.Descripcion,'') AS CatTipoPersonaIdDesc,
		CN.sDescripcionCorta AS TipoNotificacion,
		ISNULL(cag.Descripcion,'') as ClasificaAutoridadGenericaIdDesc,
		ISNULL(vc2.DESCRIPCION,'') as GrupoVulnerableDesc,
		ISNULL(vc4.DESCRIPCION,'') as EdadMenorDesc,
		ISNULL(vc3.DESCRIPCION,'') as LenguaDesc
    FROM [SISE3].[OtrasPartesAsunto] OPA
	INNER JOIN dbo.CatTiposPersona CTP WITH(NOLOCK) ON OPA.CatTipoPersonaId = CTP.CatTipoPersonaId
    LEFT JOIN [SISE3].[OtrasPartesAsunto_Adicional] OAA
        ON OPA.iPersonaId = OAA.iPersonaId
	LEFT JOIN [dbo].[CatNotificaciones]	CN ON CN.kIdCatNotificaciones = OAA.iTipoNotificacionId
	LEFT JOIN dbo.CatClasificaAutoridadGenerica cag WITH(NOLOCK) ON cag.ClasificaAutoridadGenericaId = OPA.ClasificaAutoridadGenericaId
	LEFT JOIN dbo.viCatalogos AS vc2 ON OPA.iGrupoVulnerable = vc2.ID AND vc2.Catalogo = 832 AND vc2.CatalogoPadre > 0 
	LEFT JOIN dbo.viCatalogos AS vc3 ON OPA.iLengua = vc3.ID AND vc3.Catalogo = 2156 AND vc3.CatalogoPadre > 0 
	LEFT JOIN dbo.viCatalogos AS vc4 ON OPA.iEdadMenor = vc4.ID AND vc4.Catalogo = 1497 AND vc4.CatalogoPadre > 0 
     WHERE 
    (
        (@pi_AsuntoNeunId IS NOT NULL AND OPA.AsuntoNeunId = @pi_AsuntoNeunId)
        OR
        (@pi_AsuntoNeunId IS NULL AND @pi_PersonaId IS NOT NULL AND OPA.iPersonaId = @pi_PersonaId)
    )
    AND OPA.StatusReg = 1
END
GO


