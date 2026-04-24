---
layout: "@/layouts/Legal.astro"
title: "Datenschutzerklärung"
description: "Datenschutzerklärung für Dawny. Kein Tracking. Keine Analytics. Keine Drittanbieter-SDKs."
lang: "de"
canonicalPath: "/datenschutz/"
---

**Stand:** 19. April 2026
**Sprache:** Deutsch ([English version](/en/privacy/))

## 1. Verantwortlicher

Verantwortlicher im Sinne der DSGVO ist:

**Florian Schneider**
Kreuzstraße 26
76133 Karlsruhe
Deutschland

E-Mail: info@dawnyapp.com

## 2. Überblick

Dawny ist eine native iOS-App zur persönlichen Aufgabenplanung. Dawny ist **privacy-first** entworfen:

- Es gibt **keinen Server und kein Backend** seitens des Entwicklers.
- Es findet **keine Erhebung personenbezogener Daten** durch den Entwickler statt.
- Es gibt **kein Tracking, keine Analytics, keine Werbung, keine Drittanbieter-SDKs**.
- Alle Daten verbleiben **auf deinem Gerät** bzw. – falls du iCloud nutzt – in deinem persönlichen iCloud-Konto, das ausschließlich von Apple verwaltet wird.

## 3. Welche Daten werden verarbeitet?

### 3.1 Lokale App-Daten (SwiftData)

Dawny speichert deine Aufgaben, Backlog-Einträge, Kategorien und App-Einstellungen lokal auf deinem iPhone mit dem von Apple bereitgestellten **SwiftData**-Framework. Diese Daten verlassen dein Gerät nicht – außer du hast in den iOS-Einstellungen die App-übergreifende iCloud-Synchronisation aktiviert, in welchem Fall Apple die Daten verschlüsselt zwischen deinen eigenen Apple-Geräten synchronisiert. Der Entwickler hat in keinem Fall Zugriff darauf.

### 3.2 Apple Reminders / Apple Calendar (EventKit)

Wenn du die Synchronisation mit Apple Reminders aktivierst, schreibt Dawny die Aufgaben deiner aktuellen Tagesliste in deine lokale Apple-Reminders-Datenbank und liest Änderungen von dort zurück. Die Berechtigung dafür wird beim ersten Verwendungswunsch über den iOS-Standarddialog erfragt (`NSRemindersUsageDescription`). Du kannst sie jederzeit unter *Einstellungen → Datenschutz & Sicherheit → Erinnerungen → Dawny* widerrufen.

Diese Daten werden **ausschließlich lokal bzw. innerhalb deines eigenen iCloud-Kontos** verarbeitet. Es findet kein Versand an den Entwickler oder Dritte statt.

### 3.3 Siri und App Intents

Dawny stellt Siri-Kurzbefehle bereit (z. B. „Add milk to Dawny today"). Die Berechtigung für Siri wird beim ersten Verwendungswunsch über den iOS-Standarddialog erfragt (`NSSiriUsageDescription`). Die Sprachverarbeitung erfolgt durch Apple gemäß [Apples Datenschutzrichtlinie](https://www.apple.com/legal/privacy/de-ww/). Der Entwickler erhält weder die Audiodaten noch die transkribierten Befehle.

### 3.4 Hintergrundausführung (BackgroundTasks)

Dawny verwendet das `BackgroundTasks`-Framework von Apple, um den 3-Uhr-morgens-Reset (Verschieben offener Tagesaufgaben zurück ins Backlog) durchzuführen. Dabei werden **keine Daten verschickt**; es handelt sich um eine rein lokale Operation auf deinen App-Daten.

### 3.5 App-Einstellungen (UserDefaults)

App-Einstellungen wie deine bevorzugte Reset-Uhrzeit und Sichtbarkeit von Kategorien werden in `UserDefaults` deines App-Containers gespeichert – ebenfalls rein lokal.

## 4. Daten, die NICHT verarbeitet werden

Dawny erhebt **keine** der folgenden Daten:

- Name, E-Mail, Telefonnummer, Adresse oder andere Kontaktdaten.
- Standortdaten.
- Crash-Reports oder Diagnose-Telemetrie an den Entwickler.
- Werbe-IDs (IDFA), Geräte-IDs oder Fingerprints.
- Verhaltens- oder Nutzungs-Analytics.

Die App enthält **keine Drittanbieter-SDKs** (kein Firebase, kein Sentry, kein Mixpanel, kein Facebook SDK, etc.).

## 5. App-Tracking-Transparenz

Dawny tracked nicht und ruft daher den **App-Tracking-Transparenz-Dialog (ATT)** nicht auf.

## 6. Apple als Plattform

Dawny läuft auf iOS und nutzt Apple-Dienste (App Store, TestFlight, iCloud, Siri, Reminders, Calendar). Für die Datenverarbeitung durch Apple gilt [Apples Datenschutzrichtlinie](https://www.apple.com/legal/privacy/de-ww/), auf die der Entwickler keinen Einfluss hat.

## 7. Deine Rechte

Da Dawny keine personenbezogenen Daten beim Entwickler verarbeitet, sind viele DSGVO-Rechte (Auskunft, Löschung, Berichtigung etc.) faktisch von Apple bzw. von dir selbst auf deinem Gerät auszuüben:

- **Löschung aller Dawny-Daten**: Lösche die App; damit werden alle lokalen App-Daten entfernt. Daten in deinen Apple-Reminders bleiben in Reminders bestehen.
- **Auskunft**: Alle Daten sind in der App selbst und (bei aktivierter Synchronisation) in der Reminders-App auf deinem Gerät einsehbar.
- **Beschwerde**: Du hast das Recht, dich bei einer Datenschutz-Aufsichtsbehörde zu beschweren, in Deutschland z. B. bei der für dein Bundesland zuständigen Landesdatenschutzbehörde.

## 8. Kontakt

Bei Fragen zum Datenschutz: **info@dawnyapp.com**

## 9. Änderungen dieser Datenschutzerklärung

Diese Datenschutzerklärung kann angepasst werden, wenn sich die App ändert. Wesentliche Änderungen werden mit dem nächsten App-Update mitgeteilt.

## 10. Diese Webseite

Diese Webseite (`dawnyapp.com`) wird statisch bei IONOS in Deutschland gehostet. Es werden weder Cookies noch Tracking oder Analytics eingesetzt. Standardmäßige Server-Zugriffslogs können vom Hosting-Anbieter zum Betrieb des Dienstes temporär vorgehalten werden. Weitere Informationen zur Datenverarbeitung durch IONOS findest du in der [Datenschutzerklärung von IONOS](https://www.ionos.de/terms-gtc/datenschutzerklaerung/).
