use SISE_NEW

--select  * from SISE3.viTiposAsuntoExpediente where TipoAsuntoId = 6728
--where DescripcionXCat like '%atos de la determinación judicial%'

--atos de la determinación judicial


UPDATE TiposAsunto 
set StatusReg = 0
where TipoAsuntoId = 6728