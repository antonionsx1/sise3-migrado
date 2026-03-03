SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 25/08/2023 
-- Description: Registra nueva promoción 
-- Basado en: usp_EXPE_PromocionOficialiaIns y uspx_op_addPromocion
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--EXEC [SISE3].[piInsertaPromocion] 30301133 ,5645,'2023-08-24','09:00',2,2,1475828,500,10,11,18820,52936,'Desde query 8','sin ip',NULL ,6666
-- ============================================= 
CREATE OR ALTER PROCEDURE  [SISE3].[piInsertaPromocion]
( 
        @pi_AsuntoNeunId bigint, 
        @pi_TipoCuaderno int, 
        @pi_FechaPresentacion datetime, 
        @pi_HoraPresentacion varchar(8), 
        @pi_ClasePromocion int null, 
        @pi_ClasePromovente int null, 
        @pi_TipoPromovente int, 
        @pi_TipoContenido int, 
        @pi_NumeroCopias int, 
        @pi_NumeroAnexo int, 
        @pi_Secretario int, 
        @pi_RegistroEmpleadoId int, 
        @pi_Observaciones varchar(max), 
        @pi_IpUsuario nvarchar(50),
        @pi_OrigenPromocion int = NULL,
        @pi_NumeroRegistro int = NULL,
		@pi_Fojas INT, 
        @po_NumeroOrden int = NULL OUTPUT

) 
AS 
BEGIN 
		
		BEGIN TRY
                DECLARE @OrganismoId int
				DECLARE @Mesa [varchar] (15) 
				DECLARE @YearPromocion INT
				DECLARE @po_NombreArchivo VARCHAR(50) 
				DECLARE @po_NumeroConsecutivo INT 

				SET @YearPromocion = Year(@pi_FechaPresentacion)

                SET @OrganismoId = (SELECT a.CatOrganismoId FROM Asuntos a WITH(NOLOCK) WHERE a.AsuntoNeunId = @pi_AsuntoNeunId)

				IF EXISTS (SELECT NumeroRegistro FROM Promociones where CatOrganismoId = @OrganismoId AND StatusReg =1 and YearPromocion = YEAR(GETDATE()) AND NumeroRegistro = @pi_NumeroRegistro)
					THROW 51000,'Error, número de registro ya existe',1;
				


					/*Se calcula Mesa*/
--				SELECT @Mesa = a.Descripcion 
--				FROM CatEmpleados e WITH (NOLOCK) 
--				INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
--				LEFT JOIN Areas a WITH(NOLOCK) ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
--				WHERE e.StatusRegistro = 1 
--				AND eo.StatusRegistro = 1 
--				AND eo.cargoId IN (14,18,19) 
--				AND e.EmpleadoId= @pi_Secretario
--				AND eo.CatOrganismoId = @OrganismoId

				/*Se calcula Mesa*/
            	SELECT @Mesa = a.Nombre
            	FROM CatEmpleados e WITH (NOLOCK) 
            	INNER JOIN dbo.Areas a WITH (NOLOCK) ON e.EmpleadoId = a.EmpleadoId AND a.CatOrganismoId = @OrganismoId 
            	WHERE e.StatusRegistro = 1 
            	AND a.StatusReg= 1 
            	AND e.EmpleadoId= @pi_Secretario
            	AND a.CatOrganismoId = @OrganismoId




				DECLARE @FechaExpediente DATETIME

	
				SELECT @FechaExpediente = FechaAlta
				FROM Asuntos
				WHERE AsuntoNeunId = @pi_AsuntoNeunId
					  AND CatOrganismoId = @OrganismoId
				--	  AND CatTipoAsuntoID = @pi_AsuntoId

	

				--IF CAST(@pi_FechaPresentacion AS DATE) < CAST(@FechaExpediente AS DATE)
				--	THROW 51000,'Fecha de presentación de promoción no puede ser inferior a fecha de expediente',1;



                EXEC usp_EXPE_PromocionOficialiaIns 
                        @pi_AsuntoNeunId, 
                        1,
                        @OrganismoId, 
                        0, 
                        @pi_TipoCuaderno, 
                        @pi_NumeroRegistro, 
                        @pi_FechaPresentacion, 
                        @pi_HoraPresentacion, 
                        @pi_ClasePromocion, 
                        @pi_ClasePromovente, 
                        @pi_TipoPromovente, 
                        @pi_TipoContenido, 
                        @pi_Observaciones, 
                        @pi_NumeroCopias, 
                        @pi_NumeroAnexo, 
                        NULL, 
                        NULL, 
                        @pi_Secretario, 
                        @pi_RegistroEmpleadoId, 
                        0, 
                        0, 
                        @pi_Observaciones 
                        ,0 
                        ,@pi_IpUsuario 
                        ,@Mesa
						,NULL
                        ,@po_NumeroOrden OUTPUT 
				


				EXEC [SISE3].[piInsertaArchivoPromocion] @pi_AsuntoNeunId,@YearPromocion,@OrganismoId,@pi_RegistroEmpleadoId,@po_NumeroOrden,@pi_Fojas,@pi_OrigenPromocion,@po_NombreArchivo OUT,@po_NumeroConsecutivo OUT

        END TRY
        BEGIN CATCH
                EXECUTE usp_GetErrorInfo; 
        END CATCH
		 SET NOCOUNT OFF
END

