USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[paOtraParteAsuntoExpedienteElectronico]    Script Date: 11/06/2025 04:09:11 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--=============================================
-- Author:		Oliver A. Martinez Estudillo
-- Create date: 03/06/2025
-- Description:	Actualiza otra parte de un asunto.
-- =============================================
CREATE PROCEDURE [SISE3].[paOtraParteAsuntoExpedienteElectronico]
(
	@pi_UsuarioCaptura BIGINT,
	@pi_PersonaAsunto NVARCHAR(MAX),
	@pi_PersonaId BIGINT,
	@pi_AsuntoNeunId BIGINT
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
				@CatTipoPersonaId SMALLINT,
				@TipoNotificacionIdSolicitada INT

		SELECT @catTipoAsuntoId = catTipoAsuntoId, @AsuntoId = AsuntoId
		FROM Asuntos WITH(NOLOCK)
		WHERE AsuntoNeunId = @pi_AsuntoNeunId

		SELECT @CatTipoPersonaId=CatTipoPersonaId, @TipoNotificacionIdSolicitada=TipoNotificacionIdSolicitada 
		FROM OPENJSON(@pi_PersonaAsunto) 
		WITH (CatTipoPersonaId SMALLINT, TipoNotificacionIdSolicitada INT)

		BEGIN TRAN
		SET @xmlActual = (
			SELECT 
				sNombre,
				sAPaterno,
				sAMaterno,
				CatTipoPersonaId,
				iSexo,
				iMayorEdad,
				CatTipoPersonaJuridicaId,
				sDenominacionDeAutoridad,
				ClasificaAutoridadGenericaId,
				iSujetoDerechoAgrario,
				iAceptaOponePublicarDatos,
				fFechaAceptaOponePublicarDatos,
				iForaneo,
				iCatAutoridadId,
				iUsuarioCaptura,
				iEsParteGrupoVulnerable,
				iGrupoVulnerable,
				iEdadMenor,
				iHablaLengua,
				iLengua,
				iTraductor
			FROM [SISE3].[OtrasPartesAsunto]  
			WHERE iPersonaId = @pi_PersonaId
			FOR XML PATH('ParteActual'), ROOT('PartesActual')
			);
		SET @xmlCambio = (
			SELECT 
				Nombre AS sNombre,
				APaterno AS sAPaterno,
				AMaterno AS sAMaterno,
				CatTipoPersonaId,
				Sexo AS iSexo,
				MayorEdad AS iMayorEdad,
				CatTipoPersonaJuridicaId,
				DenominacionDeAutoridad AS sDenominacionDeAutoridad,
				ClasificaAutoridadGenericaId,
				SujetoDerechoAgrario AS iSujetoDerechoAgrario,
				AceptaOponePublicarDatos AS iAceptaOponePublicarDatos,
				FechaAceptaOponePublicarDatosFecha AS fFechaAceptaOponePublicarDatos,
				Foraneo AS iForaneo,
				EsParteGrupoVulnerable AS iEsParteGrupoVulnerable,
				GrupoVulnerable AS iGrupoVulnerable,
				EdadMenor AS iEdadMenor,
				HablaLengua AS iHablaLengua,
				Lengua AS iLengua,
				Traductor AS iTraductor,
				CatAutoridadId AS iCatAutoridadId,
				UsuarioCaptura AS iUsuarioCaptura
			FROM OPENJSON(@pi_PersonaAsunto) 
			WITH (
				Nombre VARCHAR(500),
				APaterno VARCHAR(50),
				AMaterno VARCHAR(50),
				CatTipoPersonaId SMALLINT,
				Sexo INT,
				MayorEdad INT,
				CatTipoPersonaJuridicaId SMALLINT,
				DenominacionDeAutoridad VARCHAR(255),
				ClasificaAutoridadGenericaId SMALLINT,
				SujetoDerechoAgrario INT,
				AceptaOponePublicarDatos INT,
				FechaAceptaOponePublicarDatosFecha DATETIME,
				Foraneo INT,
				EsParteGrupoVulnerable INT,
				GrupoVulnerable INT,
				EdadMenor SMALLINT,
				HablaLengua SMALLINT,
				Lengua INT,
				Traductor SMALLINT,
				CatAutoridadId INT,
				UsuarioCaptura BIGINT
				) 
				FOR XML PATH('ParteCambio'), ROOT('PartesCambio')
				);
				SET @xml = @xmlActual + @xmlCambio;
				SET @xmlFinal = CAST(@xml AS XML);

		-- Actualiza OtrasPartesAsunto
		UPDATE [SISE3].[OtrasPartesAsunto]
		SET
			iUsuarioCaptura = @pi_UsuarioCaptura,
			sNombre = tbl.Nombre,
			sAPaterno = tbl.APaterno,
			sAMaterno = tbl.AMaterno,
			CatTipoPersonaId = tbl.CatTipoPersonaId,
			iSexo = tbl.Sexo,
			iMayorEdad = tbl.MayorEdad,
			CatTipoPersonaJuridicaId = NULLIF(tbl.CatTipoPersonaJuridicaId,0),
			sDenominacionDeAutoridad = tbl.DenominacionDeAutoridad,
			ClasificaAutoridadGenericaId = NULLIF(tbl.ClasificaAutoridadGenericaId,0),
			iSujetoDerechoAgrario = tbl.SujetoDerechoAgrario,
			iAceptaOponePublicarDatos = tbl.AceptaOponePublicarDatos,
			fFechaAceptaOponePublicarDatos = tbl.FechaAceptaOponePublicarDatos,
			iForaneo = tbl.Foraneo,
			iCatAutoridadId = NULLIF(tbl.CatAutoridadId, 0),
			iEsParteGrupoVulnerable = tbl.EsParteGrupoVulnerable,
			iGrupoVulnerable = tbl.GrupoVulnerable,
			iEdadMenor = NULLIF(tbl.EdadMenor, 0),
			iHablaLengua = NULLIF(tbl.HablaLengua, 0),
			iLengua = NULLIF(tbl.Lengua, 0),
			iTraductor = NULLIF(tbl.Traductor, 0)
		FROM OPENJSON(@pi_PersonaAsunto)
		WITH (
			Nombre VARCHAR(500),
			APaterno VARCHAR(50),
			AMaterno VARCHAR(50),
			CatTipoPersonaId SMALLINT,
			Sexo INT,
			MayorEdad INT,
			CatTipoPersonaJuridicaId SMALLINT,
			DenominacionDeAutoridad VARCHAR(255),
			ClasificaAutoridadGenericaId SMALLINT,
			SujetoDerechoAgrario INT,
			AceptaOponePublicarDatos INT,
			FechaAceptaOponePublicarDatos DATETIME,
			Foraneo INT,
			CatAutoridadId INT,
			EsParteGrupoVulnerable INT,
			GrupoVulnerable INT,
			EdadMenor SMALLINT,
			HablaLengua SMALLINT,
			Lengua INT,
			Traductor SMALLINT
		) AS tbl
		WHERE iPersonaId = @pi_PersonaId

		-- Inserta o actualiza en tabla adicional
		IF EXISTS (
			SELECT 1 FROM [SISE3].[OtrasPartesAsunto_Adicional]
			WHERE AsuntoNeunId = @pi_AsuntoNeunId AND iPersonaId = @pi_PersonaId AND bStatusReg = 1
		)
		BEGIN
			UPDATE [SISE3].[OtrasPartesAsunto_Adicional]
			SET iTipoNotificacionId = ISNULL(@TipoNotificacionIdSolicitada, 0),
				UsuarioCaptura = @pi_UsuarioCaptura,
				fFechaAlta = GETDATE()
			WHERE AsuntoNeunId = @pi_AsuntoNeunId AND iPersonaId = @pi_PersonaId AND bStatusReg = 1
		END
		ELSE
		BEGIN
			INSERT INTO [SISE3].[OtrasPartesAsunto_Adicional]
				(AsuntoNeunId, iAsuntoId, iPersonaId, iTipoNotificacionId, fFechaAlta, bStatusReg, UsuarioCaptura)
			VALUES
				(@pi_AsuntoNeunId, @AsuntoId, @pi_PersonaId, ISNULL(@TipoNotificacionIdSolicitada, 0), GETDATE(), 1, @pi_UsuarioCaptura)
		END

		EXEC SISE_NEWLOG.DBO.usp_BitacoraOtrasPartesAsuntoCambioIns @pi_AsuntoNeunId,@pi_PersonaId,@pi_UsuarioCaptura,'Cambio',@xmlFinal
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN
		EXEC dbo.usp_GetErrorInfo
	END CATCH
	SET NOCOUNT OFF
END
GO


