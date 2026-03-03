SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 23/08/2023 
-- Description: Se uliliza para lista las partes cuando en el modulo promociones se selecciona el radio button Partes
-- Basado en: usp_EXPE_PersonasXAsuntoSel
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--execute [SISE3].[pcPersonasXAsunto] 0, NULL,NULL, 1,1
-- exec [SISE3].[pcPersonasXAsunto]  8367099, '1/2010'
-- ============================================= 

CREATE OR ALTER PROCEDURE [SISE3].[pcPersonasXAsunto]
@pi_AsuntoNeunId [bigint], 
@pi_NoExp varchar(max) = NULL, 
@pi_Texto VARCHAR(MAX) = NULL, 
@pi_Modulo int, -- 1 Promocion, 2 Tramite 
@pi_TipoParte int --1 Persona , 2 Autoridad
AS

        BEGIN
            SET NOCOUNT ON
			IF @pi_AsuntoNeunId != 0
			BEGIN
				BEGIN
					IF @pi_Modulo = 1 
					BEGIN 
						IF @pi_NoExp IS NULL
						BEGIN
							select distinct ISNULL(ctp.Descripcion ,'') as DescripcionTipoPersona,
											isnull(p.DenominacionDeAutoridad,'') DenominacionDeAutoridad,
											isnull(cpa.Descripcion,'') as DescripcionCaracterPersona,
											ISNULL(ccag.Descripcion,'') as DescripcionClasificaAutoridadGenerica,
											p.PersonaId,
											p.Nombre,
											ISNULL(p.AMaterno,'')AS AMaterno,
											ISNULL(p.APaterno,'') AS APaterno, 
											p.CatCaracterPersonaAsuntoId,
											p.Foraneo,
											p.CatTipoPersonaId AS Tipo,
											(
											CASE WHEN p.CatTipoPersonaid = 1 THEN CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(cpa.Descripcion ,'')) 
											ELSE CONCAT(p.DenominacionDeAutoridad,' - ',ISNULL(cpa.Descripcion ,''))
											END)
											as PersonaTipo
											

					                                                         
							from PersonasAsunto p with(nolock) left join 
													CatTiposPersona ctp with(nolock) on (ctp.CatTipoPersonaId = p.CatTipoPersonaId ) left join
													CatCaracterPersonaAsunto cpa with(nolock) on (cpa.CatCaracterPersonaAsuntoId = p.CatCaracterPersonaAsuntoId) left join
													CatClasificaAutoridadGenerica ccag with(nolock) on (ccag.ClasificaAutoridadGenericaId = p.ClasificaAutoridadGenericaId ) 

							where p.AsuntoNeunId = @pi_AsuntoNeunId 
							and p.StatusReg = 1 
							order by ISNULL(ctp.Descripcion ,'')

						END
						ELSE 
						BEGIN
							select distinct ISNULL(ctp.Descripcion ,'') as DescripcionTipoPersona,
											isnull(p.DenominacionDeAutoridad,'') DenominacionDeAutoridad,
											isnull(cpa.Descripcion,'') as DescripcionCaracterPersona,
											ISNULL(ccag.Descripcion,'') as DescripcionClasificaAutoridadGenerica,
											p.PersonaId,
											p.Nombre,
											ISNULL(p.AMaterno,'')AS AMaterno,
											ISNULL(p.APaterno,'') AS APaterno, 
											p.CatCaracterPersonaAsuntoId,
											p.Foraneo,
											p.CatTipoPersonaId  AS Tipo,
											(
											CASE WHEN p.CatTipoPersonaid = 1 THEN CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(cpa.Descripcion ,'')) 
											ELSE CONCAT(p.DenominacionDeAutoridad,' - ',ISNULL(cpa.Descripcion ,''))
											END)
											as PersonaTipo
											
					                                                         
							from PersonasAsunto p with(nolock) left join 
													CatTiposPersona ctp with(nolock) on (ctp.CatTipoPersonaId = p.CatTipoPersonaId ) left join
													CatCaracterPersonaAsunto cpa with(nolock) on (cpa.CatCaracterPersonaAsuntoId = p.CatCaracterPersonaAsuntoId) left join
													CatClasificaAutoridadGenerica ccag with(nolock) on (ccag.ClasificaAutoridadGenericaId = p.ClasificaAutoridadGenericaId ) 
													left join promociones pr with(nolock) on pr.AsuntoNeunId = @pi_AsuntoNeunId AND p.PersonaId = pr.TipoPromovente AND pr.ClasePromovente = 1 and pr.StatusReg = 1
												 	CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
							where p.AsuntoNeunId = @pi_AsuntoNeunId 
							and p.StatusReg = 1
							and iif (@pi_NoExp is null, isnull(@pi_NoExp,''), a.AsuntoAlias) = isnull(@pi_NoExp,'')
							AND IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
							CONCAT(isnull(cpa.Descripcion,'') , CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(ctp.Descripcion ,'')))) LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
							order by ISNULL(ctp.Descripcion ,'')
						END
					END 
					IF @pi_Modulo = 2
					BEGIN 
						IF @pi_TipoParte = 1 
						 BEGIN 
							IF @pi_NoExp IS NULL
							BEGIN

									select distinct ISNULL(ctp.Descripcion ,'') as DescripcionTipoPersona,
													isnull(p.DenominacionDeAutoridad,'') DenominacionDeAutoridad,
													isnull(cpa.Descripcion,'') as DescripcionCaracterPersona,
													ISNULL(ccag.Descripcion,'') as DescripcionClasificaAutoridadGenerica,
													p.PersonaId,
													p.Nombre,
													ISNULL(p.AMaterno,'')AS AMaterno,
													ISNULL(p.APaterno,'') AS APaterno, 
													p.CatCaracterPersonaAsuntoId,
													p.Foraneo,
													1 as tipo,
													( CASE WHEN p.CatTipoPersonaid = 1 THEN CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(cpa.Descripcion ,'')) 
													       ELSE CONCAT(p.DenominacionDeAutoridad,' - ',ISNULL(cpa.Descripcion ,''))
													  END) as PersonaTipo
					                                                         
									from PersonasAsunto p with(nolock) left join 
															CatTiposPersona ctp with(nolock) on (ctp.CatTipoPersonaId = p.CatTipoPersonaId ) left join
															CatCaracterPersonaAsunto cpa with(nolock) on (cpa.CatCaracterPersonaAsuntoId = p.CatCaracterPersonaAsuntoId) left join
															CatClasificaAutoridadGenerica ccag with(nolock) on (ccag.ClasificaAutoridadGenericaId = p.ClasificaAutoridadGenericaId ) 

									where p.AsuntoNeunId = @pi_AsuntoNeunId 
									and p.StatusReg = 1
									and ctp.CatTipoPersonaId <> 3
									order by ISNULL(ctp.Descripcion ,'')

							END
							ELSE 
							BEGIN
										select distinct ISNULL(ctp.Descripcion ,'') as DescripcionTipoPersona,
														isnull(p.DenominacionDeAutoridad,'') DenominacionDeAutoridad,
														isnull(cpa.Descripcion,'') as DescripcionCaracterPersona,
														ISNULL(ccag.Descripcion,'') as DescripcionClasificaAutoridadGenerica,
														p.PersonaId,
														p.Nombre,
														ISNULL(p.AMaterno,'')AS AMaterno,
														ISNULL(p.APaterno,'') AS APaterno, 
														p.CatCaracterPersonaAsuntoId,
														p.Foraneo,
														1 as tipo,
														( CASE WHEN p.CatTipoPersonaid = 1 THEN CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(cpa.Descripcion ,'')) 
													       ELSE CONCAT(p.DenominacionDeAutoridad,' - ',ISNULL(cpa.Descripcion ,''))
													  END) as PersonaTipo
					                                                         
										from PersonasAsunto p with(nolock) left join 
																CatTiposPersona ctp with(nolock) on (ctp.CatTipoPersonaId = p.CatTipoPersonaId ) left join
																CatCaracterPersonaAsunto cpa with(nolock) on (cpa.CatCaracterPersonaAsuntoId = p.CatCaracterPersonaAsuntoId) left join
																CatClasificaAutoridadGenerica ccag with(nolock) on (ccag.ClasificaAutoridadGenericaId = p.ClasificaAutoridadGenericaId ) 
																left join promociones pr with(nolock) on pr.AsuntoNeunId = @pi_AsuntoNeunId AND p.PersonaId = pr.TipoPromovente AND pr.ClasePromovente = 1 and pr.StatusReg = 1
												 				CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
										where p.AsuntoNeunId = @pi_AsuntoNeunId 
										and p.StatusReg = 1
										and ctp.CatTipoPersonaId <> 3
										and iif (@pi_NoExp is null, isnull(@pi_NoExp,''), a.AsuntoAlias) = isnull(@pi_NoExp,'')
										AND IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
										CONCAT(isnull(cpa.Descripcion,'') , CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(ctp.Descripcion ,'')))) LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
										order by ISNULL(ctp.Descripcion ,'')
							END
						END
						IF  @pi_TipoParte = 2
						BEGIN 
							select distinct (CASE WHEN p.CatTipoPersonaid = 1 THEN CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(cpa.Descripcion ,'')) 
											ELSE CONCAT(p.DenominacionDeAutoridad,' - ',ISNULL(cpa.Descripcion ,''))
											END) as Nombres,
									AutoridadJudicialId = p.PersonaId,
									AutoridadJudicialDescripcion = ISNULL(cpa.Descripcion ,'')                                                                        
							from PersonasAsunto p with(nolock) left join 
													CatTiposPersona ctp with(nolock) on (ctp.CatTipoPersonaId = p.CatTipoPersonaId ) left join
													CatCaracterPersonaAsunto cpa with(nolock) on (cpa.CatCaracterPersonaAsuntoId = p.CatCaracterPersonaAsuntoId) left join
													CatClasificaAutoridadGenerica ccag with(nolock) on (ccag.ClasificaAutoridadGenericaId = p.ClasificaAutoridadGenericaId ) 
													left join promociones pr with(nolock) on pr.AsuntoNeunId = @pi_AsuntoNeunId AND p.PersonaId = pr.TipoPromovente AND pr.ClasePromovente = 1 and pr.StatusReg = 1
													CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
							where p.AsuntoNeunId = @pi_AsuntoNeunId 
							and p.StatusReg = 1
							and ctp.CatTipoPersonaId = 3
							and iif (@pi_NoExp is null, isnull(@pi_NoExp,''), a.AsuntoAlias) = isnull(@pi_NoExp,'')
							AND IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
							CONCAT(isnull(cpa.Descripcion,'') , CONCAT(Nombre, ' ', APaterno, ' ', AMaterno, ' - ',ISNULL(ctp.Descripcion ,'')))) LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
						END
					END
				END
			END
		SET NOCOUNT OFF
        END
