#!/bin/bash

# test.sh - Script to run Flutter tests for AWA Shell

echo "Running AWA Shell Tests..."
cd awa_shell || exit 1
flutter test
