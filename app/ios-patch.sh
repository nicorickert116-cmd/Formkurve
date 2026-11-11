#!/bin/bash
# Passt das von Capacitor erzeugte iOS-Projekt an: Rechte, Hintergrund-GPS, Töne im Stummmodus, Icon.
set -euo pipefail
cd "$(dirname "$0")"
P=ios/App/App/Info.plist
pb() { /usr/libexec/PlistBuddy -c "$1" "$P" 2>/dev/null || true; }
pb "Set :CFBundleDisplayName Formkurve"
pb "Add :CFBundleDisplayName string Formkurve"
pb "Add :NSLocationWhenInUseUsageDescription string Formkurve zeichnet beim Laufen deine Strecke, Distanz und dein Tempo auf."
pb "Add :NSLocationAlwaysAndWhenInUseUsageDescription string Damit dein Lauf auch bei gesperrtem Bildschirm weiter aufgezeichnet wird."
pb "Add :UIBackgroundModes array"
pb "Add :UIBackgroundModes:0 string location"
pb "Add :WKAppBoundDomains array"
pb "Add :WKAppBoundDomains:0 string nicorickert116-cmd.github.io"
pb "Add :ITSAppUsesNonExemptEncryption bool false"
/usr/libexec/PlistBuddy -c "Print" "$P" | grep -E "Location|UIBackgroundModes|location|WKAppBound|github" || true

# Töne auch im Stummmodus, gemischt mit laufender Musik
AD=ios/App/App/AppDelegate.swift
grep -q "import AVFoundation" "$AD" || sed -i '' 's/^import UIKit$/import UIKit\
import AVFoundation/' "$AD"
grep -q "AVAudioSession" "$AD" || sed -i '' 's|// Override point for customization after application launch.|// Override point for customization after application launch.\
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])\
        try? AVAudioSession.sharedInstance().setActive(true)|' "$AD"
grep -n "AVAudioSession\|import AVFoundation" "$AD"

# App-Icon und Startbild
ICON=ios/App/App/Assets.xcassets/AppIcon.appiconset
for f in "$ICON"/*.png; do cp resources/icon-1024.png "$f"; done
for f in ios/App/App/Assets.xcassets/Splash.imageset/*.png; do [ -f "$f" ] && cp resources/splash.png "$f"; done
echo "Patch fertig"
