#!/bin/bash

# Quick start script for ONVY Health SDK Demo App

echo "🚀 Starting ONVY Health SDK Demo App..."
echo ""

cd /Users/sabahy/Desktop/ONVYHealthSDK/demo-app

# Kill any existing Expo processes
echo "Cleaning up..."
lsof -ti:8081 | xargs kill -9 2>/dev/null
lsof -ti:8082 | xargs kill -9 2>/dev/null

# Start Expo
echo "Starting Expo..."
echo ""
echo "Options:"
echo "  - Press 'i' for iOS Simulator"
echo "  - Press 'w' for Web browser"
echo "  - Press 'a' for Android"
echo ""

npx expo start --clear
