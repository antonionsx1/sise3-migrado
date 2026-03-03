USE SISE_NEW
GO
ALTER FUNCTION SISE3.CalcularOrdenRecursivo(@TipoAsuntoId INT)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @OrdenRecursivo VARCHAR(MAX) = '';
    SELECT @OrdenRecursivo = CONCAT(
        ISNULL(SISE3.CalcularOrdenRecursivo(vta.Padre), ''), 
        RIGHT('00000' + CAST(vta.Orden AS VARCHAR(5)), 5)
    )
    FROM viTiposAsunto vta
    WHERE vta.TipoAsuntoId = @TipoAsuntoId;
    RETURN @OrdenRecursivo;
END;