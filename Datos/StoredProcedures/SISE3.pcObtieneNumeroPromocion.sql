SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================  
-- Author:  Diana Quiroga - MS 
-- Create date: 28/09/2023
-- Description: Validar si el numero de promoción ya existe

-- EXEC [SISE3].[pcObtieneNumeroPromocion] 1494,1
-- ================================
CREATE OR ALTER PROCEDURE [SISE3].[pcObtieneNumeroPromocion]  (
	@pi_CatOrganismoId int,
	@pi_NumeroRegistro int,
	@pi_YearPromocion int)
AS  
BEGIN  
    IF EXISTS( SELECT TOP 1 NumeroRegistro
			   FROM Promociones
			   WHERE CatOrganismoId = @pi_CatOrganismoId 
			   AND YearPromocion = @pi_YearPromocion
			   AND NumeroRegistro = @pi_NumeroRegistro
			   AND StatusReg = 1)
	BEGIN 
		SELECT 1 as existe
	END
	ELSE
	BEGIN
		SELECT 0 as existe
	END
END