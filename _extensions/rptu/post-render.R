# Läuft nach jedem Rendern, wenn im Projekt eingetragen (_quarto.yml), z. B.
#
#   project:
#     post-render: _extensions/donvollb/rptu/post-render.R
#
# Der Pfad hängt davon ab, wie die Extension installiert wurde (quarto add legt
# sie unter _extensions/donvollb/rptu/ ab, eine lokale Kopie liegt meist unter
# _extensions/rptu/). Alternative ohne festen Pfad: _rptu-post-render.R aus der
# Projektvorlage, das dieses Skript selbst sucht.
#
# 1. Aufräumen: Quarto bindet in jedes revealjs-Theme die Schrift "Source Sans Pro"
#    ein, auch wenn sie nicht verwendet wird. Mit embed-resources landen dadurch
#    ca. 3 MB ungenutzte Schriftdaten in jeder Foliendatei. Diese @font-face-Blöcke
#    werden aus den fertigen HTML-Dateien entfernt.
#    Formeln: Quarto lädt MathJax beim Präsentieren aus dem Internet. Enthält eine
#    Datei Formeln, wird stattdessen MathJax aus mathjax/ eingebettet (ca. 3 MB).
#
# 2. Handout als PDF: Zu jeder Foliendatei (Format rptu-revealjs) wird eine
#    Handout-Version gerendert (-M handout:true, siehe handout.lua), mit Chrome
#    als <name>.pdf gedruckt und die Zwischen-HTML wieder gelöscht.
#    Braucht Google Chrome (oder Chromium/Edge) und das R-Paket chromote.
#    Für Edge/Chromium: Umgebungsvariable CHROMOTE_CHROME auf die .exe setzen.
#    Ohne Handout (schneller): Umgebungsvariable RPTU_NO_HANDOUT=1 setzen.

# Liste der gerenderten Dateien (bei sehr vielen Dateien gibt Quarto sie als Datei weiter)
liste <- Sys.getenv("QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES")
dateien <- if (nzchar(liste) && file.exists(liste)) {
  readLines(liste, warn = FALSE, encoding = "UTF-8")
} else {
  strsplit(Sys.getenv("QUARTO_PROJECT_OUTPUT_FILES"), "\n")[[1]]
}
dateien <- dateien[grepl("[.]html$", dateien) & file.exists(dateien)]

# Dasselbe Quarto wie beim eigentlichen Rendern verwenden (z. B. das in RStudio
# mitgelieferte, das nicht im Suchpfad liegt); sonst "quarto" aus dem Suchpfad
quarto_bin <- function() {
  bin <- Sys.getenv("QUARTO_BIN_PATH")
  for (exe in c("quarto.exe", "quarto.cmd", "quarto")) {
    pfad <- file.path(bin, exe)
    if (nzchar(bin) && file.exists(pfad)) return(pfad)
  }
  "quarto"
}

# --- 1. Ungenutzte Schrift entfernen, MathJax einbetten -----------------------

# @font-face-Block für Source Sans Pro innerhalb des eingebetteten
# (URL-kodierten) Theme-CSS; endet beim ersten "}" (%7D)
muster <- "%40font%2Dface%20%7B%0Afont%2Dfamily%3A%20%27Source%20Sans%20Pro%27.*?%7D"

# MathJax der Extension (SVG-Ausgabe, bringt ihre Schriften selbst mit); gesucht wie
# in _rptu-post-render.R, weil der Pfad von der Installation abhängt
mathjax_datei <- list.files("_extensions", pattern = "^tex-svg-full[.]js$",
                            recursive = TRUE, full.names = TRUE)
mathjax_datei <- mathjax_datei[basename(dirname(dirname(mathjax_datei))) == "rptu"][1]
mathjax_daten <- NULL

# Im reveal.js-Teil steht math: { mathjax: '<Adresse im Internet>', … }. Die Adresse
# wird durch die eingebettete Datei ersetzt. Das Mathe-Plugin hängt "?config=…" an;
# das "#" am Ende macht daraus ein Fragment, das der Browser ignoriert.
mathjax_einbetten <- function(html) {
  if (!grepl('class="math (inline|display)"', html, useBytes = TRUE)) return(html)
  treffer <- regmatches(html, regexpr("math: \\{\\s*mathjax: '[^']*'", html, perl = TRUE, useBytes = TRUE))
  if (length(treffer) == 0 || is.na(mathjax_datei)) return(html)
  if (is.null(mathjax_daten)) {
    roh <- readBin(mathjax_datei, "raw", file.size(mathjax_datei))
    mathjax_daten <<- gsub("\n", "", jsonlite::base64_enc(roh), fixed = TRUE)
  }
  ersatz <- sub("'[^']*'$", paste0("'data:text/javascript;base64,", mathjax_daten, "#'"), treffer)
  sub(treffer, ersatz, html, fixed = TRUE, useBytes = TRUE)
}

for (f in dateien) {
  html <- readChar(f, file.size(f), useBytes = TRUE)
  neu <- gsub(muster, "", html, perl = TRUE, useBytes = TRUE)
  neu <- mathjax_einbetten(neu)
  if (!identical(neu, html)) {
    writeChar(neu, f, eos = NULL, useBytes = TRUE)
    formeln <- if (grepl("text/javascript;base64", neu, fixed = TRUE, useBytes = TRUE))
      " (mit MathJax für Formeln)" else ""
    message(sprintf("post-render: %s  %.1f MB -> %.1f MB%s",
                    basename(f), nchar(html, "bytes") / 2^20, nchar(neu, "bytes") / 2^20, formeln))
  }
}

# --- 2. Handout als PDF -------------------------------------------------------

als_pdf_drucken <- function(html, pdf) {
  b <- chromote::ChromoteSession$new()
  on.exit(b$close(), add = TRUE)
  url <- paste0("file:///", normalizePath(html, winslash = "/"), "?print-pdf")
  b$Page$navigate(url)
  b$Page$loadEventFired(wait_ = TRUE, timeout_ = 60)
  # warten, bis reveal.js das Drucklayout gebaut hat (druck.html setzt das Signal)
  for (i in 1:100) {
    fertig <- b$Runtime$evaluate("window.rptuPdfFertig === true")$result$value
    if (isTRUE(fertig)) break
    Sys.sleep(0.2)
  }
  Sys.sleep(1) # Schriften, Bilder, Formeln
  res <- b$Page$printToPDF(printBackground = TRUE, preferCSSPageSize = TRUE,
                           marginTop = 0, marginBottom = 0, marginLeft = 0, marginRight = 0)
  writeBin(jsonlite::base64_dec(res$data), pdf)
}

# Ist das PDF in einem Viewer geöffnet, sperrt Windows die Datei; sie ließe sich
# nicht überschreiben und das alte PDF bliebe unbemerkt liegen.
pdf_gesperrt <- function(pdf) {
  if (!file.exists(pdf)) return(FALSE)
  tryCatch({ con <- file(pdf, "r+b"); close(con); FALSE },
           error = function(e) TRUE, warning = function(w) TRUE)
}

pdf_hinweis <- function(pdf) {
  linie <- strrep("!", 70)
  message("\n", linie,
          "\n  ", pdf, " ist geöffnet (z. B. im PDF-Viewer) und kann nicht",
          "\n  überschrieben werden. Das PDF ist NICHT aktualisiert.",
          "\n  Bitte schließen und erneut rendern.\n",
          linie, "\n")
}

# RPTU_NO_HANDOUT=1: kein Handout. Setzt das Skript auch selbst, während es das
# Handout rendert, damit es sich nicht erneut auslöst. (RPTU_HANDOUT_RENDER ist
# der frühere Name und gilt weiterhin.)
if (Sys.getenv("RPTU_NO_HANDOUT") != "1" && Sys.getenv("RPTU_HANDOUT_RENDER") != "1") {
  for (f in dateien[!grepl("_handout[.]html$", dateien)]) {
    qmd <- sub("[.]html$", ".qmd", f)
    if (!file.exists(qmd)) next
    # nur Foliendateien mit format: rptu-revealjs im YAML-Kopf der qmd
    kopf <- readLines(qmd, n = 200, warn = FALSE, encoding = "UTF-8")
    grenzen <- which(trimws(kopf) == "---")
    if (length(grenzen) >= 2) kopf <- kopf[grenzen[1]:grenzen[2]]
    if (!any(grepl("rptu-revealjs", kopf))) next
    if (!requireNamespace("chromote", quietly = TRUE)) {
      warning("post-render: R-Paket chromote fehlt, kein PDF für ", qmd)
      next
    }

    tmp <- sub("[.]html$", "_handout.html", basename(f))
    pdf <- sub("[.]html$", ".pdf", basename(f))
    # im Ordner der Foliendatei rendern, damit relative Pfade stimmen
    alt <- setwd(dirname(normalizePath(qmd)))
    if (pdf_gesperrt(pdf)) {
      pdf_hinweis(pdf)
      setwd(alt)
      next
    }
    message("post-render: erzeuge ", pdf)
    Sys.setenv(RPTU_NO_HANDOUT = "1")
    status <- system2(quarto_bin(), c("render", shQuote(basename(qmd)), "-M", "handout:true",
                                  "--output", shQuote(tmp)))
    Sys.unsetenv("RPTU_NO_HANDOUT")
    if (status == 0 && file.exists(tmp)) {
      tryCatch(als_pdf_drucken(tmp, pdf),
               error = function(e) {
                 if (pdf_gesperrt(pdf)) pdf_hinweis(pdf)
                 else message("\npost-render: PDF-Druck fehlgeschlagen: ", conditionMessage(e), "\n")
               })
    } else {
      warning("post-render: Handout-Rendern fehlgeschlagen für ", qmd)
    }
    unlink(tmp) # Zwischendatei auch nach einem Fehler entfernen
    setwd(alt)
  }
}
