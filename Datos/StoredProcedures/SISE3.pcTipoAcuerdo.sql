SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		GGHH
-- Create date: 30/06/2024
-- Description:	Obtiene los tipos de acuerdo
-- EXEC SISE3.pcTipoAcuerdo 2
-- Modificación: SBGE 08/11/2024 Se crea consulta para obtener los Tipo de acuerdo por etapa procesal para UGIRA

-- =============================================
CREATE  PROCEDURE [SISE3].[pcTipoAcuerdo]
	@pi_CatTipoAsuntoId INT,
	@pi_EtapaProcesalId INT=null

AS
BEGIN
	if (@pi_CatTipoAsuntoId!=137)-- and @pi_CatTipoAsuntoId!=138 and @pi_CatTipoAsuntoId!=139 and @pi_CatTipoAsuntoId!=140)
	BEGIN 
		SELECT	IdTipoAcuerdo = t.kIdTipoAcuerdo,
				TipoAcuerdo = t.sTipoAcuerdo
		FROM SISE3.Cat_TipoAcuerdo t
		INNER JOIN SISE3.REL_TipoAcuerdoTipoAsunto tt ON t.kIdTipoAcuerdo = tt.fkIdTipoAcuerdo 
		WHERE t.bStatusReg = 1 
		AND tt.bStatusReg=1
		AND tt.fkIdTipoAsunto = @pi_CatTipoAsuntoId
		AND t.bGeneraProyecto = 1
		ORDER BY 1 

	END
	ELSE
	BEGIN
		SELECT	IdTipoAcuerdo = t.kIdTipoAcuerdo,
				TipoAcuerdo = t.sTipoAcuerdo
		FROM SISE3.Cat_TipoAcuerdo t
		INNER JOIN SISE3.REL_TipoAcuerdoTipoAsunto tt ON t.kIdTipoAcuerdo = tt.fkIdTipoAcuerdo 
		WHERE t.bStatusReg = 1  
		AND tt.bStatusReg=1
		AND tt.fkIdTipoAsunto = @pi_CatTipoAsuntoId
		AND t.fkIdEtapaProcesal=@pi_EtapaProcesalId
		AND t.bGeneraProyecto = 1
		ORDER BY 1 
	END
END
