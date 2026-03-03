@echo off
setlocal enabledelayedexpansion

:: Ruta al archivo de entrada
set "inputFile=funciones.txt"

:: Carpeta para los archivos de registro
set "logDir=logs"

:: Verifica si el archivo existe
if not exist "%inputFile%" (
    echo El archivo %inputFile% no existe.
    exit /b 1
)

:: Limpia la carpeta de logs si existe; si no existe, la crea
if exist "%logDir%" (
    echo Limpiando carpeta de logs...
    del /q "%logDir%\*" >nul 2>&1
) else (
    echo Creando carpeta de logs...
    mkdir "%logDir%"
)

:: Lee el archivo línea por línea
for /f "usebackq tokens=1,2 delims=," %%A in ("%inputFile%") do (
    set "line=%%A"
    :: Omite líneas que comienzan con #
    if "!line!"=="!line:#=!" (
        set "image=%%A"
        set "dockerfile=%%B"

        :: Elimina espacios en blanco al inicio y al final
        for /f "tokens=* delims= " %%i in ("!image!") do set "image=%%i"
        for /f "tokens=* delims= " %%i in ("!dockerfile!") do set "dockerfile=%%i"

        :: Construye la imagen Docker y redirige la salida al archivo de log
        echo Construyendo la imagen !image! usando el Dockerfile !dockerfile!
		:: Quitar el prefijo y el tag para generar nombre de log
		set "safeImage=!image:local.docker.com/=!"
		for /f "tokens=1 delims=:" %%i in ("!safeImage!") do set "safeImage=%%i"
        docker build -t !image! -f !dockerfile! --progress=plain . > "!logDir!\!safeImage!_build.log" 2>&1
		@REM docker build -t !image! -f !dockerfile! .
        if errorlevel 1 (
            echo Error al construir la imagen !image!. Consulta el archivo de registro %logDir%\!safeImage!_build.log para más detalles.
        ) else (
            echo Imagen !image! construida exitosamente.
        )
    )
)
