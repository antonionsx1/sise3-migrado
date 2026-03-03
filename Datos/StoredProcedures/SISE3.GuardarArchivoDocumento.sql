USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[GuardarArchivoDocumento]    Script Date: 11/22/2024 3:41:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Autor: Anabel Gonzalez
-- Fecha de creación : 24/10/2024
-- Descripción:	Inserta un archivo de documento
-- =============================================
ALTER PROCEDURE [SISE3].[GuardarArchivoDocumento]
(
 @pi_EsUpdate BIT 
,@pi_AsuntoNeunId BIGINT 
,@pi_PersonaId BIGINT
,@pi_NoBloque INT 
,@pi_TipoDocumentoId INT
,@pi_Clase INT 
,@pi_Descripcion INT
,@pi_CaracterExhibe INT
,@pi_EmpleadoId INT
,@pi_NombreArchivoUsuario NVARCHAR(255)
,@pi_catIdOrganismo INT
,@pi_ExtensionArchivo NVARCHAR(50)
,@pi_NombreArchivo VARCHAR(50) = NULL
,@pi_OrdenArchivo INT = NULL
,@po_NombreArchivo NVARCHAR(50) OUTPUT 
,@po_Orden INT OUTPUT 
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ResultRow INT
	DECLARE @ResultUpdRow INT

	DECLARE @NumOrden INT
	SET @NumOrden=(SELECT ISNULL(MAX(Orden),0) + 1  nroMaxOrden 
				   FROM DocumentoArchivos WITH(NOLOCK)	
				   WHERE AsuntoNeunId= @pi_AsuntoNeunId 
				   AND PersonaId = @pi_PersonaId 
				   AND NoBloque = @pi_NoBloque 
				   AND TipoDocumentoId = @pi_TipoDocumentoId)


	DECLARE @file VARCHAR(250)

	SET @file=
				  dbo.fnPonCeros(CAST(@pi_catIdOrganismo AS VARCHAR(50)),4)+
				 (dbo.fnPonCeros(CAST(@pi_AsuntoNeunId AS VARCHAR(50)),12) 
				+ dbo.fnPonCeros(CAST(@pi_PersonaId AS VARCHAR(50)),12)
				+ dbo.fnPonCeros(CAST(@pi_NoBloque AS VARCHAR(50)),3) 
				+ dbo.fnPonCeros(CAST(@pi_TipoDocumentoId AS VARCHAR(50)),5)
				+ dbo.fnPonCeros(CAST(@NumOrden AS VARCHAR(50)),3) )
				+ @pi_ExtensionArchivo

	SET @po_NombreArchivo = @file
	SET @po_Orden = @NumOrden
		
		BEGIN TRY
			BEGIN TRAN		


			IF(@pi_EsUpdate = 1)
			BEGIN
				UPDATE DocumentoArchivos
				SET FechaBaja = GETDATE(),
				StatusReg = 0
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
				AND PersonaId = @pi_PersonaId
				AND NoBloque = @pi_NoBloque
				AND TipoDocumentoId = @pi_TipoDocumentoId
				AND Orden = @pi_OrdenArchivo
				SET @ResultUpdRow = @@ROWCOUNT

				IF(@ResultUpdRow > 0)
					BEGIN
						INSERT INTO DocumentoArchivos (AsuntoNeunId,PersonaId,NoBloque,TipoDocumentoId,Orden,Clase,Descripcion,CaracterExhibe,StatusReg,FechaAlta,EmpleadoId,NombreArchivo,NombreArchivoUsuario,EstatusArchivo)
					 VALUES
						(@pi_AsuntoNeunId,@pi_PersonaId,@pi_NoBloque,@pi_TipoDocumentoId,@NumOrden,@pi_Clase,@pi_Descripcion,@pi_CaracterExhibe,1,GETDATE(),@pi_EmpleadoId,@file,@pi_NombreArchivoUsuario,0)
						SET @ResultRow = @@ROWCOUNT
					END


			END
			ELSE
				BEGIN
				 	INSERT INTO DocumentoArchivos (AsuntoNeunId,PersonaId,NoBloque,TipoDocumentoId,Orden,Clase,Descripcion,CaracterExhibe,StatusReg,FechaAlta,EmpleadoId,NombreArchivo,NombreArchivoUsuario,EstatusArchivo)
					 VALUES
						(@pi_AsuntoNeunId,@pi_PersonaId,@pi_NoBloque,@pi_TipoDocumentoId,@NumOrden,@pi_Clase,@pi_Descripcion,@pi_CaracterExhibe,1,GETDATE(),@pi_EmpleadoId,@file,@pi_NombreArchivoUsuario,0)
						SET @ResultRow = @@ROWCOUNT
				END 	 

		SELECT @ResultRow
					
		END TRY
		BEGIN CATCH
		    -- Ejecuto ROLLBACK solo en caso de error
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			-- Ejecuta la rutina de recuperacion de errores.
			EXECUTE dbo.usp_GetErrorInfo;
		END CATCH;
	    -- Completo mi transaccion
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION;			
		SET NOCOUNT OFF
	END