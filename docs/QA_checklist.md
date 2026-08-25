# Dawny — QA-Checkliste

_Gehört zu [RELEASE_RUNBOOK.md](RELEASE_RUNBOOK.md), Phase 3._

**Hier steht nur, was die Testsuite nicht abdecken kann.** Reset-Logik, Sync-Engine,
CloudKit-Dedup, ViewModels, Persistenz, Welcome-Flow und der iCloud-Intro laufen
automatisiert in `xcodebuild test`. Was dort grün ist, wird hier nicht noch einmal von
Hand geklickt.

Die Liste ist bewusst kurz. Wenn ein Punkt dauerhaft langweilig wird, gehört er in die
Testsuite und nicht in diese Datei.

---

## 1. Vor dem Archiv (lokal, ~5 Min.)

- [ ] Tests grün:
  ```bash
  xcodebuild test -project Dawny.xcodeproj -scheme Dawny -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
  ```
  Nicht zwei Läufe parallel auf demselben Simulator starten, die killen sich gegenseitig die App.
- [ ] `App/Sources/Localizable.xcstrings`: keine Einträge auf „Needs Review", keine leeren Werte in `en` und `de`

---

## 2. Auf echter Hardware (Debug-Build genügt)

Diese drei Bereiche haben **keine automatisierte Abdeckung** und brauchen ein physisches
Gerät. Simulator reicht nicht.

### Apple Reminders (EventKit)

Der UI-Test überspringt den EventKit-Pfad komplett (`UITestSupport` setzt
`calendarSyncEnabled = false`).

- [ ] Sync einschalten, Aufgabe in Dawny anlegen, erscheint in **Erinnerungen**
- [ ] Aufgabe in Erinnerungen abhaken, Status kommt in Dawny an
- [ ] Sync ausschalten, die zugehörigen Erinnerungen verschwinden

### Siri-Intents

Details und Formulierungen in [siri-manuelle-tests.md](siri-manuelle-tests.md).

- [ ] Aufgabe per Siri anlegen
- [ ] Aufgabe per Siri abhaken
- [ ] Heutige Aufgaben vorlesen lassen

### Widgets

- [ ] Alle drei Widgets (Heute, Backlog, Archiv) zeigen aktuelle Daten
- [ ] Abhaken im Widget schlägt in der App durch
- [ ] Tippen öffnet den passenden Tab per Deep Link

---

## 3. Nach dem Archiv, vor dem Upload

- [ ] Entitlements der **exportierten** App prüfen:
  ```bash
  unzip -q -o ~/Desktop/Dawny.ipa -d /tmp/dawny-ipa && codesign -d --entitlements :- /tmp/dawny-ipa/Payload/Dawny.app
  ```
  `aps-environment` muss auf `production` stehen. Steht dort `development`, kommen die
  stillen CloudKit-Pushes im Store-Build nicht an und Sync aktualisiert nur beim App-Start.

  > **Nicht das `.xcarchive` prüfen.** Das trägt immer die Entwickler-Entitlements, zu
  > erkennen an `get-task-allow = true`. Die Distribution-Entitlements entstehen erst beim
  > Export, wenn Xcode mit dem Distributionsprofil neu signiert. Ein Check auf dem Archiv
  > meldet also auch dann `development`, wenn alles stimmt. Dafür im Organizer
  > **Distribute App → Export** statt direkt **Upload** wählen.

- [ ] **Nur wenn sich am CloudKit-Schema etwas geändert hat:** Ad-Hoc-Build auf ein Gerät
  installieren, eine Aufgabe anlegen und in der CloudKit Console unter
  **Production → Records** nachsehen, ob der Record ankommt.

  Ein Ad-Hoc-Export deckt beide Punkte auf einmal ab, denn er wird ebenfalls mit einem
  Distributionsprofil signiert und lässt sich genauso auf `aps-environment` prüfen.

  Der Grund: Welche CloudKit-Umgebung eine App anspricht, hängt am Provisioning-Profil,
  nicht an der Build-Konfiguration. Debug-Builds und lokal gebaute Release-Builds mit
  Entwicklerprofil landen **immer** in Development. Production sehen nur TestFlight-,
  App-Store- und Ad-Hoc-Builds. Ohne diesen Schritt ist die Live-Version der erste Build,
  der das Production-Schema überhaupt berührt.

---

## Bekannte Einschränkungen (nicht testen, sind so gewollt)

- Abmeldung aus iCloud leert den lokalen Store. Verhalten von
  `NSPersistentCloudKitContainer`, als bekannte Einschränkung abgenommen.
- Eine Umbenennung auf Gerät A schlägt in einer laufenden App auf Gerät B erst nach einem
  Neustart durch.
- Zwei Geräte mit aktivem Reminders-Sync erzeugen doppelte Erinnerungen.

Hintergrund zu allen dreien in [context/cloudkit-sync-concept.md](context/cloudkit-sync-concept.md) §12 und §14.2.
