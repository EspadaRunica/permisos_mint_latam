#!/bin/bash

echo "   ____       _                         _                          ";
echo "  / __ \  ___| |__  _ __ ___   ___   __| |_ __ ___   __ _ _____  __";
echo " / / _\` |/ __| '_ \| '_ \` _ \ / _ \ / _\` | '_ \` _ \ / _\` / __\ \/ /";
echo "| | (_| | (__| | | | | | | | | (_) | (_| | | | | | | (_| \__ \>  < ";
echo " \ \__,_|\___|_| |_|_| |_| |_|\___/ \__,_|_| |_| |_|\__,_|___/_/\_\ ";
echo "  \____/                                                           ";
echo "En Dios confiamos | In God we trust"
echo "\n"


#Usuario que accedio como root
USERNAME=$SUDO_USER

# Ruta y nombre de archivo para el .pkla
FILE_PATH="/etc/polkit-1/localauthority/50-local.d/permisos_"$USERNAME"_1.0.pkla"
FILE_NAME="$(basename "$FILE_PATH")"

# Contenido del archivo que se creará
NEW_CONTENT=$(cat << EOF
[Permite ejecutar y realizar ciertas acciones sin contraseña para comodidad de $USERNAME a costa de menor seguridad]
Identity=unix-user:$USERNAME
Action=*
ResultActive=yes
EOF
)

# Verificar si el contenido del archivo es igual al contenido que se creará
if [ -f "$FILE_PATH" ] && [ "$(sudo cat "$FILE_PATH")" = "$NEW_CONTENT" ]; then
    echo #linea en blanco
    echo "El archivo '$FILE_NAME' ya contiene las reglas actualizadas. No se realizaron cambios."
else
    # Si el archivo no es igual al contenido que se creará, hacer una copia de seguridad
    if [ -f "$FILE_PATH" ]; then
        echo #linea en blanco
        echo "Se encontró una versión de '$FILE_NAME', renombrando a '$FILE_NAME.bak'..."
        sudo mv "$FILE_PATH" "$FILE_PATH.bak"
    fi

    echo #linea en blanco

    # Crear el nuevo archivo .pkla con las reglas
    echo "$NEW_CONTENT" | sudo tee "$FILE_PATH" > /dev/null

    # Asignar permisos adecuados al archivo
    sudo chmod 644 "$FILE_PATH"

    echo "El archivo $FILE_NAME ha sido creado con éxito."

    # Agregar configuración para que la terminal no solicite contraseña con sudo
    SUDO_CONFIG_LINE="$USERNAME ALL=(ALL) NOPASSWD: ALL"
    if ! grep -qF "$SUDO_CONFIG_LINE" /etc/sudoers; then
        echo "$SUDO_CONFIG_LINE" | sudo tee -a /etc/sudoers
        echo #linea en blanco
        echo "Configuración para no solicitar contraseña con sudo en la terminal agregada al archivo /etc/sudoers."
    fi

    # Reiniciar el servicio de PolicyKit
    sudo systemctl restart polkit

    echo #linea en blanco
    echo "Se reinició polkit, cambios efectuados."
fi

    echo #linea en blanco
    read -p 'Finalizado, pulse la tecla Enter para salir...'
