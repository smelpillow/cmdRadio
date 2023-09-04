# cmdRadio

Bienvenido a este proyecto GitHub que basícamente se trata de un script que utiliza el reproductor por comando MPV y un listado de ficheros .m3u para reproducir las emisoras por internet.

## Instalación

Sera necesario tener previamente instalado el reproductor por comando MPV, se puede encontrar aqui https://mpv.io/installation/. Se recomienda instalar mediante Chocolatey que resulta todo mas sencillo.

Se recomienda crear una "function" en el fichero profile del usuario para que el acceso sea mas sencillo.

Creación de perfil powershell, en caso de estar generado no hará nada.

```powershell
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
```

Crear la funcion directamente en el profile, se tiene que modificar con el path correspondiente.

```powershell
Add-Content -Path $PROFILE -Value "function cmdRadio {C:\Github\cmdRadio\cmdRadio.ps1}"
```

## Utilización

Para ejecutar el script tendremos que abrir una consola de Powershell y si hemos configurado la funcion en el profile podremos ejecutar directamente "cmdRadio", en caso de no tener generada la función habrá que abrir la ubicación del script y ejecutar directamente, por ejemplo "C:\Github\cmdRadio\cmdRadio.ps1".

El script lee los ficheros .m3u que estan en la carpeta .\InternetRadio, los muestra como un listado y le asigna un numero, al final pregunta que opción deseas, si se pone un numero que no corresponde el script da error.

