SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: SGS
-- Create date: 06/03/2024
-- Description: Inserta acuse de notificacion
-- Ejemplo de llamada
/* 

DECLARE @po_NombreArchivo [VARCHAR](200) 
exec [SISE3].[piInsertaAcuse] 16524127,124,180,'2024-03-14 00:00:00',5726,110033355,6712,'SintesisCitatorio',null,'2024-03-06 00:00:00', @po_NombreArchivo OUTPUT
select @po_NombreArchivo
*/
-- ============================================= 

CREATE OR ALTER PROC [SISE3].[piInsertaAcuse]
@pi_AsuntoNeunId [bigint] NULL,
@pi_SintesisOrden [int] NULL,
@pi_CatOrganismoId [int] NULL,
@pi_FechaNotificacion [datetime] NULL,
@pi_TipoAcuse [int] NULL,
@pi_PersonaId [bigint] NULL,
@pi_EmpleadoId [bigint] NULL,
@pi_SintesisCitatorio [VARCHAR](200) = NULL,
@pi_TipoNotificacion [int] = NULL,
@pi_FechaNotificacionCitatorio [datetime] = NULL,
@po_NombreArchivo [VARCHAR](200) OUTPUT,
@po_NotElecId [bigint] OUTPUT
AS
BEGIN
       SET NOCOUNT ON
       BEGIN TRY
            BEGIN TRAN

            DECLARE @NumeroArchivo INT
            DECLARE @IntentosNotificacion INT

            SELECT @IntentosNotificacion = ISNULL(NumIntentosNotificacion, 0) + 1
                  ,@pi_TipoNotificacion = TipoNotificacion
                  ,@po_NotElecId = NotElecId
            FROM NotificacionElectronica_Personas
            WHERE 
                AsuntoNeunId = @pi_AsuntoNeunId
                AND SintesisOrden = @pi_SintesisOrden
                AND PersonaId = @pi_PersonaId

            UPDATE NotificacionElectronica WITH(ROWLOCK)
            SET  RegistroEmpleadoId = @pi_EmpleadoId
                ,FechaActualiza =GETDATE()                
            WHERE AsuntoNeunId = @pi_AsuntoNeunId
            AND SintesisOrden = @pi_SintesisOrden
            AND CatOrganismoId = @pi_CatOrganismoId
            AND StatusReg = 1

            UPDATE
            NotificacionElectronica_Personas 
            SET
                 TipoConstanciaId = @pi_TipoAcuse
                ,HoraNotificacion = CONVERT(VARCHAR(8),@pi_FechaNotificacion,108)
                ,TipoNotificacion = @pi_TipoNotificacion
                ,FechaNotificacion = @pi_FechaNotificacion
                ,EstatusNotificacionJL = CASE WHEN @pi_FechaNotificacion IS NULL THEN NULL ELSE 1 END
                ,NotificacionElectronicaJL = CASE @pi_TipoNotificacion WHEN 3 THEN 4157 ELSE NULL END
                ,NumIntentosNotificacion = @IntentosNotificacion
                ,FechaNotificacionCitatorio = @pi_FechaNotificacionCitatorio
                ,SintesisCitatorio = @pi_SintesisCitatorio
            WHERE 
                AsuntoNeunId = @pi_AsuntoNeunId
                AND SintesisOrden = @pi_SintesisOrden
                AND PersonaId = @pi_PersonaId
			  

            SELECT @NumeroArchivo = (ISNULL( (SELECT TOP 1 CONVERT(INT, RIGHT(REPLACE(nep.NombreArchivo, SUBSTRING(nep.NombreArchivo, CHARINDEX('.', nep.NombreArchivo) , LEN(nep.NombreArchivo)), ''), 2)) 
            FROM NotificacionElectronica_Personas nep with(nolock) INNER JOIN NotificacionElectronica_Archivos nea with(nolock) ON nep.NotElecId = nea.NotElecId
            WHERE nep.AsuntoNeunId = @pi_AsuntoNeunId AND nep.SintesisOrden = @pi_SintesisOrden 
                AND ISNULL(nep.PersonaId, 0) = @pi_PersonaId), 0)) + 1  

            SET @po_NombreArchivo = dbo.fnPonCeros(CAST(@pi_CatOrganismoId AS VARCHAR(50)), 4)
                    + dbo.fnPonCeros(CAST(@pi_AsuntoNeunId AS VARCHAR(50)), 12)
                    + dbo.fnPonCeros(CAST(@pi_SintesisOrden AS VARCHAR(50)), 4)
                    + dbo.fnPonCeros(CAST(@pi_SintesisOrden AS VARCHAR(50)), 4)
                    + [dbo].[fnPonCeros](CAST(@pi_PersonaId AS VARCHAR(50)), 12)
                    + [dbo].[fnPonCeros](CAST(@NumeroArchivo AS VARCHAR(50)), 2)
       ------------------Termina Control PartesNotificacion------------------------------    
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




