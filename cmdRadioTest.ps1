# Configuración inicial
if (Test-Path "/.dockerenv") {
    # Estamos en un contenedor Docker
    $musicFolder = "/app/InternetRadio"
} else {
    # Estamos en el host
    $musicFolder = Read-Host "Ingrese la ruta de la carpeta de música [C:\GitHub\cmdRadio\InternetRadio]"
    if (-not $musicFolder) {
        $musicFolder = "C:\GitHub\cmdRadio\InternetRadio"
    }
}

if (-not (Test-Path $musicFolder)) {
    Write-Host "La carpeta de música no existe: $musicFolder" -ForegroundColor Red
    exit
}

$m3uFiles = Get-ChildItem -Path $musicFolder -Filter "*.m3u" | Select-Object -ExpandProperty Name

# Función para registrar logs
function Write-Action {
    param (
        [string]$message
    )
    $logFile = "C:\GitHub\cmdRadio\log.txt"
    Add-Content -Path $logFile -Value "$(Get-Date) - $message"
}

# Función para reproducir una estación con mpv en segundo plano
function Play-Station {
    param (
        [string]$filePath
    )
    if (-not (Test-Path $filePath)) {
        Write-Host "El archivo no existe: $filePath" -ForegroundColor Red
        return
    }

    try {
        $ipcSocket = "\\.\pipe\mpv-socket"
        Start-Process -FilePath "mpv" -ArgumentList "--shuffle --config-dir='C:\Github\cmdRadio\MpvConfig' --input-ipc-server=$ipcSocket `"$filePath`"" -NoNewWindow -PassThru
        Write-Host "Reproduciendo: $filePath" -ForegroundColor Green
        Write-Action "Reproduciendo archivo: $filePath"
    } catch {
        Write-Host "Error al reproducir el archivo: $_" -ForegroundColor Red
        Write-Action "Error al reproducir archivo: $filePath - $_"
    }
}

# Función para enviar comandos a mpv
function Send-MpvCommand {
    param (
        [string]$command
    )
    $ipcSocket = "\\.\pipe\mpv-socket"
    if (-not (Test-Path $ipcSocket)) {
        Write-Host "No se encontró el socket IPC de mpv. Asegúrate de que mpv esté en ejecución." -ForegroundColor Red
        return
    }

    $jsonCommand = @{
        command = @($command)
    } | ConvertTo-Json -Depth 10

    try {
        $pipe = [System.IO.Pipes.NamedPipeClientStream]::new(".", "mpv-socket", [System.IO.Pipes.PipeDirection]::Out)
        $pipe.Connect()
        $writer = [System.IO.StreamWriter]::new($pipe)
        $writer.WriteLine($jsonCommand)
        $writer.Flush()
        $pipe.Close()
    } catch {
        Write-Host "Error al enviar el comando a mpv: $_" -ForegroundColor Red
    }
}

# Función para detener la reproducción
function Stop-Mpv {
    $mpvProcess = Get-Process -Name "mpv" -ErrorAction SilentlyContinue
    if ($mpvProcess) {
        Stop-Process -Id $mpvProcess.Id
        Write-Host "Reproducción detenida." -ForegroundColor Green
    } else {
        Write-Host "No hay ninguna reproducción en curso." -ForegroundColor Yellow
    }
}

# Menú de prueba
do {
    Clear-Host
    Write-Host "=============================================="
    Write-Host "        Menú de Prueba de cmdRadio" -ForegroundColor Cyan
    Write-Host "=============================================="
    Write-Host "1. Reproducir una estación seleccionada"
    Write-Host "2. Reproducir una estación al azar"
    Write-Host "3. Detener reproducción"
    Write-Host "4. Pausar/Reanudar reproducción"
    Write-Host "5. Subir volumen"
    Write-Host "6. Bajar volumen"
    Write-Host "7. Salir"
    Write-Host "=============================================="

    $option = Read-Host "Seleccione una opción"

    if ($option -eq "1") {
        # Reproducir estación seleccionada
        for ($i = 0; $i -lt $m3uFiles.Count; $i++) {
            Write-Host "$($i + 1). $($m3uFiles[$i])"
        }
        $selection = Read-Host "Seleccione el número de la estación"
        if ($selection -match '^\d+$' -and [int]$selection -le $m3uFiles.Count -and [int]$selection -gt 0) {
            $selectedFile = Join-Path $musicFolder $m3uFiles[[int]$selection - 1]
            Play-Station -filePath $selectedFile
        } else {
            Write-Host "Selección no válida." -ForegroundColor Red
        }
    } elseif ($option -eq "2") {
        # Reproducir una estación al azar
        $randomFile = Get-Random -InputObject $m3uFiles
        $selectedFile = Join-Path $musicFolder $randomFile
        Play-Station -filePath $selectedFile
    } elseif ($option -eq "3") {
        # Detener reproducción
        Stop-Mpv
    } elseif ($option -eq "4") {
        # Pausar/Reanudar reproducción
        Send-MpvCommand -command "cycle pause"
    } elseif ($option -eq "5") {
        # Subir volumen
        Send-MpvCommand -command "add volume 5"
    } elseif ($option -eq "6") {
        # Bajar volumen
        Send-MpvCommand -command "add volume -5"
    } elseif ($option -eq "7") {
        # Salir
        Write-Host "Saliendo del script..." -ForegroundColor Green
        break
    } else {
        Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
    }
} while ($true)
