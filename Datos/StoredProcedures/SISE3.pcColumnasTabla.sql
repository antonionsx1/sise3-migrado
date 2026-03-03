SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Erick Garcia de la Rosa
-- Create date: 15/01/2025
-- Description:	Obtiene las columnas de una base de datos
-- =============================================
CREATE PROCEDURE SISE3.pcColumnasTabla
	@pc_nombreTabla VARCHAR(100)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		c.colid AS IdColumna, 
		o.name AS NombreTabla,
		c.name AS NombreColumna
	FROM SYSOBJECTS o
	INNER JOIN SYSCOLUMNS c on o.id = c.id
	WHERE o.xtype = 'U' AND o.name=@pc_nombreTabla;
    
END
GO
