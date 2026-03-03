USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piOtrasPartesAsuntoExpedienteElectronico]    Script Date: 11/06/2025 04:04:02 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--=============================================
-- Author:		Oliver A. Martinez Estudillo
-- Create date: 28/05/2025
-- Description:	Inserta otas partes a un asunto.
-- =============================================
CREATE PROCEDURE [SISE3].[piOtrasPartesAsuntoExpedienteElectronico]
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
       @PerId INT,
       @CatTipoPersonaId SMALLINT,
       @TipoNotificacionId INT
       BEGIN TRY
          SELECT @AsuntoId = AsuntoId 
          FROM Asuntos WITH(NOLOCK) 
          WHERE AsuntoNeunId = @pi_AsuntoNeunId


          SELECT @CatTipoPersonaId=CatTipoPersonaId, @TipoNotificacionId=TipoNotificacionId FROM OPENJSON(@pi_PersonaAsunto)WITH (CatTipoPersonaId SMALLINT, TipoNotificacionId INT)

          BEGIN TRAN
             INSERT INTO [SISE3].[OtrasPartesAsunto] (
                AsuntoId,
                AsuntoNeunId,
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
                fFechaAlta,
                fFechaBaja,
                StatusReg,
                iForaneo,
                iCatAutoridadId,
                iUsuarioCaptura,
                iEsParteGrupoVulnerable,
                iGrupoVulnerable,
                iEdadMenor,
                iHablaLengua,
                iLengua,
                iTraductor
            )
             SELECT
             @AsuntoId,
             @pi_AsuntoNeunId,
             Nombre,
             APaterno,
             AMaterno,
             CatTipoPersonaId,
             Sexo,
             MayorEdad,
             CatTipoPersonaJuridicaId,
             DenominacionDeAutoridad,
             ClasificaAutoridadGenericaId,
             SujetoDerechoAgrario,
             AceptaOponePublicarDatos,
             FechaAceptaOponePublicarDatosFecha,
             GETDATE(),         -- fFechaAlta
             NULL,              -- fFechaBaja
             1,                 -- StatusReg
             ISNULL(Foraneo, 0),
             ISNULL(CatAutoridadId, 0),
             @pi_UsuarioCaptura,
             EsParteGrupoVulnerable,
             GrupoVulnerable,
             CASE WHEN EdadMenor = 0 THEN NULL ELSE EdadMenor END,
             CASE WHEN HablaLengua = 0 THEN NULL ELSE HablaLengua END,
             CASE WHEN Lengua = 0 THEN NULL ELSE Lengua END,
             CASE WHEN Traductor = 0 THEN NULL ELSE Traductor END
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
                CatAutoridadId INT,
                EsParteGrupoVulnerable INT,
                GrupoVulnerable INT,
                EdadMenor SMALLINT,
                HablaLengua SMALLINT,
                Lengua INT,
                Traductor SMALLINT
            )
             
             SET @PerId=SCOPE_IDENTITY()
			 SET @po_PersonaId =  @PerId	


			INSERT INTO [SISE3].[OtrasPartesAsunto_Adicional]
						   ([AsuntoNeunId]
						   ,[iAsuntoId]
						   ,[iPersonaId]
						   ,[iTipoNotificacionId]
						   ,[fFechaAlta]						  
						   ,[bStatusReg]
						   ,[UsuarioCaptura])
					 VALUES
						   (@pi_AsuntoNeunId
						   ,1
						   ,@po_PersonaId
						   ,isnull(@TipoNotificacionId,0)
						   ,GETDATE()						
						   ,1
						   ,@pi_UsuarioCaptura)


             IF(@pi_IdOrganoPlenos<>0)
             BEGIN
                EXEC dbo.piVincularPartesPlenos @pi_AsuntoNeunId,@PerId, @pi_IdOrganoPlenos
            END
			EXEC SISE_NEWLOG.DBO.usp_BitacoraOtrasPartesAsuntoIns @pi_AsuntoNeunId,@PerId,@pi_UsuarioCaptura,'Alta'
            COMMIT TRAN            
        END TRY
        BEGIN CATCH
          IF @@TRANCOUNT > 0
          ROLLBACK TRANSACTION;
          EXECUTE dbo.usp_GetErrorInfo;
      END CATCH;
      SET NOCOUNT OFF
  END

GO


