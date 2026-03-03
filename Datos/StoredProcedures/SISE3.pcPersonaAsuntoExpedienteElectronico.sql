SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		GGHH
-- Create date: 07/02/2024
-- Description:	Obtiene una parte de un asunto.
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcPersonaAsuntoExpedienteElectronico]
(
	@pi_PersonaId BIGINT
)
AS
BEGIN	
	SET NOCOUNT ON
	BEGIN TRY
		SELECT 
			Nombre
			,APaterno
			,AMaterno
			,CatTipoPersonaId
			,CatCaracterPersonaAsuntoId		
			,Sexo
			,MayorEdad
			,CatTipoPersonaJuridicaId
			,DenominacionDeAutoridad
			,ClasificaAutoridadGenericaId
			,SujetoDerechoAgrario
			,AceptaOponePublicarDatos
			,FechaAceptaOponePublicarDatos = CONVERT(VARCHAR(10),FechaAceptaOponePublicarDatos,103)
			,Foraneo			
			,Recurrente
			,CaracterPromueveNombre
			,VictimaOfendidoDelito
			,Alias	
			,ParteAdhesivaApelacion	
			,EsParteGrupoVulnerable
			,GrupoVulnerable
			,EdadMenor	
			,HablaLengua
			,Lengua
			,Traductor
		FROM PersonasAsunto 
		WHERE PersonaId=@pi_PersonaId
	END TRY
	BEGIN CATCH
		-- Ejecuta la rutina de recuperacion de errores.
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
	SET NOCOUNT OFF
END
