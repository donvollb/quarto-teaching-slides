# Website veröffentlichen (intern)

Diese Datei wird nicht gerendert (sie steht nicht in `render:` der
`website/_quarto.yml`) und von `quarto use template` nicht kopiert.

## Aufbau

- Quellen: `website/` (eigenes Quarto-Projekt, `type: website`)
  - `index.qmd`: leitet auf `de/index.html` weiter
  - `de/*.qmd`: die Seiten (vorerst nur Deutsch; englische Seiten können später unter
    `en/` mit denselben Dateinamen dazukommen)
  - `bilder/`: Folien- und Element-Bilder, `demo/`: gerenderter Beispiel-Foliensatz
    (HTML) und Handout (PDF)
  - `styles.scss`: Dunkelblau, Lato (aus `../_extensions/rptu/fonts.scss`), keine
    Google-Fonts
- Ausgabe: `docs/` im Repo-Wurzelverzeichnis (`output-dir: ../docs`), inkl.
  `.nojekyll`. `docs/` wird committet (siehe `.gitignore`).

## Website aktualisieren

1. Nur wenn sich die Folien bzw. `template.qmd` geändert haben: Demo und Bilder neu
   erzeugen (braucht R mit chromote, jsonlite, magick, pdftools und Chrome):

   ```bash
   Rscript website/demo-aktualisieren.R
   ```

2. Website rendern (im Repo-Wurzelverzeichnis):

   ```bash
   quarto render website
   ```

   Seiten, die entfallen oder umbenannt wurden, bleiben in `docs/` liegen; dann
   `docs/` vorher löschen (wird vollständig neu erzeugt, inkl. `.nojekyll`).

3. Prüfen, z. B. `docs/index.html` im Browser öffnen. (Suche und Demo-iframe
   funktionieren erst über einen Webserver vollständig, z. B. `quarto preview website`.)

4. Committen und pushen, inkl. `docs/`.

## Erstes Veröffentlichen auf GitHub Pages

1. Repository `quarto-teaching-slides` unter `donvollb` anlegen und alles pushen
   (Branch `main`, inkl. `docs/`). Hinweis: Der lokale Branch heißt nach `git init`
   derzeit `master`; vor dem ersten Push z. B. `git branch -M main` (oder in Schritt 2
   `master` wählen).
2. Auf GitHub: *Settings → Pages → Build and deployment*:
   *Source: Deploy from a branch*, *Branch: main*, Ordner */docs*, *Save*.
3. Nach ein bis zwei Minuten ist die Website erreichbar unter
   <https://donvollb.github.io/quarto-teaching-slides/>.
4. Optional: in den Repository-Einstellungen (*About*, Zahnrad) die Website-URL
   eintragen.

Die bestehende User-Site `donvollb.github.io` stört nicht: Project-Pages laufen unter
dem Repository-Namen als Unterpfad.

## Warum `docs/` und nicht `quarto publish gh-pages`?

- `docs/` braucht keinen zweiten Branch und kein zusätzliches Werkzeug: rendern,
  committen, pushen. Pages wird einmal umgestellt.
- `quarto publish gh-pages` hielte `main` frei von generierten Dateien, pusht aber
  selbst (eigener Branch `gh-pages`) und trennt Quellen und Ergebnis. Für ein kleines
  Projekt mit seltenen Änderungen bringt das wenig.
- Nachteil von `docs/`: Generierte Dateien landen in der Historie von `main`, und man
  muss vor dem Commit an `quarto render website` denken.
