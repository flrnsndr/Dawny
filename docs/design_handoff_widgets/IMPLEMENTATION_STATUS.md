# Dawny Widgets — Implementierungsstand

**Stand: Widgets laufen im Simulator.** Das Extension-Target `DawnyWidgetsExtension`
ist angelegt, baut und rendert alle drei Widgets. App-Ziel `Dawny` baut fehlerfrei,
alle 51 Unit-Tests grün (inkl. 14 `ResetOutcomePlannerTests`).

## Fertig (im Code)

- **App Group Fundament** — [AppGroup.swift](../../App/Sources/Utilities/AppGroup.swift),
  [AppGroupMigrator.swift](../../App/Sources/Services/AppGroupMigrator.swift) (in
  [DawnyApp.init](../../App/Sources/DawnyApp.swift) vor dem Container). Store + UserDefaults
  werden defensiv in die App Group migriert (Copy-not-Move, Flag zuletzt, Rollback, Extension-Sperre).
  `AppSettings`, `ResetEngine`, `CategoryService`, `IntentDataStore` lesen jetzt aus der geteilten Suite/Store.
  **Ohne App-Group-Entitlement fällt alles transparent auf `.standard` + Legacy-Store zurück** — die App läuft also auch vor Schritt 2 unverändert.
- **ResetOutcomePlanner** — [ResetOutcomePlanner.swift](../../App/Sources/Services/ResetOutcomePlanner.swift):
  reine Reset-Entscheidungslogik, von `ResetEngine` (Mutation) und Widget (Als-ob-Vorschau) geteilt. Verhaltensgleich (bestehende Reset-Tests grün).
- **Intent-Vereinheitlichung** — `IntentDataStore.applyCompletion`/`uncompleteTask` (Recurring-Clone jetzt
  auch bei Siri + Widget), neuer [ToggleTaskDoneIntent.swift](../../App/Sources/Intents/ToggleTaskDoneIntent.swift).
- **Widget-Reloads** — [WidgetRefresher.swift](../../App/Sources/Utilities/WidgetRefresher.swift), aufgerufen
  an allen Task-Mutationen (IntentDataStore, ViewModels via `saveAndRefreshWidgets()`, ResetEngine, ContentView).
- **Deep-Links** — `.onOpenURL` in [ContentView.swift](../../App/Sources/Views/ContentView.swift) → `dawny://today|backlog|archive`.
- **Widget-Extension-Code** — 17 Dateien in [DawnyWidgets/](../../DawnyWidgets/): 3 Widgets (Heute/Backlog/Archiv)
  mit allen Größen inkl. Lock Screen, geteilte Datenquelle (read-only), Als-ob-/Placeholder-Logik, Chevron-Navigation.
- **Lokalisierung** — 42 neue Keys en+de in `App/Sources/Localizable.xcstrings`. Lizenz-Header auf allen neuen Dateien.
- **Entitlements** — `group.Florian.Dawny.MVP` vorab in [Dawny.entitlements](../../Dawny.entitlements)
  und [DawnyWidgets/DawnyWidgets.entitlements](../../DawnyWidgets/DawnyWidgets.entitlements) eingetragen.

## Xcode-GUI-Schritte — erledigt

1. ✅ **Widget-Extension-Target** `DawnyWidgetsExtension` (Bundle-ID `Florian.Dawny.MVP.DawnyWidgets`) angelegt.
   Xcode legte Template-Dateien in `DawnyWidgets/` und überschrieb `DawnyWidgetsBundle.swift` →
   Templates (`DawnyWidgets.swift`, `DawnyWidgetsControl.swift`, `AppIntent.swift`) gelöscht, Bundle wiederhergestellt.
2. ✅ **App Group** `group.Florian.Dawny.MVP` auf beiden Targets.
3. ✅ **URL-Scheme** `dawny` im `Dawny`-Target.
4. ✅ **Target-Membership** der geteilten App-Dateien auf das Widget-Target
   (Models, `CategoryService`, `ResetOutcomePlanner`, Intents inkl. `ToggleTaskDoneIntent`, `AppGroup`,
   `WidgetRefresher`, `Localizable.xcstrings`).
5. ✅ **`CURRENT_PROJECT_VERSION`** des Widget-Targets auf App-Wert (121) gesetzt (CFBundleVersion-Warnung).

**Vor Release noch prüfen:** Im Apple Dev-Portal muss das Distribution-Profil beider Targets die App Group `group.Florian.Dawny.MVP` enthalten (Debug/Simulator klappt bereits; App-Store-Signing separat verifizieren).

## Previews

`DawnyWidgets/WidgetPreviews.swift`: 12 `#Preview`-Blöcke (Heute S/M/L + Lock + „Öffne Dawny", Backlog S/M/L + Navigation, Archiv S/M) mit Beispieldaten. Canvas: ⌥⌘⏎. Widget-Schema NICHT direkt starten (verlangt `_XCWidgetKind`) — App-Schema starten, Widget im Simulator per Long-Press hinzufügen.

## Verifikations-Checkliste

- Migration: alte Daten bleiben erhalten; Legacy-Store bleibt als Backup liegen; `DawnyAppGroupMigrationDone` gesetzt.
- Widget vor App-Start: zeigt „Öffne Dawny", legt keinen Store an.
- Heute-Toggle (inkl. Recurring-Clone), Backlog-„+", Chevron-Cycle, Deep-Links (kalt+warm).
- Reset-Staleness: `resetHour` auf nächste Stunde stellen, App zu lassen → Heute-Placeholder, Backlog/Archiv Als-ob; App öffnen → echter Stand.
- Archiv-Punkte erscheinen nach Reset; verschwinden nach Besuch des Archiv-Tabs.
- Siri „Aufgabe erledigen" auf Recurring → Backlog-Clone entsteht (Beweis der Vereinheitlichung).
