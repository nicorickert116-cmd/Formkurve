# Formkurve installieren

Formkurve ist eine Web-App (PWA). Du stellst sie einmal kostenlos ins Netz, dann installierst du sie auf deinem Handy wie eine App. Sie läuft danach auch offline.

## Was im Ordner ist

- `index.html`: die komplette App
- `sw.js`: sorgt dafür, dass die App offline läuft
- `manifest.webmanifest` und vier Icons (`.png`): Name und Symbol auf dem Homebildschirm
- `ANLEITUNG.md`: diese Anleitung (musst du nicht hochladen)

## 1. Auf GitHub Pages veröffentlichen (kostenlos, ca. 10 Minuten)

1. ZIP entpacken. iPhone: in der Dateien-App antippen. Android: in „Dateien“ öffnen und „Extrahieren“. PC: Rechtsklick und „Alle extrahieren“.
2. Auf github.com ein kostenloses Konto anlegen und einloggen.
3. Oben rechts auf „+“ und „New repository“. Name: `formkurve`, „Public“ auswählen, „Create repository“.
4. Auf der neuen Seite den Link „uploading an existing file“ antippen.
5. Alle Dateien aus dem entpackten Ordner auswählen (nicht den Ordner selbst) und hochladen. Auf dem iPhone im Dateiauswahl-Fenster oben „Auswählen“ tippen, dann kannst du mehrere Dateien markieren.
6. Unten auf „Commit changes“.
7. Im Repository auf „Settings“, links auf „Pages“. Unter „Branch“ `main` und `/ (root)` wählen, „Save“.
8. Nach 1 bis 2 Minuten steht oben die Adresse, zum Beispiel `https://deinname.github.io/formkurve/`.

Das Repository ist öffentlich, aber dort liegt nur der Code. Deine Trainingsdaten landen nie bei GitHub, sie bleiben auf deinem Handy.

## 2. iPhone: Zum Home-Bildschirm

1. Die Adresse in Safari öffnen.
2. Auf das Teilen-Symbol tippen (Quadrat mit Pfeil nach oben).
3. „Zum Home-Bildschirm“ wählen und „Hinzufügen“ tippen.

## 3. Android: Zum Startbildschirm

1. Die Adresse in Chrome öffnen.
2. Oben rechts auf ⋮ tippen.
3. „App installieren“ oder „Zum Startbildschirm hinzufügen“ wählen.

## Wichtig zu deinen Daten

- Gespeichert wird nur auf dem Gerät. Auf dem iPhone haben Safari und die installierte App getrennte Speicher. Richte deinen Plan deshalb erst nach der Installation ein und starte Formkurve danach nur noch über das Icon.
- Mach regelmäßig ein Backup: Plan → Daten → „Backup sichern“. Die App erinnert dich nach 14 Tagen ohne Backup.
- Neues Handy: Backup-Datei auf das neue Gerät bringen und dort „Backup laden“ tippen.

## Updates einspielen

1. Die geänderten Dateien im Repository erneut hochladen. Gleichnamige Dateien werden ersetzt.
2. Wenn sich etwas geändert hat, in `sw.js` die Version in der zweiten Zeile erhöhen, zum Beispiel von `formkurve-v1.0.0` auf `formkurve-v1.0.1`.
3. Die App holt sich die neue Version im Hintergrund. Spätestens beim zweiten Öffnen ist sie aktiv.
