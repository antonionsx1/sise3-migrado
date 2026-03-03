USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piPersonaAsunto]    Script Date: 12/1/2023 6:27:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GGHH
-- Create date: 30/08/2023
-- Description:	Inserta al promovente de un asunto.
/* 
	DECLARE @po_PersonaId INT
	EXEC [SISE3].[piPersonaAsunto] 30314167,1,'a','a','',1,13,null, NULL, 155
	SELECT @po_PersonaId
*/
-- =============================================
CREATE PROCEDURE [SISE3].[piPersonaAsunto]
(
	@pi_AsuntoNeunId [bigint],
	@pi_UsuarioCaptura [bigint],
	@pi_Nombre VARCHAR(500),
	@pi_APaterno VARCHAR(50),
	@pi_AMaterno VARCHAR(50),
	@pi_CatTipoPersonaId SMALLINT,
	@pi_CatCaracterPersonaAsuntoId SMALLINT,
	@pi_DenominacionDeAutoridad VARCHAR(255) = NULL,
	@po_PersonaId INT = null OUTPUT,
	@pi_NumeroOrden INT
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @PersonaAsunto dbo.PersonaAsunto_type,
				@AsuntoId INT,
				@DenominacionDeAutoridad VARCHAR(255),
				@PersonaId INT,
				@TipoPromovete INT

		SELECT @AsuntoId = AsuntoId
		FROM dbo.Asuntos WITH(NOLOCK)
		WHERE AsuntoNeunId = @pi_AsuntoNeunId
		
		IF @pi_DenominacionDeAutoridad IS NULL
		BEGIN
			SET @DenominacionDeAutoridad = IIF(@pi_CatTipoPersonaId =3,@pi_Nombre, NULL)
		END
		ELSE BEGIN
			SET @DenominacionDeAutoridad = @pi_DenominacionDeAutoridad
		END

		IF NOT EXISTS(SELECT TOP 1 AsuntoId 
					 FROM PersonasAsunto P
					 WHERE p.[AsuntoId] = @AsuntoId AND [AsuntoNeunId] = @pi_AsuntoNeunId AND 
					 SISE3.ConcatenarNombres(p.[Nombre],p.[APaterno],p.[AMaterno])  =  SISE3.ConcatenarNombres(@pi_Nombre, @pi_APaterno, @pi_AMaterno) AND
					 p.[CatTipoPersonaId] = @pi_CatTipoPersonaId AND 
					 p.[CatCaracterPersonaAsuntoId] = @pi_CatCaracterPersonaAsuntoId )
		BEGIN

			INSERT INTO @PersonaAsunto(Nombre, APaterno,AMaterno,CatTipoPersonaId,CatTipoPersonaJuridicaId,CatCaracterPersonaAsuntoId,DenominacionDeAutoridad,
			ClasificaAutoridadGenericaId, SujetoDerechoAgrario, AceptaOponePublicarDatos, Foraneo, Recurrente, CaracterPromueveNombre,
			VictimaOfendidoDelito, ParteAdhesivaApelacion, EsGrupoVulnerable, EdadMenor,MayorEdad,Sexo,GrupoVulnerable)
			VALUES(@pi_Nombre, @pi_APaterno, @pi_AMaterno, @pi_CatTipoPersonaId, @pi_CatTipoPersonaId, @pi_CatCaracterPersonaAsuntoId, @DenominacionDeAutoridad,
			0,0,0,0,0,-1,
			0,0,0,-1,0,0,0)
		
			EXEC dbo.usp_PersonasAsuntoIns
				@pi_AsuntoId = @AsuntoId ,
				@pi_AsuntoNeunId = @pi_AsuntoNeunId,
				@pi_UsuarioCaptura = @pi_UsuarioCaptura,
				@pi_PersonaAsunto = @PersonaAsunto,
				@po_PersonaId	= @po_PersonaId OUTPUT,
				@pi_IdOrganoPlenos = 0

		END

		
		SELECT @TipoPromovete = max(pr.PersonaId)
		FROM promociones p INNER JOIN PersonasAsunto pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_numeroOrden
		WHERE p.AsuntoNeunId = @pi_AsuntoNeunId
		AND P.NumeroOrden = @pi_numeroOrden
		AND SISE3.ConcatenarNombres(pr.[Nombre],pr.[APaterno],pr.[AMaterno])  =  SISE3.ConcatenarNombres(@pi_Nombre, @pi_APaterno, @pi_AMaterno) AND
		pr.[CatTipoPersonaId] = @pi_CatTipoPersonaId AND 
		pr.[CatCaracterPersonaAsuntoId] = @pi_CatCaracterPersonaAsuntoId ;

		
		IF @po_PersonaId IS NULL 
		BEGIN 
			SET @po_PersonaId = @TipoPromovete
		END 


		UPDATE p
		SET TipoPromovente  = @TipoPromovete
		FROM promociones p INNER JOIN PersonasAsunto pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_NumeroOrden
		WHERE p.AsuntoNeunId = @pi_AsuntoNeunId
		AND p.ClasePromovente = 1;


		/*	UPDATE p
			SET PersonaId  = pr.PersonaId
			FROM promovente p INNER JOIN PersonasAsunto pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_NumeroOrden
			WHERE p.AsuntoNeunId = @pi_AsuntoNeunId
			AND p.ClasePromovente = 2;*/

END TRY
	BEGIN CATCH
		EXECUTE dbo.usp_GetErrorInfo;
	END CATCH;
END
GO

