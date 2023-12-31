$musicFolder = "C:\GitHub\cmdRadio\InternetRadio"
$m3uFiles = Get-ChildItem -Path $musicFolder -Filter "*.m3u" | Select-Object -ExpandProperty Name

# Verifica si mpv está instalado
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
        Pause
    }
    elseif ($answer -eq "r" -or $answer -eq "R") {
        do {
            $randomFile = Get-Random -InputObject $m3uFiles
            $selectedFile = Join-Path $musicFolder $randomFile
            Write-Host "Reproduciendo una estación al azar: $($randomFile)" -ForegroundColor Green
            mpv --shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' $selectedFile
            $repeat = Read-Host "¿Quieres reproducir otra estación al azar? (S/N) [S]"
            if ($repeat -eq "" -or $repeat -eq "S" -or $repeat -eq "s") {
                $repeat = $true
            } else {
                $repeat = $false
            }
        } while ($repeat)
    }
    elseif ($answer -eq "q" -or $answer -eq "Q") {
        Write-Host "Saliendo del script..." -ForegroundColor Green
        break
    }
    else {
        Write-Host "Opción inválida, por favor seleccione una opción válida." -ForegroundColor Red
        Pause
    }
}
while ($true)

Write-Host "¡Hasta luego!" -ForegroundColor Green
