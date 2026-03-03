SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Sergio Orozco - MS 
-- Create date: 07/03/2024
-- Description: Asigna Actuario y tipo de notificaciones a varias partes
-- EXEC [SISE3].[piInsertaActuarioMasivo] 
-- @pi_AsuntoNeunId = 30326323,
-- @pi_SintesisOrden = 1,
-- @pi_ActuarioId = 1,
-- @pi_PartesNotificaciones = @pi_PartesNotificaciones
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaActuarioMasivo_dev]
(
    @pi_AsuntoNeunId BIGINT,
    @pi_SintesisOrden INT,
    @pi_ActuarioId BIGINT,
	-- Usuario que hace el cambio o asignacion denotario 
    @pi_EmpleadoID BIGINT,
    -- @pi_PartesNotificaciones
    -- Mandar (ParteId, TipoNotificacionID, TieneCOE)
    @pi_PartesNotificaciones [SISE3].[ParteNotificacion_type] READONLY --Datos de Partes y tipo de notificacion
)

AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY

        DECLARE @count INT;
        DECLARE @countCoe INT;

        SET @count = (SELECT COUNT(*) FROM @pi_PartesNotificaciones);
        SET @countCoe = (SELECT COUNT(*) FROM @pi_PartesNotificaciones where TieneCOE = 1);


        IF EXISTS (
            SELECT 1
            FROM SISE3.NotificacionElectronica_Personas_Pruebas n 
            INNER JOIN @pi_PartesNotificaciones p
            ON n.PersonaId = p.ParteId
            WHERE n.AsuntoNeunId = @pi_AsuntoNeunId
            AND n.SintesisOrden = @pi_SintesisOrden
            AND n.StatusReg = 1
            AND p.TipoNotificacionID IN (5, 11)
            AND n.TipoNotificacion <> p.TipoNotificacionID
        )
        BEGIN
            THROW 51000,'Error, No es posible asignar tipo oficio u oficio libre si el valor original no es oficio u oficio libre', 1;
        END

        IF EXISTS (
            SELECT 1
            FROM @pi_PartesNotificaciones p
            WHERE p.TieneCOE = 1
            AND p.TipoNotificacionID NOT IN (1, 5, 11)
        )
        BEGIN
            THROW 51000,'Error, No es posible asignar COE si el tipo de notificación no es Personal, Oficio u Oficio libre.', 1;
        END

        UPDATE n
        SET n.TipoNotificacion = p.TipoNotificacionID,
            n.ActuarioId = @pi_ActuarioId
        FROM SISE3.NotificacionElectronica_Personas_Pruebas n 
        INNER JOIN @pi_PartesNotificaciones p
        ON n.PersonaId = p.ParteId
        WHERE n.AsuntoNeunId = @pi_AsuntoNeunId
        AND n.SintesisOrden = @pi_SintesisOrden
        AND n.StatusReg = 1
        AND p.TipoNotificacionID IN (1,3,5,6,11,12);

        IF @@ROWCOUNT <> @count
            BEGIN
				THROW 51000,'Error, No todas las Partes presentes en tabla notificacion electronica personas. No se actualizaron las partes', 1;
            END

        IF EXISTS (
            SELECT 1
            FROM SISE3.NotificacionElectronica_Personas_Pruebas n
            INNER JOIN @pi_PartesNotificaciones p
            ON n.PersonaId = p.ParteId
            LEFT JOIN SISE3.REL_NotificacionCOE_Pruebas coe
            ON n.NotElecID = coe.fkIdNotElecId
            WHERE coe.fkIdAsuntoNEUNCOE IS NOT NULL
        )
        BEGIN
            THROW 51000, 'Error, No es posible eliminar COE cuando ya está asignada.', 1;
        END


    MERGE INTO SISE3.REL_NotificacionCOE_Pruebas AS Target
    USING (
        SELECT n.NotElecID, p.TieneCOE, coe.fkIdAsuntoNEUNCOE
        FROM SISE3.NotificacionElectronica_Personas_Pruebas n
        INNER JOIN @pi_PartesNotificaciones p
        ON n.PersonaId = p.ParteId
        LEFT JOIN REL_NotificacionCOE coe
        ON n.NotElecID = coe.fkIdNotElecId
    ) AS Source (NotElecID, TieneCOE, fkIdAsuntoNEUNCOE)
    ON Target.fkIdNotElecId = Source.NotElecID AND Target.iStatusReg = 1
    WHEN MATCHED AND Source.TieneCOE = 0 AND Source.fkIdAsuntoNEUNCOE IS NULL THEN 
        UPDATE SET Target.iStatusReg = 0
    WHEN NOT MATCHED BY TARGET AND Source.TieneCOE = 1 AND Source.fkIdAsuntoNEUNCOE IS NULL THEN 
        INSERT (fkIdNotElecId, iStatusReg) VALUES (Source.NotElecID, 1);



    COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

      EXECUTE usp_GetErrorInfo; 
      ROLLBACK TRANSACTION;

    END CATCH;

END;
