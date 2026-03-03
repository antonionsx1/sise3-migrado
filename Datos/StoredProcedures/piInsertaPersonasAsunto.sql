USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piInsertaPersonasAsunto]    Script Date: 12/1/2023 6:26:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 23/08/2023 
-- Description: Se uliliza para agregar registros a la tabla PersonasAsunto
-- Basado en: usp_PersonasAsuntoIns
--execute [SISE3].[usp_EXPE_PersonasXAsuntoSel] 18672587
-- ============================================= 
CREATE PROCEDURE [SISE3].[piInsertaPersonasAsunto]
(
@pi_AsuntoId [int] ,
@pi_AsuntoNeunId [bigint],
@pi_UsuarioCaptura [bigint],
@pi_PersonaAsunto SISE3.PersonaAsunto_type readonly,
@po_PersonaId INT = null OUTPUT,
@pi_IdOrganoPlenos int=0,
@pi_AceptaOponePublicarDatos INT=0,
@pi_FechaAlta date=NULL,
@pi_StatusReg int =1,
@pi_Foraneo int=0,
@pi_CatAutoridadId INT=1,
@pi_Recurrente INT=0

)
AS

      BEGIN
        SET NOCOUNT ON
       
        DECLARE @PerId int

        BEGIN TRY
                  BEGIN TRAN
				  IF @pi_FechaAlta IS NULL
					SET @pi_FechaAlta = getdate()

	

                  INSERT INTO PersonasAsunto (
									[AsuntoId]
									,[AsuntoNeunId]
									,[Nombre]
									,[APaterno]
									,[AMaterno]
									,[CatTipoPersonaId]
									,[CatCaracterPersonaAsuntoId]
									,[CatTipoPersonaJuridicaId]
									,[CaracterPromueveNombre]
									,[UsuarioCaptura]
									,[AceptaOponePublicarDatos]
									,[FechaAlta]
									,[StatusReg]
									,[Foraneo]
									,[CatAutoridadId]
									,[Recurrente]
									)                                              
                  SELECT
                             @pi_AsuntoId,
                             @pi_AsuntoNeunId,
                             pa.Nombre,
                             pa.APaterno,
                             pa.AMaterno,
                             pa.CatTipoPersonaId,
                             pa.CatCaracterPersonaAsuntoId,
                             pa.CatTipoPersonaJuridicaId,
                             pa.CaracterPromueveNombre,
                             @pi_UsuarioCaptura,
							 @pi_AceptaOponePublicarDatos,
							 @pi_FechaAlta,
							 @pi_StatusReg,
							 @pi_Foraneo,
							 @pi_CatAutoridadId,
							 @pi_Recurrente
				
				FROM        @pi_PersonaAsunto pa 
				LEFT JOIN PersonasAsunto p
				ON   p.[AsuntoId] = @pi_AsuntoId AND [AsuntoNeunId] = @pi_AsuntoNeunId AND 
					 SISE3.ConcatenarNombres(p.[Nombre],p.[APaterno],p.[AMaterno])  =  SISE3.ConcatenarNombres(pa.Nombre, pa.APaterno, pa.AMaterno) AND
					 p.[CatTipoPersonaId] = pa.CatTipoPersonaId AND 
					 p.[CatCaracterPersonaAsuntoId] = pa.CatCaracterPersonaAsuntoId  AND 
					 p.[CatTipoPersonaJuridicaId] = pa.CatTipoPersonaJuridicaId  
			    WHERE p.[AsuntoId] IS NULL

                  
                  set @PerId=SCOPE_IDENTITY()
				  SET @po_PersonaId =  @PerId	
                  if(@pi_IdOrganoPlenos<>0)
					begin
						 exec dbo.piVincularPartesPlenos @pi_AsuntoNeunId,@PerId, @pi_IdOrganoPlenos
					end
			 
                 exec SISE_NEWLOG.DBO.usp_BitacoraPersonasAsuntoIns @pi_AsuntoNeunId,@PerId,@pi_UsuarioCaptura,'Alta'
                  
            END TRY
            BEGIN CATCH
                -- Ejecuto ROLLBACK solo en caso de error
                  IF @@TRANCOUNT > 0
                        ROLLBACK TRANSACTION;
                  -- Ejecuta la rutina de recuperacion de errores.
                  EXECUTE dbo.usp_GetErrorInfo;
            END CATCH;
          -- Completo mi transaccion
            IF @@TRANCOUNT > 0
                  COMMIT TRANSACTION;
            SET NOCOUNT OFF
      END

GO

