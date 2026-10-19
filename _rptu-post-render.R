# Startet das post-render-Skript der Extension rptu (Handout-PDF und Aufräumen).
# Eingetragen in _quarto.yml:
#
#   project:
#     post-render: _rptu-post-render.R
#
# Das Skript sucht post-render.R selbst unter _extensions/. Damit stimmt der Eintrag
# unabhängig davon, ob die Extension unter _extensions/rptu/ liegt (Kopie, lokale
# Installation) oder unter _extensions/donvollb/rptu/ (quarto add bzw.
# quarto use template von GitHub).
# Der Unterstrich am Anfang des Dateinamens sorgt dafür, dass Quarto die Datei
# nicht als Dokument rendert.

skript <- list.files("_extensions", pattern = "^post-render[.]R$",
                     recursive = TRUE, full.names = TRUE)
skript <- skript[basename(dirname(skript)) == "rptu"]

if (length(skript) == 0) {
  warning("_rptu-post-render.R: Extension nicht gefunden ",
          "(erwartet: _extensions/.../rptu/post-render.R), kein Handout-PDF")
} else {
  if (length(skript) > 1) {
    message("_rptu-post-render.R: mehrere Kopien der Extension gefunden, verwende ", skript[1])
  }
  source(skript[1], encoding = "UTF-8", local = new.env())
}
