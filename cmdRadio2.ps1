# Configuración inicial
$musicFolder = Read-Host "Ingrese la ruta de la carpeta de música [C:\GitHub\cmdRadio\InternetRadio]"
if (-not $musicFolder) {
    $musicFolder = "C:\GitHub\cmdRadio\InternetRadio"
}

if (-not (Test-Path $musicFolder)) {
    Write-Host "La carpeta de música no existe: $musicFolder" -ForegroundColor Red
    exit
}

$m3uFiles = Get-ChildItem -Path $musicFolder -Filter "*.m3u" | Select-Object -ExpandProperty Name

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

# Función para mostrar el menú con paginación
function Show-Menu {
    param (
        [int]$pageSize = 10
    )
    $currentPage = 0
    $totalPages = [math]::Ceiling($m3uFiles.Count / $pageSize)

    do {
        Clear-Host
        Write-Host "=============================================="
        Write-Host "        Radio Stations Menu (Página $($currentPage + 1) de $totalPages)" -ForegroundColor Cyan
        Write-Host "=============================================="

        # Mostrar estaciones de la página actual
        $startIndex = $currentPage * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize, $m3uFiles.Count) - 1
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            Write-Host "$($i + 1). $($m3uFiles[$i])"
        }

        Write-Host "=============================================="
        Write-Host "W. Página siguiente" -ForegroundColor Blue
        Write-Host "E. Página anterior" -ForegroundColor Green
        Write-Host "R. Reproducir una estación al azar" -ForegroundColor Magenta
        Write-Host "S. Buscar estación" -ForegroundColor Yellow
        Write-Host "H. Historial de reproducción" -ForegroundColor DarkGreen
        Write-Host "F. Favoritos" -ForegroundColor DarkRed
        Write-Host "A. Agregar estación a favoritos" -ForegroundColor DarkBlue
        write-Host "T. Temporizador de apagado" -ForegroundColor Red
        Write-Host "V. Ajustar volumen" -ForegroundColor Cyan
        Write-Host "Q. Salir" -ForegroundColor Green
        Write-Host "=============================================="

        $answer = Read-Host "Ingrese el número de opción o comando"

        if ($answer -match '^\d+$') {
            $index = [int]$answer - 1
            if ($index -ge $startIndex -and $index -le $endIndex) {
                return $index
            } else {
                Write-Host "Número fuera de rango. Intente de nuevo." -ForegroundColor Red
                Pause
            }
        } elseif ($answer -eq "w" -or $answer -eq "W") {
            if ($currentPage -lt ($totalPages - 1)) {
                $currentPage++
            } else {
                Write-Host "Ya estás en la última página." -ForegroundColor Yellow
                Pause
            }
        } elseif ($answer -eq "e" -or $answer -eq "E") {
            if ($currentPage -gt 0) {
                $currentPage--
            } else {
                Write-Host "Ya estás en la primera página." -ForegroundColor Yellow
                Pause
            }
        } elseif ($answer -eq "r" -or $answer -eq "R") {
            return "random"
        } elseif ($answer -eq "f" -or $answer -eq "F") {
            return "favorites"
        } elseif ($answer -eq "h" -or $answer -eq "H") {
            return "history"
        } elseif ($answer -eq "s" -or $answer -eq "S") {
            return "search"
        } elseif ($answer -eq "t" -or $answer -eq "T") {
            return "timer"
        } elseif ($answer -eq "v" -or $answer -eq "V") {
            return "volume"
        } elseif ($answer -eq "p" -or $answer -eq "P") {
            return "play"
        } elseif ($answer -eq "a" -or $answer -eq "A") {
            return "addFavorite"
        } elseif ($answer -eq "q" -or $answer -eq "Q") {
            return "quit"
        } else {
            Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
            Pause
        }
    } while ($true)
}

# Función para registrar logs
function Write-Action {
    param (
        [string]$message
    )
    $logFile = "C:\GitHub\cmdRadio\log.txt"
    Add-Content -Path $logFile -Value "$(Get-Date) - $message"
}

# Función para buscar estaciones
function Search-Stations {
    param (
        [string]$searchTerm
    )
    $filteredFiles = $m3uFiles | Where-Object { $_ -like "*$searchTerm*" }
    if ($filteredFiles.Count -eq 0) {
        Write-Host "No se encontraron estaciones que coincidan con '$searchTerm'" -ForegroundColor Red
    } else {
        Write-Host "Estaciones encontradas:" -ForegroundColor Cyan
        $filteredFiles | ForEach-Object { Write-Host $_ }
    }
}

# Archivo para almacenar favoritos
$favoritesFile = "C:\GitHub\cmdRadio\favorites.txt"

# Cargar favoritos desde el archivo
if (Test-Path $favoritesFile) {
    $favorites = Get-Content $favoritesFile
} else {
    $favorites = @()
}

# Función para manejar favoritos
function Add-ToFavorites {
    param (
        [string]$station
    )
    if ($favorites -contains $station) {
        Write-Host "La estación ya está en favoritos." -ForegroundColor Yellow
    } else {
        $favorites += $station
        $favorites | Set-Content -Path $favoritesFile
        Write-Host "Estación agregada a favoritos: $station" -ForegroundColor Green
    }
}

function Show-Favorites {
    if ($favorites.Count -eq 0) {
        Write-Host "No tienes estaciones favoritas." -ForegroundColor Yellow
    } else {
        Write-Host "Estaciones favoritas:" -ForegroundColor Cyan
        $favorites | ForEach-Object { Write-Host $_ }
    }
}

# Función para manejar historial de reproducción
$playHistory = @()

function Add-ToHistory {
    param (
        [string]$station
    )
    $playHistory += $station
}

function Show-History {
    Write-Host "Historial de reproducción:" -ForegroundColor Cyan
    $playHistory | ForEach-Object { Write-Host $_ }
}

# Función para ajustar el volumen
function Set-Volume {
    param (
        [int]$volumeLevel
    )
    if ($volumeLevel -lt 0 -or $volumeLevel -gt 100) {
        Write-Host "El nivel de volumen debe estar entre 0 y 100." -ForegroundColor Red
    } else {
        mpv --volume=$volumeLevel
        Write-Host "Volumen ajustado a $volumeLevel%" -ForegroundColor Green
    }
}

# Función para configurar temporizador de apagado
function Set-Timer {
    param (
        [int]$minutes
    )
    Write-Host "El temporizador está configurado para detener la reproducción en $minutes minutos." -ForegroundColor Green
    Start-Sleep -Seconds ($minutes * 60)
    Stop-Process -Name "mpv"
    Write-Host "Reproducción detenida después de $minutes minutos." -ForegroundColor Green
}

# Verifica la instalación de mpv antes de continuar
Test-MpvInstallation

do {
    $result = Show-Menu -pageSize 15

    if ($result -is [int]) {
        # Reproducir estación seleccionada
        $selectedFile = Join-Path $musicFolder $m3uFiles[$result]
        if ((Get-Content $selectedFile).Length -eq 0) {
            Write-Host "El archivo está vacío: $($m3uFiles[$result])" -ForegroundColor Red
            Write-Action "Intento de reproducción de archivo vacío: $selectedFile"
        } else {
            Write-Host "Estás escuchando $($m3uFiles[$result])" -ForegroundColor Green
            try {
                mpv --shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' $selectedFile
                Write-Action "Reproduciendo archivo: $selectedFile"
                Add-ToHistory -station $selectedFile
            } catch {
                Write-Host "Error al reproducir el archivo: $_" -ForegroundColor Red
                Write-Action "Error al reproducir archivo: $selectedFile - $_"
            }
        }
        Pause
    } elseif ($result -eq "random") {
        # Reproducir una estación al azar
        do {
            $randomFile = Get-Random -InputObject $m3uFiles
            $selectedFile = Join-Path $musicFolder $randomFile
            if ((Get-Content $selectedFile).Length -eq 0) {
                Write-Host "El archivo está vacío: $($randomFile)" -ForegroundColor Red
                Write-Action "Intento de reproducción de archivo vacío: $selectedFile"
            } else {
                Write-Host "Reproduciendo una estación al azar: $($randomFile)" -ForegroundColor Green
                try {
                    mpv --shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' $selectedFile
                    Write-Action "Reproduciendo archivo al azar: $selectedFile"
                    Add-ToHistory -station $selectedFile
                } catch {
                    Write-Host "Error al reproducir el archivo: $_" -ForegroundColor Red
                    Write-Action "Error al reproducir archivo al azar: $selectedFile - $_"
                }
            }
            $repeat = Read-Host "¿Quieres reproducir otra estación al azar? (S/N) [S]"
            if ($repeat -eq "" -or $repeat -eq "S" -or $repeat -eq "s") {
                $repeat = $true
            } else {
                $repeat = $false
            }
        } while ($repeat)
    } elseif ($result -eq "search") {
        # Buscar estación
        $searchTerm = Read-Host "Ingrese el término de búsqueda"
        Search-Stations -searchTerm $searchTerm
        Pause
    } elseif ($result -eq "favorites") {
        # Mostrar favoritos
        Show-Favorites
        Pause
    } elseif ($result -eq "addFavorite") {
        # Agregar estación a favoritos
        $stationToAdd = Read-Host "Ingrese el nombre de la estación para agregar a favoritos"
        Add-ToFavorites -station $stationToAdd
        Pause
    } elseif ($result -eq "history") {
        # Mostrar historial de reproducción
        Show-History
        Pause
    } elseif ($result -eq "volume") {
        # Ajustar volumen
        $volumeLevel = Read-Host "Ingrese el nivel de volumen (0-100)"
        Set-Volume -volumeLevel $volumeLevel
        Pause
    } elseif ($result -eq "timer") {
        # Configurar temporizador de apagado
        $minutes = Read-Host "Ingrese el tiempo en minutos para detener la reproducción"
        Set-Timer -minutes $minutes
        Pause
    } elseif ($result -eq "quit") {
        # Salir del script
        Write-Host "Saliendo del script..." -ForegroundColor Green
        Write-Action "Saliendo del script"
        exit
    } else {
        Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
    }
} while ($true)
