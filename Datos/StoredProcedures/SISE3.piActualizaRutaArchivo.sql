SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: Saul Garcia - MS
-- Alter date: 25/01/2024
-- Objetivo: Actualiza la ruta histórica encontrada al archivo
-- EXEC SISE3.piActualizaRutaArchivo 30301133, 1,2023,4
-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[piActualizaRutaArchivo]
(
@pi_AsuntoNeunId BIGINT NULL,
@pi_YearPromocion INT NULL, 
@pi_NumeroOrden INT NULL,  --
@pi_catIdOrganismo INT,
@pi_Origen INT NULL, 
@pi_TipoModulo INT, --1 Promocion 2 Acuerdo
@pi_AsuntoDocumentoId INT NULL,
@pi_kIdRuta INT NULL
)
AS
BEGIN

	IF @pi_TipoModulo = 1 
	BEGIN 
		MERGE INTO REL_ArchivosRutaHistorica AS t
		USING (SELECT  @pi_AsuntoNeunId as AsuntoNeunId
					  ,@pi_YearPromocion as YearPromocion
					  ,@pi_catIdOrganismo as CatOrganismoId
                      ,@pi_NumeroOrden as NumeroOrden
					  ,@pi_kIdRuta as idRuta) AS s
			ON (t.AsuntoNeunId = s.AsuntoNeunId 
				AND t.YearPromocion = s.YearPromocion
				AND t.CatOrganismoId = s.CatOrganismoId
                AND t.NumeroOrden = s.NumeroOrden)
		WHEN MATCHED THEN
			UPDATE SET idRuta = @pi_kIdRuta, fechaModificacion = GETDATE()
		WHEN NOT MATCHED THEN
			INSERT (AsuntoNeunId, YearPromocion, CatOrganismoId, idRuta, fechaAlta, fechaModificacion, NumeroOrden)
			VALUES (s.AsuntoNeunId, s.YearPromocion, s.CatOrganismoId, s.idRuta, GETDATE(), GETDATE(), @pi_NumeroOrden);
	END
	ELSE IF @pi_TipoModulo = 2
	BEGIN 
		UPDATE AsuntosDocumentos
		SET TipoRuta = @pi_kIdRuta
		WHERE AsuntoNeunId=@pi_AsuntoNeunId 
			AND NombreArchivo IS NOT NULL
			AND AsuntoDocumentoId=@pi_AsuntoDocumentoId 			  
			AND StatusReg IN (1,2)
	END

END
