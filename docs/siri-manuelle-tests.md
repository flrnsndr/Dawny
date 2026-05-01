# Siri – Manuelle Testroutine

Getestete Intents: `AddTaskIntent`, `AddTaskTodayIntent`, `MoveTaskToTodayIntent`, `CompleteTaskIntent`, `ListTodayTasksIntent`

Voraussetzungen: App auf Gerät installiert (kein Simulator), Siri aktiviert, mindestens 2–3 Aufgaben im Backlog und eine Aufgabe im Heute-Bereich vorhanden.

**Wichtig:** Siri-Phrasen beginnen mit dem Befehl und enden mit dem App-Namen (`"... in Dawny"`). Das Muster `"Dawny, Befehl"` (App-Name vorne) ist kein gültiges AppShortcut-Format und führt zu „Ich finde keine passende App".

---

## Block 1 – App geschlossen, Grundfunktion

App vollständig schließen (aus dem App Switcher entfernen). Alle Befehle in diesem Block mit geschlossener App testen.

| # | Befehl | Erwartetes Ergebnis |
|---|--------|---------------------|
| 1.1 | „Neue Aufgabe in Dawny" | Siri fragt „Wie soll die Aufgabe heißen?" – nach Eingabe: Bestätigung, App öffnen und prüfen ob Aufgabe im Backlog erscheint |
| 1.2 | „Aufgabe in Dawny hinzufügen" | Gleich wie 1.1 |
| 1.3 | „Aufgabe für heute in Dawny" | Siri fragt nach Titel – Aufgabe landet im Heute-Bereich, nicht im Backlog |
| 1.4 | „Heute in Dawny" | Gleich wie 1.3 |

**Kein Auswahlscreen zwischen Dawny und Notizen darf erscheinen.** Falls doch: prüfen ob in der Notizen-App ein Ordner oder eine Liste mit dem Namen „Dawny" existiert und diesen löschen.

---

## Block 2 – Sync-Verhalten prüfen

Nach Befehlen aus Block 1:

**Notizen-App:** Nach jedem Befehl prüfen ob eine neue Notiz erstellt wurde → **es darf keine geben**

**Erinnerungen-App:**
- Nach 1.1 / 1.2 (Backlog): kein neuer Eintrag erwartet
- Nach 1.3 / 1.4 (Heute): Dawny öffnen, damit der SyncEngine-Sync ausgeführt wird → danach Erinnerungen prüfen → **ein neuer Eintrag wird erwartet**

Hintergrund: Der SyncEngine synct Daily-Focus-Aufgaben nach Erinnerungen, wenn die App aktiv wird. Dieser Sync läuft bewusst nicht innerhalb des Intents selbst — ein Eintrag der direkt nach dem Siri-Befehl (ohne App zu öffnen) in Erinnerungen erscheint wäre ein Fehler.

---

## Block 3 – Entity-basierte Befehle

Voraussetzung: mindestens eine Aufgabe namens „Einkaufen" im Backlog (einer beliebigen Kategorie), eine Aufgabe namens „Sport" im Heute-Bereich.

| # | Befehl | Erwartetes Ergebnis |
|---|--------|---------------------|
| 3.1 | „Einkaufen auf heute in Dawny" | Siri verschiebt „Einkaufen" in den Heute-Bereich, Bestätigung wird vorgelesen |
| 3.2 | „Einkawfen auf heute in Dawny" (Tippfehler-Simulation via Aussprache) | Siri erkennt „Einkaufen" trotz Lautverzerrung (Fuzzy Matching) |
| 3.3 | „Sport in Dawny abschließen" | Siri markiert „Sport" als erledigt, Bestätigung wird vorgelesen |
| 3.4 | „Mark Sport done in Dawny" | Gleich wie 3.3 (Englisch) |
| 3.5 | Aufgabe in einer benannten Kategorie (z.B. „Privat") via Siri verschieben | Im Auswahlscreen: Subtitle zeigt „Privat · Backlog" — kategorisierte Tasks erscheinen in der Liste |

Wenn Siri mehrere Aufgaben zur Auswahl anbietet: Auswahl treffen und prüfen ob korrekte Aufgabe betroffen ist.

---

## Block 4 – Reihenfolge und Vollständigkeit der Entity-Vorschläge

Befehl: „[Aufgabe] auf heute in Dawny" – Siri zeigt Auswahlscreen.

Prüfen:
- Aufgaben aus dem **Heute-Bereich** erscheinen vor Backlog-Aufgaben
- **Aufgaben aller Kategorien** sind sichtbar, nicht nur unkategorisierte
- Subtitle zeigt **Kategorie · Status** (z.B. „Privat · Backlog", „Arbeit · Daily Focus")

---

## Block 5 – Heute-Liste vorlesen

| # | Befehl | Erwartetes Ergebnis |
|---|--------|---------------------|
| 5.1 | „Was steht heute in Dawny an" | Siri liest Aufgaben aus dem Heute-Bereich vor |
| 5.2 | (Heute-Bereich leer) „Was steht heute in Dawny an" | Siri antwortet „Dein Heute-Bereich ist leer" o.ä. |

---

## Block 6 – Routing-Test

Siri-Verlauf zurücksetzen: Einstellungen → Siri & Diktierfunktion → Siri-Verlauf löschen.

Dann testen:

| # | Befehl | Erwartetes Ergebnis |
|---|--------|---------------------|
| 6.1 | „Neue Aufgabe in Dawny" | Siri geht **direkt** zu Dawny, kein App-Auswahlscreen |
| 6.2 | „Neue Aufgabe in Dawny" (3× wiederholen) | Nach wiederholter Nutzung: Routing wird stabiler |

---

## Bekannte Einschränkungen

- **AssistantSchemas für Tasks existieren nicht** im öffentlichen iOS SDK (geprüft gegen iOS 26.4 SDK). Eine task-spezifische semantische Priorisierung von Dawny gegenüber Systemapps ist daher nicht möglich. Siri lernt die Präferenz stattdessen aus dem Nutzerverhalten.
- **App-Name als Präfix** (`"Dawny, neue Aufgabe"`) ist kein gültiges AppShortcut-Phrasen-Format und führt zu „Ich finde keine passende App".
- **Notizen-Ordner mit App-Namen** können den Disambiguation-Screen auslösen. Sicherstellen dass kein Ordner/Liste namens „Dawny" in Apple Notizen oder Erinnerungen existiert.
- Entity-basierte Intents (`MoveTaskToTodayIntent`, `CompleteTaskIntent`) erfordern eine Aufgabe im Datenbestand — mit leerem Backlog/Heute zeigt Siri „Keine Aufgaben gefunden".
