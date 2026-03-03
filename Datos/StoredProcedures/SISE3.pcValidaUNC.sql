SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 28/11/2023 
-- Description: Verifica si un Organismo posee asignación a la Unidad de Notificación Comun UNC
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--EXEC [SISE3].[pcValidaUNC] 180
-- ============================================= 
CREATE OR ALTER PROCEDURE SISE3.pcValidaUNC (
		@pi_CatOrganismoId INT
		,@po_UNCEstado INT OUTPUT)
AS
BEGIN
	IF EXISTS(SELECT IdUNC FROM SISE3.UNCXOrganismo WHERE CatOrganismoId = @pi_CatOrganismoId and StatusReg = 1)
	BEGIN
		SET @po_UNCEstado = 1
	END
	ELSE BEGIN
		SET @po_UNCEstado = 0
	END
END