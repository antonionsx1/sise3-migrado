SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mario Alejandro Santiago de la Cruz
-- Create date: 11/11/2023
-- Description:	Obtiene el AreaId a partir del empleadoId  en la tabla Areas
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[uspx_getArea]
(
@pi_AsuntoNeunId int  =null,
@pi_EmpleadoId int  =null
)	
AS
BEGIN

     SELECT TOP 1 AreaId FROM Areas 
	 WHERE EmpleadoId = @pi_EmpleadoId 
END
