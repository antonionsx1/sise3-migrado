SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		GGHH
-- Create date: 06/02/2024
-- Description:	Inserta al parte a un asunto.
-- Basado en usp_PersonasAsuntoIns
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[piPersonaAsuntoExpedienteElectronico]
(
@pi_AsuntoNeunId BIGINT,
@pi_UsuarioCaptura BIGINT,
@pi_PersonaAsunto NVARCHAR(MAX),
@po_PersonaId BIGINT = NULL OUTPUT,
@pi_IdOrganoPlenos INT = 0
)
AS
BEGIN
	
	SET NOCOUNT ON
	DECLARE @AsuntoId INT,
			@PerId INT
	BEGIN TRY
		SELECT @AsuntoId = AsuntoId 
		FROM Asuntos WITH(NOLOCK) 
		WHERE AsuntoNeunId = @pi_AsuntoNeunId

		BEGIN TRAN
			INSERT INTO PersonasAsunto (
				AsuntoId
				,AsuntoNeunId
				,UsuarioCaptura
				,Nombre
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
				,FechaAceptaOponePublicarDatos
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
				)                                              
		
			SELECT @AsuntoId
				,@pi_AsuntoNeunId
				,@pi_UsuarioCaptura
				,Nombre
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
				,FechaAceptaOponePublicarDatosFecha
				,Foraneo
				,Recurrente 
				,CASE WHEN CaracterPromueveNombre = 0 THEN -1 ELSE CaracterPromueveNombre END
				,VictimaOfendidoDelito
				,Alias
				,ParteAdhesivaApelacion
				,EsParteGrupoVulnerable
				,GrupoVulnerable
				,CASE WHEN EdadMenor = 0 THEN -1 ELSE EdadMenor END
				,CASE WHEN HablaLengua = 0 THEN NULL ELSE HablaLengua END
				,CASE WHEN Lengua = 0 THEN NULL ELSE Lengua END
				,CASE WHEN Traductor = 0 THEN NULL ELSE Traductor END
			FROM OPENJSON(@pi_PersonaAsunto)
			WITH (
				Nombre VARCHAR(500),
				APaterno VARCHAR(50),
				AMaterno VARCHAR(50),
				CatTipoPersonaId SMALLINT,
				CatCaracterPersonaAsuntoId SMALLINT,
				Sexo INT,
				MayorEdad INT,
				CatTipoPersonaJuridicaId SMALLINT,
				DenominacionDeAutoridad VARCHAR(255),
				ClasificaAutoridadGenericaId SMALLINT,
				SujetoDerechoAgrario INT,
				AceptaOponePublicarDatos INT,
				FechaAceptaOponePublicarDatosFecha DATETIME,
				Foraneo INT,
				Recurrente INT,
				CaracterPromueveNombre INT,
				VictimaOfendidoDelito INT,
				Alias VARCHAR(300),
				ParteAdhesivaApelacion INT,
				EsParteGrupoVulnerable INT,
				GrupoVulnerable INT,
				EdadMenor SMALLINT,
				HablaLengua SMALLINT,
				Lengua INT,
				Traductor SMALLINT
			)
             
			SET @PerId=SCOPE_IDENTITY()
			SET @po_PersonaId =  @PerId	

			IF(@pi_IdOrganoPlenos<>0)
			BEGIN
				EXEC dbo.piVincularPartesPlenos @pi_AsuntoNeunId,@PerId, @pi_IdOrganoPlenos
			END
			 
			EXEC SISE_NEWLOG.DBO.usp_BitacoraPersonasAsuntoIns @pi_AsuntoNeunId,@PerId,@pi_UsuarioCaptura,'Alta'
		COMMIT TRAN            
	END TRY
	BEGIN CATCH
		-- Ejecuto ROLLBACK solo en caso de error
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		-- Ejecuta la rutina de recuperacion de errores.
        EXECUTE dbo.usp_GetErrorInfo;
    END CATCH;
	SET NOCOUNT OFF
END

