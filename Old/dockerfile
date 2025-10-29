# Usa una imagen base de PowerShell
FROM mcr.microsoft.com/powershell:latest

# Instala mpv
RUN apt-get update && \
    apt-get install -y mpv && \
    apt-get clean

# Crea un directorio de trabajo
WORKDIR /app

# Copia el script y los archivos necesarios al contenedor
COPY cmdRadio.ps1 /app/cmdRadio.ps1
COPY InternetRadio /app/InternetRadio
COPY MpvConfig /app/MpvConfig

# Establece el script como ejecutable por defecto
CMD ["pwsh", "/app/cmdRadio.ps1"]