# cmdRadio

Bienvenido a este proyecto GitHub que basícamente se trata de un script que utiliza el reproductor por comando MPV y un listado de ficheros .m3u para reproducir las emisoras por internet.

## Requisitos

### Windows

El script requiere de la instalación de Mpv <https://mpv.io/installation/> que recomiendo instalar mediante Chocolatey <https://chocolatey.org/install>. Tambien necesitamos tener generado un pefil de Powershell para poder añadir la función, ademas de reconfigurar la ejecución de scripts en powershell.

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

### Linux

La instalación de MPV en Linux Ubuntu, se realiza de la siguiente manera.

<https://snapcraft.io/install/mpv/ubuntu>

## Instalación

Despues de instalar los requisitos, la instalación es simplemente descargar el proyecto y ubicarlo preferiblemente en "C:\GitHub\cmdRadio" de este modo no tendremos que modificar la ubicación de los ficheros .m3u.

En caso de que la carpeta la queramos poner en otra ubicación, tendremos que editar el fichero "cmdRadio.ps1" y modificar la ruta en la primera linea del script.

## Utilización

Para ejecutar el script tendremos que abrir una consola de Powershell y si hemos configurado la funcion en el profile podremos ejecutar directamente "cmdRadio", en caso de no tener generada la función habrá que abrir la ubicación del script y ejecutar directamente, por ejemplo "C:\Github\cmdRadio\cmdRadio.ps1".

El script lee los ficheros .m3u que estan en la carpeta .\InternetRadio, los muestra como un listado y le asigna un numero, al final pregunta que opción deseas, si se pone un numero que no corresponde el script da error.

## Personalización

Hay varias cosas que podemos personalizar dentro del script, pero principalmente lo que mas nos interesará es el mantenimiento de los ficheros .m3u, el listado se ha obtenido de este otro proyecto GitHub (<https://github.com/junguler/m3u-radio-music-playlists>), este proyecto tiene muchisimos enlaces de radios, pero personalmente he creado una pequeña selección.

En caso de querer modificar los ficheros, los tendremos en "C:\GitHub\cmdRadio\InternetRadio", ahí podemos modificar, añadir o quitar los ficheros de las listas.

### Actualización de ficheros M3U

Añado pequeño script para actualizar los ficheros M3U, antes de ejecutar el script tendremos que clonar el proyecto de GitHub de "junguler" para tener los ultimos ficheros actualizados.

1. Clonamos el proyecto de Junguler (git clone https://github.com/junguler/m3u-radio-music-playlists.git)
2. Antes de ejecutar el script (getM3UFiles.ps1), tendremos que revisar que las variables de la rutas a los ficheros sean correctas.
3. Con esa variable revisada, podemos ejecutar el script, solo se actualizaran los ficheros de la carpeta de cmdRadio en "InternetRadio".
4. Ejecutamos de nuevo el fichero "cmdRadio.ps1" para que se actualize el listado de ficheros.

## Configuración Windows Terminal

Se añade fichero settings.json con los datos para añadir una pestaña personalizada en el Terminal,se añade fichero .png con icono para el Terminal.

## Configuración de MPV

Se añaden ficheros de configuración de Mpv, para que se pueda modificar la configuración y que sea una configuración específica para el script.

Se añade linea "watch-later-directory=~/.mpv/watch_later" en el fichero de configuración de MPV para que los archivos temporales no se guarden dentro del proyecto.
