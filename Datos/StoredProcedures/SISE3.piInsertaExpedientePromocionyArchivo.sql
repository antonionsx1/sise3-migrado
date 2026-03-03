SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Christian Araujo - MS
-- Alter date: 28/08/2023 
-- Description: Registra un nuevo expediente, promoción y archivo de promoción
-- Basado en: usp_EXPE_PromocionOficialiaIns y uspx_op_addPromocion, uspx_addAsunto y uspx_op_addDocumento
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--EXEC [SISE3].[[piInsertaExpedientePromocionyArchivo]] 30301133 ,5645,'2023-08-24','09:00',2,2,1475828,500,10,11,18820,52936,'Desde query 8','sin ip',NULL ,6666
-- ============================================= 
CREATE OR ALTER PROCEDURE [SISE3].[piInsertaExpedientePromocionyArchivo]
	(
	--Parametros para expediente
	@pi_CatOrganismoId [int]  ,					-- Parametro que contiene el Identificador de organismmo para el asunto 
	@pi_CatTipoAsuntoId [int]  ,				-- Parametro que contiene el Identificador del Tipo Asunto
	@pi_NumeroOCC [varchar](50)  ,				-- Parametro para el Numero que se asigna a este expediente en OCC
	@pi_NoExpediente [varchar](50),		-- Parametro para el Numero de Expediente que se asigna al Asunto
	@pi_EmpleadoId [bigint],					--Identificador del empleado que creo el expediente
	@pi_TipoProcedimiento [int]	= null,
	--Parametros para Promocion
	--@pi_AsuntoNeunId bigint, --Se obtiene de la creación del expediente
        @pi_TipoCuaderno int, 
        @pi_FechaPresentacion datetime, 
        @pi_HoraPresentacion varchar(8), 
        @pi_ClasePromocion int=NULL, 
        @pi_ClasePromovente int=NULL, 
        @pi_TipoPromovente int=NULL, 
        @pi_TipoContenido int, 
        @pi_NumeroCopias int, 
        @pi_NumeroAnexo int=NULL, 
        @pi_Secretario int=NULL, 
        --@pi_RegistroEmpleadoId int, Se obtiene con @pi_Empleadoid
        @pi_Observaciones varchar(max), 
        @pi_IpUsuario nvarchar(50),
        @pi_OrigenPromocion int = NULL,
        @pi_NumeroRegistro int = NULL,
        @po_NumeroOrden int = NULL OUTPUT,
		--Parametros para PromocionArchivos
		@po_AsuntoNeunId bigint = NULL OUTPUT,
		--@pi_AsuntoNeunId bigint, Se obtiene de la creación del expediente
        --@pi_YearPromocion int,
        --@pi_NumeroOrden int,
        --@pi_RegistroEmpleadoId int,  Se obtiene con @pi_Empleadoid
        --@pi_Clase int,
        --@pi_Descripcion int,
        --@pi_Caracter int,
        @po_NombreArchivo varchar(50) output,
        @po_NumeroConsecutivo int output,
        --@pi_Origen int,
		@pi_fojas smallint = NULL
	)
AS
BEGIN
	/*Se ejecuta la creación del Expediente*/


	DECLARE @CatMateriaId [smallint]
	DECLARE @AsuntoNeunId [bigint]
	DECLARE	@AsuntoId [int]
	DECLARE @YearPromocion int
	DECLARE @po_AsuntoId [int] 
	DECLARE @Mesa [nvarchar] (15) 
	
	SET @pi_NumeroOCC = dbo.fnPonCeros(@pi_NumeroOCC,11) 
	SET @pi_TipoProcedimiento = ISNULL(@pi_TipoProcedimiento,0)
	SET @YearPromocion = YEAR(@pi_FechaPresentacion)
	
	SELECT @CatMateriaId = CatMateriaId 
	FROM OrganismosTipoAsuntoMaterias
	WHERE CatTipoAsuntoId = @pi_CatTipoAsuntoId
	AND CatOrganismoId = @pi_CatOrganismoId 		
	
	
	--IF NOT EXISTS (SELECT AsuntoNeunId from Asuntos where AsuntoNeunId = @po_AsuntoNeunId AND NumeroOCC = @pi_NumeroOCC and CatOrganismoId = @pi_CatOrganismoId)
	--BEGIN
		
	--END
		--IF CAST(@pi_FechaPresentacion AS DATE) < CAST(GETDATE() AS DATE)
		--THROW 51000,'Fecha de presentación de promoción no puede ser inferior a fecha de expediente',1;
	


	
		BEGIN TRY
				--Se crea expediente
				if Exists (
                             select AsuntoAlias  
                             from Asuntos  with(nolock)
                             where CatMateriaId = @CatMateriaId and 
                             CatOrganismoId =  @pi_CatOrganismoId and 
                             CatTipoAsuntoId = @pi_CatTipoAsuntoId and 
                             AsuntoAlias = @pi_NoExpediente and
                             CatTipoProcedimiento =  @pi_TipoProcedimiento
                             and StatusReg  = 1) 
                  
				THROW 51000,'Ya existe el Número de expediente para este organismo, Materia y Tipo de Asunto',1;
                        --exec usp_GetErrorCustomInfo 'Ya existe un expediente para este organismo'
                       -- RAISERROR ('Ya existe el Numero de expediente para este organismo, Materia y Tipo de Asunto', -- Texto del Mensaje
                       --            16, -- Severity
                                   --1     -- State
                                   
                        --return  -- Si existe un expediente de la Materia, Organismo, Tipo de Asunto y NoExpediente, sale del procedimiento Almacenado                    
                  
				Declare @MaxAsuntoNeunId bigint, @MaxAsuntoId int, @NumeroAlias int
                  
                  --set @po_AsuntoNeunId = (select  ISNULL(max(AsuntoNeunId), 1) + 1 from AsuntosNeun )
                  
                  
                  
                  set @NumeroAlias = (select dbo.fnAliasaNumero(@pi_NoExpediente))
                  
                  Set @po_AsuntoId = 1--(Select IsNull(Max(AsuntoId), 0) + 1 from Asuntos with(nolock) where AsuntoNeunId = @po_AsuntoNeunId )
                  
                  INSERT INTO Asuntos with(rowlock) ( 
                             [AsuntoId]
                             ,[CatMateriaId]
                             ,[CatOrganismoId]
                             ,[CatTipoAsuntoId]
                             ,[NumeroOCC]
                             ,[AsuntoAlias]
                             ,[AsuntoNumeroAnterior] -- Campo que contiene el Numero de Neun en el Sistema Anterior
                             ,[AsuntoNeunPadre]           -- Campo que contendra el Neun Relacionado con Este Asunto Cuando Se crea el registro su Valor por defecto es 0 (Cero)
                             ,[AsuntoStatus]              -- Campo para controlar los diferentes Estados del Asunto 2 = Se genera Asunto por primera vez 1 = se guarda los detalles del Asunto
                             ,[FechaAlta]
                             ,[FechaBaja]
                             ,[StatusReg]
                             ,[CatTipoProcedimiento]
                             ,[Empleadoid]
                             ,[NumeroAlias]
                              )
                  values( 
							 1,
							 --@po_AsuntoId,
                             @CatMateriaId   ,
                             @pi_CatOrganismoId   ,
                             @pi_CatTipoAsuntoId  ,
                             @pi_NumeroOCC   ,
                             @pi_NoExpediente  ,
                             0, --@pi_AsuntoNumeroAnterior ,
                             0, -- Valor por defecto para el NeunPadre
                             2, -- Valor por defecto para el Estado del Asunto y la captura del Detalle
                             GETDATE(),
                             null, 
                             1,
                             @pi_TipoProcedimiento,
                             @pi_Empleadoid,
                             @NumeroAlias )
                             
                             
                set @po_AsuntoNeunId =SCOPE_IDENTITY() 
                INSERT INTO AsuntosNeun with(rowlock) (AsuntoNeunId) values (@po_AsuntoNeunId)  
				SET @AsuntoNeunId = @po_AsuntoNeunId
				/*
				EXEC usp_AsuntosIns 
				@CatMateriaId,
				@pi_CatOrganismoId,
				@pi_CatTipoAsuntoId,
				@pi_NumeroOCC,
				@pi_NoExpediente,
				@pi_TipoProcedimiento,
				@pi_EmpleadoId,
				@AsuntoNeunId OUTPUT,
				@AsuntoId OUTPUT
				SET @po_AsuntoNeunId = @AsuntoNeunId
				*/
                DECLARE @OrganismoId int
                SET @OrganismoId = (SELECT a.CatOrganismoId FROM Asuntos a WITH(NOLOCK) WHERE a.AsuntoNeunId = @AsuntoNeunId)

				IF EXISTS (SELECT NumeroRegistro FROM Promociones where CatOrganismoId = @OrganismoId AND StatusReg =1 and YearPromocion = @YearPromocion AND NumeroRegistro = @pi_NumeroRegistro)
				THROW 51000,'Error, número de registro ya existe',1;
				
				/*Se calcula Mesa*/
				SELECT @Mesa = a.Descripcion
				--FROM CatEmpleados e WITH (NOLOCK) 
				--INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) ON e.EmpleadoId = eo.EmpleadoId 
				FROM dbo.Areas a WITH(NOLOCK)
                WHERE a.StatusReg = 1 
				--AND eo.StatusRegistro = 1 
				--AND eo.cargoId IN (14,18,19) 
				AND a.EmpleadoId= @pi_Secretario
				AND a.CatOrganismoId = @pi_CatOrganismoId
				

				/*Se ejecuta la creación de la promoción*/
                EXEC usp_EXPE_PromocionOficialiaIns 
                        @AsuntoNeunId, 
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
                        @pi_EmpleadoId, 
                        0, 
                        0, 
                        @pi_Observaciones 
                        ,0 
                        ,@pi_IpUsuario 
                        --,@pi_OrigenPromocion
						,@Mesa
						,NULL
                        ,@po_NumeroOrden OUTPUT 
				
                       

		END TRY
        BEGIN CATCH
                EXECUTE usp_GetErrorInfo; 
        END CATCH

	/*Se ejecuta la creación del ArchivoPromocion
		y se inserta con estado -1 que significa archivo no asociado*/
	SET NOCOUNT ON
                --DECLARE @CatOrganismoId INT
                --DECLARE @AsuntoId INT
                DECLARE @NumeroRegistro INT
                DECLARE @pi_ClaseSISE1 INT
                DECLARE @pi_DescripcionSISE1 INT 
                DECLARE @pi_CaracterSISE1 INT
                DECLARE @pi_NumeroConsecutivo INT = null
                DECLARE @pi_PromoFileIdentificador UNIQUEIDENTIFIER = null      
                DECLARE @insertaAnexo INT = 1
				DECLARE @ClaseAnexo INT =0
                
                --SET @YearPromocion = YEAR(@pi_FechaPresentacion)
                --SET @pi_ClaseSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(1,@pi_Clase)
                --SET @pi_DescripcionSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(2,@pi_Descripcion)
                --SET @pi_CaracterSISE1=dbo.fnClaseDescripcionCaracterSISE2aSISE1(3,@pi_Caracter)
                                
                SELECT--  @CatOrganismoId = a.CatOrganismoId,
                                @AsuntoId = a.AsuntoId,
                                @NumeroRegistro = p.NumeroRegistro
                FROM Asuntos a 
                INNER JOIN Promociones p ON a.AsuntoNeunId = p.AsuntoNeunId
                WHERE a.AsuntoNeunId = @AsuntoNeunId
                AND p.YearPromocion = @YearPromocion
                AND p.NumeroOrden = @po_NumeroOrden
                
                                select top 1 * from SISE3.REL_RolEmpleadoXOrganismo
                --QUE EL EMPLEADO PERTENEZCA AL ORGANISMOS DEL ASUNTO
                IF NOT EXISTS(  SELECT TOP 1 IdCatEmpleado 
                                                --FROM EmpleadoOrganismo 
												FROM SISE3.REL_RolEmpleadoXOrganismo
                                                WHERE  IdCatEmpleado= @pi_EmpleadoId
                                                AND bStatus = 1 
                                                AND IdOrganismo IN(@pi_CatOrganismoId,3))
 BEGIN 
                        SET @insertaAnexo = 0--CON CERO INDICAMOS QUE EL USUARIO NO PERTENECE AL ORGANO DEL ASUNTO POR LO TANTO NO INSERTA 
 END


				
				SELECT @ClaseAnexo = 1
				FROM PromocionArchivos With(NoLock) 
				WHERE AsuntoNeunId =@AsuntoNeunId 
				AND AsuntoId=@AsuntoId 
				AND YearPromocion =@YearPromocion 
				AND NumeroRegistro =@NumeroRegistro 
				AND NumeroOrden = @po_NumeroOrden
				AND ClaseAnexo = 0

			BEGIN TRY

				IF @ClaseAnexo = 0
				BEGIN

					SET @pi_NumeroConsecutivo = IIF(@pi_NumeroConsecutivo=0, @po_NumeroConsecutivo, @pi_NumeroConsecutivo)
				
					SET @pi_NumeroConsecutivo=(SELECT isnull(max(Consecutivo),0) + 1 as nroConsecutivo
						--SET @pi_NumeroConsecutivo=(SELECT IIF(MAX(CONSECUTIVO) IS NULL,0,MAX(CONSECUTIVO)+1)
																						FROM PromocionArchivos With(NoLock) 
																						WHERE AsuntoNeunId =@AsuntoNeunId 
																						AND AsuntoId=@AsuntoId 
																						AND YearPromocion =@YearPromocion 
																						AND NumeroRegistro =@NumeroRegistro 
																						AND NumeroOrden = @po_NumeroOrden)
					SET @po_NumeroConsecutivo = @pi_NumeroConsecutivo
             
						--El nombre se forma: 4 (corid) + 12 (Asuid) + 6 (Orden) + 6 (Registro)+ 3(Consecutivo) + 0(Significa que es capturada desde SISE 2.0)
						DECLARE @file VARCHAR(250)
						SET @file =     dbo.fnPonCeros(CAST(@pi_CatOrganismoId AS VARCHAR(50)),4)
												+ dbo.fnPonCeros(CAST(@AsuntoNeunId AS VARCHAR(50)),12) 
												+ dbo.fnPonCeros(CAST(@po_NumeroOrden AS VARCHAR(50)),6)
												+ dbo.fnPonCeros(CAST(@NumeroRegistro AS VARCHAR(50)),6) 
												+ dbo.fnPonCeros(CAST(@pi_NumeroConsecutivo AS VARCHAR(50)),3)
												+ CAST(@pi_OrigenPromocion AS VARCHAR(1))
												+ '.pdf'
                                        
						SET @po_NombreArchivo=@file
                
						IF (@insertaAnexo = 1)
                                BEGIN
                                        INSERT INTO PromocionArchivos WITH(ROWLOCK)
                                         (CatOrganismoId
                                         ,AsuntoNeunId
                                         ,AsuntoId                                       
                                         ,NumeroOrden
                                         ,NumeroRegistro                                         
                                         ,YearPromocion                          
                                         ,Consecutivo           
                                         ,Origen                         
                                         ,NombreArchivo
                                         ,ClaseAnexo
                                         ,DescripcionAnexo
                                         ,CaracterAnexo
                                         ,StatusArchivo
                                         ,FechaAlta                             
                                         ,RegistroEmpleadoSISEId
                                         ,EstatusArchivo
										 ,Fojas
                                         )
                                        VALUES
                                         (@pi_CatOrganismoId
                                         ,@AsuntoNeunId
                                         ,@AsuntoId
                                         ,@po_NumeroOrden
                                         ,@NumeroRegistro
                                         ,@YearPromocion                                      
                                         ,@pi_NumeroConsecutivo 
                                         ,@pi_OrigenPromocion --ORIGEN 0:SISE, 1:FESE, 1:SL
                                         ,CAST(@file AS VARCHAR(50))
                                         ,0
                                         ,5031
                                         ,0
                                         ,-1
                                         ,GETDATE()
                                         ,ISNULL(@pi_EmpleadoId,0)      
                                         ,0-- CUANDO EL DOCUMENTO ESTE EN LA SAN, FU LO CAMBIA A 1
                                         ,@pi_fojas
                                         )
                                         
                                        SET @pi_PromoFileIdentificador = (SELECT PromoFileIdentificador 
                                         FROM PromocionArchivos with(rowlock) 
                                         WHERE CatOrganismoId = @pi_CatOrganismoId 
                                         AND AsuntoNeunId = @AsuntoNeunId 
                                         AND AsuntoId = @AsuntoId 
                                         AND NumeroOrden = @po_NumeroOrden 
                                         AND NumeroRegistro = @NumeroRegistro 
                                         AND YearPromocion = @YearPromocion
                                         AND Consecutivo = @pi_NumeroConsecutivo 
                                         AND Origen = @pi_OrigenPromocion--0 
                                         AND StatusArchivo = 1)
                                        
                                  
                                        EXEC usp_Promocion_Bitacora @pi_CatOrganismoId,@YearPromocion,@po_NumeroOrden,@pi_OrigenPromocion,6--el 6 es el origen(SISE) y el 3 indica que es una alta en tabla promocionArchivos de un anexo
                                END
                                ELSE
                                BEGIN
                                         RAISERROR ('El usuario que intenta insertar la promoción no es válido para el expediente', -- Texto del Mensaje
                                                16, -- Severity
                                                1       -- State
                                                );
                                END
						END
                END TRY
                BEGIN CATCH
                 -- EJECUTO ROLLBACK SOLO EN CASO DE ERROR
                        IF @@TRANCOUNT > 0
                                ROLLBACK TRANSACTION;
                        -- EJECUTA LA RUTINA DE RECUPERACION DE ERRORES.
                        EXECUTE dbo.usp_GetErrorInfo;
                END CATCH;
         -- COMPLETO MI TRANSACCION
                IF @@TRANCOUNT > 0
                        COMMIT TRANSACTION;
                        --IF (@CatOrganismoId IN (949,964,981,982,1275,1277,1281) and(@insertaAnexo=1))
                        --BEGIN
                        --EXEC sisecjfdb02.sise.dbo.usp_EXPE_PromocionAnexosArchivoSISE1Ins @CatOrganismoId,@pi_AsuntoNeunId,@pi_NumeroOrden,@NumeroRegistro,@pi_YearPromocion,@pi_NumeroConsecutivo,@file,@pi_ClaseSISE1,@pi_DescripcionSISE1,@pi_CaracterSISE1,@pi_PromoFileIdentificador
                        --END
                SET NOCOUNT OFF

END
