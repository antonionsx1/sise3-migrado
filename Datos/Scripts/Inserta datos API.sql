DECLARE @IdAPI INT;

-- Insertar en SISE3.CatAPI y obtener el IdAPI generado
INSERT INTO SISE3.CatAPI (sDescripcion, sURL, bEstatus)
OUTPUT INSERTED.IdAPI INTO @IdAPI
VALUES ('Obtiene organo, estado o ciudad por nombre', '/api/capturaExpediente/obtieneOrganoPorNombre', 1);

-- Usar el IdAPI generado en el segundo INSERT
INSERT INTO SISE3.REL_RolAPi (IdPrivilegio, IdAPI, sVerbo)
VALUES (142, @IdAPI, 'GET');
