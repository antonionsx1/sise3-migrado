USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[piRelacionPromocionElectronicayFisica]    Script Date: 12/1/2023 6:28:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- exec [SISE3].[piRelacionPromocionElectronicayFisica] 1492, 1494, 202321401494000002, 14

CREATE PROCEDURE [SISE3].[piRelacionPromocionElectronicayFisica]
	@pi_NumeroOrden INT,
	@pi_CatOrganismoId INT,
    @pi_IdPromocion BIGINT,
    @pi_Origen INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @YearPromocion INT
    DECLARE @AsuntoNeunId BIGINT

    SELECT @YearPromocion=YearPromocion, @AsuntoNeunId=AsuntoNeunId FROM Promociones 
    WHERE NumeroOrden=@pi_NumeroOrden 
          AND CatOrganismoId=@pi_CatOrganismoId
          AND StatusReg=1

    -- PROMOCIÓN ELECTRÓNICA ORIGEN (6)
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
    -- DEMANDAS ELECTRÓNICAS ORIGEN (5)
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
        SELECT 'PENDIENTE DE IMPLEMENTAR'
    END

    UPDATE Promociones SET
        OrigenPromocion=@pi_Origen
    WHERE NumeroOrden=@pi_NumeroOrden
          AND CatOrganismoId=@pi_CatOrganismoId
          AND YearPromocion=@YearPromocion
          AND StatusReg=1



END
GO

