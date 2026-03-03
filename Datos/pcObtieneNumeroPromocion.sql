-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 24/08/2023
-- Description: Obtiene el siguiente numero de promocion disponible para el año en curso
-- EXEC [SISE3].[pcObtieneNumeroPromocion] 1494
-- ==
==============================
CREATE PROCEDURE [SISE3].[pcObtieneNumeroPromocion]  (
	@pi_CatOrganismoId int,
@pi_StatusReg int = 1)
AS  
BEGIN  
    SELECT ISNULL(MAX(NumeroRegistro),0) + 1 AS Registro FROM Promociones
    WHERE CatOrganismoId = @pi_CatOrganismoId 
	AND YearPromocion
 = YEAR(GETDATE())  AND StatusReg = @pi_StatusReg
END;
