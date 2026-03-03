USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piPromovente]    Script Date: 12/1/2023 6:28:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GGHH
-- Create date: 30/08/2023
-- Description:	Inserta al promovente de un asunto.
-- SISE3.piPromovente 30301737,2771, 'Nombre', 'Paterno', 'Materno', 163080889, 54514
-- =============================================
CREATE PROCEDURE [SISE3].[piPromovente]
	@pi_AsuntoNeunId BIGINT,
	@pi_Tipo INT,
	@pi_Nombre VARCHAR(510),
	@pi_APaterno VARCHAR(100),
	@pi_AMaterno VARCHAR(100),
	@pi_PersonaId INT,
	@pi_RegistroEmpleadoId INT,
	@pi_numeroOrden INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @PromoventeAsunto [PromoventeAsunto_type],
				@PromoventeDomicilioAsunto [PromoventeDomicilioAsunto_type],
				@AsuntoId INT, 
				@PromoventeId INT,
				@TipoPromovete INT,
				@PersonaParteIns INT

		SELECT @AsuntoId = AsuntoId
		FROM Asuntos WITH(NOLOCK)
		WHERE AsuntoNeunId = @pi_AsuntoNeunId

		IF NOT EXISTS(SELECT TOP 1 AsuntoId 
					 FROM promovente P
					 WHERE p.[AsuntoId] = @AsuntoId AND [AsuntoNeunId] = @pi_AsuntoNeunId AND 
					 SISE3.ConcatenarNombres(p.[Nombre],p.[APaterno],p.[AMaterno])  =  SISE3.ConcatenarNombres(@pi_Nombre, @pi_APaterno, @pi_AMaterno) AND
					 p.Tipo = @pi_Tipo )
		BEGIN

			INSERT INTO @PromoventeAsunto(PersonaId, Tipo,Nombre,APaterno,AMaterno, Sexo, FechaNacimiento,TipoIdentificador, Email, RegistroEmpleadoId)
			VALUES(@pi_PersonaId, @pi_Tipo, @pi_Nombre, @pi_APaterno, @pi_AMaterno,0,CONVERT(DATETIME,0), 0, '', @pi_RegistroEmpleadoId)

			INSERT INTO @PromoventeDomicilioAsunto(CalleNumero, CodigoPostal, Colonia, Delegacion, Entidad, Localidad, RegistroEmpleadoId)
			VALUES (NULL, 0, NULL, 0, 0, NULL, @pi_RegistroEmpleadoId)

			EXEC dbo.usp_EXPE_PromoventeIns 
				@pi_AsuntoId = @AsuntoId,
				@pi_AsuntoNeunId = @pi_AsuntoNeunId,
				@pi_PromoventeAsunto  = @PromoventeAsunto,
				@pi_PromoventeDomicilioAsunto = @PromoventeDomicilioAsunto,
				@pi_EsInterconexion = false

		END

		SELECT @TipoPromovete = max(pr.promoventeid)
		FROM promociones p INNER JOIN promovente pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_numeroOrden
		WHERE p.AsuntoNeunId = @pi_AsuntoNeunId 
		AND P.NumeroOrden = @pi_numeroOrden 
		AND SISE3.ConcatenarNombres(pr.[Nombre],pr.[APaterno],pr.[AMaterno])  =  SISE3.ConcatenarNombres(@pi_Nombre, @pi_APaterno, @pi_AMaterno) 
		AND  pr.Tipo = @pi_Tipo ;


		UPDATE p
		SET TipoPromovente  = @TipoPromovete
		FROM promociones p INNER JOIN promovente pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_numeroOrden
		WHERE p.AsuntoNeunId = @pi_AsuntoNeunId
		AND P.NumeroOrden = @pi_numeroOrden;

		IF @pi_PersonaId IS NOT NULL
		BEGIN
		    /*Valida si ya existe una persona parte asociada a la promoción y promovente */
			SET @PersonaParteIns = IIF ((SELECT COUNT(*) 
										FROM SISE3.PromocionPromoventeParte
										WHERE StatusReg = 1 AND AsuntoNeunId = @pi_AsuntoNeunId AND NumeroOrden = @pi_numeroOrden AND PromoventeId = @TipoPromovete AND PersonaId = @pi_PersonaId)=0,1,0)
			
			/*Valida que no este asignado*/
			IF @PersonaParteIns = 1 
			BEGIN
				INSERT INTO [SISE3].[PromocionPromoventeParte]
				([CatOrganismoId],[YearPromocion],[NumeroOrden],[AsuntoNeunId],[PromoventeId],[PersonaId],[FechaAlta],[StatusReg],[UsuarioCaptura])
				SELECT DISTINCT p.CatOrganismoId, p.YearPromocion,[NumeroOrden],p.AsuntoNeunId,TipoPromovente,@pi_PersonaId,GETDATE(),1,@pi_RegistroEmpleadoId
				FROM promociones p INNER JOIN promovente pr ON p.AsuntoNeunId = pr.AsuntoNeunId AND p.NumeroOrden = @pi_numeroOrden 
				WHERE p.AsuntoNeunId = @pi_AsuntoNeunId AND P.NumeroOrden = @pi_numeroOrden;
			END
			
			
				UPDATE SISE3.PromocionPromoventeParte
				SET StatusReg = 0 , FechaBaja = GETDATE()
				WHERE StatusReg = 1 AND AsuntoNeunId = @pi_AsuntoNeunId AND NumeroOrden = @pi_numeroOrden AND PromoventeId = @TipoPromovete AND PersonaId <> @pi_PersonaId

		END

	END TRY
	BEGIN CATCH
		EXECUTE dbo.usp_GetErrorInfo;
	END CATCH;
END
GO

