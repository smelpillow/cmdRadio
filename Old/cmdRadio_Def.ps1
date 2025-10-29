# cmdRadio - Smelpillow - Libre de usar y compartir
# Este script permite crear una lista de reproducción M3U con las emisoras de radio disponibles en la carpeta especificada.
# Requiere PowerShell 5.0 o superior y MPV para la reproducción de las emisoras.

# Definimos la ruta de la carpeta con los M3U
$musicFolder = Read-Host "Ingrese la ruta de la carpeta de música [C:\GitHub\m3u-radio-music-playlists]"
if (-not $musicFolder) {
    $musicFolder = "C:\GitHub\cmdRadio\InternetRadio"
}

# Verificamos si la carpeta existe
if (-not (Test-Path $musicFolder)) {
    Write-Host "La carpeta de música no existe: $musicFolder" -ForegroundColor Red
    exit
}

# Obtenemos todos los archivos M3U en la carpeta y subcarpetas
$m3uFiles = Get-ChildItem -Path $musicFolder -Filter "*.m3u" -Recurse | Select-Object -ExpandProperty FullName

# Función para obtener la lista de archivos .m3u
function Get-M3UFiles {
    return Get-ChildItem -Path $m3uFiles -Filter "*.m3u" -Recurse
}

# Función para reproducir un archivo con mpv
function Start-M3UFile {
    param (
        [string]$filePath
    )
    # Reproducir el archivo directamente en la terminal
    & mpv --shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' "$filePath"
}

# Función para mostrar el menú y permitir selección repetida
function Show-Menu {
    while ($true) {
        $files = Get-M3UFiles
        if ($files.Count -eq 0) {
            Write-Host "No se encontraron archivos .m3u."
            return
        }

        Write-Host "`nSelecciona un archivo para reproducir:"
        for ($i=0; $i -lt $files.Count; $i++) {
            Write-Host "$($i+1). $($files[$i].Name)"
        }

        Write-Host "0. Salir"
        $selection = Read-Host "Introduce el número del archivo"

        if ($selection -eq "0") {
            Write-Host "Saliendo..."
            break
        } elseif ($selection -match "^\d+$" -and [int]$selection -le $files.Count -and [int]$selection -gt 0) {
            Start-M3UFile $files[[int]$selection - 1].FullName
        } else {
            Write-Host "Selección no válida, intenta de nuevo."
        }
    }
}

# Ejecutar el menú en un bucle hasta que el usuario salga
Show-Menu
