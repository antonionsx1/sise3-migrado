
DECLARE @max_CatCamposAsuntoId INT
declare @max_TipoAsuntoId INT
declare @padreSubMenu int = 1812


-- Se inserta en CatCamposAsunto
INSERT INTO CatCamposAsunto (Descripcion,FechaAlta,FechaBaja,StatusReg,IsMigrated)
SELECT 'Asuntos relacionados dentro del propio órgano Grid', GETDATE(), NULL, 1, NULL;

SELECT @max_CatCamposAsuntoId = max(CatCampoAsuntoId)
from CatCamposAsunto;

-- Se inserta en tipo asunto
insert into TiposAsunto(CatTipoAsuntoId,CatTipoOrganismoId,CatCampoAsuntoId,Nivel,Padre,Clase,Tipo,Catalogo,Orden,Normatividad,CatCampoFormatoId,FechaAlta,FechaBaja,StatusReg,EsMultiple,Descripcion,FechaActualiza,IsMigrated,TipoProcedimiento,VisibleInternet)
VALUES(2,2,@max_CatCamposAsuntoId, 1,@padreSubMenu, 1, 16,Null,1,NULL,3,GETDATE(),NULL,1,1, 'Asuntos relacionados dentro del propio órgano Grid', NULL,NULL,NULL,1);

SELECT @max_TipoAsuntoId = max(TipoAsuntoId)
from TiposAsunto;

-- Se actualizan los valores existentes
UPDATE TiposAsunto
SET Padre = @max_TipoAsuntoId
WHERE Padre = @padreSubMenu
and TipoAsuntoId in (1813, 1814, 1815);