# App Store Connect — Lizenz- und Datenschutz-Checkliste

Diese Schritte musst du **manuell in App Store Connect** erledigen. Sie sind
Teil der rechtlichen Lizenzierung der App, lassen sich aber nicht aus dem
Repository heraus automatisieren.

## 1. EULA — Apples Standard verwenden

1. Gehe zu **App Store Connect → My Apps → Dawny → App Information**.
2. Scrolle zu **License Agreement**.
3. Stelle sicher, dass **"Use Apple's Standard License Agreement for Apps"**
   aktiviert ist (kein Custom-EULA hochgeladen).
4. Damit gilt automatisch das
   [Apple Standard License Agreement (EA1602)](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)
   für jeden, der Dawny aus dem App Store oder über TestFlight installiert.

**Wenn du später eine eigene EULA willst** (z. B. für Pro-Features mit
In-App-Käufen), kannst du den Custom-EULA-Slot dort befüllen. Aktuell nicht nötig.

## 2. Privacy Policy URL hinterlegen

Pflichtfeld in App Store Connect für **jede** App, auch wenn keine Daten
erhoben werden. Ohne URL geht keine Review durch.

1. Hoste eine der folgenden Dateien (oder beide) öffentlich erreichbar:
   - `docs/PRIVACY.de.md`
   - `docs/PRIVACY.en.md`
2. **Vor dem Hosting** die mit `[BITTE ERGÄNZEN: …]` / `[PLEASE FILL IN: …]`
   markierten Stellen ausfüllen — insbesondere **deine ladungsfähige
   Postanschrift** (DSGVO Art. 13 Pflicht).
3. Empfohlene Hosting-Optionen:
   - **GitHub Pages** des Repos (kostenlos, ein Klick): aktiviere unter
     *Settings → Pages → Source: main branch / docs folder*. Die URL wäre dann
     `https://flrnsndr.github.io/Dawny/PRIVACY.de` bzw. `.../PRIVACY.en`.
   - Eigene Domain.
4. In App Store Connect: **App Information → Privacy Policy URL** eintragen.
   - Wenn du nur eine Sprache hosten willst: Englisch wählen, das ist die
     "Primary Language" deiner App.
   - Wenn du beide hostest, kannst du in App Store Connect pro Lokalisierung
     unterschiedliche URLs angeben (App Privacy → Privacy Policy URL je Locale).

## 3. App Privacy Details ausfüllen

Pflicht seit Dezember 2020. Diese Angaben erscheinen als **Privacy Nutrition
Labels** auf der App-Store-Produktseite.

1. Gehe zu **App Store Connect → My Apps → Dawny → App Privacy**.
2. **Data Collection**: Wähle **"No, we do not collect data from this app"**.
   - Dawny erhebt keine personenbezogenen Daten beim Entwickler. Alles bleibt
     auf dem Gerät bzw. in iCloud des Nutzers.
   - Apple zählt Daten, die **nur lokal** auf dem Gerät bleiben oder im
     **eigenen iCloud-Account** des Nutzers landen (Reminders, EventKit), nicht
     als "Data Collection" durch dich als Entwickler. Daher ist "No" korrekt.
3. Speichern und veröffentlichen.

## 4. Privacy Manifest — passt es noch?

Die Datei `App/PrivacyInfo.xcprivacy` ist Teil dieses Repos und wird
automatisch in den App-Bundle eingebunden (das `App/`-Verzeichnis ist eine
File-System-Synchronized Group in Xcode 16+). Aktuell deklariert sie:

- **Tracking**: nein.
- **Tracking-Domains**: keine.
- **Erhobene Datenarten**: keine.
- **Required-Reason-APIs**: nur `NSPrivacyAccessedAPICategoryUserDefaults` mit
  Reason `CA92.1` (App-eigene Settings).

**Wenn du später** Folgendes hinzufügst, musst du das Manifest erweitern:

| Neue Funktion / API | Manifest-Update |
|---|---|
| `FileManager` mit `modificationDate` / `creationDate` | `NSPrivacyAccessedAPICategoryFileTimestamp` mit `C617.1` |
| `ProcessInfo().systemUptime` | `NSPrivacyAccessedAPICategorySystemBootTime` mit `35F9.1` |
| `URL.resourceValues` mit `volumeAvailableCapacityKey` o. ä. | `NSPrivacyAccessedAPICategoryDiskSpace` mit `E174.1` |
| `UITextInputMode.activeInputModes` | `NSPrivacyAccessedAPICategoryActiveKeyboards` mit `54BD.1` |
| Drittanbieter-SDKs | Jedes SDK muss eigenes Privacy Manifest mitliefern. Bei Hinzufügen prüfen. |
| Tracking, Analytics, Werbung | `NSPrivacyTracking` auf `true` und Datenkategorien deklarieren. **Nicht** ohne ATT-Dialog! |

Apple-Referenz:
[Describing data use in privacy manifests](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests).

## 5. Export-Compliance (jeder TestFlight-Build)

Bei jedem neuen Build fragt App Store Connect nach **Export Compliance**.
Dawny verwendet **keine eigene Verschlüsselung** außer dem, was iOS / Apples
Standard-APIs (HTTPS, SwiftData, Keychain) bereitstellen.

- Wähle **"None of the algorithms mentioned above"** bzw.
  **"Yes, but limited to Apple's standard exemptions"**.
- Optional: trage in der `Info.plist` einmalig `ITSAppUsesNonExemptEncryption`
  = `false` ein, dann erscheint die Frage nicht mehr bei jedem Build.

## 6. Markenrechtlicher Hinweis (optional, langfristig)

Der Name "Dawny" und das Logo sind in diesem Repo als **Common-Law-Marke** über
die `NOTICE`-Datei dokumentiert. Für stärkeren Schutz:

- **DPMA (DE)**: Anmeldung einer Wortmarke ab ca. 290 € Gebühr (online).
- **EUIPO (EU)**: ab ca. 850 € (eine Klasse), deckt 27 Länder.

Vorher prüfen, ob "Dawny" markenrechtlich frei ist
([TMview](https://www.tmdn.org/tmview/)). Reine Empfehlung, keine Pflicht
für die App-Store-Veröffentlichung.

---

## Quick-Reference

| Was | Wo | Status |
|---|---|---|
| EULA = Apple Standard EA1602 | App Information → License Agreement | manuell |
| Privacy Policy URL | App Information → Privacy Policy URL | manuell |
| Privacy Nutrition Labels | App Privacy → Data Collection | manuell |
| Privacy Manifest im Bundle | `App/PrivacyInfo.xcprivacy` | automatisch via Xcode |
| Export Compliance | Build-Upload-Dialog oder `Info.plist` | manuell |
