# Dawny – Einfache Start-Anleitung

## Wo liegt der Code?

Alle Swift-Quellen und Ressourcen der App liegen im Repository unter:

```text
App/
├── Assets.xcassets/
└── Sources/          ← Models, Views, ViewModels, Services, …
```

Das Xcode-Projekt **`Dawny.xcodeproj`** (in der **Wurzel** des Repositories) bindet den Ordner **`App/`** automatisch ein. Es gibt keinen zweiten Quellordner mehr wie früher `Dawny/Sources` neben `App/`.

## Schnellstart mit Xcode

1. Repository **klonen** und den Projektordner öffnen.
2. **`Dawny.xcodeproj`** per Doppelklick öffnen (oder in Xcode: *File → Open*).
3. Oben das **Scheme „Dawny“** und einen **Simulator** (iOS 18+) wählen.
4. **⌘ + R** drücken – die App sollte starten.

## Was du im Navigator siehst

- **App** – enthält `Sources` (Swift-Code) und `Assets.xcassets`.
- **DawnyTests** / **DawnyUITests** – Unit- und UI-Tests.

## Capabilities (Kalender / Hintergrund)

Falls nötig: Projekt **Dawny** auswählen → Target **Dawny** → Tab **Signing & Capabilities** → **+ Capability** → **Background Modes** → *Background fetch* und *Background processing* aktivieren.

## Was kannst du testen?

### Test 1: Task hinzufügen

1. **Backlog-Tab** (unten rechts)
2. **+** (oben rechts)
3. Text eingeben → **Hinzufügen** (oder Return/Fertig)
4. Der Task erscheint in der Liste.

### Test 2: Task zu „Heute“ verschieben

1. Task nach links wischen
2. **Heute** antippen
3. **Heute-Tab** (unten links) – der Task sollte dort sein.

### Test 3: Task abschließen

Checkbox antippen – Task wird als erledigt markiert.

### Test 4: Kalender-Sync (echtes Gerät)

Nach Zugriff auf Erinnerungen: Task zu „Heute“ verschieben und in der **Erinnerungen-App** prüfen.

## Häufige Probleme

### Build schlägt fehl

1. **Product → Clean Build Folder** (⇧⌘K)
2. Erneut **⌘B**

### „Cannot find … in scope“

Prüfen, ob **`App/Sources`** im Projekt sichtbar ist und das Scheme **Dawny** gewählt ist.

### App startet nicht

- Simulator mit **iOS 18+** wählen
- **Deployment Target** des Targets auf iOS 18.0 prüfen

### Keine Berechtigung für Erinnerungen

Beim ersten Start normal; lokale Funktionen gehen oft trotzdem. Auf dem Simulator ggf. Dialog bestätigen.

## Weitere Infos

- Ausführlichere Übersicht: [README.md](../README.md)
- Anforderungen und Architektur: [PRD.md](PRD.md)

Viel Erfolg mit Dawny.
