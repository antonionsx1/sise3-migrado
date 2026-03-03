SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:  Saul Garcia
-- Create date:  29/01/2024
-- Description: Devuelve el oficio por el folio
-- EXEC [SISE3].[paActualizaEstadoOficio] 1494,'399/2023',6712
-- =============================================

CREATE OR ALTER PROC [SISE3].[paActualizaEstadoOficio]
(
	 @pi_GuidDocumento UNIQUEIDENTIFIER
	,@pi_IdRuta INT = NULL
    ,@pi_Nombre VARCHAR(100) = NULL
    ,@pi_Extension VARCHAR(5) = NULL
    ,@pi_Firmado BIT = 0 
    ,@pi_AsuntoNeunId BIGINT = NULL
    ,@pi_AsuntoDocumentoId INT = NULL
    ,@pi_AnexoParteId BIGINT = NULL
    ,@pi_CatOrganismoId INT = NULL
)
AS
BEGIN

    IF @pi_Firmado = 0 AND @pi_AsuntoNeunId IS NOT NULL AND @pi_AsuntoDocumentoId IS NOT NULL AND @pi_AnexoParteId IS NOT NULL AND @pi_CatOrganismoId IS NOT NULL
    BEGIN
        UPDATE [SISE3].[EstadoOficio]
        SET [kIdRuta] = ISNULL(@pi_IdRuta, [kIdRuta])
            ,[NombreArchivo] = ISNULL(@pi_Nombre, [NombreArchivo])
            ,[ExtensionDocumento] = ISNULL(@pi_Extension, [ExtensionDocumento])
            ,[Firmado] = @pi_Firmado
            ,[uGuid] = @pi_GuidDocumento
        WHERE AsuntoNeunId = @pi_AsuntoNeunId
        AND AsuntoDocumentoId = @pi_AsuntoDocumentoId
        AND ParteId = @pi_AnexoParteId
        AND CatOrganismoId = @pi_CatOrganismoId
    END
    ELSE
    BEGIN
        UPDATE [SISE3].[EstadoOficio]
        SET [kIdRuta] = ISNULL(@pi_IdRuta, [kIdRuta])
            ,[NombreArchivo] = ISNULL(@pi_Nombre, [NombreArchivo])
            ,[ExtensionDocumento] = ISNULL(@pi_Extension, [ExtensionDocumento])
            ,[Firmado] = @pi_Firmado
        WHERE uGuid = @pi_GuidDocumento
    END   
    
END

