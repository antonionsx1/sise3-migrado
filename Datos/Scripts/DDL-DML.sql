----Creación de campo
ALTER TABLE [Anexos] ADD  Texto NVARCHAR(MAX)


----Insert Oficio Libre
INSERT INTO AnexoSTipo
VALUES ( 'Oficio Libre', getdate(), null, 2, 0, null)