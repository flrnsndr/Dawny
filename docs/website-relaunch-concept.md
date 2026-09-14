# Dawny Website Relaunch, Umsetzungskonzept

**Stand:** 28. August 2026
**Zielsystem:** dawnyapp.com, IONOS Webhosting Plus, statisches Astro-Build
**Adressat dieses Dokuments:** der Agent, der den Relaunch umsetzt. Alles hier ist verbindlich, sofern nicht ausdrücklich als Vorschlag oder offener Punkt markiert.

---

## 0. Ausgangslage

Die Seite ist nicht kaputt, sie wurde bewusst abgeschaltet. Commit `e6755a3` ("chore(website): take dawnyapp.com offline") hat den Deploy-Workflow von `website/dist/` auf `website/offline/` umgestellt. Weil `lftp mirror --reverse --delete` läuft, hat dieser Upload jede zuvor veröffentlichte Datei vom Webspace entfernt. Aktueller Zustand:

- Root liefert eine zweisprachige Hinweisseite ("This site is currently offline").
- Jede alte URL läuft in 404 und bekommt dieselbe Seite als `ErrorDocument`.
- `X-Robots-Tag: noindex` und `Cache-Control: no-store` sind gesetzt, die Domain fällt aus dem Index.

Im Repo liegt vollständig einsatzbereit:

- `website/` mit Astro 5, Tailwind 4, DE/EN-i18n, Legal-Layout, Sitemap, RSS, `llms.txt`, FTPS-Deploy-Skript.
- `website/prototype/` mit dem Entwurf aus der früheren Sitzung: statischer One-Pager, `index.html` (389 Zeilen), `styles.css` (803 Zeilen), `demo.js` (404 Zeilen, geführte Reset-Demo), Bilder und Instrument-Serif-Font. Dieser Ordner ist **nicht** eingecheckt.

Der Prototyp ist inhaltlich und optisch die bessere Grundlage als die alten Astro-Sections. Er wird nach Astro portiert, nicht ersetzt.

---

## 1. Getroffene Entscheidungen

| Thema | Entscheidung |
| --- | --- |
| Sprachen | DE und EN, beide vollständig, wie bisher unter `/de/` und `/en/` |
| Blog | entfällt komplett, alle 20 Blog-URLs plus `/blog/` und die RSS-Feeds gehen per 301 auf die jeweilige Startseite |
| Analytics | PostHog bleibt, cookieless, EU-Hosting |
| Impressum | ladungsfähige Straßenanschrift statt Postfach |
| Struktur | ein langer Scroller pro Sprache, dazu nur die zwei Rechtsseiten |
| Technik | Astro bleibt, Prototyp wird portiert |
| FAQ | stark ausgebaut, thematisch aufgeteilt und über die Seite verstreut, nicht als ein Klumpen am Ende |
| Anschrift | Kreuzstraße 26, 76133 Karlsruhe |
| Kontaktweg | ausschließlich E-Mail an `info@dawnyapp.com`, kein Formular, keine Telefonnummer (Begründung und Restrisiko in 2.10) |
| USt-IdNr. und Marke | beides nicht vorhanden, Dawny ist ein privates Projekt ohne Einnahmen |
| OG-Bild | wird in der neuen Palette neu entworfen, je Sprache eines |

---

## 2. Rechtlicher Teil

> Vorbemerkung, die im Umsetzungsdokument stehen bleibt: das hier ist keine Rechtsberatung. Es ist eine Zusammenstellung der üblichen Abmahnvektoren für eine deutsche App-Marketingseite und wie wir sie schließen. Restrisiko bleibt immer. Die zwei Punkte, bei denen ich Florian dringend zu einer anwaltlichen Kurzprüfung rate, sind mit **PRÜFEN** markiert.

### 2.1 Impressum, `/de/impressum/` und `/en/imprint/`

Pflichtangaben nach § 5 DDG (das DDG hat im Mai 2024 das TMG abgelöst, die Norm heißt weiter § 5, die Verweise im bestehenden Text stimmen also):

1. **Name:** Florian Schneider
2. **Anschrift, verbindlich:**
   ```
   Florian Schneider
   Kreuzstraße 26
   76133 Karlsruhe
   Deutschland
   ```
   Das bisherige "Postfach 11 13 15, 76063 Karlsruhe" wird ersatzlos entfernt. § 5 Abs. 1 Nr. 1 DDG verlangt die Anschrift, unter der der Diensteanbieter niedergelassen ist, ein Postfach genügt dafür nach überwiegender Auffassung nicht. Die Adresse steht ausschließlich im Impressum, nicht im Footer und nicht in der Datenschutzerklärung als zweite Kopie. In der Datenschutzerklärung wird sie unter "Verantwortlicher" ebenfalls genannt, das ist die einzige zulässige Doppelung und dort Pflicht.
3. **Kontakt, verbindlich:** E-Mail `info@dawnyapp.com`, dazu eine zugesicherte Antwortzeit. Ins Impressum kommt der Satz:
   > Ich beantworte Anfragen in der Regel innerhalb weniger Tage.

   Kein Kontaktformular, keine Telefonnummer. Die Begründung und das verbleibende Restrisiko stehen in 2.10, das ist bewusst entschieden und kein Versehen.
4. **Verantwortlich nach § 18 Abs. 2 MStV:** war wegen des Blogs drin. Ohne journalistisch-redaktionelle Inhalte ist die Angabe nicht mehr erforderlich, aber unschädlich. Empfehlung: drin lassen, kostet nichts.
5. **Umsatzsteuer-Identifikationsnummer: entfällt.** Es gibt keine. § 5 Abs. 1 Nr. 6 DDG verlangt die Angabe nur, wenn eine vorhanden ist. Es wird also weder eine Zeile "USt-IdNr.: nicht vorhanden" geschrieben noch eine Steuernummer eingetragen. Eine Steuernummer gehört ausdrücklich **nicht** ins Impressum.
6. **EU-Streitschlichtung: der bestehende Absatz muss raus.** Die ODR-Plattform der EU-Kommission wurde zum 20. Juli 2025 eingestellt, die zugrundeliegende ODR-Verordnung ist aufgehoben. Ein Impressum, das weiter auf `ec.europa.eu/consumers/odr` verlinkt, verweist auf einen toten Dienst. Das ist inzwischen selbst ein Abmahnvektor und der Link ist zusätzlich ein Haftungsrisiko für tote Verweise. Ersatzlos streichen.
7. **Verbraucherschlichtung nach § 36 VSBG:** die Pflicht trifft Unternehmer, die eine Website betreiben, ausgenommen sind Unternehmer mit zehn oder weniger Beschäftigten. Bei einem Einzelunternehmer greift die Ausnahme, der Satz ist nicht erforderlich. Er ist aber unschädlich und beruhigt. Empfehlung: den bestehenden Satz "Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen" behalten, in der Ich-Form umschreiben.
8. **Haftung für Inhalte und Links:** bestehende Absätze behalten, sie sind korrekt formuliert und verweisen auf §§ 7 bis 10 DDG.
9. **Urheberrecht und Marken:** bestehenden Absatz behalten, Formulierung entschärfen. **Es ist keine Marke eingetragen.** Der heutige Satz "Die Marke „Dawny", das Dawny-Logo und das App-Icon sind Marken von Florian Schneider" erweckt den Eindruck einer Registermarke und muss weg. Verbindliche Neufassung:
   > „Dawny", das Logo und das App-Icon sind Kennzeichen von Florian Schneider. Der Quellcode der App steht unter der MIT-Lizenz öffentlich zur Verfügung.

   Nirgends auf der Seite darf ein ® stehen. Ein ™ ist rechtlich unbedenklich, wird aber ebenfalls weggelassen, weil es nach mehr aussieht, als da ist. Sollte später eine Wortmarke eingetragen werden, darf die stärkere Formulierung samt Registernummer nachgezogen werden.
10. **Apple-Marken:** neuer Absatz, den es bisher nicht gibt und der bei jeder App-Seite dazugehört:
    > Apple, das Apple-Logo, iPhone, iPad, Mac, Apple Watch, iCloud, Siri und App Store sind Marken der Apple Inc., eingetragen in den USA und anderen Ländern. App Store ist eine Dienstleistungsmarke der Apple Inc.
11. Die Ich-Form ist durchgängig zu verwenden. Das aktuelle Impressum wechselt zwischen "wir" und Einzelperson. Bei einer Einzelperson, die eine kostenlose App aus Interesse baut, wirkt das "wir" wie eine Firma, die es nicht gibt. Das ist nicht nur Stil: wer sich größer darstellt, als er ist, macht sich angreifbarer.

**Hinweis zum Hobbystatus.** Dawny ist ein privates Projekt ohne Einnahmen. Die Impressumspflicht nach § 5 DDG knüpft an "geschäftsmäßige, in der Regel gegen Entgelt angebotene" digitale Dienste an, und man kann durchaus vertreten, dass eine kostenlose Hobby-App ohne jede Monetarisierung darunter nicht fällt. Wir stützen uns darauf **nicht**. Gründe: die Abgrenzung ist unscharf, "geschäftsmäßig" verlangt keine Gewinnerzielungsabsicht, sondern nur eine nachhaltige Tätigkeit, und eine App im App Store mit eigener Domain und Marketingseite sieht von außen nach genau dem aus. Ein vollständiges Impressum kostet nichts und nimmt die ganze Diskussion vorweg. Dieselbe Logik gilt für die Datenschutzerklärung.

Was aus dem Hobbystatus dagegen wirklich folgt: keine USt-IdNr. (Punkt 5), keine Pflicht nach § 36 VSBG (Punkt 7), keine BFSG-Pflichten (Abschnitt 2.6).

### 2.2 Datenschutzerklärung, `/de/datenschutz/` und `/en/privacy/`

Der bestehende Text ist gut und bleibt weitgehend erhalten. Änderungen:

1. Verantwortlicher: Florian Schneider, Kreuzstraße 26, 76133 Karlsruhe, `info@dawnyapp.com`.
2. Stand-Datum aktualisieren.
3. **Reihenfolge bleibt, wie sie ist.** Der Abschnitt "Diese Webseite" steht heute am Ende, inhaltlich schöner wäre er vorne. Rechtlich ist das egal, und einen langen Text umzusortieren kostet Zeit ohne Gegenwert. Also nur Inhalte ändern, Struktur nicht anfassen.
4. **Hosting IONOS:** ergänzen, dass für die Server-Logfiles Art. 6 Abs. 1 lit. f DSGVO die Rechtsgrundlage ist (Interesse am sicheren und störungsfreien Betrieb) und dass mit IONOS eine Vereinbarung zur Auftragsverarbeitung nach Art. 28 DSGVO besteht. Einordnung dazu siehe 2.11.
5. **PostHog:** der Abschnitt ist inhaltlich korrekt und beschreibt die Konfiguration, die in `src/components/PostHog.astro` tatsächlich gesetzt ist (`cookieless_mode: 'always'`, `persistence: 'memory'`, `autocapture: false`, `disable_session_recording: true`, `disable_surveys: true`). Diese Konfiguration ist bei der Portierung **unverändert zu übernehmen**, sie ist die technische Grundlage dafür, dass kein Consent-Banner nötig ist. Wer sie ändert, ändert die Rechtslage. Zusätzlich in den Text:
   - PostHog, Inc. ist Auftragsverarbeiter, Verarbeitung in der EU (AWS eu-central-1, Frankfurt).
   - Ein Zugriff aus den USA im Rahmen von Support ist nicht ausgeschlossen, abgesichert über die Standardvertragsklauseln im DPA von PostHog. Siehe 2.11.
   - Der Satz zum Widerspruch bleibt.
6. **Kontaktaufnahme:** neuer, kurzer Abschnitt. Fehlt heute vollständig und wird oft moniert. Wörtlich zu übernehmen:
   > ### Kontaktaufnahme
   >
   > Wenn du mir schreibst, verarbeite ich deine E-Mail-Adresse und den Inhalt deiner Nachricht, um sie zu beantworten. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO, mein berechtigtes Interesse daran, Anfragen beantworten zu können. Deine Nachricht liegt in meinem E-Mail-Postfach und wird gelöscht, wenn der Vorgang erledigt ist. Weitergegeben wird sie nicht.

   Die englische Fassung ist eine Übersetzung davon.
7. **App Store:** kurzer Hinweis, dass der Klick auf den Download-Button zu Apple führt und dort Apples Datenschutzrichtlinie gilt.
8. **Keine Einbindung externer Ressourcen** außer PostHog: ausdrücklich benennen. Keine Google Fonts vom CDN, keine YouTube-Einbettung, keine Karten, keine Social-Plugins, keine externen Bilder. Das ist im Build sicherzustellen, siehe 7.9.
9. Der Abschnitt "App-Tracking-Transparenz" bleibt.

### 2.3 Cookie-Banner

Es wird keiner gebaut. Begründung, die auch in der Datenschutzerklärung steht: § 25 TDDDG verlangt Einwilligung nur für das Speichern von Informationen auf dem Endgerät und den Zugriff auf dort gespeicherte Informationen. Mit `persistence: 'memory'` und `cookieless_mode: 'always'` findet beides nicht statt. Bedingung: es darf auch sonst nichts in `localStorage`, `sessionStorage` oder Cookies geschrieben werden. **Das gilt auch für eigene Features.** Ein Dark-Mode-Umschalter mit gespeicherter Präferenz oder ein "FAQ-Abschnitt bleibt aufgeklappt"-Zustand in `localStorage` würde die Banner-Freiheit kippen. Deshalb:

- **Kein manueller Theme-Switcher.** Dark Mode ausschließlich über `prefers-color-scheme`.
- **Kein persistenter UI-Zustand.** Alles, was die Seite sich merkt, lebt nur im Speicher der laufenden Seite.
- Die Sprachumschaltung ist ein normaler Link, kein gespeicherter Zustand.

### 2.4 Apple-Assets und App-Store-Badge

Der Prototyp baut das Apple-Logo als eigenen SVG-Pfad nach und setzt es in einen selbstgebauten Button ("Laden im App Store"). Das ist zu ersetzen. Apple stellt die Badges bereit und verlangt ihre unveränderte Verwendung in Form, Farbe, Mindestgröße und Schutzraum. Die offiziellen Dateien liegen bereits im Repo:

```
website/public/assets/app-store-badge-de-blk.svg
website/public/assets/app-store-badge-de-wht.svg
website/public/assets/app-store-badge-en-blk.svg
website/public/assets/app-store-badge-en-wht.svg
```

Regeln für die Umsetzung:

- Badge je nach Sprache und Farbschema wählen, hell auf dunklem Grund die weiße Variante, sonst die schwarze.
- Badge nicht einfärben, nicht drehen, nicht mit eigenem Text überlagern, nicht in einen eigenen Button setzen. Der Badge **ist** der Button.
- Mindesthöhe 40 px, Schutzraum rundherum mindestens ein Zehntel der Badge-Höhe.
- `alt`-Text: "Dawny im App Store laden" beziehungsweise "Download Dawny on the App Store".
- Der selbstgebaute `<a class="appstore">` samt Inline-SVG aus dem Prototyp wird ersatzlos gelöscht.
- Kein Apple-Gerätemockup mit fotografiertem iPhone-Rahmen aus fremder Quelle. Die vorhandenen Screenshots werden ohne Geräterahmen oder mit einem selbst gezeichneten, generischen abgerundeten Rahmen gezeigt.

### 2.5 Schriften und externe Ressourcen

Bleibt wie bisher: alle Fonts self-hosted über `@fontsource-variable/*` und `@fontsource/instrument-serif`. Kein Request an `fonts.googleapis.com` oder `fonts.gstatic.com`. Das ist nach dem LG-München-Urteil zu Google Fonts der Standardweg und muss beim Portieren des Prototyps erhalten bleiben. Der Prototyp bindet Instrument Serif lokal per `@font-face` ein, in Astro übernimmt das der bestehende Import in `src/styles/global.css`.

Zu prüfen nach dem Build: `grep -rEo 'https?://[^"'"'"' )]+' dist/` darf außer `posthog.com`, `apps.apple.com`, `dawnyapp.com`, `schema.org` und den Links in den Rechtstexten nichts liefern.

### 2.6 Barrierefreiheit und BFSG

Das Barrierefreiheitsstärkungsgesetz gilt seit 28. Juni 2025. Es erfasst Dienstleistungen im elektronischen Geschäftsverkehr gegenüber Verbrauchern, also im Kern Websites, über die Verträge geschlossen werden. Eine reine Produktseite ohne Bestellfunktion für eine kostenlose App fällt nach der üblichen Lesart nicht darunter, zusätzlich greift die Kleinstunternehmerausnahme für Dienstleistungen. Ergebnis: keine Pflicht zur Barrierefreiheitserklärung, kein Feedback-Mechanismus nötig.

Trotzdem wird sauber gebaut, aber ohne formale Abnahme. Die Trennlinie verläuft dort, wo Aufwand entsteht.

**Wird gemacht, weil es beim Bauen nichts kostet:**

- Kontrast mindestens 4,5:1 für Text, 3:1 für große Schrift und Bedienelemente. Die Palette in 6.1 ist darauf ausgelegt.
- Sichtbarer Fokusring auf allen interaktiven Elementen, nie `outline: none` ohne Ersatz.
- Semantische Überschriftenhierarchie, genau ein `h1` pro Seite, keine Sprünge.
- Skip-Link zum Hauptinhalt (im Prototyp vorhanden, übernehmen).
- Jedes Bild mit sinnvollem `alt`, dekorative Grafiken mit `alt=""` und `aria-hidden`.
- Die FAQ-Akkordeons als natives `<details>` und `<summary>`, damit sie ohne JavaScript und mit Tastatur funktionieren.
- Die geführte Reset-Demo respektiert `prefers-reduced-motion` und hat eine Pause-Steuerung, siehe 6.5. Das ist auch schlicht bessere Bedienung, unabhängig von jeder Norm.

**Wird nicht gemacht:** kein formaler WCAG-Durchlauf, kein VoiceOver-Protokoll, keine dokumentierte Kontrastmessung je Farbpaar, keine Barrierefreiheitserklärung. Stattdessen ein Stichprobencheck vor dem Livegang: einmal mit der Tastatur durch die Seite, einmal ein FAQ-Block mit VoiceOver, einmal Zoom auf 200 Prozent. Findet sich dabei nichts Grobes, ist es gut genug. Das ist eine bewusste Entscheidung, weil hier keine Rechtspflicht besteht.

### 2.7 Bilder, Screenshots, Emojis

- Alle Screenshots sind eigene Aufnahmen aus dem Simulator, unproblematisch.
- In den Screenshots dürfen keine echten personenbezogenen Daten stehen. Es sind ausschließlich Testaufgaben zu verwenden, siehe die vorhandenen Seeder in `App/Sources/ScreenshotSeeder.swift`.
- Emojis in Beispielaufgaben sind unbedenklich, sie werden vom System-Font gerendert und nicht als Bild eingebunden.
- Keine Stockfotos, keine Icons aus fremden Sets. Alle Symbole auf der Seite werden als Inline-SVG selbst gezeichnet oder es sind SF-Symbols-Screenshots innerhalb der App-Screenshots, die als Teil der eigenen Oberfläche zulässig sind. SF Symbols dürfen **nicht** als freistehende Grafik auf der Website verwendet werden, das verbietet Apples Lizenz.

### 2.8 Lizenz und Quellcode

Die App ist MIT-lizenziert und öffentlich auf GitHub. Der Hinweis darauf bleibt im Impressum und darf gerne auch als Vertrauenssignal in den FAQ-Block "Daten und Vertrauen". `NOTICE` und `LICENSE` im Repo-Root sind davon unberührt.

### 2.9 Werbliche Aussagen

Alles auf der Seite muss der Realität der ausgelieferten App entsprechen, sonst ist es irreführende Werbung nach § 5 UWG. Konkret geprüft und in diesem Konzept berücksichtigt:

- "kostenlos, kein Abo, keine In-App-Käufe, keine Werbung" stimmt.
- "kein Tracking in der App" stimmt, die App enthält keine Analytics-SDKs. Auf der Website läuft PostHog, das darf nicht vermischt werden. Formulierung immer: "Die App sammelt nichts. Auf dieser Website messe ich anonym die Reichweite, ohne Cookies."
- "keine Konten" stimmt.
- Die Angabe zur Mindest-iOS-Version muss mit der App-Store-Seite übereinstimmen. Im Projekt steht `IPHONEOS_DEPLOYMENT_TARGET = 18.6` auf Target-Ebene. **PRÜFEN** gegen die tatsächliche App-Store-Angabe, bevor eine Zahl auf die Seite geschrieben wird. Im Zweifel keine Zahl nennen, sondern "Erfordert ein aktuelles iPhone" vermeiden und stattdessen gar nichts sagen, denn der App Store zeigt es ohnehin an.
- Keine Vergleichsaussagen gegen namentlich genannte Konkurrenzprodukte. Der alte Blog hatte einen Beitrag "dawny-vs-todoist", der fällt mit dem Blog weg und wird nicht auf die Seite geholt. Vergleichende Werbung ist zulässig, aber sie ist ein Streitanlass, den wir für nichts eintauschen.

### 2.10 Kontaktweg, und warum kein Formular

**Entscheidung:** die Seite nennt ausschließlich `info@dawnyapp.com` und die zugesicherte Antwortzeit aus 2.1. Es gibt kein Kontaktformular und keine Telefonnummer.

**Was die Rechtslage verlangt.** § 5 Abs. 1 Nr. 2 DDG fordert Angaben, die "eine schnelle elektronische Kontaktaufnahme und unmittelbare Kommunikation" ermöglichen, "einschließlich der Adresse der elektronischen Post". Aus dem Wort "einschließlich" liest die Rechtsprechung, dass die E-Mail-Adresse allein nicht zwingend genügt und ein zweiter, gleichwertig schneller Weg danebenstehen soll. Der EuGH (C-649/17) hat das entschärft: es muss kein Telefon und kein Fax sein, es genügt ein anderer Weg, der eine zügige Kontaktaufnahme erlaubt.

**Warum wir es trotzdem bei der E-Mail belassen.** Ein Formular hätte auf einer statisch ausgelieferten Seite eine Serverkomponente nötig gemacht, mit Spamschutz, Absenderpostfach, eigener Seite in zwei Sprachen und dauerhafter Wartung. Das ist für ein kostenloses Hobbyprojekt unverhältnismäßig, und ein Formular, das nach einem PHP-Update still nicht mehr zustellt, ist als "zweiter Kanal" schlechter als gar keiner. Eine Telefonnummer wäre rechtlich am eindeutigsten und kostenlos, scheidet aber aus Gründen der Privatsphäre aus.

**Das Restrisiko, klar benannt.** Die Auslegung "E-Mail allein genügt nicht" ist verbreitet, aber sie ist Auslegung und kein Gesetzeswortlaut. Bei einer kostenlosen App ohne Vertragsschluss, ohne Wettbewerber und ohne Verbrauchergeschäft ist die praktische Wahrscheinlichkeit einer Beanstandung sehr klein. Sie ist nicht null. Das ist eine bewusste Abwägung zugunsten des Aufwands, keine Nachlässigkeit.

**Falls das später anders bewertet wird**, ist der günstigste Nachzug eine Telefonnummer im Impressum, eine Zeile ohne jede Technik. Der Text ist deshalb so zu bauen, dass der Kontaktblock im Impressum ein eigener i18n-Key ist und sich ergänzen lässt, ohne dass am Layout etwas angefasst werden muss.

**Umsetzung.** Die E-Mail-Adresse erscheint an drei Stellen: im Impressum, in der Datenschutzerklärung unter "Verantwortlicher" und "Kontaktaufnahme", und als `mailto:`-Link im Footer. Keine Verschleierung durch JavaScript oder Bildschreibweise. Solche Tricks helfen gegen Spam kaum und machen die Adresse für Screenreader und für Menschen unbrauchbar, die sie kopieren wollen.

### 2.11 AVV und DPA, kurz gehalten

Formal verlangt Art. 28 DSGVO einen Vertrag, sobald jemand personenbezogene Daten im Auftrag verarbeitet. Das trifft hier auf IONOS zu (IP-Adressen in den Serverlogs) und auf PostHog (IP und User-Agent für den Tages-Hash). Ob der Verantwortliche die Rohdaten selbst je zu Gesicht bekommt, ist dafür unerheblich. Die Ausnahme für rein persönliche Tätigkeiten (Art. 2 Abs. 2 lit. c DSGVO) greift bei einer öffentlich erreichbaren Website nicht.

**Praktisch ist das kein Aufwand.** Beide Verträge bestehen bereits, ohne dass etwas unterschrieben werden müsste: IONOS führt die Vereinbarung zur Auftragsverarbeitung als Bestandteil der Vertragsbedingungen, abrufbar im Kundenkonto. PostHog bindet sein Data Processing Addendum über die Nutzungsbedingungen ein, abrufbar unter posthog.com/dpa, inklusive Standardvertragsklauseln. Der einzige sinnvolle Handgriff ist, beide PDFs einmal herunterzuladen und abzulegen, damit sie im unwahrscheinlichen Fall einer Nachfrage greifbar sind.

**Konsequenz für die Umsetzung:** der Agent schreibt die Sätze in der Datenschutzerklärung ohne Vorbehalt, sie stimmen. Es braucht keine Platzhalter, keine Fallunterscheidung und keine alternative Textvariante.

**Einordnung des Risikos**, damit niemand hier mehr Sorgfalt investiert, als der Punkt verdient: ein fehlender AVV ist kein Abmahnthema, es gibt keinen Wettbewerber. Der einzige denkbare Weg wäre eine Beschwerde bei der Landesdatenschutzbehörde, die Unterlagen anfordert. Bei einem kostenlosen Projekt ohne eigenen Datenbestand endet so etwas mit einer Aufforderung zur Nachbesserung. Die ernsthaften Risiken dieser Seite liegen woanders, nämlich bei der Impressumsanschrift (2.1), dem toten ODR-Link (2.1) und der Badge-Nutzung (2.4).

### 2.12 Zusammenfassung der Handlungspunkte für Florian

Diese Punkte kann kein Agent erledigen:

1. Bei Gelegenheit: AVV von IONOS und DPA von PostHog als PDF ablegen (siehe 2.11). Blockiert den Livegang nicht.
2. Optional: anwaltliche Kurzprüfung von Impressum und Datenschutzerklärung.

Mehr ist es nicht. Nichts davon blockiert den Livegang.

Erledigt und im Konzept eingearbeitet: Anschrift, zweiter Kontaktkanal, USt-IdNr. (keine), Markenfrage (keine Eintragung), Kontaktadresse.

---

## 3. Informationsarchitektur

Eine lange Seite pro Sprache, dazu zwei Rechtsseiten. Sonst nichts.

```
/                       → 302 auf /de/ oder /en/ nach Accept-Language (bleibt wie bisher)
/de/                    → der One-Pager
/en/                    → the one-pager
/de/impressum/          → Impressum
/de/datenschutz/        → Datenschutzerklärung
/en/imprint/            → Imprint
/en/privacy/            → Privacy Policy
```

Sechs URLs, alles statisch, keine Serverlogik. Alles andere ist Redirect, siehe 7.8.

### 3.1 Abschnittsfolge des One-Pagers

Die Leitidee bleibt der Tagesbogen aus dem Prototyp: hell im Hero, Nacht beim Reset, danach wieder Papier. Die FAQ-Blöcke sind bewusst **keine** eigene Endsektion, sondern sitzen jeweils direkt hinter dem Abschnitt, dessen Fragen sie beantworten. Wer scrollt, bekommt die Antwort dort, wo die Frage entsteht.

| # | Anker | Abschnitt | Typ |
| --- | --- | --- | --- |
| 1 | (kein) | Hero | Bühne, hell |
| 2 | `#reset` | Ein Tag in Dawny, geführte Demo | Interaktiv, Nachtstimmung |
| 3 | `#faq-reset` | **FAQ-Block A: Der Reset** | 6 Fragen |
| 4 | `#bedienung` | Die drei Orte, Bedienungs-Erklärstrecke | Split, hell |
| 5 | `#faq-bedienung` | **FAQ-Block B: Wie nutze ich Dawny am besten?** | 12 Fragen, zwei Untergruppen |
| 6 | `#haltung` | Warum Dawny so ist, wie es ist | Textbühne, warm |
| 7 | `#faq-konzept` | **FAQ-Block C: Das Konzept dahinter** | 8 Fragen |
| 8 | `#geraete` | Widgets, Siri, Sync | Split plus Faktenraster |
| 9 | `#faq-technik` | **FAQ-Block D: Geräte, Sync und Widgets** | 7 Fragen |
| 10 | `#vertrauen` | Kostenlos, ohne Konto, Quellcode offen | Faktenband |
| 11 | `#faq-daten` | **FAQ-Block E: Daten, Kosten, Support** | 7 Fragen |
| 12 | (kein) | Schluss-CTA | zentriert |
| 13 | (kein) | Footer | Rechtsseiten, Sprache, Kontakt |

Gesamt 40 Fragen. Das ist viel und deshalb wichtig: die Blöcke sind visuell klar voneinander getrennt, jeder hat eine eigene Überschrift und eine kurze Einleitungszeile, und innerhalb von Block B gibt es zwei beschriftete Untergruppen. Niemand soll 40 zugeklappte Zeilen am Stück sehen.

### 3.2 Navigation

Sticky Header mit Wortmarke links und vier Zielen rechts: **Der Reset**, **Bedienung**, **Fragen**, **EN/DE**. "Fragen" springt auf `#faq-bedienung`, weil das der wichtigste Block ist.

Zusätzlich, und das ist der Teil, der die Länge beherrschbar macht: **ein FAQ-Register direkt unter dem Hero** ist ausdrücklich **nicht** vorgesehen. Stattdessen bekommt jeder FAQ-Block am Ende eine dezente Zeile "Weiter zu: [Titel des nächsten FAQ-Blocks]". So entsteht ein Pfad durch die Fragen, ohne dass oben eine Inhaltsverzeichnis-Wand steht.

Eine Fortschrittsleiste am rechten Rand ist **nicht** vorgesehen. Sie stand in einer früheren Fassung und ist gestrichen, weil sie einen zweiten `IntersectionObserver`, einen Sonderfall ab 1280 px und die in 7.10 beschriebene Reflow-Falle mitbringt, ohne dass sie irgendetwas erklärt. Der Header und die "Weiter zu"-Zeilen leisten die Orientierung.

---

## 4. Abschnitte im Detail

Alle Texte sind die deutsche Fassung und gehen so in `src/i18n/de.json`. Die englische Fassung ist eine Übersetzung mit identischen Keys, nicht eine eigene Textwelt. Übersetzungshinweise stehen in 5.7.

### 4.1 Hero

**Kicker:** To-do-App fürs iPhone
**H1:** Jeden Morgen eine leere Liste.
**Lead:** Was du dir für heute vornimmst, zählt. Nachts um drei endet der Tag: Erledigtes wird abgelegt, Liegengebliebenes wandert ins Archiv, statt sich anzuhäufen. Morgens entscheidest du neu, was heute wirklich dran ist.
**CTA:** offizieller App-Store-Badge, darunter die Zeile "Kostenlos. Kein Abo, keine Werbung, kein Konto."
**Bild:** `hero-heute.png`, die Heute-Ansicht, `fetchpriority="high"`, kein `loading="lazy"`.

Layout: zweispaltig ab 900 px, darunter Bild unter dem Text. Das Hero-Bild ist das LCP-Element und darf weder lazy geladen noch von einer Animation verzögert werden.

### 4.2 Geführte Demo, `#reset`

Wird eins zu eins aus `website/prototype/demo.js` übernommen. Kurzbeschreibung für den umsetzenden Agenten, damit er weiß, was er portiert:

Drei Spalten nebeneinander, Backlog, Heute, Archiv. Eine Zeitachse mit fünf Stationen (Vorher, Morgens, Tagsüber, 03:00 Uhr, Nächster Morgen) läuft von selbst los, sobald der Abschnitt sichtbar wird. Aufgaben wandern einzeln zwischen den Spalten, mit Vorlauf-Hervorhebung, Zielmarke und Nachleuchten. Unter der Bühne steht eine Bildunterschrift mit `aria-live="polite"`, die den aktuellen Schritt beschreibt. Ohne JavaScript bleibt der Endzustand nach dem Reset im Markup stehen und die Zeitachse ist ausgeblendet, das ist im Prototyp bereits so gelöst und muss erhalten bleiben.

Änderungen gegenüber dem Prototyp:

1. **Pause-Steuerung ergänzen.** Neben "Nochmal abspielen" ein Button "Anhalten" beziehungsweise "Weiter". WCAG 2.2 verlangt für automatisch startende Bewegung, die länger als fünf Sekunden läuft, eine Möglichkeit zum Anhalten. Der Durchlauf dauert bei `SPEED = 1` rund 28 Sekunden.
2. **`prefers-reduced-motion`**: kein Autostart, keine Wanderung. Stattdessen zeigt die Zeitachse fünf klickbare Stationen und die Spalten springen ohne Übergang in den jeweiligen Zustand.
3. Die drei Erklärabsätze unter der Bühne (Anläufe, wiederkehrende Aufgaben, warum drei Uhr) bleiben, wandern aber inhaltlich in FAQ-Block A und werden hier durch **einen** Satz ersetzt: "Drei Orte, eine Regel: Heute ist eine Zusage, keine Ablage."

### 4.3 Bedienung, `#bedienung`

Drei Split-Blöcke, abwechselnd links und rechts, wie im Prototyp.

**Block 1, Backlog.** Überschrift "Sortiert nach Zeithorizont, nicht nach Priorität". Text wie im Prototyp, aber die Kategorienliste auf den tatsächlichen Stand bringen:

- **Schnell erledigt** für alles, was in ein paar Minuten geht
- **Die nächsten Tage** für das, was diese Woche dran ist
- **Die nächsten Wochen** und **Die nächsten Monate** für den Rest
- **Irgendwann** für alles ohne Horizont
- eigene Kategorien, so viele du willst, mit eigenem Symbol
- wiederkehrende Kategorien als Sonderfall

Bild: `backlog.png`.

**Block 2, Heute.** Überschrift "Heute ist bewusst kurz". Text wie im Prototyp. Ergänzen: "Aus dem Backlog holst du eine Aufgabe mit einem Wisch nach rechts nach Heute." Bild: `heute.png`.

**Block 3, Archiv.** Neuer Block, den der Prototyp nicht hat, der aber gebraucht wird, weil das Archiv der am meisten missverstandene Ort ist. Überschrift "Das Archiv ist kein Papierkorb". Text:

> Im Archiv liegen zwei Dinge nebeneinander: unter **Erledigt**, was du geschafft hast, nach Datum sortiert. Unter **Archiviert**, was liegengeblieben ist. Nichts davon ist gelöscht. Ein Wisch nach rechts holt eine Aufgabe zurück, entweder in den Backlog oder direkt nach Heute. Wer den Morgen nach dem Reset öffnet, bekommt zuerst eine kurze Übersicht, was in der Nacht abgelegt wurde.

Bild: `archiv.png`.

### 4.4 Haltung, `#haltung`

Ruhiger Textabschnitt, warmes Papier, breite Serifenüberschrift, maximal 62 Zeichen Zeilenlänge. Drei kurze Absätze, keine Aufzählung:

**Überschrift:** Eine To-do-Liste soll dich nicht überführen.

> Die meisten Listen wachsen. Was du heute nicht schaffst, steht morgen wieder da, und übermorgen auch, nur mit einem roten Punkt daneben. Nach zwei Wochen ist die Liste ein Protokoll deiner Versäumnisse und du öffnest sie nicht mehr.

> Dawny dreht das um. Ein Platz in der Heute-Liste ist eine Zusage für diesen einen Tag. Wird sie nicht eingelöst, ist der Tag vorbei und die Aufgabe wandert ins Archiv, ohne Vorwurf und ohne roten Punkt. Sie ist nicht weg, sie ist nur nicht mehr im Weg.

> Was wirklich wichtig ist, holst du zurück. Was du dreimal nicht zurückholst, war es nicht.

### 4.5 Geräte, `#geraete`

Split-Block "Widgets" wie im Prototyp, Bild `widgets.png`. Danach ein Faktenraster mit sechs Kacheln, angepasst an den tatsächlichen Stand:

| Kachel | Text |
| --- | --- |
| Sync mit Erinnerungen | Wer möchte, spiegelt die Heute-Liste in die Apple Erinnerungen. Damit tauchen die Aufgaben auch auf Mac, iPad und Apple Watch auf. |
| iCloud-Sync, optional | Standardmäßig aus. Wer sie einschaltet, hält iPhone und iPad im Gleichstand, über den eigenen iCloud-Account, ohne fremden Server. |
| Kurzbefehle und Siri | Aufgaben per Sprache anlegen oder aus einer Automation heraus, direkt in den Backlog oder nach Heute. |
| Drei Widgets | Heute, Backlog und Archiv, in mehreren Größen. Abhaken geht direkt im Widget, ohne die App zu öffnen. |
| Deutsch und Englisch | Vollständig übersetzt, inklusive Widgets und Kurzbefehlen. Die App folgt der Systemsprache. |
| Reset-Zeit einstellbar | Drei Uhr nachts ist die Voreinstellung, keine Vorschrift. Wer später schlafen geht, verschiebt sie. |

### 4.6 Vertrauen, `#vertrauen`

Schmales Band, drei Aussagen nebeneinander, große Zahlen oder Wörter, wenig Text:

- **0 €** Kein Abo, keine Pro-Version, keine In-App-Käufe.
- **Kein Konto** Keine Registrierung, kein Login, keine E-Mail-Adresse.
- **Offener Quellcode** Die App ist unter der MIT-Lizenz auf GitHub einsehbar.

Darunter eine Zeile: "Die App sammelt nichts. Auf dieser Website messe ich anonym die Reichweite, ohne Cookies. Mehr dazu in der Datenschutzerklärung."

### 4.7 Schluss-CTA

Wie im Prototyp: App-Icon, große Serifenzeile "Morgen früh ist die Liste leer. Was schreibst du drauf?", offizieller Badge, darunter "Kostenlos, ohne Konto."

### 4.8 Footer

Links: Wortmarke. Mitte: Impressum, Datenschutz, Kontakt (`mailto:info@dawnyapp.com`), GitHub. Rechts: Sprachumschalter. Darunter eine Zeile "Gemacht in Deutschland." Der Blog-Link aus dem Prototyp entfällt.

## 5. FAQ-Inhalte

Das ist der Kern des Relaunchs. Alle Antworten unten sind gegen den Quellcode geprüft, die Belegstellen stehen als Kommentar dabei und gehören **nicht** in die Website.

Format: `<details>` mit `<summary>`, ein Frage-Antwort-Paar pro Eintrag, immer zugeklappt beim Laden. Antworten sind zwei bis fünf Sätze, kein Marketing, keine Ausrufezeichen.

### 5.1 Block A: Der Reset, `#faq-reset`

**Einleitungszeile:** Was nachts um drei passiert, und warum.

1. **Was passiert um drei Uhr nachts genau?**
   Dawny beendet den Tag und leert die Heute-Liste. Erledigte Aufgaben liegen danach im Archiv unter „Erledigt". Nicht erledigte wandern in der Grundeinstellung ebenfalls ins Archiv, unter „Archiviert". Wiederkehrende Aufgaben gehen zurück in den Backlog. Die App muss dafür nicht geöffnet sein.

2. **Warum drei Uhr und nicht Mitternacht?**
   Weil ein Tag nicht um zwölf endet, sondern wenn du schlafen gehst. Wer um halb eins noch etwas abhakt, will es im Heute von gestern sehen und nicht im Morgen von heute.

3. **Kann ich die Uhrzeit ändern?**
   Ja. In den Einstellungen stellst du die Reset-Zeit auf jede volle Stunde. Drei Uhr ist nur die Voreinstellung. *(Beleg: `SettingsView.resetSection`, `DatePicker` auf `settings.resetHour`.)*

4. **Was passiert mit Aufgaben, die ich nicht geschafft habe?**
   Sie werden nicht stillschweigend auf morgen geschoben. In der Grundeinstellung wandern sie ins Archiv, weil ein Platz in der Heute-Liste eine Zusage ist und keine Ablage. Mit einem Wisch nach rechts holst du sie von dort zurück, in den Backlog oder direkt nach Heute.

5. **Sind meine erledigten Aufgaben danach weg?**
   Nein. Sie liegen im Archiv unter „Erledigt", nach Datum sortiert. Du kannst dort jederzeit nachsehen, was du an einem bestimmten Tag geschafft hast.

6. **Woher weiß ich, was nachts passiert ist?**
   Beim ersten Öffnen nach einem Reset zeigt Dawny eine kurze Übersicht in zwei Schritten: erst was aus Heute abgelegt wurde, dann was aus dem Backlog aufgeräumt wurde. Danach bist du auf dem Stand und die Übersicht verschwindet. *(Beleg: `AutoArchiveReviewView`, zweiseitiges Sheet.)*

### 5.2 Block B: Wie nutze ich Dawny am besten?, `#faq-bedienung`

Der wichtigste Block. Zwei beschriftete Untergruppen, jeweils mit eigener kleiner Überschrift innerhalb desselben Abschnitts.

**Einleitungszeile:** Die Handgriffe, die man einmal gesehen haben muss, und wie man sich den Tag damit einteilt.

#### Untergruppe B1: Die Handgriffe

1. **Wie bekomme ich eine Aufgabe vom Backlog zu Heute?**
   Wisch die Zeile nach rechts. Es erscheint eine orange Sonne mit „Heute", und die Aufgabe wechselt hinüber. Wische weit genug, dann brauchst du nicht einmal zu tippen. *(Beleg: `BacklogView`, `.swipeActions(edge: .leading)` mit `sun.max.fill`, Label `backlog.swipe.today`.)*

2. **Wie hake ich eine Aufgabe ab?**
   Tippe im Heute-Tab auf den Kreis links neben der Aufgabe. Sie rutscht nach unten zu den erledigten Aufgaben. Wenn du sie dort nicht sehen willst, blendest du den Bereich in den Einstellungen aus. *(Beleg: `AppSettings.showCompletedTasksInToday`.)*

3. **Wie lege ich eine neue Aufgabe an?**
   In Heute und im Backlog steht unter der Liste immer eine leere Zeile. Tippe hinein, schreib los, mit Return legst du sie an und kannst direkt die nächste tippen. Für den Backlog wählst du vorher die Kategorie, in die sie soll.

4. **Wie hole ich etwas aus dem Archiv zurück?**
   Wisch die Zeile im Archiv nach rechts. Du bekommst zwei Ziele: „Backlog" legt sie zurück in die Ablage, „Heute" nimmt sie dir sofort für heute vor. Ein Wisch nach links löscht sie endgültig. *(Beleg: `ArchiveView`, `swipeActions` leading mit `tray.fill` und `sun.max.fill`, trailing mit `trash`.)*

5. **Wie sortiere ich eine Aufgabe in eine andere Kategorie?**
   Halte die Zeile im Backlog gedrückt, dann erscheint eine Liste aller Kategorien. Alternativ ziehst du die Aufgabe auf die Überschrift der Zielkategorie. *(Beleg: `categoryContextMenu`, `.draggable(BacklogTaskTransfer)`, `handleCategoryHeaderDrop`.)*

6. **Kann ich Notizen an eine Aufgabe hängen?**
   Ja. Tippe die Aufgabe an, um die Details zu öffnen. Kurze Notizen zeigt Dawny direkt in der Zeile unter dem Titel an.

7. **Kann ich eigene Kategorien anlegen?**
   Ja, so viele du willst, jeweils mit eigenem Namen und Symbol. Am Ende der Kategorieliste im Backlog steht dafür eine eigene Zeile.

8. **Was sind wiederkehrende Kategorien?**
   Eine Kategorie lässt sich als wiederkehrend markieren. Alles darin wird nie archiviert, sondern geht nachts zurück in den Backlog, egal ob du es erledigt hast oder nicht. Genau richtig für Sport, Gießen oder Vokabeln.

#### Untergruppe B2: Wie man sich den Tag einteilt

9. **Wie viele Aufgaben gehören in Heute?**
   So viele, wie du dir an diesem einen Tag wirklich zutraust. Bei den meisten sind das drei bis fünf. Die Liste ist bewusst kurz gehalten, damit du abends noch draufschaust, statt sie wegzuwischen.

10. **Wann plane ich am besten?**
    Morgens, in einer Minute. Du gehst den Backlog von oben nach unten durch, holst raus, was heute dran ist, und schließt die App wieder. Der Reset hat dir die Liste dafür schon leergeräumt.

11. **Was mache ich mit Aufgaben, die ich immer wieder verschiebe?**
    Wenn eine Aufgabe zum dritten Mal ins Archiv wandert, ist das die Antwort. Entweder du zerlegst sie in einen ersten kleinen Schritt, den du wirklich heute machst, oder du lässt sie im Archiv liegen. Beides ist eine Entscheidung, und beide sind besser als das ewige Weiterschieben.

12. **Ich habe eine große Sache vor, die Wochen dauert. Wie bilde ich die ab?**
    Gar nicht als eine Aufgabe. Dawny hat bewusst keine Projekte und keine Unteraufgaben. Leg die große Sache als Kategorie an und schreib die nächsten konkreten Schritte hinein. Jeden Morgen holst du einen davon nach Heute.

### 5.3 Block C: Das Konzept dahinter, `#faq-konzept`

**Einleitungszeile:** Die Fragen, die kommen, wenn Dawny sich anders verhält als erwartet.

1. **Warum kann ich im Backlog nichts abhaken?**
   Weil Erledigen im Heute passiert. Der Backlog ist eine Sammlung von allem, was irgendwann ansteht, nicht die Liste, an der du gerade arbeitest. Der Kreis ist deshalb sichtbar, aber ausgegraut. Hol die Aufgabe mit einem Wisch nach Heute, dann kannst du sie abhaken. *(Beleg: `TaskRowView(showsDisabledToggle: true)` im Backlog.)*

2. **Warum werden nicht erledigte Aufgaben überhaupt archiviert?**
   Weil eine Liste, die nur wächst, irgendwann nicht mehr gelesen wird. Wenn Liegengebliebenes automatisch stehen bleibt, kostet dich jeder Blick auf die Liste Energie für Dinge, die du längst abgeschrieben hast. Dawny räumt sie weg und überlässt dir die Entscheidung, ob du sie zurückholst.

3. **Mich stört, dass Aufgaben schon beim ersten Mal archiviert werden. Was kann ich tun?**
   Das lässt sich einstellen. In den Einstellungen steht unter „Make it count" eine Zahl von 1 bis 7. Sie sagt, wie oft eine Aufgabe in Heute liegenbleiben darf, bevor sie ins Archiv geht. Bei 3 wandert sie zweimal zurück in den Backlog und erst beim dritten Mal ins Archiv. *(Beleg: `AppSettings.makeItCountThreshold`, Bereich `1...7`, Standard 1, Logik in `ResetOutcomePlanner`.)*

4. **Warum kann ich einer Aufgabe keine Priorität geben?**
   Weil Prioritäten eine Lüge sind, die man sich selbst erzählt. Nach zwei Wochen ist alles „hoch". Dawny stellt stattdessen die einfachere Frage: wann ungefähr? Daraus werden die Zeithorizonte im Backlog. Die eigentliche Priorisierung passiert jeden Morgen, wenn du entscheidest, was nach Heute wandert.

5. **Warum gibt es keine Fälligkeitsdaten und keine Erinnerungen?**
   Weil ein Datum in der Zukunft eine Entscheidung vertagt, statt sie zu treffen. In Dawny gibt es genau zwei Zeitpunkte: heute und irgendwann. Wenn du eine Aufgabe an einem festen Termin brauchst, gehört sie in den Kalender oder in die Erinnerungen-App, und dorthin kann Dawny sie auch spiegeln.

6. **Warum keine Projekte, Tags oder Unteraufgaben?**
   Weil jede zusätzliche Struktur eine zusätzliche Entscheidung ist, die du triffst, bevor du irgendetwas erledigt hast. Dawny hat eine Ebene: Aufgabe, in einer Kategorie. Wer mehr Struktur braucht, legt mehr Kategorien an.

7. **Ist eine archivierte Aufgabe verloren?**
   Nein. Archiviert heißt einsortiert, nicht gelöscht. Das Archiv ist durchsuchbar und nach Datum sortiert, und ein Wisch holt jede Aufgabe zurück. Gelöscht wird nur, was du selbst löschst.

8. **Warum ist eine Aufgabe aus dem Backlog verschwunden, obwohl sie nie in Heute war?**
   Auch der Backlog räumt sich auf. Jede Kategorie hat eine Lebensdauer: „Schnell erledigt" sieben Tage, „Die nächsten Tage" 21, „Die nächsten Wochen" 60, „Die nächsten Monate" ein Jahr. Was länger unangetastet liegt, wandert ins Archiv. „Irgendwann" hat keine Frist, dort bleibt alles liegen, und wiederkehrende Kategorien sind ausgenommen. Bei eigenen Kategorien stellst du die Frist selbst ein. *(Beleg: `TaskCategory.defaultAutoArchiveDays`, Auto-Tidy in `ResetOutcomePlanner`.)*

### 5.4 Block D: Geräte, Sync und Widgets, `#faq-technik`

**Einleitungszeile:** Was auf anderen Geräten ankommt, und was nicht.

1. **Was können die Widgets?**
   Es gibt drei, in mehreren Größen: Heute, Backlog und Archiv. Aufgaben lassen sich direkt im Widget abhaken, die App muss dafür nicht starten. Ein Tippen auf eine Zeile springt an die passende Stelle in der App. Der nächtliche Reset gilt für die Widgets genauso.

2. **Läuft Dawny auf dem iPad oder dem Mac?**
   Dawny ist eine iPhone-App. Wer die Aufgaben auf anderen Apple-Geräten sehen will, aktiviert die Synchronisation mit der Erinnerungen-App, dann tauchen sie dort auf Mac, iPad und Apple Watch auf.

3. **Wie funktioniert die Synchronisation mit der Erinnerungen-App?**
   In den Einstellungen schaltest du sie ein und verknüpfst eine Liste. Dawny schreibt deine Heute-Aufgaben dorthin und liest Änderungen von dort zurück. Beim ersten Mal fragt iOS nach der Berechtigung.

4. **Kann ich meine bestehenden Erinnerungen nach Dawny importieren?**
   Nein, und das ist Absicht. Der Sinn von Dawny ist, dass du jeden Morgen neu entscheidest, was heute zählt. Eine Liste mit 200 importierten Altlasten wäre das Gegenteil davon.

5. **Was macht der iCloud-Sync?**
   Er hält zwei Geräte mit derselben Apple-ID auf demselben Stand, über deinen eigenen iCloud-Account. Es gibt keinen Server bei mir. Der Sync ist standardmäßig aus und wird erst nach einem Neustart der App wirksam. *(Beleg: `AppSettings.iCloudSyncEnabled`, Kommentar zum `ModelContainer` in `DawnyApp.init()`.)*

6. **Was kann Siri?**
   Du kannst Aufgaben per Sprache anlegen, entweder in den Backlog oder direkt nach Heute, und die Kategorie mitsprechen. Dawny meldet sich dafür mit App Intents beim System an, die Kurzbefehle-App findet die Aktionen automatisch.

7. **Was passiert, wenn ich das iPhone tagelang nicht anfasse?**
   Nichts geht verloren. Der Reset holt beim nächsten Start nach, was in der Zwischenzeit fällig war, und die Übersicht zeigt dir, was abgelegt wurde.

### 5.5 Block E: Daten, Kosten, Support, `#faq-daten`

**Einleitungszeile:** Wem was gehört und was das kostet.

1. **Kostet Dawny etwas?**
   Nein. Die App ist vollständig kostenlos. Es gibt kein Abo, keine Pro-Version, keine In-App-Käufe und keine Werbung. Es gibt auch keine Funktion, die hinter einer Bezahlschranke liegt.

2. **Wo ist der Haken?**
   Es gibt keinen. Dawny ist als Werkzeug entstanden, das ich selbst benutze. Der Quellcode liegt offen auf GitHub, du kannst nachsehen, was die App tut.

3. **Brauche ich ein Konto?**
   Nein. Du lädst die App und legst los. Es gibt keine Registrierung, keinen Login und ich kenne deine E-Mail-Adresse nicht.

4. **Wo liegen meine Aufgaben?**
   Auf deinem iPhone. Wenn du den iCloud-Sync einschaltest, zusätzlich in deinem eigenen iCloud-Account, den Apple verwaltet. Ich habe in keinem Fall Zugriff darauf, weil es keinen Server von mir gibt.

5. **Sammelt die App Daten über mich?**
   Nein. Die App enthält keine Analytics-SDKs, kein Crash-Reporting an mich, keine Werbe-IDs und keine Tracker. Auf dieser Website messe ich anonym die Reichweite, ohne Cookies und ohne dich wiederzuerkennen. Die Einzelheiten stehen in der Datenschutzerklärung.

6. **Wie werde ich alle meine Daten wieder los?**
   App löschen. Damit sind alle lokalen Daten weg. Was du in die Erinnerungen-App gespiegelt hast, bleibt dort und musst du bei Bedarf dort löschen.

7. **Ich habe einen Fehler gefunden oder einen Wunsch. Wohin damit?**
   Schreib mir an `info@dawnyapp.com`. In der App findest du unter Einstellungen ebenfalls einen direkten Weg dorthin. Fehlerberichte und Wünsche landen beide bei mir persönlich, es gibt kein Ticketsystem dazwischen.

### 5.6 Strukturierte Daten

Alle 40 Fragen gehen in **ein** `FAQPage`-JSON-LD-Objekt pro Sprachseite. Nicht ein Objekt pro Block, denn eine Seite darf nur eine `FAQPage` tragen. Das JSON-LD wird aus derselben Datenquelle erzeugt wie das sichtbare Markup, damit beides nie auseinanderläuft. Der Antworttext im JSON-LD ist reiner Text ohne Auszeichnung.

Zusätzlich bleibt das `SoftwareApplication`-Objekt aus dem bestehenden `SchemaOrg.astro` erhalten, mit `offers.price = "0"`. Beide Objekte kommen in einen `@graph`.

### 5.7 Englische Fassung

Gleiche Struktur, gleiche Keys, gleiche Reihenfolge. Keine wörtliche Übersetzung, sondern derselbe Ton auf Englisch. Zwei Fallen:

- Die Begriffe der Oberfläche müssen zu den englischen Strings der App passen: Today, Backlog, Archive, Quick, Next couple of days, Next couple of weeks, Next couple of months, Someday, Uncategorized, Make it count. Nachschlagen in `App/Sources/Localizable.xcstrings`, nicht raten.
- Bei den Wisch-Gesten stimmt die Richtung sprachübergreifend, weil die App keine RTL-Sprache unterstützt. Trotzdem "swipe right" schreiben, nicht "swipe from the left edge".

---

## 6. Visuelles Konzept

### 6.1 Farbpalette

Übernommen aus dem Prototyp, weil sie besser ist als die alte Astro-Palette. Sie kommt als Tailwind-Theme-Tokens in `src/styles/global.css` und ersetzt den dortigen `@theme`-Block.

```css
@theme {
  /* Tag */
  --color-paper:      #FAF8F5;
  --color-paper-warm: #FDF5EA;
  --color-paper-2:    #F3EDE3;
  --color-ink:        #17140F;
  --color-ink-2:      #4B443A;
  --color-muted:      #7C7468;
  --color-rule:       #E3DBCE;
  --color-accent:     #C0521A;
  --color-accent-soft:#F6E3D2;
  --color-card:       #FFFFFF;
  --color-success:    #34A853;

  /* Nacht, für den Reset-Abschnitt */
  --color-night:      #14151A;
  --color-night-2:    #1B1D24;
  --color-night-ink:  #F3EEE5;
  --color-night-muted:#9B958A;
  --color-night-rule: #2C2F38;
}
```

Dark Mode über `@media (prefers-color-scheme: dark)`, Werte wie im Prototyp (`styles.css` Zeilen 42 bis 59). Kein Umschalter, siehe 2.3.

Kontrastprüfung, verbindlich vor dem Livegang: `--color-muted` auf `--color-paper` liegt bei etwa 4,6:1 und ist damit knapp über der Grenze. Es darf deshalb **nur für Fließtext ab 16 px** verwendet werden, nicht für kleinere Labels. Für alles unter 16 px wird `--color-ink-2` genommen.

### 6.2 Typografie

- **Serif für Überschriften:** Instrument Serif 400, für `h1` und `h2`. Gibt der Seite den Charakter, den der Prototyp gefunden hat.
- **Sans für alles andere:** Inter Variable, self-hosted.
- Der Prototyp benutzt für Fließtext die System-Font-Stack. Beim Portieren auf Inter wechseln, damit die Seite auf Android und Windows nicht auseinanderfällt.
- Basisgröße 17 px, Zeilenhöhe 1.65, Textspalten maximal 62 Zeichen.
- Überschriftengrößen fluid über `clamp()`, `h1` von 2.5rem bis 4.5rem, `h2` von 1.75rem bis 2.75rem.
- Keine Versalien-Überschriften, keine Buchstabensperrung außer beim Kicker (dort `0.08em`).

### 6.3 Layout und Raster

- Inhaltsbreite 1140 px, Innenabstand `clamp(1.25rem, 4vw, 2.5rem)`.
- Vertikaler Sektionsabstand `clamp(4rem, 8.5vw, 7.5rem)`.
- Trennung zwischen Abschnitten über Flächenwechsel (Papier, warmes Papier, Nacht), nicht über Linien. Haarlinien nur innerhalb von Listen und Akkordeons.
- Keine Kartenschatten. Der Prototyp verzichtet bewusst darauf, das bleibt so. Tiefe entsteht über Flächen und Haarlinien.
- Bilder ohne Rahmen, mit `border-radius: 1.5rem` und einem 1 px `--color-rule`-Rand.

### 6.4 FAQ-Gestaltung

Das ist der Teil, der über die Qualität der Seite entscheidet, weil 40 Akkordeons schnell nach Support-Datenbank aussehen.

- Jeder FAQ-Block bekommt eine eigene Flächenfarbe im Wechsel, damit man beim Scrollen merkt, dass ein neues Thema beginnt.
- Blocküberschrift als Serif-`h2`, darunter die Einleitungszeile in `--color-muted`, maximal ein Satz.
- Die Fragen liegen in **einer Spalte** in Lesebreite, die Liste zentriert, maximal 68 Zeichen breit. Zwei Spalten standen in einer früheren Fassung und sind gestrichen: aufklappbare `<details>` springen dabei beim Öffnen, und mit CSS-`columns` reißt ein geöffnetes Akkordeon über die Spaltengrenze. Gegen die Wandwirkung hilft stattdessen der Blockschnitt, höchstens zwölf Fragen pro Block, plus die Untergruppen in Block B.
- Jede Frage ist ein `<details>` mit Haarlinie darüber. `<summary>` trägt die Frage in 1.0625rem, halbfett, mit einem Plus-Symbol rechts, das per CSS zu einem Minus rotiert. `list-style: none` und `::-webkit-details-marker { display: none }` nicht vergessen.
- Beim Aufklappen **kein** Höhenübergang. Das Akkordeon öffnet und schließt direkt, so wie `<details>` es von sich aus tut. Der weiche Übergang über `interpolate-size: allow-keywords` stand in einer früheren Fassung und ist gestrichen, weil er nur in Chromium greift und damit zwei Verhaltensweisen zu pflegen wären. Das Plus-zu-Minus-Symbol darf animieren, das ist eine reine `transform`-Angabe.
- Untergruppen in Block B bekommen eine kleine Überschrift in Versalien-Kicker-Stil über der jeweiligen Fragengruppe, mit deutlich mehr Abstand darüber als zwischen den Fragen.
- Am Ende jedes Blocks eine Zeile "Weiter zu: [nächster Block]" als Textlink mit Pfeil.

### 6.5 Bewegung

- Alles respektiert `prefers-reduced-motion: reduce`. Bei reduzierter Bewegung: keine Einblendungen beim Scrollen, keine Demo-Animation.
- Einblendungen beim Scrollen nur für Split-Blöcke, 300 ms, 12 px Versatz, `cubic-bezier(0.22, 1, 0.36, 1)`. Nichts darf länger als 400 ms dauern. Umsetzung: **ein** `IntersectionObserver` im Seitenfuß, der allen Elementen mit `data-reveal` eine Klasse setzt und sich danach abmeldet. Keine Konfiguration pro Element, keine Bibliothek.
- Der Hero animiert **nicht**. Er ist sofort da, wegen LCP.
- Die geführte Demo ist die einzige längere Animation der Seite und hat deshalb eine Pause-Steuerung.

### 6.6 Bildmaterial

Vorhanden in `website/prototype/img/`: `hero-heute.png`, `heute.png`, `backlog.png`, `archiv.png`, `widgets.png` plus Icons. Diese werden nach `src/assets/screenshots/` übernommen und über Astros `<Image>`-Komponente eingebunden, damit AVIF und WebP samt `srcset` erzeugt werden.

**Offener Punkt:** die Screenshots stammen vom 18. August 2026, die App steht bei 1.3.0 in Entwicklung. Vor dem Livegang prüfen, ob die Oberfläche noch stimmt, insbesondere im Backlog (Kategorien) und im Archiv. Neu erzeugen über das vorhandene `Screenshots.xctestplan` und `ScreenshotSeeder.swift`. Nur Testaufgaben, keine echten Daten.

### 6.7 OG-Bild, Neuentwurf

Das bestehende `scripts/generate-og.mjs` rendert eine Karte in der alten blau-goldenen Palette und passt farblich nicht mehr zur Seite. Es wird neu gestaltet, bleibt aber technisch beim bisherigen Weg: Inline-SVG, per `sharp` nach PNG, 1200 × 630, im `prebuild` erzeugt, kein Handbetrieb.

Gestaltungsvorgabe:

- Fläche: `--color-paper-warm` (`#FDF5EA`), vollflächig, kein Verlauf.
- Unten am Bildrand ein flacher Bogen in `--color-accent` (`#C0521A`), der wie ein Sonnenaufgang aus dem unteren Rand ragt, Höhe etwa ein Sechstel der Bildhöhe. Das ist dasselbe Motiv wie das App-Icon und der Tagesbogen der Seite.
- Links oben das App-Icon, 96 px, mit dem 1 px `--color-rule`-Rand wie alle Bilder der Seite.
- Darunter, linksbündig, in Instrument Serif, `--color-ink`, etwa 76 px: **Jeden Morgen eine leere Liste.** (englische Variante: **A clean list every morning.**)
- Darunter, in Inter, `--color-ink-2`, etwa 30 px: **Dawny, To-do-App fürs iPhone** beziehungsweise **Dawny, the to-do app for iPhone**.
- Kein App-Store-Badge im OG-Bild. Apples Richtlinien für die Badge-Verwendung sind auf Vorschaubilder nicht zugeschnitten und der Nutzen ist null.
- Rechter Bildrand bleibt frei. Verschiedene Plattformen beschneiden unterschiedlich, alles Wichtige muss in den mittleren 1000 px liegen.

**Zwei Bilder, nicht eins.** Das Skript erzeugt `og-image-de.png` und `og-image-en.png`, jede Sprachseite verweist auf ihres. Bisher gibt es nur ein englisches, das auch auf der deutschen Seite hängt.

Die Schriften bezieht das Skript aus `node_modules/@fontsource*`, nicht aus dem Netz, sonst bricht der CI-Build ohne Netzzugriff.

**Vorgehen:** erst rendern, dann ansehen, dann entscheiden. Florian will die Variante sehen, bevor sie festgezurrt wird. Der Agent legt beide PNGs an und zeigt sie, bevor er weiterbaut.

---

## 7. Technische Umsetzung

### 7.1 Grundsatz

Astro bleibt. Der Prototyp wird portiert, nicht kopiert. Konkret heißt das: die Struktur und das CSS des Prototyps sind die Vorlage, aber sie werden in Astro-Komponenten und Tailwind-Theme-Tokens überführt, damit i18n, Bildoptimierung, Sitemap und der bestehende Deploy weiter funktionieren.

**Leitregel für den umsetzenden Agenten: so wenig eigene Mechanik wie möglich.** Sie gilt im Zweifel vor jedem gestalterischen Wunsch in diesem Dokument.

- Kein UI-Framework, keine Komponentenbibliothek, kein Alpine, keine Animationsbibliothek. Astro, Tailwind, natives HTML.
- Aufklappbares immer als `<details>` und `<summary>`, nie nachgebaut.
- Eine Komponente entsteht nur für etwas, das **mehr als einmal** auf der Seite vorkommt. Alles andere ist normales Markup in `src/pages/[lang]/index.astro`, damit die Seite als Ganzes lesbar bleibt.
- Eigenes JavaScript nur an drei Stellen: die geführte Demo, der Deep-Link-Öffner für die FAQ, ein `IntersectionObserver` für die Einblendungen. Sonst nirgends.
- Kein `localStorage`, kein `sessionStorage`, keine Cookies, siehe 2.3.

Die geführte Demo ist die bewusste Ausnahme von dieser Regel. Sie ist das Element, das den Reset begreifbar macht, und wird deshalb vollständig portiert, obwohl sie der komplizierteste Teil der Seite bleibt. Sie ist gekapselt: ein Abschnitt, eine Skriptdatei, keine Abhängigkeit zum Rest der Seite. Wer sie später nicht mehr pflegen will, kann Abschnitt und Skript ersatzlos entfernen, ohne dass etwas anderes bricht.

### 7.2 Dateien, die gelöscht werden

```
website/src/content/blog/              (kompletter Ordner, 20 Markdown-Dateien)
website/src/content/config.ts          (nur die Blog-Collection; falls keine andere Collection dazukommt, ganze Datei)
website/src/pages/de/blog/             (Ordner)
website/src/pages/en/blog/             (Ordner)
website/src/pages/de/rss.xml.ts
website/src/pages/en/rss.xml.ts
website/src/layouts/BlogLayout.astro
website/src/layouts/BlogPost.astro
website/src/lib/blog.ts
website/src/lib/rss.ts
website/src/components/ManifestStatement.astro
website/src/components/ResetAnimation.astro
website/src/components/TwoLists.astro
website/src/components/ContrastBlock.astro
website/src/components/AudienceBlock.astro
website/src/components/RemindersBlock.astro
website/src/components/HeroSunrise.astro
website/src/components/SunriseStage.astro
website/src/components/MakeItCount.astro
website/src/components/FaqBlock.astro
website/offline/                       (erst nach erfolgreichem Relaunch, siehe 8)
```

In `astro.config.mjs` fällt die Funktion `blogLastmod()` samt `BLOG_LASTMOD` und der `serialize`-Hook weg, weil es keine Blog-Daten mehr gibt.

`src/pages/llms.txt.ts` und `llms-full.txt.ts` bleiben, müssen aber angepasst werden: sie ziehen heute Blog-Inhalte. Neue Fassung listet die beiden Sprachstartseiten und die Rechtsseiten und gibt den FAQ-Inhalt als Volltext aus, das ist für LLM-Auffindbarkeit sogar wertvoller als die alten Blogposts.

### 7.3 Dateien, die neu entstehen

```
website/src/data/faq.de.ts             FAQ-Daten, typisiert
website/src/data/faq.en.ts
website/src/data/faq.ts                Typen und Helfer (Blockdefinition, Reihenfolge)
website/src/components/SiteHeader.astro      kommt auf drei Seitentypen vor
website/src/components/ResetStage.astro      Portierung der geführten Demo
website/src/components/SplitBlock.astro      viermal: Backlog, Heute, Archiv, Widgets
website/src/components/FaqSection.astro      fünfmal: rendert genau einen Block
website/src/components/AppStoreBadge.astro   zweimal: Hero und Schluss-CTA, sprach- und themeabhängig
website/src/scripts/reset-stage.ts           aus prototype/demo.js
website/src/scripts/page.ts                  Deep-Link-Öffner und Einblendungen, wenige Zeilen
```

**Bewusst keine eigenen Komponenten:** Hero, Haltungsabschnitt, Faktenraster, Vertrauensband und Schluss-CTA. Sie kommen je genau einmal vor. Eine Komponente dafür wäre kein Baustein, sondern nur ein Ort, an dem Markup versteckt liegt. Sie stehen als normales Markup in `src/pages/[lang]/index.astro`. Die Seite ist damit in einer Datei überschaubar, und wer eine Überschrift ändern will, sucht nicht erst die passende Komponente. `Footer.astro` und `SchemaOrg.astro` existieren bereits und werden weiterverwendet.

Eine Fortschrittsleiste (`SectionRail.astro`) stand in einer früheren Fassung und ist gestrichen, siehe 3.2.

### 7.4 FAQ-Datenmodell

```ts
// src/data/faq.ts
export type FaqItem = { id: string; q: string; a: string };
export type FaqGroup = { label?: string; items: FaqItem[] };
export type FaqBlock = {
  id: "reset" | "bedienung" | "konzept" | "technik" | "daten";
  anchor: string;      // z.B. "faq-reset"
  title: string;
  intro: string;
  groups: FaqGroup[];
  next?: { anchor: string; label: string };
  surface: "paper" | "paper-warm" | "paper-2";
};
```

`FaqSection.astro` bekommt genau einen `FaqBlock` und rendert ihn. Die `id` jedes Items ist stabil und sprachübergreifend gleich (`reset-uhrzeit`, `bedienung-backlog-nach-heute`, ...), damit Deep-Links wie `/de/#reset-uhrzeit` funktionieren und in beiden Sprachen dasselbe treffen. Jedes `<details>` trägt diese `id`.

Zusatz, klein aber nützlich: ein Skript im Seitenfuß öffnet beim Laden das `<details>`, dessen `id` im Hash steht, und scrollt dorthin. Zustandslos, kein `localStorage`.

Das JSON-LD wird in `SchemaOrg.astro` aus allen Blöcken zusammengesetzt, siehe 5.6.

### 7.5 i18n

Die FAQ-Texte gehen **nicht** in `de.json`/`en.json`, sondern in die eigenen `faq.de.ts`/`faq.en.ts`. Grund: 40 Fragen mit mehrsätzigen Antworten machen die JSON-Wörterbücher unlesbar und die Blockstruktur lässt sich in JSON nicht sauber typisieren. Alle übrigen Texte bleiben im bestehenden JSON-Schema.

Ein Testfall, der in CI läuft oder zumindest als Skript existiert: `faq.de.ts` und `faq.en.ts` müssen dieselben Block-`id`s, dieselbe Reihenfolge und dieselben Item-`id`s haben. Ein fehlender Eintrag in einer Sprache muss den Build brechen.

### 7.6 Bilder

Alle Screenshots über `astro:assets` einbinden:

```astro
import { Image } from "astro:assets";
import backlog from "@/assets/screenshots/backlog.png";
<Image src={backlog} alt="…" widths={[420, 660, 880]} sizes="(min-width: 900px) 40vw, 90vw" loading="lazy" />
```

Das Hero-Bild bekommt `loading="eager"` und `fetchpriority="high"`, alle anderen `loading="lazy"`. Jedes `<img>` trägt `width` und `height` beziehungsweise wird von `<Image>` damit versehen, damit kein Layoutsprung entsteht.

### 7.7 Metadaten pro Sprachseite

- `<title>`: "Dawny: To-do-App fürs iPhone mit täglichem Reset" beziehungsweise "Dawny: the iPhone to-do app that resets every night". Unter 60 Zeichen halten.
- `<meta name="description">`: 150 bis 160 Zeichen, Text aus dem Prototyp übernehmen, aber `dawny.app` durch `dawnyapp.com` ersetzen.
- `canonical` auf die eigene Sprachseite, `hreflang` für `de`, `en` und `x-default` auf `/en/`.
- Open Graph und Twitter Card wie im bestehenden `Base.astro`, aber je Sprache das eigene OG-Bild (`og-image-de.png`, `og-image-en.png`), Gestaltung siehe 6.7.
- `apple-itunes-app` mit `app-id=6762262959` bleibt.
- **Achtung:** der Prototyp enthält an mehreren Stellen `https://dawny.app/` und `app-id=0000000000`. Beides ist beim Portieren zu ersetzen, sonst zeigen Canonical, hreflang und Smart App Banner ins Leere.

### 7.8 Redirects, `public/.htaccess`

Die bestehende Datei wird die Basis, sie ist gut. Ergänzungen für den Blog-Abbau, direkt nach dem HTTPS-Block einzusetzen:

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On

  # Blog abgeschaltet: alles auf die passende Sprachstartseite.
  RewriteRule ^de/blog(/.*)?$  /de/  [L,R=301]
  RewriteRule ^en/blog(/.*)?$  /en/  [L,R=301]
  RewriteRule ^de/rss\.xml$    /de/  [L,R=301]
  RewriteRule ^en/rss\.xml$    /en/  [L,R=301]
  RewriteRule ^blog(/.*)?$     /en/  [L,R=301]
</IfModule>
```

Die bestehenden Regeln `^rss\.xml$ → /en/rss.xml` und `^feed/?$ → /en/rss.xml` müssen **geändert** werden, sonst leiten sie auf eine 301-Kette. Neu jeweils direkt auf `/en/`.

Zusätzlich zu entfernen: nichts. `ErrorDocument 404 /en/` bleibt, ebenso der Sprach-Redirect am Root und die Cache-Regeln.

Ergänzt wird genau eine Zeile, im bestehenden `mod_headers`-Block:

```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
```

**Keine Content-Security-Policy.** Sie stand in einer früheren Fassung dieses Konzepts und wurde bewusst gestrichen. Begründung: eine CSP ist reine Härtung, sie erfüllt keine Rechtspflicht und schützt hier vor Angriffen, die es auf einer Seite ohne Login, ohne Nutzereingaben und ohne fremde Inhalte praktisch nicht gibt. Dem stünde ein realer Nachteil gegenüber: der PostHog-Snippet liegt inline, Astro setzt die Stylesheets inline (`inlineStylesheets: "always"`), und PostHog lädt je nach Konfiguration von wechselnden Hosts. Eine zu eng gesetzte CSP blockiert das Analytics still, ohne Fehlermeldung im Seitenbild. Der Aufwand, das sauber zu verifizieren und dauerhaft nachzuziehen, steht in keinem Verhältnis.

Die bereits vorhandenen Header bleiben unverändert: `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, `X-Frame-Options`. Die kosten nichts und können nichts kaputtmachen.

### 7.9 Deploy

`.github/workflows/deploy-website.yml` wird auf den Vor-Offline-Stand zurückgesetzt. Am einfachsten über `git show e6755a3^:.github/workflows/deploy-website.yml`, das ist die Fassung mit `npm ci`, `npm run build` und `mirror --reverse --delete --verbose dist/`. Bitte nicht den ganzen Commit reverten, weil `website/offline/` als Notausgang erhalten bleiben soll, siehe 8.4.

Die zurückgesetzte Fassung reicht `PUBLIC_POSTHOG_PROJECT_TOKEN` und `PUBLIC_POSTHOG_HOST` bereits als Env an `npm run build` durch, dort ist nichts zu ergänzen. **Zu prüfen ist nur, ob die beiden Secrets im Repository noch existieren.** Fehlen sie, rendert `PostHog.astro` still gar nichts und die Messung fehlt, ohne dass der Build fehlschlägt.

### 7.10 Performance-Budget

Verbindlich, wird vor dem Livegang gemessen:

- Lighthouse Mobile: Performance 95+, Accessibility 100, Best Practices 100, SEO 100.
- LCP unter 2,0 s im Lighthouse-Mobile-Lauf. LCP-Element ist das Hero-Bild.
- CLS unter 0,05. Jedes Bild mit Dimensionen, keine nachgeladenen Fonts ohne `font-display: swap`.
- Gesamtes JavaScript unter 20 KB gzip ohne PostHog. Die Demo ist der größte Brocken, `demo.js` liegt bei 13,6 KB unkomprimiert.
- Keine Web-Font-Datei über 40 KB, `unicode-range`-Subsets nutzen, was `@fontsource` von sich aus tut.

Bekannte Falle aus früheren Messungen: Scroll-Handler, die pro Ereignis `offsetHeight` oder `getBoundingClientRect` lesen, lösen zusammen mit der Scroll-Tiefe-Messung von PostHog erzwungene Layout-Berechnungen aus. Deshalb hängt in diesem Konzept nichts mehr am Scroll-Ereignis: die Einblendungen laufen über einen `IntersectionObserver`, die Fortschrittsleiste ist gestrichen. Falls doch einmal ein Scroll-Handler nötig wird, Werte einmal pro Frame cachen.

---

## 8. Reihenfolge der Umsetzung

Jeder Schritt ist ein eigener Commit auf einem Feature-Branch, nicht auf `main`. `main` ist geschützt, direkter Push scheitert.

**Schritt 1, Aufräumen.** Blog löschen, tote Komponenten löschen, `astro.config.mjs` entschlacken, `llms.txt` anpassen. Akzeptanz: `npm run build` läuft durch, `dist/` enthält keine Blog-Pfade mehr.

**Schritt 2, Design-Grundlage.** Prototyp-Palette und Typografie nach `global.css`, Instrument Serif und Inter über `@fontsource`. Akzeptanz: eine leere Testseite zeigt die neuen Tokens in hell und dunkel.

**Schritt 3, Rechtsseiten.** Impressum und Datenschutz in beiden Sprachen nach Abschnitt 2 überarbeiten. Zuerst, nicht zuletzt, damit sie nicht am Ende unter Zeitdruck entstehen. Alle Angaben stehen fest, es bleibt nichts offen: Anschrift, Kontaktadresse, Antwortzeit, Markenformulierung, Wegfall von ODR und USt-IdNr., AVV-Sätze ohne Vorbehalt. Es braucht deshalb weder Platzhalter noch ein Prüfskript, beides ist aus diesem Konzept gestrichen. Akzeptanz: beide Rechtsseiten sind in beiden Sprachen vollständig und enthalten keinen Verweis mehr auf ODR, Postfach oder eine Marke.

**Schritt 4, Seitengerüst.** Header, Footer, Hero, Schluss-CTA, Sprachumschalter, Badge-Komponente. Akzeptanz: `/de/` und `/en/` rendern Hero und Footer korrekt, Badge ist der offizielle.

**Schritt 5, Inhaltsabschnitte.** Split-Blöcke, Haltung, Faktenraster, Vertrauensband. Akzeptanz: alle Texte aus Abschnitt 4 sind in beiden Sprachen vorhanden.

**Schritt 6, FAQ.** Datenmodell, `FaqSection.astro`, alle fünf Blöcke, JSON-LD, Deep-Link-Öffner, Paritätstest DE/EN. Akzeptanz: 40 Fragen in beiden Sprachen, Rich-Results-Test von Google zeigt eine gültige `FAQPage`.

**Schritt 7, Reset-Demo.** Portierung von `demo.js`, Pause-Steuerung, Reduced-Motion-Pfad. Akzeptanz: Demo läuft, lässt sich anhalten, funktioniert ohne JavaScript als statischer Endzustand.

**Schritt 8, OG-Bild.** `generate-og.mjs` nach 6.7 neu bauen, beide Sprachvarianten rendern, **Florian vorlegen**, erst danach festzurren. Akzeptanz: beide PNGs liegen vor, `Base.astro` verweist je Sprache auf die richtige, Vorschau in einem OG-Debugger stimmt.

**Schritt 9, Feinschliff.** Scroll-Einblendungen, Fokusringe, Zoom-Test bei 200 Prozent, Kontrastmessung.

**Schritt 10, Infrastruktur.** `.htaccess` mit Redirects und HSTS, Deploy-Workflow zurückstellen, PostHog-Secrets prüfen.

**Schritt 11, Livegang.** Siehe 8.4.

### 8.1 Prüfliste vor dem Livegang

- [ ] Impressum enthält Kreuzstraße 26, 76133 Karlsruhe, die Antwortzeit-Zusage, keinen ODR-Link, keine USt-IdNr.-Zeile, kein ®, den Apple-Markenhinweis
- [ ] Datenschutzerklärung nennt IONOS-AVV und PostHog-DPA (siehe 2.11, beide bestehen von Haus aus) und hat den Abschnitt Kontaktaufnahme
- [ ] `info@dawnyapp.com` steht im Impressum, in der Datenschutzerklärung und als `mailto:` im Footer, und das Postfach wird tatsächlich gelesen
- [ ] Beide OG-Bilder vorhanden, jede Sprachseite verweist auf ihres
- [ ] `grep -r "dawny.app" dist/` liefert nichts (nur `dawnyapp.com`)
- [ ] `grep -r "0000000000" dist/` liefert nichts
- [ ] Keine externen Requests außer PostHog, geprüft im Netzwerk-Tab bei geleertem Cache
- [ ] HSTS-Header gesetzt, keine CSP (bewusst, siehe 7.8)
- [ ] Kein Cookie, kein `localStorage`-Eintrag nach einem vollständigen Seitendurchlauf inklusive FAQ-Aufklappen
- [ ] Offizieller App-Store-Badge, verlinkt auf `https://apps.apple.com/app/id6762262959`, Link funktioniert
- [ ] Alle 40 FAQ-Antworten gegen den Stand der App 1.3.0 geprüft
- [ ] Screenshots zeigen die aktuelle Oberfläche und nur Testdaten
- [ ] Lighthouse-Werte nach 7.10 erreicht
- [ ] Tastaturdurchlauf über die ganze Seite ohne Fokusfalle
- [ ] Stichprobe: ein FAQ-Block mit VoiceOver, einmal Zoom auf 200 Prozent (kein formaler WCAG-Durchlauf, siehe 2.6)
- [ ] Alle Redirects aus 7.8 geprüft, jeweils genau eine 301 ohne Kette
- [ ] `sitemap-index.xml` enthält nur die sechs echten URLs
- [ ] `robots.txt` ist wieder erreichbar und erlaubt das Crawling (die Datei in `public/` ist unverändert korrekt, sie war nur vom Webspace gelöscht)

### 8.2 Nach dem Livegang

- Google Search Console: neue Sitemap einreichen, die alten Blog-URLs in der Abdeckung beobachten, bis sie als "Weitergeleitet" geführt werden.
- `X-Robots-Tag: noindex` ist mit dem Wegfall von `offline/.htaccess` automatisch weg. Trotzdem prüfen: `curl -sI https://dawnyapp.com/de/ | grep -i robots` darf nichts liefern.
- `Cache-Control: no-store` aus der Offline-Phase ist ebenfalls weg. Prüfen, dass HTML mit `max-age=0, must-revalidate` und Assets mit `immutable` ausgeliefert werden.

### 8.3 Was ausdrücklich nicht gebaut wird

- Kein Blog, keine RSS-Feeds, keine Content-Collection.
- Kein Kontaktformular und keine Serverlogik jeder Art. Die Seite bleibt ein Ordner mit statischen Dateien (siehe 2.10).
- Kein Newsletter, kein Chat-Widget, kein Captcha.
- Kein Cookie-Banner.
- Kein Theme-Umschalter.
- Keine Content-Security-Policy (siehe 7.8).
- Kein Presskit, keine Downloadseite, keine Roadmap-Seite.
- Keine Vergleichstabelle gegen andere Apps.
- Kein UI-Framework, keine Komponentenbibliothek, keine Animationsbibliothek (siehe 7.1).
- Keine Fortschrittsleiste am Seitenrand (siehe 3.2).
- Keine zweispaltige FAQ und kein Höhenübergang beim Aufklappen (siehe 6.4).
- Keine Komponente für Abschnitte, die nur einmal vorkommen (siehe 7.3).

### 8.4 Notausgang

`website/offline/` bleibt im Repo. Wenn die Seite kurzfristig wieder vom Netz muss, genügt es, im Workflow die drei Zeilen des Deploy-Schritts auf `offline/` umzustellen und zu pushen. Das ist in der README der Website zu dokumentieren, damit niemand nach dem Relaunch rätselt, wozu der Ordner da ist.

---

## 9. Offene Punkte

Diese Punkte blockieren den Baubeginn nicht, müssen aber vor dem Livegang erledigt sein.

**Entschieden und eingearbeitet:** Anschrift (Kreuzstraße 26, 76133 Karlsruhe), Kontaktweg (nur E-Mail plus Antwortzeit, kein Formular), keine USt-IdNr., keine eingetragene Marke, Kontaktadresse `info@dawnyapp.com`, OG-Bild wird neu entworfen, keine CSP, kein formaler Barrierefreiheits-Durchlauf, kein `check-legal.mjs`.

**Noch offen:**

| # | Punkt | Wer |
| --- | --- | --- |
| 1 | Mindest-iOS-Version gegen den App-Store-Eintrag prüfen | Agent, per Abgleich |
| 2 | Screenshots gegen App 1.3.0 prüfen und ggf. neu erzeugen | Agent |
| 3 | `PUBLIC_POSTHOG_PROJECT_TOKEN` und `PUBLIC_POSTHOG_HOST` als Repository-Secrets vorhanden? | Agent prüft, Florian ergänzt |
| 4 | OG-Bild-Entwurf abnehmen | Florian, nach Schritt 8 |
| 5 | AVV und DPA als PDF ablegen, ohne Eile | Florian |
| 6 | Optional: anwaltliche Kurzprüfung der beiden Rechtsseiten | Florian |

---

## 10. Wo die Wünsche an Grenzen stoßen

Ehrlich benannt, damit später niemand überrascht ist.

**Vierzig Fragen sind viel.** Die Aufteilung in fünf Blöcke und die Untergliederung in Block B machen das beherrschbar, aber es bleibt eine lange Seite. Realistisch liegt sie bei etwa 9000 Wörtern in der deutschen Fassung. Wer sie von oben bis unten liest, braucht eine Viertelstunde. Das ist in Ordnung für eine Seite, die auch als Handbuch dient, aber es ist bewusst eine Entscheidung gegen die kürzest mögliche Marketingseite. Falls sich das im Nachhinein als zu viel anfühlt, ist der sauberste Rückzug, die Blöcke C bis E auf eine zweite Seite `/de/fragen/` zu ziehen und auf der Startseite nur A und B zu lassen. Das Datenmodell aus 7.4 ist so gebaut, dass dieser Schnitt später eine Stunde Arbeit ist und keine Neuentwicklung.

**Beim Kontaktweg haben wir bewusst Aufwand gegen Restrisiko getauscht.** Die verbreitete Lesart von § 5 DDG will neben der E-Mail einen zweiten Kanal sehen. Wir liefern ihn nicht, weil ein Formular eine Serverkomponente samt Spamschutz, Absenderpostfach und dauerhafter Pflege bedeutet hätte und eine Telefonnummer die Privatadresse um eine Privatnummer ergänzt hätte. Für eine kostenlose App ohne Vertragsschluss und ohne Wettbewerber ist die Wahrscheinlichkeit einer Beanstandung sehr klein, aber sie ist nicht null. Falls es je zum Thema wird, ist die Reparatur eine einzige Zeile im Impressum. Die Einzelheiten stehen in 2.10.

**Ebenfalls bewusst weggelassen:** Content-Security-Policy, formaler Barrierefreiheits-Durchlauf, Platzhalter-Prüfskript, Umsortieren der Datenschutzerklärung. Jedes für sich vertretbar, zusammen sparen sie einen spürbaren Teil der Umsetzung. Wer das später anders sieht, findet die Begründungen in 7.8, 2.6 und in Schritt 3. Keine dieser Auslassungen betrifft eine Rechtspflicht.

**"Alle rechtlichen Aspekte abgedeckt" gibt es nicht.** Was hier steht, schließt die bekannten und häufig abgemahnten Lücken: Impressumsanschrift, toter ODR-Link, Google Fonts, Cookie-Einwilligung, Apple-Marken, Badge-Nutzung. Nicht geschlossen ist bewusst die Zweitkanal-Frage, siehe oben. Es ersetzt keine anwaltliche Prüfung, und es gibt Bereiche, in denen die Rechtsprechung sich bewegt, allen voran die Frage, ob cookieloses Analytics ohne Einwilligung dauerhaft haltbar bleibt. Wenn absolute Ruhe das Ziel ist, ist der einzige wirklich risikofreie Weg, auf PostHog zu verzichten. Das war die Empfehlung, die Entscheidung ist bewusst anders gefallen und das ist in Ordnung, solange DPA und Konfiguration stimmen.

**Die Screenshots sind der wahrscheinlichste Grund, warum die Seite in sechs Monaten falsch ist.** Sie veralten mit jedem UI-Update, und die FAQ-Antworten mit ihnen. Deshalb steht in jeder Antwort, die sich auf konkretes Verhalten bezieht, ein Beleg im Quellcode. Wer die App ändert, sollte in diesem Dokument nachsehen, ob eine Antwort mitwandert. Ein leichter Weg, das zu erzwingen, wäre ein Testfall in `DawnyTests`, der die Kategorielebensdauern und den Standardwert von `makeItCountThreshold` gegen die auf der Website genannten Zahlen prüft. Das ist ein Vorschlag, keine Vorgabe.

**Die geführte Demo ist teuer im Unterhalt, und das ist bewusst entschieden.** Der Prototyp bringt 404 Zeilen JavaScript mit, die eine Choreografie beschreiben. Mit der Pause-Steuerung und dem Reduced-Motion-Pfad aus 4.2 werden daraus realistisch etwa 500. Damit ist sie das einzige Stück der Seite, das nicht dem Grundsatz aus 7.1 folgt. Es gab die Wahl zwischen einer schlichten Schrittsteuerung von etwa vierzig Zeilen und der vollen Choreografie, und die Entscheidung ist zugunsten der Choreografie gefallen, weil sie in dreißig Sekunden erklärt, wofür der Text drei Absätze braucht. Der Preis: sie muss bei jeder Änderung am Reset-Verhalten angefasst werden, und sie ist der Teil, den ein anderer Agent am ehesten missversteht. Abgefedert wird das dadurch, dass sie gekapselt ist, ein Abschnitt und eine Skriptdatei ohne Verbindung zum Rest. Wenn sie irgendwann im Weg steht, lässt sie sich ersatzlos herausnehmen, und der Rückfall ist ein stilles, fünfstufiges Bild.

**Einfachheit und Wirkung ziehen an derselben Stelle in verschiedene Richtungen.** Außerhalb der Demo ist die Seite bewusst arm an Mechanik: natives `<details>`, ein einziger `IntersectionObserver`, fünf Komponenten statt vierzehn, keine Bibliothek. Gestrichen wurden dafür die Fortschrittsleiste, die zweispaltige FAQ, der weiche Höhenübergang beim Aufklappen und die Komponenten für Abschnitte, die nur einmal vorkommen. Jede dieser Streichungen kostet ein wenig Politur. Zusammen sorgen sie dafür, dass die Seite in einem Jahr noch verständlich ist, auch für jemanden, der sie nicht gebaut hat.
