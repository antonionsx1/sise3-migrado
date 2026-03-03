-- GET
-- /api/ObtenerOtrasPartes
-- Obtiene información sobre las otras partes asociadas a un expediente.
-- Permisos: Oficial de Partes, Oficial Judicial, Analista SISE, Secretario, Administradores.

-- PASO 1: Crear privilegio
SET IDENTITY_INSERT SISE3.CatPrivilegio ON;
INSERT INTO SISE3.CatPrivilegio (IdPrivilegio, sNombrePrivilegio, sDescripcion, sModulo, bEstatus)
VALUES (231, N'Consulta otras partes', N'Permite consultar información de otras partes asociadas a un expediente.', N'Usuarios', 1);
SET IDENTITY_INSERT SISE3.CatPrivilegio OFF;

-- PASO 2: Registrar API
SET IDENTITY_INSERT SISE3.CatAPI ON;
INSERT INTO SISE3.CatAPI (IdApi, sDescripcion, sURL, bEstatus)
VALUES (421, N'Consulta de otras partes asociadas a un expediente.', N'/api/ObtenerOtrasPartes', 1);
SET IDENTITY_INSERT SISE3.CatAPI OFF;

-- PASO 3: Relacionar privilegio con roles
INSERT INTO SISE3.REL_PrivilegioXRol (IdRol, IdPrivilegio, bEstatus, fFechaAlta)
SELECT IdRol, 231, 1, GETDATE()
FROM SISE3.CatRol
WHERE IdRol IN (1, 3, 4, 5, 6, 7, 15, 18, 143, 152);

-- PASO 4: Relacionar privilegio con API
INSERT INTO SISE3.REL_RolAPi (IdPrivilegio, IdAPI, sVerbo)
VALUES (231, 421, 'GET');


-- GET
-- /api/ObtenerOtrasPartesDetalle
-- Obtiene el detalle de otras partes asociadas a un expediente.
-- Permisos: Oficial de Partes, Oficial Judicial, Analista SISE, Secretario, Administradores.

-- PASO 1
SET IDENTITY_INSERT SISE3.CatPrivilegio ON;
INSERT INTO SISE3.CatPrivilegio (IdPrivilegio, sNombrePrivilegio, sDescripcion, sModulo, bEstatus)
VALUES (232, N'Consulta detalle de otras partes', N'Permite consultar el detalle de las otras partes asociadas a un expediente.', N'ExpedienteElectronico', 1);
SET IDENTITY_INSERT SISE3.CatPrivilegio OFF;

-- PASO 2
SET IDENTITY_INSERT SISE3.CatAPI ON;
INSERT INTO SISE3.CatAPI (IdApi, sDescripcion, sURL, bEstatus)
VALUES (422, N'Detalle de otras partes asociadas a un expediente.', N'/api/ObtenerOtrasPartesDetalle', 1);
SET IDENTITY_INSERT SISE3.CatAPI OFF;

-- PASO 3
INSERT INTO SISE3.REL_PrivilegioXRol (IdRol, IdPrivilegio, bEstatus, fFechaAlta)
SELECT IdRol, 232, 1, GETDATE()
FROM SISE3.CatRol
WHERE IdRol IN (1, 3, 4, 5, 6, 7, 15, 18, 143, 152);

-- PASO 4
INSERT INTO SISE3.REL_RolAPi (IdPrivilegio, IdAPI, sVerbo)
VALUES (232, 422, 'GET');


-- POST
-- /api/InsertarOtraParte
-- Crea una nueva entrada de "otra parte" para un expediente.
-- Permisos: Oficial de Partes, Oficial Judicial, Analista SISE, Secretario, Administradores.

-- PASO 1
SET IDENTITY_INSERT SISE3.CatPrivilegio ON;
INSERT INTO SISE3.CatPrivilegio (IdPrivilegio, sNombrePrivilegio, sDescripcion, sModulo, bEstatus)
VALUES (233, N'Crear otras partes para un expediente', N'Permite registrar otras partes asociadas a un expediente.', N'ExpedienteElectronico', 1);
SET IDENTITY_INSERT SISE3.CatPrivilegio OFF;

-- PASO 2
SET IDENTITY_INSERT SISE3.CatAPI ON;
INSERT INTO SISE3.CatAPI (IdApi, sDescripcion, sURL, bEstatus)
VALUES (423, N'Registro de otras partes para un expediente.', N'/api/InsertarOtraParte', 1);
SET IDENTITY_INSERT SISE3.CatAPI OFF;

-- PASO 3
INSERT INTO SISE3.REL_PrivilegioXRol (IdRol, IdPrivilegio, bEstatus, fFechaAlta)
SELECT IdRol, 233, 1, GETDATE()
FROM SISE3.CatRol
WHERE IdRol IN (1, 3, 4, 5, 6, 7, 15, 18, 143, 152);

-- PASO 4
INSERT INTO SISE3.REL_RolAPi (IdPrivilegio, IdAPI, sVerbo)
VALUES (233, 423, 'POST');


-- DELETE
-- /api/EliminarOtraParte
-- Elimina una entrada de "otra parte" asociada a un expediente.
-- Permisos: Oficial de Partes, Oficial Judicial, Analista SISE, Secretario, Administradores.

-- PASO 1
SET IDENTITY_INSERT SISE3.CatPrivilegio ON;
INSERT INTO SISE3.CatPrivilegio (IdPrivilegio, sNombrePrivilegio, sDescripcion, sModulo, bEstatus)
VALUES (234, N'Eliminar otras partes para un expediente', N'Permite eliminar otras partes asociadas a un expediente.', N'ExpedienteElectronico', 1);
SET IDENTITY_INSERT SISE3.CatPrivilegio OFF;

-- PASO 2
SET IDENTITY_INSERT SISE3.CatAPI ON;
INSERT INTO SISE3.CatAPI (IdApi, sDescripcion, sURL, bEstatus)
VALUES (424, N'Eliminación de otras partes asociadas a un expediente.', N'/api/EliminarOtraParte', 1);
SET IDENTITY_INSERT SISE3.CatAPI OFF;

-- PASO 3
INSERT INTO SISE3.REL_PrivilegioXRol (IdRol, IdPrivilegio, bEstatus, fFechaAlta)
SELECT IdRol, 234, 1, GETDATE()
FROM SISE3.CatRol
WHERE IdRol IN (1, 3, 4, 5, 6, 7, 15, 18, 143, 152);

-- PASO 4
INSERT INTO SISE3.REL_RolAPi (IdPrivilegio, IdAPI, sVerbo)
VALUES (234, 424, 'DELETE');


-- PUT
-- /api/ActualizaOtraParte
-- Actualiza la información de una "otra parte" asociada a un expediente.
-- Permisos: Oficial de Partes, Oficial Judicial, Analista SISE, Secretario, Administradores.

-- PASO 1
SET IDENTITY_INSERT SISE3.CatPrivilegio ON;
INSERT INTO SISE3.CatPrivilegio (IdPrivilegio, sNombrePrivilegio, sDescripcion, sModulo, bEstatus)
VALUES (235, N'Actualizar otras partes para un expediente', N'Permite actualizar la información de otras partes asociadas a un expediente.', N'ExpedienteElectronico', 1);
SET IDENTITY_INSERT SISE3.CatPrivilegio OFF;

-- PASO 2
SET IDENTITY_INSERT SISE3.CatAPI ON;
INSERT INTO SISE3.CatAPI (IdApi, sDescripcion, sURL, bEstatus)
VALUES (425, N'Actualización de otras partes asociadas a un expediente.', N'/api/ActualizaOtraParte', 1);
SET IDENTITY_INSERT SISE3.CatAPI OFF;

-- PASO 3
INSERT INTO SISE3.REL_PrivilegioXRol (IdRol, IdPrivilegio, bEstatus, fFechaAlta)
SELECT IdRol, 235, 1, GETDATE()
FROM SISE3.CatRol
WHERE IdRol IN (1, 3, 4, 5, 6, 7, 15, 18, 143, 152);

-- PASO 4
INSERT INTO SISE3.REL_RolAPi (IdPrivilegio, IdAPI, sVerbo)
VALUES (235, 425, 'PUT');
