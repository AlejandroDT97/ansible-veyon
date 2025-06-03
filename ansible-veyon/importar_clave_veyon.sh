#!/bin/bash

# Obtener los primeros tres bloques de la IP del alumno
RED_BASE=$(hostname -I | awk '{print $1}' | cut -d"." -f1-3)

# IP del profesor en la subred
PROFESOR_IP="${RED_BASE}.200"

# Ruta de montaje temporal
MOUNT_DIR="/tmp/clave_veyon"
CLAVE_PEM="clave-aula_public_key.pem"
NOMBRE_CLAVE="teacher"

# Crear carpeta de montaje si no existe
sudo mkdir -p "$MOUNT_DIR"

# Montar carpeta compartida del profesor
sudo mount -t cifs "//$PROFESOR_IP/veyon" "$MOUNT_DIR" -o guest

# Comprobar si el archivo existe y es legible
if [ ! -r "$MOUNT_DIR/$CLAVE_PEM" ]; then
  echo "[ERROR] No existe o no hay permisos para leer $CLAVE_PEM"
  exit 1
fi

# Crear carpeta de claves si no existe
sudo mkdir -p /etc/veyon/keys/public

# Copiar la clave a la carpeta del sistema
sudo cp "$MOUNT_DIR/$CLAVE_PEM" "/etc/veyon/keys/public/${NOMBRE_CLAVE}_public_key.pem"
sudo chmod 644 "/etc/veyon/keys/public/${NOMBRE_CLAVE}_public_key.pem"

# Importar la clave pública
sudo veyon-cli authkeys import  "$NOMBRE_CLAVE"/public "/etc/veyon/keys/public/${NOMBRE_CLAVE}_public_key.pem"

# Asignar grupo de acceso
sudo veyon-cli authkeys setaccessgroup "$NOMBRE_CLAVE"/public VEYON

# Reiniciar el servicio de Veyon
if systemctl list-unit-files | grep -q veyon.service; then
  sudo systemctl restart veyon
fi

echo "[OK] Clave pública de Veyon importada correctamente desde el profesor (${PROFESOR_IP})"
