# 🌅 Dawn - Einfache Start-Anleitung für Anfänger

## Was ist passiert?

Ich habe **21 Swift-Dateien** mit dem kompletten Code für die Dawn-App erstellt! Alle Dateien liegen in:
```
/Users/florianschneider/Git/Dawn/Dawn/Sources/
```

## Was musst du jetzt tun?

### 🎯 Schritt 1: Xcode öffnen

1. Öffne **Xcode** auf deinem Mac
2. Du siehst ein Willkommens-Fenster

### 🎯 Schritt 2: Neues Projekt erstellen

1. Klicke auf **"Create New Project"**
2. **Wichtig - Wähle aus:**
   - Oben in Tabs: **iOS** (nicht macOS!)
   - Unten: Das **"App"** Template (blaues Icon mit Telefon)
3. Klicke **"Next"**

### 🎯 Schritt 3: Projekt-Einstellungen

Fülle das Formular aus:

| Feld | Was eingeben |
|------|--------------|
| **Product Name** | `Dawn` |
| **Team** | Dein Apple Team (oder "None") |
| **Organization Identifier** | `com.deinname` (egal was) |
| **Interface** | **SwiftUI** ⚠️ WICHTIG! |
| **Language** | **Swift** |
| **Storage** | **NICHT** SwiftData anhaken! |

Klicke **"Next"** und wähle als Speicherort:
```
/Users/florianschneider/Git/Dawn
```

Klicke **"Create"**

### 🎯 Schritt 4: Die alten Dateien löschen

Xcode hat automatisch 2 Dateien erstellt die wir nicht brauchen:

1. Im **Project Navigator** (linke Spalte) siehst du:
   - `DawnApp.swift` 
   - `ContentView.swift`
2. **Rechtsklick auf beide** → "Delete" → **"Move to Trash"**

### 🎯 Schritt 5: Unsere Dateien hinzufügen

**Jetzt der wichtige Teil!**

1. **Rechtsklick** auf "Dawn" (das blaue Icon ganz oben im Navigator)
2. Wähle **"Add Files to Dawn..."**
3. **Navigiere zu:** `/Users/florianschneider/Git/Dawn/Dawn/Sources`
4. **Wähle den ganzen `Sources` Ordner** aus
5. ⚠️ **WICHTIG - Stelle sicher dass angehakt ist:**
   - ✅ **"Create groups"** (NICHT "Create folder references")
   - ❌ **"Copy items if needed"** NICHT anhaken!
6. Klicke **"Add"**

**Du solltest jetzt sehen:**
- Dawn (Projekt)
  - Dawn (Ordner)
    - Sources
      - Models
      - Services
      - Views
      - ViewModels
      - Protocols
      - Extensions

### 🎯 Schritt 6: Info.plist hinzufügen

1. **Ziehe die Datei** `/Users/florianschneider/Git/Dawn/Info.plist`
2. **Direkt** in dein Xcode-Projekt (neben Sources)
3. Wenn gefragt: ✅ "Copy items if needed" anhaken

### 🎯 Schritt 7: Background Modes aktivieren

1. Klicke auf **"Dawn"** (Projekt, blaues Icon ganz oben)
2. Wähle das **Target "Dawn"** (unter TARGETS)
3. Klicke auf Tab **"Signing & Capabilities"**
4. Klicke auf **"+ Capability"** (oben links)
5. Suche und füge hinzu: **"Background Modes"**
6. In der neuen Box, hake an:
   - ✅ Background fetch
   - ✅ Background processing

### 🎯 Schritt 8: iOS 18 einstellen

1. Bleibe im **Target "Dawn"**
2. Klicke auf Tab **"General"**
3. Scrolle runter zu **"Minimum Deployments"**
4. Ändere auf: **iOS 18.0**

### 🎯 Schritt 9: FERTIG! App starten

1. **Wähle** oben links neben "Dawn" einen Simulator aus
   - z.B. "iPhone 15 Pro" (iOS 18.0+)
2. **Drücke den Play-Button** ▶️ (oder ⌘ + R)

**Die App sollte starten!** 🎉

## 📱 Was kannst du jetzt testen?

### Test 1: Task hinzufügen
1. Tippe auf **Backlog-Tab** (unten rechts)
2. Tippe auf **+** (oben rechts)
3. Schreibe "Mein erster Task"
4. Tippe **"Hinzufügen"**
5. ✅ Task erscheint in der Liste!

### Test 2: Task zu "Heute" verschieben
1. **Swipe** den Task nach links
2. Tippe auf **"Heute"** (orange)
3. Wechsle zum **Heute-Tab** (unten links)
4. ✅ Task ist dort!

### Test 3: Task abschließen
1. Tippe auf die **Checkbox** neben dem Task
2. ✅ Task wird grün und abgehakt!

### Test 4: Kalender-Sync (nur auf echtem iPhone!)
1. Verschiebe einen Task zu "Heute"
2. Öffne die **Erinnerungen-App**
3. ✅ Task sollte dort auch erscheinen!

## ❓ Häufige Probleme

### "Build failed" oder rote Fehler?
**Lösung:**
1. Product → Clean Build Folder (⇧ + ⌘ + K)
2. Dann nochmal Build (⌘ + B)
3. Warte bis "Build Succeeded" erscheint

### "Cannot find 'Task' in scope"
**Lösung:**
- Du hast die `Sources` Dateien nicht richtig hinzugefügt
- Wiederhole Schritt 5, aber wähle den ganzen Ordner!

### App startet nicht?
**Prüfe:**
- ✅ iOS 18.0 Simulator ausgewählt?
- ✅ Minimum Deployment auf iOS 18.0?
- ✅ Info.plist im Projekt?

### "Keine Berechtigung für Erinnerungen"
Das ist normal beim ersten Start im Simulator!
- Klicke "OK" und teste die App trotzdem
- Die lokalen Features funktionieren auch ohne Kalender

## 🆘 Brauchst du Hilfe?

Wenn etwas nicht funktioniert:
1. Schaue in die ausführliche **README.md**
2. Prüfe ob alle Dateien im Projekt sind
3. Mache einen Screenshot vom Fehler

## 🎊 Geschafft!

Wenn du die App siehst: **Herzlichen Glückwunsch!**

Du hast deine erste iOS-App mit:
- ✅ 21 Swift-Dateien
- ✅ SwiftUI Interface
- ✅ SwiftData Datenbank
- ✅ EventKit-Integration
- ✅ Background Tasks
- ✅ Haptic Feedback

Viel Spaß mit Dawn! 🌅

