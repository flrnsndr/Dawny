# Dawny V1.0 – Manuelle QA Release-Checkliste

_Da wir auf automatisierte UI-Tests verzichten, muss diese Checkliste vor jedem Build, der in den App Store (oder TestFlight Release Candidate) geht, zwingend manuell und vollständig auf einem physischen Gerät (nicht nur Simulator) durchlaufen werden._

## 1. Siri & App Intents (Kritischer Pfad)

_Hintergrund: App Intents laufen out-of-process. Hier entstehen die meisten unsichtbaren SwiftData-Crashes._

- [ ] **Task via Siri hinzufügen (App geöffnet):** Siri aktivieren ("Füge [Task] in Dawny hinzu").
  - _Erwartet:_ Siri bestätigt. Task erscheint sofort oder nach kurzem Refresh in der UI. Kein Crash.

- [ ] **Task via Siri hinzufügen (App komplett geschlossen/Force Quit):** App abschießen. Siri aktivieren und Task hinzufügen. App danach öffnen.
  - _Erwartet:_ Task ist in der Liste vorhanden. Die App startet regulär ohne Absturz.

- [ ] **Fokus-Task (Today) via Siri hinzufügen:** Den spezifischen Intent für "Heute" über Siri triggern.
  - _Erwartet:_ Task landet direkt im "Daily Focus" und nicht nur im Backlog.

- [ ] **Kurzbefehle-App (Shortcuts) Check:** Die Kurzbefehle-App öffnen und prüfen, ob die Dawny-Shortcuts dort als Bausteine verfügbar und funktional sind.

## 2. Der tägliche Reset ("Make it Count")

_Hintergrund: Die Core-Mechanik der App. Datumswechsel müssen sauber getrackt werden, ohne Endlosschleifen auszulösen._

- [ ] **Reset Simulation:** App öffnen, Tasks in "Today" und "Backlog" anlegen. In die iOS-Einstellungen gehen und das Datum manuell auf den nächsten Tag stellen. Zurück zu Dawny wechseln.
  - _Erwartet:_ Die `ResetEngine` triggert. Der "Today"-Screen ist leer (oder zeigt den Sunrise-Status). Offene Tasks von gestern sind korrekt ins Backlog/Archiv verschoben.

- [ ] **Reset bei geschlossener App:** Tasks anlegen. App via Force Quit beenden. Datum in iOS auf morgen stellen. App starten.
  - _Erwartet:_ Identisches, sauberes Reset-Verhalten direkt beim Start. Keine verwaisten Tasks im "Today"-View.

## 3. Kalender-Synchronisation (EventKit Edge Cases)

_Hintergrund: System-Permissions sind dynamisch. User ändern gerne mittendrin ihre Meinung._

- [ ] **Happy Path:** Kalenderzugriff erlauben. Prüfen, ob Termine korrekt und performant im Daily Focus angezeigt werden.

- [ ] **Berechtigung zur Laufzeit entziehen:** App läuft im Hintergrund. In die iOS-Einstellungen gehen -> Dawny -> Kalenderzugriff komplett verbieten. Zurück in die App wechseln.
  - _Erwartet:_ App crasht **nicht**. UI fängt den Status auf (z.B. Hinweistext "Kalenderzugriff fehlt" oder die Kalender-Sektion verschwindet einfach sauber).

- [ ] **Neuer Tag / Kalender Refresh:** Ändern sich die Termine beim simulierten Tageswechsel (siehe Punkt 2) korrekt auf die Termine des neuen Tages?

## 4. SwiftData & Persistenz (Data Integrity)

- [ ] **CRUD Basis:** 5 Tasks schnell hintereinander anlegen, editieren, als erledigt markieren, löschen.

- [ ] **Persistenz-Check:** App hart abschießen (Force Quit) und neu starten.
  - _Erwartet:_ Der Zustand ist exakt so wie vor dem Beenden. Keine Datenverluste.

- [ ] **Kategorien (falls in V1 aktiv):** Neue Kategorie anlegen, Task zuweisen, Kategorie löschen.
  - _Erwartet:_ Task verliert Zuweisung, aber App stürzt nicht durch fehlende Referenzen (Cascade Deletion Rules) ab.

## 5. UI, Design & Accessibility

- [ ] **Dark Mode Check:** Gerät in den Dark Mode schalten. Alle Views durchklicken.
  - _Erwartet:_ Keine schwarzen Texte auf dunkelgrauem Grund. Alle Kontraste (besonders Custom Views und leere States) sind gut lesbar.

- [ ] **Dynamic Type (Große Schrift):** In den iOS-Einstellungen (Bedienungshilfen) die Schriftgröße auf Maximum stellen.
  - _Erwartet:_ Keine überlappenden Texte, unlesbaren Buttons oder abgeschnittenen Task-Titel. Die UI bricht sauber um.

---

**Freigabe für Release:**

- Version: ****\_\_****

- Datum: ****\_\_****

- Getestet von: ****\_\_****
