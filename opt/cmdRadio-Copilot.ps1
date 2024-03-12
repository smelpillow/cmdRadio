$musicFolder = "C:\GitHub\cmdRadio\InternetRadio"
$m3uFiles = Get-ChildItem -Path $musicFolder -Filter "*.m3u" | Select-Object -ExpandProperty Name

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

function Show-Menu {
    Clear-Host
    Write-Host "=============================================="
    Write-Host "        Radio Stations Menu" -ForegroundColor Cyan
    Write-Host "=============================================="
    
    for ($i = 0; $i -lt $m3uFiles.Count; $i++) {
        Write-Host "$($i + 1). $($m3uFiles[$i])"
    }

    # Agregar la opción "Random"
    Write-Host "R. Reproducir una estación al azar" -ForegroundColor Cyan

    Write-Host "Q. Salir" -ForegroundColor Green
    Write-Host "=============================================="
}

# Verifica la instalación de mpv antes de continuar
Test-MpvInstallation

do {
    Show-Menu
    $answer = Read-Host "Ingrese el número de opción"

    if ($answer -match '^\d+$' -and [int]$answer -ge 1 -and [int]$answer -le $m3uFiles.Count) {
        $selectedFile = Join-Path $musicFolder $m3uFiles[$answer - 1]
        Write-Host "Estás escuchando $($m3uFiles[$answer - 1])" -ForegroundColor Green
        mpv --shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' $selectedFile
    }
    elseif ($answer -eq "R" -or $answer -eq "r") {
        # Agregar lógica para reproducir una estación al azar
        Write-Host "Reproduciendo una estación al azar..." -ForegroundColor Green
        # Aquí puedes implementar la reproducción aleatoria
    }
    elseif ($answer -eq "Q" -or $answer -eq "q") {
        Write-Host "Saliendo del script..." -ForegroundColor Green
        exit
    }
    else {
        Write-Host "Opción no válida. Inténtalo de nuevo." -ForegroundColor Red
    }
} while ($true)
