# Función para iniciar mpv con soporte IPC
function Start-MpvWithIpc {
    param (
        [string]$filePath,
        [string]$ipcSocket = "\\\\.\\pipe\\mpv-socket"
    )

    try {
        Write-Host "Iniciando mpv con soporte IPC..." -ForegroundColor Cyan
        Start-Process -FilePath "mpv" -ArgumentList "--input-ipc-server=$ipcSocket", "--shuffle", "--config-dir='C:\Github\cmdRadio\MpvConfig'", $filePath -NoNewWindow
        Start-Sleep -Seconds 5  # Aumentar tiempo de espera para garantizar que mpv esté listo
        Write-Host "mpv iniciado correctamente." -ForegroundColor Green
    } catch {
        Write-Host "Error al iniciar mpv: $_" -ForegroundColor Red
    }
}

# Función para enviar comandos JSON a mpv
function Send-MpvCommand {
    param (
        [string]$ipcSocket = "\\\\.\\pipe\\mpv-socket",
        [hashtable]$command
    )

    try {
        $jsonCommand = $command | ConvertTo-Json -Depth 10
        Write-Host "Enviando comando JSON: $jsonCommand" -ForegroundColor Cyan

        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $ipcSocket, [System.IO.Pipes.PipeDirection]::InOut)
        $pipe.Connect(1000)  # Tiempo de espera para conectar
        $writer = New-Object System.IO.StreamWriter($pipe)
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($pipe)

        # Enviar comando
        $writer.WriteLine($jsonCommand)

        # Leer respuesta
        $response = $reader.ReadLine()
        Write-Host "Respuesta del socket: $response" -ForegroundColor Green

        $pipe.Close()
        return $response | ConvertFrom-Json
    } catch {
        Write-Host "Error al enviar comando a mpv: $_" -ForegroundColor Red
    }
}

# Función para reproducir una estación con JSON IPC
function Start-RadioWithIpc {
    param (
        [string]$url
    )

    $ipcSocket = "\\\\.\\pipe\\mpv-socket"

    if (-not $url) {
        Write-Host "La URL proporcionada está vacía. Intente de nuevo." -ForegroundColor Red
        return
    }

    # Iniciar mpv con IPC
    Start-MpvWithIpc -filePath $url -ipcSocket $ipcSocket

    # Confirmar que mpv está reproduciendo
    Write-Host "Reproduciendo estación: $url" -ForegroundColor Green
}

# Menú en modo texto para ejecutar las funciones
function Show-TextMenu {
    do {
        Clear-Host
        Write-Host "=============================================="
        Write-Host "          cmdRadio IPC Menu" -ForegroundColor Cyan
        Write-Host "=============================================="
        Write-Host "1. Reproducir una estación" -ForegroundColor Green
        Write-Host "2. Pausar reproducción" -ForegroundColor Yellow
        Write-Host "3. Reanudar reproducción" -ForegroundColor Cyan
        Write-Host "4. Detener reproducción" -ForegroundColor Red
        Write-Host "5. Salir" -ForegroundColor Magenta
        Write-Host "=============================================="

        $choice = Read-Host "Seleccione una opción (1-5)"

        switch ($choice) {
            "1" {
                Write-Host "Opción seleccionada: Reproducir una estación" -ForegroundColor Cyan
                $url = Read-Host "Ingrese la URL de la estación"
                Start-RadioWithIpc -url $url
                Pause
            }
            "2" {
                Write-Host "Opción seleccionada: Pausar reproducción" -ForegroundColor Yellow
                $pauseCommand = @{
                    "command" = @("set_property", "pause", $true)
                }
                Send-MpvCommand -command $pauseCommand
                Write-Host "Reproducción pausada." -ForegroundColor Yellow
                Pause
            }
            "3" {
                Write-Host "Opción seleccionada: Reanudar reproducción" -ForegroundColor Cyan
                $resumeCommand = @{
                    "command" = @("set_property", "pause", $false)
                }
                Send-MpvCommand -command $resumeCommand
                Write-Host "Reproducción reanudada." -ForegroundColor Green
                Pause
            }
            "4" {
                Write-Host "Opción seleccionada: Detener reproducción" -ForegroundColor Red
                $stopCommand = @{
                    "command" = @("quit")
                }
                Send-MpvCommand -command $stopCommand
                Write-Host "Reproducción detenida." -ForegroundColor Red
                Pause
            }
            "5" {
                Write-Host "Saliendo del menú..." -ForegroundColor Magenta
                Exit
            }
            default {
                Write-Host "Opción no válida. Intente de nuevo." -ForegroundColor Red
                Pause
            }
        }
    } while ($true)
}

# Llamar al menú
Show-TextMenu
