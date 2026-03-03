SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- exec [SISE3].[piRelacionPromocionElectronicayFisica] 17, 1494, 1024586, 6, 6712

CREATE OR ALTER PROCEDURE [SISE3].[piRelacionPromocionElectronicayFisica]
	@pi_NumeroOrden INT,
	@pi_CatOrganismoId INT,
    @pi_IdPromocion BIGINT,
    @pi_Origen INT,
	@pi_EmpleadoId BIGINT,
    @pi_ConExpediente BIT NULL = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @YearPromocion INT
    DECLARE @AsuntoNeunId BIGINT
	DECLARE @IdRelacion BIGINT

    SELECT @YearPromocion=YearPromocion, @AsuntoNeunId=AsuntoNeunId FROM Promociones 
    WHERE NumeroOrden=@pi_NumeroOrden 
          AND CatOrganismoId=@pi_CatOrganismoId
          AND StatusReg=1
		--   AND YearPromocion = YEAR(GETDATE())

    -- PROMOCIÓN ELECTRÓNICA ORIGEN (6)
	-- ** PARA ESTE CASO SE ENVIA EL kIdPromocion EN EL PARÁMETRO DE @pi_IdPromocion **
    IF(@pi_Origen=6)
    BEGIN
        INSERT INTO dbo.JL_REL_PromocionSISE
        (
             fkIdPromocion      --1
            ,CatOrganismoId     --2
            ,YearPromocion      --3
            ,NumeroOrden        --4
            ,AsuntoNeunId       --5
            ,OrigenPromocion    --6
        )
        VALUES
        (
             @pi_IdPromocion    --1
            ,@pi_CatOrganismoId --2
            ,@YearPromocion     --3
            ,@pi_NumeroOrden    --4
            ,@AsuntoNeunId      --5
            ,@pi_Origen         --6
        )

    END
    -- PROMOCIÓN ELECTRÓNICA DE INTERCONEXIÓN ORIGEN (14) 
    -- ** PARA ESTE CASO SE ENVIA EL kiIdFolio EN EL PARÁMETRO DE @pi_IdPromocion **
    ELSE IF (@pi_Origen=14)
    BEGIN
        INSERT INTO dbo.ICOIJ_REL_PromocionSISE
        (
             fkIdPromocion      --1
            ,CatOrganismoId     --2
            ,YearPromocion      --3
            ,NumeroOrden        --4
            ,AsuntoNeunId       --5
            ,OrigenPromocion    --6
        )
        VALUES
        (
             @pi_IdPromocion    --1
            ,@pi_CatOrganismoId --2
            ,@YearPromocion     --3
            ,@pi_NumeroOrden    --4
            ,@AsuntoNeunId      --5
            ,@pi_Origen         --6
        )
    END
    -- PROMOCIÓN ELECTRÓNICA DE INTERCONEXIONES ENTRE ÓRGANOS JURISDICCIONALES ORIGEN (22)
    -- ** PARA ESTE CASO SE ENVIA EL kiIdFolio EN EL PARÁMETRO DE @pi_IdPromocion **
    ELSE IF (@pi_Origen=22)
    BEGIN
        IF(@pi_ConExpediente=0)
        BEGIN
            INSERT INTO dbo.IOJ_REL_PromocionSISE
            (
                fkIdPromocion      --1
                ,CatOrganismoId     --2
                ,YearPromocion      --3
                ,NumeroOrden        --4
                ,AsuntoNeunId       --5
                ,OrigenPromocion    --6
            )
            VALUES
            (
                @pi_IdPromocion    --1
                ,@pi_CatOrganismoId --2
                ,@YearPromocion     --3
                ,@pi_NumeroOrden    --4
                ,@AsuntoNeunId      --5
                ,@pi_Origen         --6
            )
        END
        ELSE
        BEGIN
            INSERT INTO dbo.JL_REL_PromocionSISE
            (
                fkIdPromocion      --1
                ,CatOrganismoId     --2
                ,YearPromocion      --3
                ,NumeroOrden        --4
                ,AsuntoNeunId       --5
                ,OrigenPromocion    --6
            )
            VALUES
            (
                @pi_IdPromocion    --1
                ,@pi_CatOrganismoId --2
                ,@YearPromocion     --3
                ,@pi_NumeroOrden    --4
                ,@AsuntoNeunId      --5
                ,@pi_Origen         --6
            )
        END
    END
    -- DEMANDAS ELECTRÓNICAS ORIGEN (5)
	-- ** PARA ESTE CASO SE ENVIA EL kIdDemanda EN EL PARÁMETRO DE @pi_IdPromocion **
    ELSE IF (@pi_Origen=5)
    BEGIN
        INSERT INTO dbo.JL_REL_DemandaSISE
        (
             fkIdDemanda        --1
            ,CatOrganismoId     --2
            ,YearPromocion      --3
            ,NumeroOrden        --4
            ,AsuntoNeunId       --5
            ,OrigenPromocion    --6
        )
        VALUES
        (
             @pi_IdPromocion    --1
            ,@pi_CatOrganismoId --2
            ,@YearPromocion     --3
            ,@pi_NumeroOrden    --4
            ,@AsuntoNeunId      --5
            ,@pi_Origen         --6
        )
    END
    -- DEMANDAS ELECTRÓNICAS INTERCONEXIÓN ORIGEN (15)
	-- ** PARA ESTE CASO SE ENVIA EL kIdDemanda EN EL PARÁMETRO DE @pi_IdPromocion **
    ELSE IF (@pi_Origen=15)
    BEGIN
        INSERT INTO dbo.ICOIJ_REL_DemandaSISE
        (
             fkIdDemanda        --1
            ,CatOrganismoId     --2
            ,YearPromocion      --3
            ,NumeroOrden        --4
            ,AsuntoNeunId       --5
            ,OrigenPromocion    --6
        )
        VALUES
        (
             @pi_IdPromocion    --1
            ,@pi_CatOrganismoId --2
            ,@YearPromocion     --3
            ,@pi_NumeroOrden    --4
            ,@AsuntoNeunId      --5
            ,@pi_Origen         --6
        )
    END
    -- COMUNICACIONES OFICIALES ORIGEN (29)
    ELSE IF (@pi_Origen=29)
    BEGIN
        INSERT INTO dbo.JL_REL_DemandaSISE
        (
             fkIdDemanda		--1
            ,CatOrganismoId     --2
            ,YearPromocion      --3
            ,NumeroOrden        --4
            ,AsuntoNeunId       --5
            ,OrigenPromocion    --6
        )
        VALUES
        (
             @pi_IdPromocion    --1
            ,@pi_CatOrganismoId --2
            ,@YearPromocion     --3
            ,@pi_NumeroOrden    --4
            ,@AsuntoNeunId      --5
            ,@pi_Origen         --6
        )
    END

    UPDATE Promociones SET
        OrigenPromocion=@pi_Origen
    WHERE NumeroOrden=@pi_NumeroOrden
          AND CatOrganismoId=@pi_CatOrganismoId
          AND YearPromocion=@YearPromocion
          AND StatusReg=1

    IF(@pi_Origen = 22 AND @pi_ConExpediente = 0)
    BEGIN
        
        SELECT @AsuntoNeunId = AsuntoNeunId FROM Promociones 
        WHERE NumeroOrden=@pi_NumeroOrden
        AND CatOrganismoId=@pi_CatOrganismoId
        AND YearPromocion=@YearPromocion
        AND OrigenPromocion = 22
        AND StatusReg=1

        UPDATE IOJ_REL_PromocionSISE
        SET AsuntoNeunId = @AsuntoNeunId
        WHERE NumeroOrden=@pi_NumeroOrden
        AND CatOrganismoId=@pi_CatOrganismoId
        AND YearPromocion=@YearPromocion
        AND fkIdPromocion = @pi_IdPromocion
    END

END
