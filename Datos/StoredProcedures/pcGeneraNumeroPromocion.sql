USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcGeneraNumeroPromocion]    Script Date: 12/1/2023 6:16:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 24/08/2023
-- Description: Obtiene el [pcGeneraNumeroPromocion] numero de promocion disponible para el año en curso
-- EXEC [SISE3].[pcGeneraNumeroPromocion] 180
-- ================================
CREATE PROCEDURE [SISE3].[pcGeneraNumeroPromocion]  (
	@pi_CatOrganismoId int,
@pi_StatusReg int = 1)
AS  
BEGIN  
    SELECT ISNULL(MAX(NumeroRegistro),0) + 1 AS Registro 
	FROM Promociones
    WHERE CatOrganismoId = @pi_CatOrganismoId 
	AND YearPromocion = YEAR(GETDATE())  
	AND StatusReg = @pi_StatusReg
END;
GO

