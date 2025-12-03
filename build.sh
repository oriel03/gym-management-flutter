#!/bin/bash

# Configurar para evitar errores interactivos
export DEBIAN_FRONTEND=noninteractive

# Instalar Flutter si no está
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Configurar PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Precaché Flutter (acelera la compilación)
flutter precache --web

# Deshabilitar analytics
flutter config --no-analytics

# Obtener dependencias
echo "Obteniendo dependencias..."
flutter pub get

# Compilar para web con optimizaciones
echo "Compilando para web..."
flutter build web \
  --release \
  --web-renderer canvaskit \
  --no-tree-shake-icons

echo "Compilación completada"