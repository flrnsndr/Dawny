# Dawny — Release Runbook

_Dieser Ablauf gilt für jeden Build, der in TestFlight oder den App Store geht. Schritt für Schritt durcharbeiten, nichts überspringen._

---

## Versionsstrategie (Semver)

| Änderungstyp | Beispiel | Bump |
|---|---|---|
| Neues Feature, spürbare UX-Änderung | Reset-Stunde konfigurierbar | **Minor** `0.7 → 0.8` |
| Bugfix, Kleinigkeit, Textkorrekturen | Crash beim Archivieren behoben | **Patch** `0.7.0 → 0.7.1` |
| Komplettes Redesign, Breaking Change | Neue Tab-Architektur | **Major** `0 → 1.0` |

**Build-Nummer:** immer um +1 erhöhen, unabhängig vom Versionstyp. Niemals zurücksetzen.

---

## Phase 1 — Vorbereitung (lokal)

- [ ] Alle relevanten PRs gemergt, Branch ist auf `main`
- [ ] `git status` ist sauber — nichts uncommittet oder gestagter
- [ ] Tests grün:
  ```bash
  xcodebuild test -project Dawny.xcodeproj -scheme Dawny -destination 'platform=iOS Simulator,name=iPhone 16'
  ```
- [ ] **Lokalisation vollständig:** `App/Sources/Localizable.xcstrings` öffnen und prüfen, dass keine Strings den Status „Needs Review" oder leere Übersetzungen haben (en + de)

---

## Phase 2 — Version & Build bumpen

1. In Xcode: **Project → Dawny target → General**
2. **Version** (`MARKETING_VERSION`) anpassen — Semver laut obiger Tabelle
3. **Build** (`CURRENT_PROJECT_VERSION`) um +1 erhöhen
4. Änderung committen:
   ```bash
   git add Dawny.xcodeproj/project.pbxproj
   git commit -m "chore: bump version to X.Y.Z (build NNN)"
   ```
5. Tag vergeben und pushen:
   ```bash
   git tag vX.Y.Z
   git push origin main --tags
   ```

---

## Phase 3 — QA auf physischem Gerät

→ Vollständige Checkliste in **[docs/QA_checklist.md](QA_checklist.md)** durchlaufen.

_Simulator reicht nicht — besonders Siri-Intents und EventKit müssen auf echtem Hardware getestet werden._

---

## Phase 4 — Archive & Upload

1. In Xcode: **Product → Scheme → Edit Scheme** → sicherstellen, dass Run-Config auf **Release** steht
2. **Product → Archive** (dauert ~1–2 Min.)
3. Im Organizer: **Validate App** — alle Warnungen lesen und beheben
4. **Distribute App → App Store Connect → Upload**

---

## Phase 5 — App Store Connect

> Detaillierte rechtliche Pflichten → **[docs/APP_STORE_CONNECT_CHECKLIST.md](APP_STORE_CONNECT_CHECKLIST.md)**

- [ ] Build erscheint unter **TestFlight** (kann 5–30 Min. dauern)
- [ ] **"What's New"**-Text für diesen Release vorbereiten — in beiden Sprachen (en + de), max. 4000 Zeichen, Nutzersprache, kein Tech-Jargon
- [ ] Screenshots prüfen: Haben sich UI-Flows verändert? Falls ja → neue Screenshots mit Xcode Simulator oder physischem Gerät erstellen
- [ ] **App Store Connect → My Apps → Dawny → [Version] → Submit for Review**

---

## Phase 6 — GitHub Release erstellen

1. Auf GitHub: **Releases → Draft a new release**
2. Tag wählen: `vX.Y.Z` (der in Phase 2 gesetzte Tag)
3. Titel: `Dawny vX.Y.Z`
4. Release Notes schreiben — gleicher Inhalt wie "What's New" im App Store, kann auf Englisch sein
5. **Publish release**

---

## Phase 7 — Post-Release

- [ ] Version für nächsten Zyklus vorbereiten: `MARKETING_VERSION` auf `X.Y+1.0` setzen, `CURRENT_PROJECT_VERSION` bleibt unverändert (nächster Build bumpt ihn) — committen mit `chore: open X.Y+1.0 development`
- [ ] GitHub Milestone für diesen Release schließen (falls verwendet)
- [ ] TestFlight-Gruppe aktualisieren, falls neue externe Tester eingeladen werden sollen

---

## Freigabe

| Feld | Wert |
|---|---|
| Version | |
| Build | |
| Datum | |
| Getestet von | |
| QA Checkliste abgezeichnet | ja / nein |
