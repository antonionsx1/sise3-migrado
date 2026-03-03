---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 23/08/2023 
-- Description: Se uliliza para lista las partes cuando en el modulo promociones se selecciona el radio button Partes
-- Basado en: usp_EXPE_PersonasXAsuntoSel
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--execute [SISE3].[pcPersonasXAsunto] 18672587
-- ============================================= 

CREATE PROCEDURE [SISE3].[pcPersonasXAsunto]
@pi_AsuntoNeunId [bigint]
AS

        BEGIN
                SET NOCOUNT ON

                        select  ISNULL(ctp.Descripcion ,'') as DescripcionTipoPersona,
                                        isnull(p.DenominacionDeAutoridad,'') DenominacionDeAutoridad,
                                        isnull(cpa.Descripcion,'') as DescripcionCaracterPersona,
                                        ISNULL(ccag.Descripcion,'') as DescripcionClasificaAutoridadGenerica,
                                        p.PersonaId,
                                        p.Nombre,
                                        p.AMaterno,
                                        p.APaterno, 
                                        p.CatCaracterPersonaAsuntoId,
                                        p.Foraneo,
                                        1 as tipo,
										CONCAT(Nombre, ' ', AMaterno, ' ', APaterno, ' - ',ISNULL(ctp.Descripcion ,'')) as PersonaTipo
                                                                         
                        from PersonasAsunto p with(nolock) left join 
                                                CatTiposPersona ctp with(nolock) on (ctp.CatTipoPersonaId = p.CatTipoPersonaId ) left join
                                                CatCaracterPersonaAsunto cpa with(nolock) on (cpa.CatCaracterPersonaAsuntoId = p.CatCaracterPersonaAsuntoId) left join
                                                CatClasificaAutoridadGenerica ccag with(nolock) on (ccag.ClasificaAutoridadGenericaId = p.ClasificaAutoridadGenericaId )                                        
                        where p.AsuntoNeunId = @pi_AsuntoNeunId 
                        and p.StatusReg = 1
                        order by ISNULL(ctp.Descripcion ,'')

                SET NOCOUNT OFF
        END
