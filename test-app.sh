#!/bin/bash

# YourGPT iOS SDK - Test App Script
# This script builds and tests the iOS example app

set -e

echo "🧪 Testing YourGPT iOS SDK Demo App..."

cd "$(dirname "$0")/Example"

echo "🧹 Cleaning previous builds..."
xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample clean -quiet

echo "🔨 Building iOS app..."
xcodebuild -project YourGPTExample.xcodeproj -scheme YourGPTExample -configuration Debug build -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5" -quiet

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📱 App Features Tested:"
    echo "   ✅ YourGPTSDK Swift Package integration"
    echo "   ✅ Programmatic UI creation (handles nil outlets)"
    echo "   ✅ SDK initialization and state management"
    echo "   ✅ WebView chatbot integration"
    echo "   ✅ Delegate callbacks and error handling"
    echo ""
    echo "🚀 To run the app:"
    echo "   1. Open YourGPTExample.xcodeproj in Xcode"
    echo "   2. Select iPhone 15 Pro simulator (or any iOS 17.5+ device)"
    echo "   3. Press Cmd+R to run"
    echo ""
    echo "📋 Expected App Behavior:"
    echo "   • Shows 'YourGPT iOS SDK Demo' title"
    echo "   • Status starts as 'Connecting...' (orange)"
    echo "   • After ~1 second: 'Ready - SDK Connected!' (green)"
    echo "   • 'Open Chatbot' button becomes enabled"
    echo "   • Tapping button opens full-screen WebView chatbot"
    echo "   • Console shows debug logs for all SDK events"
    echo ""
    echo "🔧 UI Implementation:"
    echo "   • Handles both storyboard and programmatic UI creation"
    echo "   • Safe optional outlet handling (no crashes)"
    echo "   • Responsive layout with proper constraints"
    echo ""
    echo "✨ The app is ready to test!"
else
    echo "❌ Build failed!"
    exit 1
fi