# Dawn - Intentional Daily Planning

Dawn ist eine minimalistische iOS-App für bewusstes tägliches Task-Management mit der einzigartigen **Zero-Overdue-Philosophie**: Tasks die bis 3 Uhr morgens nicht abgeschlossen wurden, wandern automatisch zurück ins Backlog.

## ✨ Features

- 📝 **Quick Entry**: Text-first Task-Erstellung
- 🌅 **Daily Focus**: Tägliche Planung mit ausgewählten Tasks
- 🔄 **3-AM-Reset**: Automatischer Reset nicht abgeschlossener Tasks
- 📅 **EventKit-Sync**: Bidirektionale Synchronisation mit iOS Erinnerungen
- 🎨 **Moderne UI**: SwiftUI mit Haptic Feedback
- 🧪 **Testbar**: Umfassende Tests

## 🚀 Xcode-Setup (Schritt für Schritt)

### 1. Xcode-Projekt erstellen

1. **Öffne Xcode**
2. **Erstelle neues Projekt:**
   - File → New → Project
   - iOS → App
   - Product Name: `Dawn`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 18.0`
3. **Speichere** in `/Users/florianschneider/Git/Dawn`

### 2. Dateien zum Projekt hinzufügen

**Im Finder:**
1. Öffne `/Users/florianschneider/Git/Dawn/Dawn/Sources`
2. Siehst du alle Swift-Dateien? Gut!

**In Xcode:**
1. **Lösche** die automatisch erstellten Dateien:
   - `DawnApp.swift` (alt)
   - `ContentView.swift` (alt)
   
2. **Füge Ordner hinzu:**
   - Rechtsklick auf "Dawn" (blau) im Project Navigator
   - "Add Files to Dawn..."
   - Wähle den `Dawn/Sources` Ordner
   - ✅ **"Create groups"** auswählen
   - ✅ **"Copy items if needed"** NICHT auswählen
   - Klicke "Add"

3. **Wiederhole** für `Dawn/Tests` und `Dawn/UITests`

### 3. Info.plist konfigurieren

**In Xcode:**
1. Klicke auf "Dawn" (Projekt, blau ganz oben)
2. Wähle Target "Dawn"
3. Tab "Info"
4. Rechtsklick → "Open As" → "Source Code"
5. **Ersetze** den Inhalt mit der `/Users/florianschneider/Git/Dawn/Info.plist`

**Oder:** Ziehe die `Info.plist` einfach ins Projekt

### 4. Capabilities aktivieren

1. Projekt → Target "Dawn" → Tab "Signing & Capabilities"
2. Klicke "+ Capability"
3. Füge hinzu: **Background Modes**
   - ✅ Background fetch
   - ✅ Background processing

### 5. Build Settings prüfen

1. Target "Dawn" → Tab "Build Settings"
2. Suche nach "Swift Language Version"
3. Stelle sicher: **Swift 6**
4. Suche nach "iOS Deployment Target"
5. Stelle sicher: **iOS 18.0**

### 6. Erste Build

1. **Wähle** Simulator (z.B. iPhone 15 Pro)
2. **Drücke** ⌘ + B (Build)
3. **Siehst du Fehler?**
   - Imports fehlen? Normal bei erstem Build
   - Einfach nochmal ⌘ + B drücken

### 7. App starten!

**Drücke** ⌘ + R (Run)

Die App sollte jetzt starten! 🎉

## ⚠️ Häufige Probleme

### "Cannot find 'Task' in scope"
**Lösung:** Task ist ein SwiftData Model. Stelle sicher dass alle Dateien im Projekt sind.

### "Module 'EventKit' not found"
**Lösung:** Info.plist fehlt oder Capabilities nicht aktiviert. Siehe Schritt 3+4.

### Build schlägt fehl
**Lösung:** 
1. Product → Clean Build Folder (⇧ + ⌘ + K)
2. Nochmal Build (⌘ + B)

### App startet nicht
**Lösung:** 
- iOS 18+ Simulator verwenden
- Deployment Target auf iOS 18.0 setzen

## 📱 App testen

### Quick-Test:
1. Öffne **Backlog-Tab** (unten rechts)
2. Tippe auf **+** (oben rechts)
3. Gib einen Task ein → **Hinzufügen**
4. **Swipe nach links** → "Heute" antippen
5. Wechsle zum **Heute-Tab** (unten links)
6. Task sollte da sein! ✅
7. Tippe auf **Checkbox** → Task als erledigt markieren

### EventKit-Sync testen:
1. Öffne **iOS Erinnerungen-App** (auf Simulator)
2. Gehe zurück zu Dawn
3. Verschiebe Task zu "Heute"
4. Öffne wieder **Erinnerungen**
5. Task sollte dort erscheinen! 🎊

## 🛠 Tech Stack

- **Platform**: iOS 18.0+
- **Language**: Swift 6
- **UI**: SwiftUI
- **Data**: SwiftData
- **Integration**: EventKit

## 📖 Weitere Dokumentation

- [ARCHITECTURE_AND_MODEL.md](docs/ARCHITECTURE_AND_MODEL.md) - Technische Details
- [PRD.md](docs/PRD.md) - Product Requirements

## 🎉 Fertig!

Du hast jetzt eine funktionsfähige Dawn-App! 

Bei Fragen: Siehe die Dokumentation oder frag nach Hilfe! 🚀
