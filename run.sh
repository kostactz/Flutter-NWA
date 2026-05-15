#!/bin/bash

# run.sh - Script to run or build the AWA Shell

show_help() {
  echo "Usage: ./run.sh [run|build] [debug|release] [PWA_URL]"
  echo "Example: ./run.sh run debug https://my-pwa.com"
  echo "Example: ./run.sh build release https://my-pwa.com"
}

if [ "$#" -lt 2 ]; then
  show_help
  exit 1
fi

ACTION=$1
MODE=$2
PWA_URL=$3

if [ "$ACTION" != "run" ] && [ "$ACTION" != "build" ]; then
  echo "Invalid action: $ACTION. Must be 'run' or 'build'."
  show_help
  exit 1
fi

if [ "$MODE" != "debug" ] && [ "$MODE" != "release" ]; then
  echo "Invalid mode: $MODE. Must be 'debug' or 'release'."
  show_help
  exit 1
fi

cd awa_shell || exit 1

DART_DEFINES=""
if [ -n "$PWA_URL" ]; then
  DART_DEFINES="--dart-define=PWA_URL=$PWA_URL"
fi

if [ "$ACTION" == "run" ]; then
  if [ "$MODE" == "debug" ]; then
    echo "Running in debug mode..."
    flutter run --debug $DART_DEFINES
  else
    echo "Running in release mode..."
    flutter run --release $DART_DEFINES
  fi
elif [ "$ACTION" == "build" ]; then
  if [ "$MODE" == "debug" ]; then
    echo "Building APK in debug mode..."
    flutter build apk --debug $DART_DEFINES
    # Can also build ios: flutter build ios --debug $DART_DEFINES
  else
    echo "Building APK in release mode..."
    flutter build apk --release $DART_DEFINES
    # Can also build ios: flutter build ios --release $DART_DEFINES
  fi
fi
