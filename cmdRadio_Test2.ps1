# cmdRadio - Smelpillow - Libre de usar y compartir
# Este script permite crear una lista de reproducción M3U con las emisoras de radio disponibles en la carpeta especificada.
# Requiere PowerShell 5.0 o superior y MPV para la reproducción de las emisoras.

# Configuración inicial
$musicFolder = Read-Host "Ingrese la ruta de la carpeta de música [C:\GitHub\m3u-radio-music-playlists]"
if (-not $musicFolder) {
    $musicFolder = "C:\GitHub\m3u-radio-music-playlists"
}

# Verificar si la carpeta existe
if (-not (Test-Path $musicFolder)) {
    Write-Host "La carpeta de música no existe: $musicFolder" -ForegroundColor Red
    exit
}

# Obtener todos los archivos M3U en la carpeta y subcarpetas
$m3uFiles = Get-ChildItem -Path $musicFolder -Filter "*.m3u" -Recurse | Select-Object -ExpandProperty FullName

# Función para reproducir un archivo con mpv
function Start-WithMpv {
    param (
        [string]$filePath
    )
    # Reproducir el archivo directamente en la terminal
    & mpv --shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' --script-opts=osc-visibility=always "$filePath"
    return $true
}

# Función para buscar Radio Online
function Search-RadioOnline {
    param (
        [string]$searchTerm
    )
    if (-not $searchTerm -or $searchTerm.Trim() -eq "") {
    Write-Host "Debes ingresar un texto para buscar." -ForegroundColor Yellow
    Pause
    return
    }
    $apiUrl = "https://de1.api.radio-browser.info/json/stations/search?name=$searchTerm"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        if ($response.Count -eq 0) {
            Write-Host "No se encontraron estaciones que coincidan con '$searchTerm'" -ForegroundColor Red
        } else {
            # Almacenar los resultados de la búsqueda
            $searchResults = $response
            $pageSize = 20
            $currentPage = 0
            $totalPages = [math]::Ceiling($searchResults.Count / $pageSize)

            do {
                Clear-Host
                Write-Host "Resultados de búsqueda para '$searchTerm' (Página $($currentPage + 1) de $totalPages):" -ForegroundColor Cyan
                $startIndex = $currentPage * $pageSize
                $endIndex = [math]::Min($startIndex + $pageSize, $searchResults.Count) - 1

                for ($i = $startIndex; $i -le $endIndex; $i++) {
                    Write-Host "$($i + 1). $($searchResults[$i].name) - $($searchResults[$i].url)"
                }

                Write-Host "=============================================="
                Write-Host "W. Página siguiente" -ForegroundColor Blue
                Write-Host "E. Página anterior" -ForegroundColor Green
                Write-Host "R. Reproducir una estación aleatoria de los resultados" -ForegroundColor Magenta
                Write-Host "Q. Salir" -ForegroundColor Red
                Write-Host "=============================================="

                $selection = Read-Host "Seleccione el número de la estación o un comando"
                if ($selection -match '^\d+$') {
                    $index = [int]$selection - 1
                    if ($index -ge 0 -and $index -lt $searchResults.Count) {
                        $selectedStation = $searchResults[$index]
                        if (-not $selectedStation.url) {
                            Write-Host "La estación seleccionada no tiene una URL válida." -ForegroundColor Red
                        } else {
                            if (Start-WithMpv $selectedStation.url) {
                                Write-Action "Reproduciendo estación online: $($selectedStation.name) - $($selectedStation.url)"
                                Add-ToHistory -station $selectedStation.url
                            }
                        }
                        break
                    } else {
                        Write-Host "Número fuera de rango. Intente de nuevo." -ForegroundColor Red
                    }
                } elseif ($selection -eq "w" -or $selection -eq "W") {
                    if ($currentPage -lt ($totalPages - 1)) {
                        $currentPage++
                    } else {
                        Write-Host "Ya estás en la última página." -ForegroundColor Yellow
                    }
                } elseif ($selection -eq "e" -or $selection -eq "E") {
                    if ($currentPage -gt 0) {
                        $currentPage--
                    } else {
                        Write-Host "Ya estás en la primera página." -ForegroundColor Yellow
                    }
                } elseif ($selection -eq "r" -or $selection -eq "R") {
                    # Reproducir una estación aleatoria de los resultados
                    do {
                        $randomStation = Get-Random -InputObject $searchResults
                        if (-not $randomStation.url) {
                            Write-Host "La estación seleccionada no tiene una URL válida." -ForegroundColor Red
                        } else {
                            Write-Host "Reproduciendo estación aleatoria: $($randomStation.name)" -ForegroundColor Green
                            Write-Host "URL: $($randomStation.url)" -ForegroundColor Cyan
                            try {
                                if (Start-WithMpv $randomStation.url) {
                                    Write-Action "Reproduciendo estación online aleatoria: $($randomStation.name) - $($randomStation.url)"
                                    Add-ToHistory -station $randomStation.url
                                }
                            } catch {
                                Write-Host "Error al reproducir la estación: $_" -ForegroundColor Red
                                Write-Action "Error al reproducir estación aleatoria: $($randomStation.name) - $_"
                            }
                        }
                        $repeat = Read-Host "¿Quieres reproducir otra estación aleatoria? (S/N) [S]"
                        if ($repeat -eq "" -or $repeat -eq "S" -or $repeat -eq "s") {
                            $repeat = $true
                        } else {
                            $repeat = $false
                        }
                    } while ($repeat)
                } elseif ($selection -eq "q" -or $selection -eq "Q") {
                    break
                } else {
                    Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
                }
            } while ($true)
        }
    } catch {
        Write-Host "Error al consultar la API: $_" -ForegroundColor Red
    }
}

# Función de busqueda local de estaciones
function Search-LocalStations {
    param (
        [string]$searchTerm
    )
    if (-not $searchTerm -or $searchTerm.Trim() -eq "") {
        Write-Host "Debes ingresar un texto para buscar." -ForegroundColor Yellow
        Pause
        return
    }
    $results = $m3uFiles | Where-Object { $_ -like "*$searchTerm*" } | Sort-Object { Split-Path $_ -Leaf }
    if ($results.Count -eq 0) {
        Write-Host "No se encontraron archivos que coincidan con '$searchTerm'" -ForegroundColor Red
        Pause
        return
    }
    do {
        $i = 1
        foreach ($file in $results) {
            Write-Host "$i. $(Split-Path $file -Leaf)"
            $i++
        }
        Write-Host "R. Reproducir una estación aleatoria de los resultados" -ForegroundColor Magenta
        Write-Host "Q. Salir de la búsqueda" -ForegroundColor Red

        $selection = Read-Host "Seleccione el número de la estación, 'R' para aleatoria o 'Q' para salir"
        if ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $results.Count) {
                $selectedFile = $results[$index]
                if ((Get-Content $selectedFile).Length -eq 0) {
                    Write-Host "El archivo está vacío: $(Split-Path $selectedFile -Leaf)" -ForegroundColor Red
                    Write-Action "Intento de reproducción de archivo vacío: $selectedFile"
                } else {
                    Write-Host "Estás escuchando $(Split-Path $selectedFile -Leaf)" -ForegroundColor Green
                    try {
                        Start-WithMpv $selectedFile
                        Write-Action "Reproduciendo archivo: $selectedFile"
                        Add-ToHistory -station $selectedFile
                    } catch {
                        Write-Host "Error al reproducir el archivo: $_" -ForegroundColor Red
                        Write-Action "Error al reproducir archivo: $selectedFile - $_"
                    }
                }
                Pause
                break
            } else {
                Write-Host "Número fuera de rango." -ForegroundColor Red
                Pause
            }
        } elseif ($selection -eq "r" -or $selection -eq "R") {
            do {
                $randomFile = Get-Random -InputObject $results
                if ((Get-Content $randomFile).Length -eq 0) {
                    Write-Host "El archivo está vacío: $(Split-Path $randomFile -Leaf)" -ForegroundColor Red
                    Write-Action "Intento de reproducción de archivo vacío: $randomFile"
                } else {
                    Write-Host "Reproduciendo estación aleatoria: $(Split-Path $randomFile -Leaf)" -ForegroundColor Green
                    try {
                        Start-WithMpv $randomFile
                        Write-Action "Reproduciendo archivo aleatorio: $randomFile"
                        Add-ToHistory -station $randomFile
                    } catch {
                        Write-Host "Error al reproducir el archivo: $_" -ForegroundColor Red
                        Write-Action "Error al reproducir archivo aleatorio: $randomFile - $_"
                    }
                }
                $repeat = Read-Host "¿Quieres reproducir otra estación aleatoria? (S/N) [S]"
                if ($repeat -eq "" -or $repeat -eq "S" -or $repeat -eq "s") {
                    $repeat = $true
                } else {
                    $repeat = $false
                }
            } while ($repeat)
        } elseif ($selection -eq "q" -or $selection -eq "Q") {
            break
        } else {
            Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
            Pause
        }
    } while ($true)
}

# Función para reproducir una estación aleatoria en línea
function Get-RandomRadioOnline {
    $apiUrl = "https://de1.api.radio-browser.info/json/stations"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        if ($response.Count -eq 0) {
            Write-Host "No se encontraron estaciones disponibles en la API." -ForegroundColor Red
        } else {
            $randomStation = Get-Random -InputObject $response
            if (-not $randomStation.url) {
                Write-Host "La estación seleccionada no tiene una URL válida." -ForegroundColor Red
            } else {
                Write-Host "Reproduciendo estación aleatoria: $($randomStation.name)" -ForegroundColor Green
                Write-Host "URL: $($randomStation.url)" -ForegroundColor Cyan
                if (Start-WithMpv $randomStation.url) {
                    Write-Action "Reproduciendo estación online aleatoria: $($randomStation.name) - $($randomStation.url)"
                    Add-ToHistory -station $randomStation.url
                }
            }
        }
    } catch {
        Write-Host "Error al consultar la API: $_" -ForegroundColor Red
    }
}

# Variable global para el historial de reproducción
$playHistory = @()

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
        [int]$pageSize = 15
    )
    $currentPage = 0
    $totalPages = [math]::Ceiling($m3uFiles.Count / $pageSize)

    do {
        Clear-Host
        Write-Host "=============================================="
        Write-Host "        cmdRadio 2.0 Menu (Página $($currentPage + 1) de $totalPages)" -ForegroundColor Cyan
        Write-Host "=============================================="

        # Mostrar estaciones de la página actual
        $startIndex = $currentPage * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize, $m3uFiles.Count) - 1

        for ($i = $startIndex; $i -le $endIndex; $i++) {
        Write-Host "$($i + 1). $(Split-Path $m3uFiles[$i] -Leaf)"
        }

        Write-Host "=============================================="
        Write-Host "W. Página siguiente" -ForegroundColor Blue
        Write-Host "E. Página anterior" -ForegroundColor Green
        Write-Host "R. Reproducir una estación al azar" -ForegroundColor Magenta
        Write-Host "B. Buscar estación local por nombre" -ForegroundColor DarkYellow
        Write-Host "O. Buscar estación en línea" -ForegroundColor Cyan
        Write-Host "X. Reproducir estación aleatoria en línea" -ForegroundColor Magenta
        Write-Host "H. Historial de reproducción" -ForegroundColor DarkGreen
        Write-Host "F. Favoritos" -ForegroundColor DarkRed
        Write-Host "A. Agregar estación a favoritos" -ForegroundColor DarkBlue
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
        } elseif ($answer -eq "p" -or $answer -eq "P") {
            return "play"
        } elseif ($answer -eq "a" -or $answer -eq "A") {
            return "addFavorite"
        } elseif ($answer -eq "q" -or $answer -eq "Q") {
            return "quit"
        } elseif ($answer -eq "o" -or $answer -eq "O") {
            return "radioonline"
        } elseif ($answer -eq "x" -or $answer -eq "X") {
            return "randomOnline"
        } elseif ($answer -eq "b" -or $answer -eq "B") {
            $searchTerm = Read-Host "Ingrese el texto a buscar"
            Search-LocalStations -searchTerm $searchTerm
        } else {
            Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
            Pause
        }
    } while ($true)
}

function Write-Action {
    param (
        [string]$message
    )
    # Cambiar la ubicación del archivo de log a la carpeta del usuario
    $logFolder = Join-Path $env:USERPROFILE "cmdRadio"
    if (-not (Test-Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder | Out-Null
    }
    $logFile = Join-Path $logFolder "log.txt"
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

# Archivo para almacenar favoritos
$favoritesFile = "C:\GitHub\cmdRadio\favorites.txt"

# Cargar favoritos desde el archivo
if (Test-Path $favoritesFile) {
    $favorites = Get-Content $favoritesFile
} else {
    $favorites = @()
}

# Función para cargar los favoritos desde el archivo
function Get-Favorites {
    if (Test-Path $favoritesFile) {
        return Get-Content $favoritesFile
    } else {
        return @()
    }
}

# Función para manejar favoritos
function Add-ToFavorites {
    param (
        [string]$station
    )
    if ($favorites -contains $station) {
        Write-Host "La estación ya está en favoritos." -ForegroundColor Yellow
    } else {
        # Agregar el favorito al archivo
        Add-Content -Path $favoritesFile -Value $station
        # Actualizar la variable $favorites
        $favorites = Get-Favorites
        Write-Host "Estación agregada a favoritos: $station" -ForegroundColor Green
    }
}

# Función para mostrar favoritos
function Show-Favorites {
    # Actualizar la variable $favorites antes de mostrar
    $favorites = Get-Favorites
    if ($favorites.Count -eq 0) {
        Write-Host "No tienes estaciones favoritas." -ForegroundColor Yellow
    } else {
        Write-Host "Estaciones favoritas:" -ForegroundColor Cyan
        $favorites | ForEach-Object { Write-Host $_ }
    }
}

# Función para manejar historial de reproducción
function Add-ToHistory {
    param (
        [string]$station
    )
    $global:playHistory += $station
    Write-Action "Estación añadida al historial: $station"
}

function Show-History {
    if ($playHistory.Count -eq 0) {
        Write-Host "El historial de reproducción está vacío." -ForegroundColor Yellow
    } else {
        Write-Host "Historial de reproducción:" -ForegroundColor Cyan
        $playHistory | ForEach-Object { Write-Host $_ }
    }
}

# Verifica la instalación de mpv antes de continuar
Test-MpvInstallation

do {
    $result = Show-Menu -pageSize 30
    
    if ($result -is [int]) {
    # Reproducir estación seleccionada
    $selectedFile = $m3uFiles[$result]
        if ((Get-Content $selectedFile).Length -eq 0) {
            Write-Host "El archivo está vacío: $(Split-Path $selectedFile -Leaf)" -ForegroundColor Red
            Write-Action "Intento de reproducción de archivo vacío: $selectedFile"
        } else {
            Write-Host "Estás escuchando $(Split-Path $selectedFile -Leaf)" -ForegroundColor Green
            try {
                if (Start-WithMpv $selectedFile) {
                    Write-Action "Reproduciendo archivo: $selectedFile"
                    Add-ToHistory -station $selectedFile
                }
            } catch {
                Write-Host "Error al reproducir el archivo: $_" -ForegroundColor Red
                Write-Action "Error al reproducir archivo: $selectedFile - $_"
            }
        }
        Pause
        } elseif ($result -eq "random") {
    # Reproducir una estación al azar
        do {
            $selectedFile = Get-Random -InputObject $m3uFiles
            if ((Get-Content $selectedFile).Length -eq 0) {
                Write-Host "El archivo está vacío: $(Split-Path $selectedFile -Leaf)" -ForegroundColor Red
                Write-Action "Intento de reproducción de archivo vacío: $selectedFile"
            } else {
                Write-Host "Reproduciendo una estación al azar: $(Split-Path $selectedFile -Leaf)" -ForegroundColor Green
                try {
                    if (Start-WithMpv $selectedFile) {
                        Write-Action "Reproduciendo archivo: $selectedFile"
                        Add-ToHistory -station $selectedFile
                }
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
    } elseif ($result -eq "radioonline") {
        # Buscar estación en línea
        $searchTerm = Read-Host "Ingrese el término de búsqueda"
        Search-RadioOnline -searchTerm $searchTerm
        Pause
    } elseif ($result -eq "randomOnline") {
        # Reproducir una estación al azar
        Get-RandomRadioOnline
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
