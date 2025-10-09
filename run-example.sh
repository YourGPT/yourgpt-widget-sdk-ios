#!/bin/bash

# YourGPT iOS SDK - Run Example Script
# This script builds and runs the iOS example app in the simulator

set -e

echo "🏗️  Building YourGPT iOS SDK Example..."

cd "$(dirname "$0")/Example"

# Clean and build
echo "🧹 Cleaning previous builds..."
xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample clean

echo "📱 Building for iOS Simulator..."
xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample -configuration Debug build -sdk iphonesimulator

echo "✅ Build completed successfully!"
echo ""
echo "📱 Available iPhone Simulators:"
xcrun simctl list devices iPhone | grep "iPhone" | head -5

echo ""
echo "🚀 To run the app:"
echo "1. Open YourGPTExample.xcodeproj in Xcode"
echo "2. Select an iPhone simulator"  
echo "3. Press Cmd+R to run"
echo ""
echo "📖 The demo app will:"
echo "   • Initialize the YourGPT SDK"
echo "   • Show SDK connection status"
echo "   • Allow you to open the chatbot in a WebView"
echo "   • Demonstrate delegate callbacks"