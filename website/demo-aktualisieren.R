# Demo und Bilder der Website aktualisieren
#
# Aufruf (im Repo-Wurzelverzeichnis oder im Ordner website/):
#   Rscript website/demo-aktualisieren.R
#
# 1. rendert template.qmd im Repo-Wurzelverzeichnis (Vortrag + Handout-PDF),
# 2. kopiert template.html und template.pdf nach website/demo/
#    (beispiel.html, beispiel.pdf),
# 3. erzeugt aus der Demo Bilder einzelner Folien und Elemente für website/bilder/
#    (dazu eine Handout-Seite aus dem PDF),
# 4. löscht die Ausgaben im Wurzelverzeichnis wieder.
#
# Danach die Website neu rendern:  quarto render website
# Braucht: Quarto, R mit chromote, jsonlite, magick und pdftools, Google Chrome.

# --- Ordner bestimmen -----------------------------------------------------------

skript <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
web_dir <- if (length(skript) == 1) dirname(normalizePath(skript)) else normalizePath("website")
wurzel <- dirname(web_dir)
stopifnot(file.exists(file.path(wurzel, "template.qmd")))

demo_dir <- file.path(web_dir, "demo")
bild_dir <- file.path(web_dir, "bilder")
dir.create(demo_dir, showWarnings = FALSE)
dir.create(bild_dir, showWarnings = FALSE)

# --- 1. + 2. Rendern und kopieren ----------------------------------------------

alt <- setwd(wurzel)
status <- system2("quarto", c("render", "template.qmd"))
setwd(alt)
if (status != 0 || !file.exists(file.path(wurzel, "template.pdf"))) {
  stop("Rendern von template.qmd fehlgeschlagen (oder kein PDF erzeugt)")
}
kopiert <- file.copy(file.path(wurzel, c("template.html", "template.pdf")),
                     file.path(demo_dir, c("beispiel.html", "beispiel.pdf")), overwrite = TRUE)
unlink(file.path(wurzel, c("template.html", "template.pdf", "template_handout.html")))
if (!all(kopiert)) {
  stop("Demo nicht vollständig kopiert (ist website/demo/beispiel.pdf noch geöffnet?)")
}
message("Demo kopiert nach ", demo_dir)

# --- 3. Bilder ------------------------------------------------------------------

b <- chromote::ChromoteSession$new(width = 1600, height = 900)
b$Page$navigate(paste0("file:///", normalizePath(file.path(demo_dir, "beispiel.html"), winslash = "/")))
b$Page$loadEventFired(wait_ = TRUE, timeout_ = 60)
Sys.sleep(1.5)

js <- function(code) b$Runtime$evaluate(code, returnByValue = TRUE)$result$value

# Kopier-Knöpfe an Codeblöcken für die Bilder ausblenden
js("var st=document.createElement('style'); st.textContent='.code-copy-button{display:none!important}'; document.head.appendChild(st); true")

# Folie anhand des Anfangs ihrer Überschrift anzeigen (NULL = Titelfolie),
# mit allen Fragmenten (also so, wie sie am Ende aussieht)
zeige <- function(titel = NULL) {
  if (is.null(titel)) {
    js("Reveal.slide(0, 0)")
  } else {
    ok <- js(sprintf(
      "(function(){var t=%s;
         var s=[].slice.call(document.querySelectorAll('.reveal .slides section')).find(function(x){
           var h=x.querySelector(':scope > h1, :scope > h2');
           return h && h.textContent.trim().indexOf(t)===0;});
         if(!s) return false;
         var i=Reveal.getIndices(s); Reveal.slide(i.h, i.v, 999); return true;})()",
      jsonlite::toJSON(titel, auto_unbox = TRUE)))
    if (!isTRUE(ok)) stop("Folie nicht gefunden: ", titel)
  }
  Sys.sleep(0.8)
}

speichern <- function(daten, datei, breite) {
  roh <- tempfile(fileext = ".png")
  writeBin(jsonlite::base64_dec(daten), roh)
  bild <- magick::image_read(roh)
  if (!is.null(breite)) bild <- magick::image_resize(bild, paste0(breite, "x"))
  magick::image_write(bild, file.path(bild_dir, datei), format = "png")
  unlink(roh)
}

# ganze Folie (Fenster 1600 x 900), verkleinert auf 1200 px Breite
folie <- function(datei, titel = NULL) {
  zeige(titel)
  speichern(b$Page$captureScreenshot(format = "png")$data, datei, 1200)
}

# einzelnes Element einer Folie (CSS-Selektor), mit etwas Rand.
# eng = TRUE: nur so breit wie der Inhalt (Text), statt der ganzen Folienbreite;
# extra = zusätzlicher Platz rechts (z. B. für Symbole hinter Überschriften),
# links = zusätzlicher Platz links (z. B. für Nummern vor Listenpunkten)
element <- function(datei, titel, selektor, rand = 14, eng = TRUE, extra = 0, links = 0) {
  zeige(titel)
  r <- js(sprintf(
    "(function(){var e=document.querySelector('.reveal .slides section.present %s');
       if(!e) return null; var r=e.getBoundingClientRect();
       if(%s){var g=document.createRange(); g.selectNodeContents(e); var t=g.getBoundingClientRect();
              r={x:Math.min(r.x,t.x), y:r.y, width:t.right-Math.min(r.x,t.x)+%d, height:r.height};}
       return [r.x, r.y, r.width, r.height];})()",
    selektor, if (eng) "true" else "false", as.integer(extra)))
  if (is.null(r)) stop("Element nicht gefunden: ", selektor, " auf ", titel)
  r <- unlist(r)
  clip <- list(x = max(0, r[1] - rand - links), y = max(0, r[2] - rand),
               width = r[3] + 2 * rand + links, height = r[4] + 2 * rand, scale = 1)
  speichern(b$Page$captureScreenshot(format = "png", clip = clip)$data, datei, NULL)
}

folie("folie-titel.png")
folie("folie-agenda.png", "Heutige Themen")
folie("folie-abschnitt.png", "Aufbau eines Foliensatzes")
folie("folie-spalten.png", "Zwei Spalten")
folie("folie-semesterplan.png", "Semesterplan")
folie("folie-kaesten.png", "Kästen, Farben und Text")
folie("folie-formeln.png", "Formeln")
folie("folie-symbole.png", "Symbole")
folie("folie-nur-vortrag.png", "Nur im Vortrag")
folie("folie-grafik.png", "Grafiken mit ggplot2")
folie("folie-markierungen.png", "Markierungen im Output")
folie("folie-loesung.png", "Lösung Übung 1")

element("el-kasten.png", "Kästen, Farben und Text", ".kasten", eng = FALSE)
element("el-farben.png", "Kästen, Farben und Text", "p:has(> .gruen)")
element("el-box.png", "Kästen, Farben und Text", "p:has(> .box)")
element("el-frage.png", "Kästen, Farben und Text", "p:has(> .frage)")
element("el-achtung.png", "Symbole", "h2", extra = 70)
element("el-ki.png", "Symbole", "h3.ki", extra = 40)
element("el-markiert.png", "Markierungen im Output", ".markiert", eng = FALSE)
element("el-nummern.png", "Markierungen im Output", "ul", links = 30)

b$close()

# Handout-Seite zur Folie "Nur im Vortrag" (Startseite: Vortrag und Handout nebeneinander)
pdf <- file.path(demo_dir, "beispiel.pdf")
seite <- which(grepl("Nur im Vortrag", pdftools::pdf_text(pdf)))[1]
if (is.na(seite)) stop("Handout-Seite \"Nur im Vortrag\" nicht gefunden")
breite_pt <- pdftools::pdf_pagesize(pdf)$width[seite]
roh <- pdftools::pdf_render_page(pdf, seite, dpi = 1200 / (breite_pt / 72))
magick::image_write(magick::image_read(roh), file.path(bild_dir, "handout-nur-vortrag.png"), format = "png")

message("Bilder gespeichert in ", bild_dir)
