#!/bin/bash

# run.sh - Script to run or build the AWA Shell

show_help() {
  echo "Usage: ./run.sh run [debug|release] [PWA_URL]"
  echo "       ./run.sh build release [OPTIONS]"
  echo ""
  echo "Options for build:"
  echo "  --platform=android|ios"
  echo "  --pwa-url=https://..."
  echo "  --package-name=com.company.app"
  echo "  --app-name=\"My PWA\""
  echo "  --version=\"1.0.0+1\""
  echo "  --icon-url=\"https://.../icon.png\""
  echo "  --permissions=\"camera,gallery,files,location,sms\""
  echo "  --keystore=\"/path/to/keystore\""
  echo "  --keystore-password=\"pass\""
  echo "  --key-alias=\"alias\""
  echo "  --key-password=\"pass\""
}

if [ "$#" -lt 1 ]; then
  show_help
  exit 1
fi

ACTION=$1

if [ "$ACTION" == "run" ]; then
  MODE=$2
  PWA_URL=$3
  cd awa_shell || exit 1
  DART_DEFINES=""
  if [ -n "$PWA_URL" ]; then
    DART_DEFINES="--dart-define=PWA_URL=$PWA_URL"
  fi
  if [ "$MODE" == "debug" ]; then
    echo "Running in debug mode..."
    flutter run --debug $DART_DEFINES
  else
    echo "Running in release mode..."
    flutter run --release $DART_DEFINES
  fi
elif [ "$ACTION" == "build" ]; then
  MODE=$2
  if [ "$MODE" != "release" ]; then
    echo "Build action currently supports 'release' mode only via the White-Label Engine."
    show_help
    exit 1
  fi
  shift 2 # Remove 'build' and 'release' from args
  cd awa_shell || exit 1
  
  # Forward all remaining arguments to the Dart CLI builder
  dart run tool/build.dart "$@"
else
  echo "Invalid action: $ACTION. Must be 'run' or 'build'."
  show_help
  exit 1
fi