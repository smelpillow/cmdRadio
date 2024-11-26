# Rutas de las carpetas
$carpetaDestino = 'C:\GitHub\m3u-radio-music-playlists\allradio.net'
$carpetaOrigen = 'C:\GitHub\cmdRadio\InternetRadio'

# Verificar si las carpetas existen
if (-not (Test-Path $carpetaDestino)) {
    Write-Host "La carpeta destino '$carpetaDestino' no existe. Creándola..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $carpetaDestino -Force | Out-Null
}

if (-not (Test-Path $carpetaOrigen)) {
    Write-Error "La carpeta origen '$carpetaOrigen' no existe. Por favor, verifica la ruta."
    exit
}

# Leer los archivos existentes en la carpeta de destino y guardarlos en una variable
$archivosDestino = Get-ChildItem -Path $carpetaDestino -Recurse | Select-Object -ExpandProperty Name

# Leer los archivos de la carpeta de origen
$archivosOrigen = Get-ChildItem -Path $carpetaOrigen -Recurse

# Iterar sobre los archivos de origen
foreach ($archivo in $archivosOrigen) {
    $nombreArchivo = $archivo.Name
    $rutaArchivoOrigen = $archivo.FullName
    $rutaArchivoDestino = Join-Path -Path $carpetaDestino -ChildPath $archivo.Name

    # Comprobar si el archivo ya existe en la carpeta de destino
    if ($archivosDestino -notcontains $nombreArchivo -or ($archivo.LastWriteTime -gt (Get-Item $rutaArchivoDestino).LastWriteTime)) {
        Write-Host "Copiando archivo: $nombreArchivo..." -ForegroundColor Green
        
        # Crear los directorios de destino si no existen
        $directorioDestino = Split-Path -Path $rutaArchivoDestino -Parent
        if (-not (Test-Path $directorioDestino)) {
            New-Item -ItemType Directory -Path $directorioDestino -Force | Out-Null
        }

        # Copiar el archivo
        Copy-Item -Path $rutaArchivoOrigen -Destination $rutaArchivoDestino -Force
    } else {
        Write-Host "El archivo '$nombreArchivo' ya existe y no necesita ser copiado." -ForegroundColor Yellow
    }
}

Write-Host "Proceso completado." -ForegroundColor Cyan

