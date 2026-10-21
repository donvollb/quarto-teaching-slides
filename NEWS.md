## 0.5.0 (21.10.2026)

- Zu volle Folien: Nach dem Rendern meldet das Skript Folien, deren Inhalt in die
  Fußzeile reicht oder die im Druck zwei Seiten belegen, z. B.
  `Folie 7 (Ergebnisse): 13 px in der Fußzeile`. Bisher fiel das erst im Vortrag oder
  im Handout auf (verdeckt, abgeschnitten oder auf zwei Seiten verteilt). Geprüft wird
  der Vortrag, also auch Folien mit `.no-handout` und Renders ohne Handout. Es ist nur
  ein Hinweis, das Rendern läuft weiter.
- Ohne installiertes Chrome druckt das Skript das Handout mit „Chrome for Testing“,
  wenn es einmal mit `chromote::chrome_versions_add("latest-stable",
  "chrome-headless-shell")` heruntergeladen wurde (chromote ab 0.5.0, ohne
  Administratorrechte). Fehlt beides, nennt die Meldung beim Rendern diesen Befehl.
- Vorlage und Demo zeigen jetzt eine Folie vor der Titelfolie, die Abschnittsanzeige
  und Markierungsfarben über Rollen (Folie „Farben selbst wählen“).

## 0.4.0 (21.10.2026)

- Folien vor der Titelfolie: `## Vorbereitung {.no-handout .vor-titel}` (englisch
  `.before-title`) steht im Vortrag vor der Titelfolie, und der Vortrag beginnt mit
  dieser Folie. Die Titelfolie bleibt Folie 1, alle anderen Folien behalten Nummer und
  Adresse; die vorgezogenen Folien haben keine Nummer. Im Handout bleiben sie (ohne
  `.no-handout`) an ihrer Stelle, ebenfalls ohne Nummer. Eigene Skripte, die solche
  Folien verschieben, sind damit überflüssig und sollten entfernt werden.
- Abschnittsanzeige: Mit `abschnitt-anzeige: true` (englisch `section-indicator: true`)
  steht über jedem Folientitel klein Nummer und Name des Abschnitts. Für lange
  Abschnittstitel gibt es die Kurzform `# Titel {kurz="…"}` (englisch `short=`). Ohne
  den Eintrag bleibt alles wie bisher.

## 0.3.0 (21.10.2026)

- Markierungen: In `markierung-rollen:` (englisch `highlight-roles:`) geht statt eines
  Farbnamens auch ein eigener Farbwert, z. B. `fixed: "#3470A8"`. Rahmen, Nummer und
  Fettdruck sehen aus wie bei den Farbnamen; bei hellen Farben wird die Nummer
  automatisch dunkel gesetzt.

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
