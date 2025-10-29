# Variable global para el historial de reproducción
$videoHistory = @()

# Archivo para almacenar favoritos
$favoritesFile = "C:\GitHub\cmdRadio\cmdTube\favorites.txt"

# Cargar favoritos desde el archivo
if (Test-Path $favoritesFile) {
    $favorites = Get-Content $favoritesFile
} else {
    $favorites = @()
}

# Función para verificar la instalación de mpv
function Test-MpvInstallation {
    $mpvExecutable = "mpv"
    $mpvPath = Get-Command $mpvExecutable -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

    if (-not $mpvPath) {
        Write-Host "¡Advertencia! mpv no está instalado o no se encuentra en el PATH del sistema." -ForegroundColor Yellow
        $response = Read-Host "¿Deseas continuar sin mpv? (S/N) [S]"
        if ($response -eq "" -or $response -eq "S" -or $response -eq "s") {
            return
        } else {
            Write-Host "Saliendo del script..." -ForegroundColor Green
            exit
        }
    }
}

# Función para buscar videos en YouTube
function Search-YouTube {
    param (
        [string]$searchTerm
    )
    $apiUrl = "https://www.youtube.com/results?search_query=$searchTerm"
    try {
        Write-Host "Buscando videos para '$searchTerm' en YouTube..." -ForegroundColor Cyan
        Start-Process -FilePath "mpv" -ArgumentList "--ytdl-format=best --ytdl-raw-options=search=\"$searchTerm\""
        Write-Action "Buscando videos en YouTube: $searchTerm"
    } catch {
        Write-Host "Error al buscar videos en YouTube: $_" -ForegroundColor Red
    }
}

# Función para reproducir un video desde una URL
function Start-Video {
    param (
        [string]$videoUrl
    )
    try {
        Write-Host "Reproduciendo video: $videoUrl" -ForegroundColor Green
        Start-Process -FilePath "mpv" "-ArgumentList --config-dir=C:\Github\cmdRadio\cmdTube" "$videoUrl"
        Write-Action "Reproduciendo video: $videoUrl"
        Add-ToHistory -video $videoUrl
    } catch {
        Write-Host "Error al reproducir el video: $_" -ForegroundColor Red
    }
}

# Función para manejar historial de reproducción
function Add-ToHistory {
    param (
        [string]$video
    )
    $global:videoHistory += $video
    Write-Action "Video añadido al historial: $video"
}

function Show-History {
    if ($videoHistory.Count -eq 0) {
        Write-Host "El historial de reproducción está vacío." -ForegroundColor Yellow
    } else {
        Write-Host "Historial de reproducción:" -ForegroundColor Cyan
        $videoHistory | ForEach-Object { Write-Host $_ }
    }
}

# Función para manejar favoritos
function Add-ToFavorites {
    param (
        [string]$videoUrl
    )
    if ($favorites -contains $videoUrl) {
        Write-Host "El video ya está en favoritos." -ForegroundColor Yellow
    } else {
        Add-Content -Path $favoritesFile -Value $videoUrl
        $favorites += $videoUrl
        Write-Host "Video agregado a favoritos: $videoUrl" -ForegroundColor Green
    }
}

function Show-Favorites {
    if ($favorites.Count -eq 0) {
        Write-Host "No tienes videos favoritos." -ForegroundColor Yellow
    } else {
        Write-Host "Videos favoritos:" -ForegroundColor Cyan
        $favorites | ForEach-Object { Write-Host $_ }
    }
}

# Función para reproducir un video aleatorio de los favoritos
function Start-RandomFavorite {
    if ($favorites.Count -eq 0) {
        Write-Host "No tienes videos favoritos para reproducir." -ForegroundColor Yellow
    } else {
        $randomVideo = Get-Random -InputObject $favorites
        Start-Video -videoUrl $randomVideo
    }
}

# Función para registrar logs
function Write-Action {
    param (
        [string]$message
    )
    $logFile = "C:\GitHub\cmdRadio\cmdTube\log.txt"
    $maxLines = 500  # Número máximo de líneas en el archivo de log

    # Agregar la nueva entrada al log
    Add-Content -Path $logFile -Value "$(Get-Date) - $message"

    # Limitar el número de líneas en el archivo
    if (Test-Path $logFile) {
        $lines = Get-Content $logFile
        if ($lines.Count -gt $maxLines) {
            $lines = $lines[-$maxLines..-1]  # Mantener solo las últimas N líneas
            $lines | Set-Content -Path $logFile
        }
    }
}

# Verifica la instalación de mpv antes de continuar
Test-MpvInstallation

# Menú principal
do {
    Clear-Host
    Write-Host "=============================================="
    Write-Host "        cmdTube 1.0 Menu" -ForegroundColor Cyan
    Write-Host "=============================================="
    Write-Host "1. Buscar videos en YouTube" -ForegroundColor Blue
    Write-Host "2. Reproducir video desde URL" -ForegroundColor Green
    Write-Host "3. Mostrar historial de reproducción" -ForegroundColor Magenta
    Write-Host "4. Mostrar favoritos" -ForegroundColor DarkGreen
    Write-Host "5. Agregar video a favoritos" -ForegroundColor DarkBlue
    Write-Host "6. Reproducir video aleatorio de favoritos" -ForegroundColor DarkRed
    Write-Host "7. Salir" -ForegroundColor Red
    Write-Host "=============================================="

    $option = Read-Host "Seleccione una opción"

    if ($option -eq "1") {
        $searchTerm = Read-Host "Ingrese el término de búsqueda"
        Search-YouTube -searchTerm $searchTerm
    } elseif ($option -eq "2") {
        $videoUrl = Read-Host "Ingrese la URL del video"
        Start-Video -videoUrl $videoUrl
    } elseif ($option -eq "3") {
        Show-History
        Pause
    } elseif ($option -eq "4") {
        Show-Favorites
        Pause
    } elseif ($option -eq "5") {
        $videoUrl = Read-Host "Ingrese la URL del video para agregar a favoritos"
        Add-ToFavorites -videoUrl $videoUrl
        Pause
    } elseif ($option -eq "6") {
        Start-RandomFavorite
        Pause
    } elseif ($option -eq "7") {
        Write-Host "Saliendo del script..." -ForegroundColor Green
        break
    } else {
        Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
        Pause
    }
} while ($true)
