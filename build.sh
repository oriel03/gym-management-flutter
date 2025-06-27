#!/bin/bash

# Define la versión de Flutter que quieres usar (la que requiere tu pubspec.yaml)
FLUTTER_VERSION="3.8.0-124.0.dev"

# Clona el repositorio de Flutter
git clone https://github.com/flutter/flutter.git

# Mueve el directorio de Flutter
cd flutter

# Cambia a la versión específica requerida por tu proyecto
git checkout $FLUTTER_VERSION

# Vuelve al directorio raíz del proyecto
cd ..

# Agrega Flutter al PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Verifica que Flutter esté disponible y en la versión correcta
flutter --version

# Acepta las licencias de Android (esto puede ser necesario)
flutter doctor --android-licenses --no-license-check

# Obtiene las dependencias del proyecto
flutter pub get

# Construye la aplicación web
flutter build web --release