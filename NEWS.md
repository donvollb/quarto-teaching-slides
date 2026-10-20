## 0.2.0 (20.10.2026)

- Markierungen: Farben lassen sich unabhängig von der Nummer wählen, z. B.
  `::: {.markiert m1="…" m2="…" farben="gruen navy"}` (englisch `colors=`). Die
  Nummern `[1]{.nr}` auf derselben Folie übernehmen die Farben. Mit
  `markierung-rollen:` (englisch `highlight-roles:`) in der `_quarto.yml` lassen sich
  Begriffen feste Farben zuordnen, z. B. `intercept: gruen`. Ohne Angabe bleibt alles
  wie bisher.
- Handout: Fragmente mit `fragment-index` oder mit Stilklassen wie `.fade-up` und
  einer Überschrift darin landeten im PDF auf einer eigenen Seite, und Teile der
  Folie konnten über der Titelfolie liegen. Jetzt stehen sie wie alle Fragmente
  vollständig auf ihrer Folie. Der Vortrag ist unverändert.

## 0.1.1 (20.10.2026)

- Abschnittsnummern im Handout stimmen jetzt mit dem Vortrag überein, auch wenn eine
  Abschnittsfolie mit `.no-handout` entfällt. Bisher rückten die folgenden Nummern auf.
- Markierungen ab `m7`: Die sechs Farben wiederholen sich (`m7` wie `m1` usw.). Bisher
  fehlten ab der siebten Markierung Farbe und sichtbare Nummer.
- Einzelne Bilder mit `fig-align` (`center`, `left`, `right`) stehen wieder an der
  richtigen Stelle. Bisher wurden sie zusätzlich nach rechts verschoben, bei `right`
  bis über den Folienrand. Bilder ohne `fig-align` stehen weiterhin mittig.
- Schlägt der Druck des Handouts fehl, wird die Zwischendatei `…_handout.html`
  trotzdem gelöscht.
- Neue Umgebungsvariable `RPTU_NO_HANDOUT=1`, um nur den Vortrag zu erzeugen. Der
  bisherige Name `RPTU_HANDOUT_RENDER` funktioniert weiterhin.

## 0.1.0 (19.10.2026)

Erste Version.

- Format `rptu-revealjs`: Folien im Design der RPTU; jedes Rendern erzeugt den Vortrag
  (HTML) und ein Handout (PDF) ohne schrittweise Einblendungen und ohne Inhalte, die
  mit `.no-handout` nur für den Vortrag gekennzeichnet sind.
- Abschnittsfolien mit Nummern, Agenda, Fußzeile mit Kontakt, Veranstaltung und
  Foliennummer.
- Markierungen im R-Output, Kästen, Hervorhebungen, Symbole, Semesterplan.
- Formeln auch ohne Internet (MathJax wird eingebettet).
- Optional: ggplot2-Theme `theme_rptu()` mit Farben und Schrift der Folien.
- Deutsche Klassennamen mit englischen Aliassen.
- Projektvorlage für `quarto use template` und Website mit Anleitungen.
