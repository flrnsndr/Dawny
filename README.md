# Dawny - Intentional Daily Planning

Dawny ist eine minimalistische iOS-App für bewusstes tägliches Task-Management mit der einzigartigen **Zero-Overdue-Philosophie**: Tasks die bis 3 Uhr morgens nicht abgeschlossen wurden, wandern automatisch zurück ins Backlog.

## ✨ Features

- 📝 **Quick Entry**: Text-first Task-Erstellung
- 🌅 **Daily Focus**: Tägliche Planung mit ausgewählten Tasks
- 🔄 **3-AM-Reset**: Automatischer Reset nicht abgeschlossener Tasks
- 📅 **EventKit-Sync**: Bidirektionale Synchronisation mit iOS Erinnerungen
- 🎨 **Moderne UI**: SwiftUI mit Haptic Feedback
- 🧪 **Testbar**: Umfassende Tests

## 🚀 Xcode-Setup

Das Repository enthält bereits das fertige Projekt. Der Anwendungscode liegt unter **`App/`** (Swift-Quellen in `App/Sources/`) und wird von Xcode über `Dawny.xcodeproj` eingebunden.

1. Repository klonen und im Finder oder Terminal in den Projektordner wechseln.
2. **`Dawny.xcodeproj`** doppelklicken (oder in Xcode: File → Open und die Datei auswählen).
3. Oben das Scheme **Dawny** und einen **Simulator** mit iOS 18+ wählen.
4. **⌘ + B** zum Bauen, **⌘ + R** zum Starten.

### Capabilities (für EventKit / Hintergrund)

Falls du das Projekt neu anlegst oder Capabilities fehlen: Target **Dawny** → **Signing & Capabilities** → **+ Capability** → **Background Modes** mit *Background fetch* und *Background processing*.

### Build Settings

- **Swift:** 6  
- **iOS Deployment Target:** 18.0

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
2. Gehe zurück zu Dawny
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

- [EINFACHE_ANLEITUNG.md](docs/EINFACHE_ANLEITUNG.md) - Schritt-für-Schritt Anleitung für Anfänger
- [PRD.md](docs/PRD.md) - Product Requirements und Architektur-Details

## 🎉 Fertig!

Du hast jetzt eine funktionsfähige Dawny-App! 

Bei Fragen: Siehe die Dokumentation oder frag nach Hilfe! 🚀
