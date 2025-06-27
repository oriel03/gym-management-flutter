#!/bin/bash

# Define la versión de Flutter que quieres usar
FLUTTER_VERSION="3.19.6" # Puedes usar la versión que quieras

# Descarga el SDK de Flutter
git clone https://github.com/flutter/flutter.git --branch $FLUTTER_VERSION

# Agrega Flutter al PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Verifica que Flutter esté disponible
flutter --version

# Obtiene las dependencias
flutter pub get

# Construye la aplicación web
flutter build web --release