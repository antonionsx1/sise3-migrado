---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
@pi_IdOrganoPlenos int=0
)
AS

      BEGIN
        SET NOCOUNT ON
       
        DECLARE @PerId int

        BEGIN TRY
                  BEGIN TRAN
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
                             @pi_UsuarioCaptura
                             
                  FROM        @pi_PersonaAsunto pa 
                  
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


