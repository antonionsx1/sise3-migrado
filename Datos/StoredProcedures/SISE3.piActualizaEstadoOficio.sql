SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  Christian Araujo - MS 
-- Create date: 10/01/2024
-- Description: Obtiene el catalogo de zonas y actuario por organismo
-- EXEC [SISE3].[piActualizaEstadoOficio]  30315077, 107, 180, 171520824, 'oficio000001','\\10.100.126.204\desa_fs\Promociones8', 'Oficio20241','pdf', '0000-0000-0000-0000'
-- ================================
CREATE OR ALTER PROCEDURE SISE3.piActualizaEstadoOficio (@pi_AsuntoNeunId INT
										,@pi_AsuntoDocumentoId INT
										,@pi_AnexoParteId INT
										,@pi_CatOrganismoId INT
										,@pi_NombreDocumento VARCHAR(255)
										,@pi_RutaAnexo VARCHAR (255)
										,@pi_NombreArchivo VARCHAR (50)
										,@pi_ExtensionDocumento VARCHAR(4)
										,@pi_GuidDocumento uniqueidentifier)
AS
BEGIN
	
	UPDATE Anexos
	SET NombreDocumento = @pi_NombreDocumento
	,RutaAnexo= @pi_RutaAnexo
	,NombreArchivo = @pi_NombreArchivo
	,ExtensionDocumento = @pi_ExtensionDocumento
	,uGuidDocumento = @pi_GuidDocumento
	WHERE AsuntoNeunId = @pi_AsuntoNeunId
	AND AsuntoDocumentoId = @pi_AsuntoDocumentoId
	AND AnexoParteId = @pi_AnexoParteId
	AND CatOrganismoId = @pi_CatOrganismoId
END