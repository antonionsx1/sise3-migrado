SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		Diana Quiroga Microsoft
-- Create date: 22/09/2023
-- Description:	Actualiza promoción 
-- Example: SELECT SISE3.EstatusPromocion( 10,1, NULL)
/* DECLARE @return_value int 
 EXEC SISE3.[paActualizaPromocion]  @pi_catIdOrganismo = 180, 
	@pi_AsuntoNeunId = 30314039,  
	@pi_TipoCuaderno = 11711,  
	@pi_FechaPresentacion = '2023-10-30',  
	@pi_HoraPresentacion= '11:07',
	@pi_ClasePromovente = 2,  
	@pi_TipoPromovente = 24312568,  
	@pi_TipoContenido = 2723,  
	@pi_NumeroCopias = 0,  
	@pi_NumeroAnexo = 0,  
	@pi_Secretario = 26459,  
	@pi_RegistroEmpleadoId = 6712, 
	@pi_NumeroFojasTomos = '0',
	@pi_Observaciones = '',
	@pi_IpUsuario='10.100.127.240' , 
	@pi_OrigenPromocion =4,  
	@pi_NumeroRegistro =103,  
	@pi_NumeroOrden = 90,
	@pi_YearPromocion = 2023,
	@pi_AsuntoNeunIdNuevo = null */
-- =============================================

CREATE procedure [SISE3].[paActualizaPromocion]  
(  
--DECLARE
	@pi_catIdOrganismo INT, 
	@pi_AsuntoNeunId BIGINT,  --Nuevo
	@pi_TipoCuaderno INT, 
	@pi_FechaPresentacion VARCHAR(50),  
	@pi_HoraPresentacion VARCHAR(8),   
	@pi_ClasePromovente INT,  
	@pi_TipoPromovente INT,  
	@pi_TipoContenido INT,  
	@pi_NumeroCopias INT,  
	@pi_NumeroAnexo INT,  
	@pi_Secretario INT,  
	@pi_RegistroEmpleadoId INT, 
	@pi_NumeroFojasTomos VARCHAR (100),  
	@pi_Observaciones VARCHAR(max),
	@pi_IpUsuario NVARCHAR(50) , 
	@pi_OrigenPromocion INT,  
	@pi_NumeroRegistro INT,  
	@pi_NumeroOrden INT,
	@pi_YearPromocion INT,
	@pi_AsuntoNeunIdNuevo  BIGINT = NULL

/*@pi_Contenido varchar(max),  
@pi_FechaEntrega varchar (50)
@pi_PersonaRecibe int, 
 
@pi_EstadoPromocion int,  
@pi_NumeroTomos int,  

@pi_SelectorRegistro bit  
@pi_Mesa nvarchar(15)=NULL*/

)  
AS  
BEGIN  

/*	SET @pi_catIdOrganismo = 1494
	SET @pi_AsuntoNeunId = 30313404
	SET @pi_TipoCuaderno = 5645
	SET @pi_FechaPresentacion= '04/09/2020'
	SET @pi_HoraPresentacion = '18:39:31'
	SET @pi_ClasePromovente = 1
	SET @pi_TipoPromovente =   171519576
	SET @pi_TipoContenido = 522
	SET @pi_NumeroCopias = 0
	SET @pi_NumeroAnexo = 0
	SET @pi_Secretario = 94042
	SET @pi_RegistroEmpleadoId = 6712
	SET @pi_NumeroFojasTomos = 0
	SET @pi_Observaciones = 4
	SET @pi_IpUsuario = 'as'
	SET @pi_OrigenPromocion =4
	SET @pi_NumeroRegistro = 50115
	SET @pi_NumeroOrden = 641
	SET @pi_YearPromocion = 2020*/
	SET NOCOUNT ON  
	
	DECLARE @pi_registroAnterior INT     
	DECLARE @Mesa VARCHAR(15) , @pi_AsuntoId INT , @actualizaAsuntoNeunId INT 
	DECLARE @FechaExpediente DATETIME

	SET @pi_AsuntoId = 1
	SET @actualizaAsuntoNeunId = 1
	
	SELECT @FechaExpediente = FechaAlta
	FROM Asuntos
	WHERE AsuntoNeunId = @pi_AsuntoNeunId
		  AND CatOrganismoId = @pi_catIdOrganismo
	--	  AND CatTipoAsuntoID = @pi_AsuntoId

	

	--IF CAST(@pi_FechaPresentacion AS DATE) < CAST(@FechaExpediente AS DATE)
	--	THROW 51000,'Fecha de presentación de promoción no puede ser inferior a fecha de expediente',1;

	SELECT @pi_registroAnterior = NumeroRegistro , @actualizaAsuntoNeunId = 0 
	FROM Promociones WITH(NOLOCK)  
	WHERE AsuntoId=@pi_AsuntoId 
		  AND AsuntoNeunId=@pi_AsuntoNeunId 
		  AND CatOrganismoId=@pi_catIdOrganismo  
		  AND YearPromocion=@pi_YearPromocion 
		  AND NumeroOrden=@pi_NumeroOrden  
		  AND OrigenPromocion=@pi_OrigenPromocion

	IF @pi_ClasePromovente = 3
	BEGIN 
		/*Se recalcula el tipo de promovente para autoridad judicial*/
		SELECT @pi_TipoPromovente = AutoridadJudicialId
		FROM AutoridadJudicial aj 
		LEFT JOIN CatEmpleados ea WITH(NOLOCK) 
			ON ea.EmpleadoId = aj.EmpleadoId
		WHERE ea.EmpleadoId = @pi_TipoPromovente
	END

	SELECT AsuntoNeunId=@pi_AsuntoNeunId, @pi_registroAnterior ,@actualizaAsuntoNeunId

	SELECT @Mesa = a.Descripcion 
	FROM CatEmpleados e WITH (NOLOCK) 
	INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) 
		ON e.EmpleadoId = eo.EmpleadoId 
	LEFT JOIN Areas a WITH(NOLOCK) 
		ON a.EmpleadoId = e.EmpleadoId AND a.CatOrganismoId = eo.CatOrganismoId
	WHERE e.StatusRegistro = 1 
		  AND eo.StatusRegistro = 1 
		  AND eo.cargoId IN (14,18,19) 
		  AND e.EmpleadoId= @pi_Secretario
		  AND eo.CatOrganismoId = @pi_catIdOrganismo

	BEGIN TRY  
		BEGIN TRAN  
           
		-- actualizamos el registro en la tabla promocion  
		UPDATE [dbo].[Promociones] WITH(ROWLOCK)  
		SET HoraPresentacion = @pi_HoraPresentacion  
			,ClasePromovente = @pi_ClasePromovente  
			,TipoPromovente = @pi_TipoPromovente  
			,TipoContenido = @pi_TipoContenido  
			,NumeroCopias = @pi_NumeroCopias  
			,NumeroAnexos = @pi_NumeroAnexo  
			,FechaPresentacion = @pi_FechaPresentacion
			,Secretario = @pi_Secretario   
			,RegistroEmpleadoId =@pi_RegistroEmpleadoId  
			,FechaActualiza = GETDATE()    
			,NumeroFojasTomos=@pi_NumeroFojasTomos  
			,Observaciones=@pi_Observaciones  
			,TipoCuaderno=@pi_TipoCuaderno  
			,IPUsuario=@pi_IpUsuario
			,Mesa=@Mesa
			,[YearPromocion] = year(@pi_FechaPresentacion)
			,AsuntoNeunId = IIF(@pi_AsuntoNeunIdNuevo IS NOT NULL ,@pi_AsuntoNeunIdNuevo,@pi_AsuntoNeunId )
	   WHERE AsuntoId=@pi_AsuntoId 
			 AND AsuntoNeunId=@pi_AsuntoNeunId   
			 AND YearPromocion=@pi_YearPromocion 
			 AND NumeroOrden=@pi_NumeroOrden  
			 AND OrigenPromocion=@pi_OrigenPromocion  
			 AND CatOrganismoId = @pi_catIdOrganismo
	  
	   UPDATE PromocionArchivos
	   SET AsuntoNeunId =  IIF(@pi_AsuntoNeunIdNuevo IS NOT NULL ,@pi_AsuntoNeunIdNuevo,@pi_AsuntoNeunId )
		   ,YearPromocion = YEAR(@pi_FechaPresentacion),
		   Fojas = @pi_NumeroFojasTomos
	   WHERE CatOrganismoId=@pi_catIdOrganismo 
			 AND AsuntoId=@pi_AsuntoId 
			 AND AsuntoNeunId=@pi_AsuntoNeunId 
			 AND NumeroOrden=@pi_NumeroOrden  
			 AND YearPromocion=@pi_YearPromocion 

	   
		/*IF  @actualizaAsuntoNeunId = 1
		BEGIN 
			UPDATE [dbo].[Promociones] WITH(ROWLOCK)  
				SET
					HoraPresentacion = @pi_HoraPresentacion  
					,ClasePromovente = @pi_ClasePromovente  
					,TipoPromovente = @pi_TipoPromovente  
					,TipoContenido = @pi_TipoContenido  
					,NumeroCopias = @pi_NumeroCopias  
					,NumeroAnexos = @pi_NumeroAnexo  
					,FechaPresentacion = @pi_FechaPresentacion
					,Secretario = @pi_Secretario   
					,RegistroEmpleadoId =@pi_RegistroEmpleadoId  
					,FechaActualiza = GETDATE()    
					,NumeroFojasTomos=@pi_NumeroFojasTomos  
					,Observaciones=@pi_Observaciones  
					,TipoCuaderno=@pi_TipoCuaderno  
					,IPUsuario=@pi_IpUsuario
					,Mesa=@Mesa
					,AsuntoNeunId=@pi_AsuntoNeunId
					,[YearPromocion] = year(@pi_FechaPresentacion)
			WHERE AsuntoId=@pi_AsuntoId --and AsuntoNeunId=@pi_AsuntoNeunId   
			 and YearPromocion=@pi_YearPromocion and NumeroOrden=@pi_NumeroOrden  
			 and  OrigenPromocion=@pi_OrigenPromocion
		END*/

		IF @pi_registroAnterior <> @pi_NumeroRegistro   
		BEGIN  

			UPDATE Promociones WITH(ROWLOCK)  
			SET NumeroRegistro = @pi_NumeroRegistro  
			WHERE AsuntoId=@pi_AsuntoId 
					AND AsuntoNeunId=ISNULL(@pi_AsuntoNeunIdNuevo,@pi_AsuntoNeunId) 
					AND CatOrganismoId=@pi_catIdOrganismo  
					AND YearPromocion=@pi_YearPromocion 
					AND NumeroOrden=@pi_NumeroOrden  
					AND  OrigenPromocion=@pi_OrigenPromocion  
      
			UPDATE PromocionArchivos WITH(ROWLOCK)     
			SET NumeroRegistro = @pi_NumeroRegistro  
			WHERE CatOrganismoId=@pi_catIdOrganismo 
					AND AsuntoId=@pi_AsuntoId 
					AND AsuntoNeunId=ISNULL(@pi_AsuntoNeunIdNuevo,@pi_AsuntoNeunId) 
					AND NumeroOrden=@pi_NumeroOrden  
					AND YearPromocion=@pi_YearPromocion 
					AND NumeroRegistro=@pi_registroAnterior  

		END    

		-- Se agrego caso para cuando @pi_registroAnterior es nullo y no de registro se especifica. 18/04/2016 PVB
		ELSE IF(@pi_registroAnterior is NULL and  @pi_NumeroRegistro is not null )
		BEGIN
			
			UPDATE Promociones WITH(ROWLOCK)  
			SET NumeroRegistro = @pi_NumeroRegistro  
			WHERE AsuntoId=@pi_AsuntoId 
				  AND AsuntoNeunId=ISNULL(@pi_AsuntoNeunIdNuevo,@pi_AsuntoNeunId) 
				  AND CatOrganismoId=@pi_catIdOrganismo  
				  AND YearPromocion=@pi_YearPromocion 
				  AND NumeroOrden=@pi_NumeroOrden  
				  AND  OrigenPromocion=@pi_OrigenPromocion  
      
			UPDATE PromocionArchivos WITH(ROWLOCK)     
			SET NumeroRegistro = @pi_NumeroRegistro  
			WHERE CatOrganismoId=@pi_catIdOrganismo 
				  AND AsuntoId=@pi_AsuntoId 
				  AND AsuntoNeunId=ISNULL(@pi_AsuntoNeunIdNuevo,@pi_AsuntoNeunId) 
				  AND NumeroOrden=@pi_NumeroOrden  
				  AND YearPromocion=@pi_YearPromocion 

		END
    
		--exec usp_Promocion_Bitacora @pi_catIdOrganismo, @pi_YearPromocion ,@pi_NumeroOrden, @pi_OrigenPromocion ,4--4 indica que es cambio en tabla promociones  
		EXEC usp_Promocion_Bitacora @pi_catIdOrganismo,@pi_YearPromocion,@pi_NumeroOrden,@pi_OrigenPromocion,4
    
       
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
   --if (@pi_CatIdOrganismo = 949 or @pi_CatIdOrganismo = 964 or @pi_CatIdOrganismo = 1372 or @pi_CatIdOrganismo = 1374 or @pi_CatIdOrganismo = 464 or @pi_CatIdOrganismo = 480 or @pi_CatIdOrganismo = 1200 or @pi_CatIdOrganismo = 1201 or @pi_CatIdOrganismo= 1202)
   --if (@pi_CatIdOrganismo = 949 or @pi_CatIdOrganismo = 964 or @pi_CatIdOrganismo = 1372 or @pi_CatIdOrganismo = 1374 or @pi_CatIdOrganismo = 464 or @pi_CatIdOrganismo = 480 or @pi_CatIdOrganismo = 1200 or @pi_CatIdOrganismo = 1201 or @pi_CatIdOrganismo202)--SBGE se modifico a peticion de PP Charly 25/03/2015
   --begin  
   --exec sisecjfdb02.sise.dbo.usp_EXPE_PromocionSISE1Upd @pi_FechaPresentacion,@pi_HoraPresentacion,@pi_ClasePromocion,@pi_ClasePromovente,@pi_TipoPromovente,@pi_TipoContenido,@pi_Contenido,@pi_FechaEntrega,@pi_PersonaRecibe,@pi_Secretario,@pi_RegistroEmpleadoId,@pi_TipoCuaderno,@pi_AsuntoNeunId,@pi_YearPromocion,@pi_NumeroOrden,@pi_OrigenPromocion  
   --end  
     
  SET NOCOUNT OFF  
END 
