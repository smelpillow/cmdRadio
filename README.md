# cmdRadio

Bienvenido a este proyecto GitHub que basícamente se trata de un script que utiliza el reproductor por comando MPV y un listado de ficheros .m3u para reproducir las emisoras por internet.

## Requisitos

El script requiere de la instalación de Mpv https://mpv.io/installation/ que recomiendo instalar mediante Chocolatey https://chocolatey.org/install. Tambien necesitamos tener generado un pefil de Powershell para poder añadir la función, ademas de reconfigurar la ejecución de scripts en powershell.

Recomiendo seguir los siguientes pasos:

1. Instalar Chocolatey.
2. Instalar MPV.
3. Modificar la ejecución de scripts.
    ```Powershell
    Set-ExecutionPolicy Bypass -Scope LocalMachine
    ```
4. Crear perfil de powershell.
    ```powershell
    if (!(Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force
    }
    ```
5. Añadir la funcion al perfil.
    ```powershell
    Add-Content -Path $PROFILE -Value "function cmdRadio {C:\Github\cmdRadio\cmdRadio.ps1}"
    ```
6. Reinicar el terminal para que se apliquen los cambios.

## Instalación

Despues de instalar los requisitos, la instalación es simplemente descargar el proyecto y ubicarlo preferiblemente en "C:\GitHub\cmdRadio" de este modo no tendremos que modificar la ubicación de los ficheros .m3u.

En caso de que la carpeta la queramos poner en otra ubicación, tendremos que editar el fichero "cmdRadio.ps1" y modificar la ruta en la primera linea del script.

## Utilización

Para ejecutar el script tendremos que abrir una consola de Powershell y si hemos configurado la funcion en el profile podremos ejecutar directamente "cmdRadio", en caso de no tener generada la función habrá que abrir la ubicación del script y ejecutar directamente, por ejemplo "C:\Github\cmdRadio\cmdRadio.ps1".

El script lee los ficheros .m3u que estan en la carpeta .\InternetRadio, los muestra como un listado y le asigna un numero, al final pregunta que opción deseas, si se pone un numero que no corresponde el script da error.

## Personalización

Hay varias cosas que podemos personalizar dentro del script, pero principalmente lo que mas nos interesará es el mantenimiento de los ficheros .m3u, el listado se ha obtenido de este otro proyecto GitHub (https://github.com/junguler/m3u-radio-music-playlists), este proyecto tiene muchisimos enlaces de radios, pero personalmente he creado una pequeña selección.

En caso de querer modificar los ficheros, los tendremos en "C:\GitHub\cmdRadio\InternetRadio", ahí podemos modificar, añadir o quitar los ficheros de las listas.

## Configuración de MPV

Se añaden ficheros de configuración de Mpv, para que se pueda modificar la configuración y que sea una configuración específica para el script.
