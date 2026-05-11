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
3. Oben das **Scheme „Dawny“** und einen **Simulator** mit **iOS 26.2+** wählen.
4. **⌘ + R** drücken – die App sollte starten.

Beim **ersten Start** kann ein kurzer **Welcome**-Assistent erscheinen; durchtippen oder überspringen, bis die Hauptansicht mit der oberen Leiste sichtbar ist.

## Was du im Navigator siehst

- **App** – enthält `Sources` (Swift-Code) und `Assets.xcassets`.
- **DawnyTests** – Unit-Tests.

**In der laufenden App** (keine klassische Tab-Leiste unten): oben **Einstellungen** (Zahnrad links), in der Mitte die Umschaltung **Backlog** / **Heute**, rechts **Archiv**. Inhalt und Wischen zwischen den Bereichen **Backlog**, **Heute** und **Archiv** erfolgen über diese Leiste bzw. den Pager darunter.

## Capabilities (Kalender / Hintergrund)

Falls nötig: Projekt **Dawny** auswählen → Target **Dawny** → Tab **Signing & Capabilities** → **+ Capability** → **Background Modes** → *Background fetch* und *Background processing* aktivieren.

## Was kannst du testen?

### Test 1: Task hinzufügen

1. Oben **Backlog** antippen.
2. In der Liste nach unten scrollen, bis die **Quick-Entry-Zeile** sichtbar ist (Platzhalter z. B. „Neue Aufgabe …“ auf Deutsch bzw. der Text aus deiner Systemsprache).
3. Die Zeile antippen, Titel eingeben, mit **Return** (oder dem Bestätigen-Button neben dem Feld, sobald er erscheint) anlegen.
4. Der Task erscheint in der Liste.

Wenn **Kategorien** in den Einstellungen aktiv sind, gibt es pro aufgeklappter Kategorie eine eigene Quick-Entry-Zeile am Ende der jeweiligen Sektion.

### Test 2: Task zu „Heute“ verschieben

1. Im **Backlog** eine Task-Zeile **nach rechts wischen**, bis die Aktion **Heute** sichtbar wird (leading Swipe wie in der Erinnerungen-App).
2. **Heute** antippen.
3. Oben **Heute** wählen – der Task sollte dort in der Liste stehen.

### Test 3: Task abschließen

Im **Heute**-Bereich die Checkbox antippen – der Task wird als erledigt markiert.

### Test 4: Kalender-Sync (echtes Gerät)

Nach Zugriff auf Erinnerungen: Task zu „Heute“ verschieben und in der **Erinnerungen-App** prüfen.

### Test 5: Archiv (optional)

Nach einem **täglichen Reset** können erledigte bzw. archivierte Aufgaben im **Archiv** (Symbol rechts oben) landen – dort kannst du sie einsehen.

## Häufige Probleme

### Build schlägt fehl

1. **Product → Clean Build Folder** (⇧⌘K)
2. Erneut **⌘B**

### „Cannot find … in scope“

Prüfen, ob **`App/Sources`** im Projekt sichtbar ist und das Scheme **Dawny** gewählt ist.

### App startet nicht

- Simulator mit **iOS 26.2+** wählen (passend zum **Deployment Target** des Targets, derzeit iOS 26.2).

### Keine Berechtigung für Erinnerungen

Beim ersten Start normal; lokale Funktionen gehen oft trotzdem. Auf dem Simulator ggf. Dialog bestätigen.

## Weitere Infos

- Ausführlichere Übersicht: [README.md](../README.md)
- Anforderungen und Architektur: [PRD.md](PRD.md)

Viel Erfolg mit Dawny.
