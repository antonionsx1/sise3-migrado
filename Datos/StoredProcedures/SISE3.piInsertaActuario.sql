SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 10/01/2024
-- Description: Obtiene el catalogo de zonas y actuario por organismo
-- EXEC [SISE3].[piInsertaActuario]  30315077, 6, 45491, 171520994
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaActuario]
(
    @pi_AsuntoNeunId INT,
    @pi_AsuntoId INT,
    @pi_ActuarioId INT,
    @pi_Parte INT
)

AS

    UPDATE NotificacionElectronica_Personas
    SET ActuarioId = @pi_ActuarioId
    WHERE AsuntoNeunId = @pi_AsuntoNeunId
    AND SintesisOrden = @pi_AsuntoId
    AND PersonaId = @pi_Parte
    AND StatusReg = 1