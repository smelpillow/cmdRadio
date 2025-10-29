function Start-Menu {
    param (
        [string[]]$Opciones,
        [int]$Columnas = 2
    )

    $filas = [math]::Ceiling($Opciones.Count / $Columnas)
    Write-Host "`n=== MENÚ PRINCIPAL ===`n"
    for ($i = 0; $i -lt $filas; $i++) {
        $linea = ""
        for ($j = 0; $j -lt $Columnas; $j++) {
            $index = $i + $j * $filas
            if ($index -lt $Opciones.Count) {
                $numero = $index + 1
                $texto = "$numero) $($Opciones[$index])"
                $linea += "{0,-35}" -f $texto
            }
        }
        Write-Host $linea
    }

    do {
        $seleccion = Read-Host "`nSelecciona una opción (1-$($Opciones.Count))"
        $valida = $seleccion -as [int]
    } while ($valida -lt 1 -or $valida -gt $Opciones.Count)

    return $valida
}

$menuOpciones = @(
    "Generar certificado VPN",
    "Revocar certificado",
    "Exportar CSV",
    "Ver logs de errores",
    "Actualizar repositorio",
    "Salir"
)

$opcionElegida = Start-Menu -Opciones $menuOpciones

switch ($opcionElegida) {
    1 { Ejecutar-GenerarCertificado }
    2 { Ejecutar-RevocarCertificado }
    3 { Ejecutar-ExportarCSV }
    4 { Ejecutar-VerLogs }
    5 { Ejecutar-ActualizarRepo }
    6 { Write-Host "Saliendo..."; exit }
}
