º#!/bin/bash

musicFolder="/GitHub/cmdRadio/InternetRadio"
m3uFiles=($(find "$musicFolder" -type f -name "*.m3u" -exec basename {} \;))

# Verifica si mpv está instalado
function testMpvInstallation {
    if ! command -v mpv &> /dev/null; then
        read -p "¡Advertencia! mpv no está instalado o no se encuentra en el PATH del sistema. ¿Deseas continuar sin mpv? (S/N) [S]: " response
        if [[ -z "$response" || "$response" == "S" || "$response" == "s" ]]; then
            return
        else
            echo "Saliendo del script..."
            exit
        fi
    fi
}

function showMenu {
    clear
    echo "=============================================="
    echo "        Radio Stations Menu"
    echo "=============================================="
    
    for ((i=0; i<${#m3uFiles[@]}; i++)); do
        echo "$((i + 1)). ${m3uFiles[i]}"
    done

    # Agregar la opción "Random"
    echo "R. Reproducir una estación al azar"

    echo "Q. Salir"
    echo "=============================================="
}

# Verifica la instalación de mpv antes de continuar
testMpvInstallation

while true; do
    showMenu
    read -p "Ingrese el número de opción: " answer

    if [[ "$answer" =~ ^[0-9]+$ && "$answer" -ge 1 && "$answer" -le "${#m3uFiles[@]}" ]]; then
        selectedFile="$musicFolder/${m3uFiles[answer - 1]}"
        echo "Estás escuchando ${m3uFiles[answer - 1]}"
        mpv --shuffle --config-dir='/GitHub/cmdRadio/mpv' "$selectedFile"
        read -p "Presiona Enter para continuar..."
    elif [[ "$answer" == "r" || "$answer" == "R" ]]; then
        while true; do
            randomFile="${m3uFiles[RANDOM % ${#m3uFiles[@]}]}"
            selectedFile="$musicFolder/$randomFile"
            echo "Reproduciendo una estación al azar: $randomFile"
            mpv --shuffle --config-dir='/GitHub/cmdRadio/mpv' "$selectedFile"
            read -p "¿Quieres reproducir otra estación al azar? (S/N) [S]: " repeat
            if [[ -z "$repeat" || "$repeat" == "S" || "$repeat" == "s" ]]; then
                repeat=true
            else
                repeat=false
                break
            fi
        done
    elif [[ "$answer" == "q" || "$answer" == "Q" ]]; then
        echo "Saliendo del script..."
        break
    else
        echo "Opción inválida, por favor seleccione una opción válida."
        read -p "Presiona Enter para continuar..."
    fi
done

echo "¡Hasta luego!"
