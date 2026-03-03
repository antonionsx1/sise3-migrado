SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		GGHH
-- Create date: 07/02/2024
-- Description:	Actualiza una parte de un asunto.
-- Basado en usp_PersonasAsuntoUpd
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[paPersonaAsuntoExpedienteElectronico]
(
	@pi_UsuarioCaptura BIGINT,
	@pi_PersonaAsunto NVARCHAR(MAX),
	@pi_PersonaId BIGINT,
	@pi_AsuntoNeunId BIGINT,
	@pi_IdOrganoPlenos INT = 0
)
AS
BEGIN	
	SET NOCOUNT ON
	BEGIN TRY
		
		DECLARE @catTipoAsuntoId INT,
				@AsuntoId INT,
				@xmlActual AS VARCHAR(MAX), 
				@xmlCambio AS VARCHAR(MAX),
				@xml AS VARCHAR(MAX),
				@xmlFinal AS XML,
				@PersonaAsuntoActual PersonaAsunto_type,
				@PersonaAsuntoCambios PersonaAsunto_type

		SELECT @catTipoAsuntoId = catTipoAsuntoId, 
				@AsuntoId = AsuntoId
		FROM Asuntos WITH(NOLOCK) 
		WHERE AsuntoNeunId=@pi_AsuntoNeunId
			
		BEGIN TRAN
			SET @xmlActual=(
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
				FROM PersonasAsunto 
				WHERE PersonaId=@pi_PersonaId
				FOR XML PATH ('ParteActual'), 
				ROOT('PartesActual'))

			SET @xmlCambio=(
				SELECT 
					Nombre,
					APaterno,
					AMaterno,
					CatTipoPersonaId,
					CatCaracterPersonaAsuntoId,
					Sexo,
					MayorEdad,
					CatTipoPersonaJuridicaId,
					DenominacionDeAutoridad,
					ClasificaAutoridadGenericaId,
					SujetoDerechoAgrario,
					AceptaOponePublicarDatos,
					FechaAceptaOponePublicarDatos = FechaAceptaOponePublicarDatosFecha,
					Foraneo,
					Recurrente,
					CaracterPromueveNombre,
					VictimaOfendidoDelito,
					Alias,
					ParteAdhesivaApelacion,
					EsParteGrupoVulnerable,
					GrupoVulnerable,
					EdadMenor,
					HablaLengua,
					Lengua,
					Traductor
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
				FOR XML PATH ('ParteCambio'), 
				ROOT('PartesCambio')
			)

			SET @xml=@xmlActual + @xmlCambio
			SET @xmlFinal = CAST(@xml as XML) 

			UPDATE PersonasAsunto 
			SET	UsuarioCaptura = @pi_UsuarioCaptura
				,PersonasAsunto.Nombre  = tbl.Nombre
				,PersonasAsunto.APaterno = tbl.APaterno
				,PersonasAsunto.AMaterno = tbl.AMaterno
				,PersonasAsunto.CatTipoPersonaId = tbl.CatTipoPersonaId
				,PersonasAsunto.CatCaracterPersonaAsuntoId = tbl.CatCaracterPersonaAsuntoId
				,PersonasAsunto.Sexo = tbl.Sexo
				,PersonasAsunto.MayorEdad = tbl.MayorEdad
				,PersonasAsunto.CatTipoPersonaJuridicaId = tbl.CatTipoPersonaJuridicaId
				,PersonasAsunto.DenominacionDeAutoridad = tbl.DenominacionDeAutoridad
				,PersonasAsunto.ClasificaAutoridadGenericaId = tbl.ClasificaAutoridadGenericaId
				,PersonasAsunto.SujetoDerechoAgrario = tbl.SujetoDerechoAgrario
				,PersonasAsunto.AceptaOponePublicarDatos = tbl.AceptaOponePublicarDatos
				,PersonasAsunto.FechaAceptaOponePublicarDatos = tbl.FechaAceptaOponePublicarDatosFecha
				,PersonasAsunto.Foraneo = tbl.Foraneo
				,PersonasAsunto.Recurrente = tbl.Recurrente
				,PersonasAsunto.CaracterPromueveNombre = CASE WHEN tbl.CaracterPromueveNombre = 0 THEN -1 ELSE tbl.CaracterPromueveNombre END
				,PersonasAsunto.VictimaOfendidoDelito = tbl.VictimaOfendidoDelito
				,PersonasAsunto.Alias = tbl.Alias
				,PersonasAsunto.ParteAdhesivaApelacion = tbl.ParteAdhesivaApelacion
				,PersonasAsunto.EsParteGrupoVulnerable = tbl.EsParteGrupoVulnerable
				,PersonasAsunto.GrupoVulnerable = tbl.GrupoVulnerable
				,PersonasAsunto.EdadMenor = CASE WHEN tbl.EdadMenor = 0 THEN -1 ELSE tbl.EdadMenor END
				,PersonasAsunto.HablaLengua = CASE WHEN tbl.HablaLengua = 0 THEN NULL ELSE tbl.HablaLengua END
				,PersonasAsunto.Lengua =  CASE WHEN tbl.Lengua = 0 THEN NULL ELSE tbl.Lengua END
				,PersonasAsunto.Traductor = CASE WHEN tbl.Traductor = 0 THEN NULL ELSE tbl.Traductor END
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
			)tbl
			WHERE PersonasAsunto.PersonaId = @pi_PersonaId
            
			IF(@pi_IdOrganoPlenos<>0)
			BEGIN
				UPDATE [SISE_NEW].[dbo].[PersonasPlenos]
				SET [IdTribunalPlenos] = @pi_IdOrganoPlenos
				WHERE AsuntoNeunId= @pi_AsuntoNeunId and PersonaId= @pi_PersonaId
			END
			
			EXEC SISE_NEWLOG.DBO.usp_BitacoraPersonasAsuntoCambioIns @pi_AsuntoNeunId,@pi_PersonaId,@pi_UsuarioCaptura,'Cambio',@xmlFinal
		
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

