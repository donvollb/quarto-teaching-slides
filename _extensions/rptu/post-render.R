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
#    Ohne installiertes Chrome: einmalig in R
#      chromote::chrome_versions_add("latest-stable", "chrome-headless-shell")
#    ausführen (lädt „Chrome for Testing“, ohne Adminrechte); das Skript nutzt es dann.
#    Ohne Handout (schneller): Umgebungsvariable RPTU_NO_HANDOUT=1 setzen.
#
# 3. Zu volle Folien melden: Der Vortrag wird im Drucklayout geöffnet und jede
#    Folie geprüft, die mehrere PDF-Seiten belegt oder deren Inhalt in die Fußzeile
#    reicht. Nur eine Meldung, das Rendern läuft normal weiter (auch ohne chromote).

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

# qmd zu einer gerenderten Foliendatei, wenn sie format: rptu-revealjs im YAML-Kopf
# hat (sonst NA); Zwischendateien des Handouts zählen nicht
foliensatz_qmd <- function(f) {
  qmd <- sub("[.]html$", ".qmd", f)
  if (grepl("_handout[.]html$", f) || !file.exists(qmd)) return(NA_character_)
  kopf <- readLines(qmd, n = 200, warn = FALSE, encoding = "UTF-8")
  grenzen <- which(trimws(kopf) == "---")
  if (length(grenzen) >= 2) kopf <- kopf[grenzen[1]:grenzen[2]]
  if (any(grepl("rptu-revealjs", kopf))) qmd else NA_character_
}

# Öffnet eine Foliendatei im Drucklayout (?print-pdf) in Chrome und wartet, bis
# reveal.js es gebaut hat (druck.html setzt das Signal); die Sitzung schließt der Aufrufer
druckansicht <- function(html) {
  b <- chromote::ChromoteSession$new()
  url <- paste0("file:///", normalizePath(html, winslash = "/"), "?print-pdf")
  b$Page$navigate(url)
  b$Page$loadEventFired(wait_ = TRUE, timeout_ = 60)
  for (i in 1:100) {
    fertig <- b$Runtime$evaluate("window.rptuPdfFertig === true")$result$value
    if (isTRUE(fertig)) break
    Sys.sleep(0.2)
  }
  Sys.sleep(1) # Schriften, Bilder, Formeln
  b
}

# Browser für den Druck: das installierte Google Chrome bzw. der Browser aus
# CHROMOTE_CHROME; sonst ein mit chromote heruntergeladenes Chrome for Testing
# (chrome-headless-shell, die neueste vorhandene Version)
chrome_suchen <- function() {
  if (!requireNamespace("chromote", quietly = TRUE)) return(FALSE)
  if (nzchar(Sys.getenv("CHROMOTE_CHROME"))) return(TRUE)
  pfad <- suppressMessages(tryCatch(chromote::find_chrome(), error = function(e) NULL))
  if (length(pfad) == 1 && nzchar(pfad) && file.exists(pfad)) return(TRUE)
  geladen <- tryCatch(chromote::chrome_versions_list("installed", "chrome-headless-shell"),
                      error = function(e) NULL)
  if (is.null(geladen) || nrow(geladen) == 0) return(FALSE)
  geladen <- geladen[file.exists(geladen$path), , drop = FALSE]
  if (nrow(geladen) == 0) return(FALSE)
  neueste <- geladen$path[order(numeric_version(geladen$version), decreasing = TRUE)][1]
  Sys.setenv(CHROMOTE_CHROME = neueste)
  TRUE
}

# Erst bei der ersten Foliendatei prüfen; fehlt ein Browser, einmal Bescheid geben
chrome <- NA
chrome_da <- function() {
  if (is.na(chrome)) {
    chrome <<- chrome_suchen()
    if (!chrome && requireNamespace("chromote", quietly = TRUE)) {
      message("\npost-render: Kein Chrome gefunden, deshalb kein Handout-PDF und keine Prüfung",
              "\n  auf zu volle Folien. Abhilfe: Google Chrome installieren oder einmalig in R",
              "\n    chromote::chrome_versions_add(\"latest-stable\", \"chrome-headless-shell\")",
              "\n  ausführen (lädt Chrome for Testing, ohne Adminrechte).\n")
    }
  }
  chrome
}

als_pdf_drucken <- function(html, pdf) {
  b <- druckansicht(html)
  on.exit(b$close(), add = TRUE)
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
  for (f in dateien) {
    qmd <- foliensatz_qmd(f)
    if (is.na(qmd)) next
    if (!requireNamespace("chromote", quietly = TRUE)) {
      warning("post-render: R-Paket chromote fehlt, kein PDF für ", qmd)
      next
    }
    if (!chrome_da()) next

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

# --- 3. Zu volle Folien melden ------------------------------------------------

# Ist eine Folie zu voll, ragt ihr Inhalt im Vortrag in die Fußzeile; im Druck
# verteilt reveal.js sie auf zwei Seiten oder der Rest wird abgeschnitten.
# Geprüft wird der Vortrag im Drucklayout (alle Einblendungen sichtbar), nicht das
# Handout: Es hat dasselbe Layout, und so fallen auch .no-handout-Folien und Renders
# mit RPTU_NO_HANDOUT=1 auf. Pro Seite:
#   1. Belegt die Folie mehrere Seiten?
#   2. Reicht sichtbarer Inhalt in die Fußzeile? Unsichtbare Container (z. B. auf
#      volle Höhe gestreckte Spalten) zählen nicht mit, Kästen und Codeblöcke mit
#      Hintergrund oder Rahmen schon.
JS_UEBERLAUF <- "(function (toleranz) {
  var out = [];
  var seiten = document.querySelectorAll('.pdf-page');
  if (!seiten.length) return '';
  var hoehe = seiten[0].offsetHeight; // normale Seite (Titelfolie)
  seiten.forEach(function (seite) {
    var folie = seite.querySelector('section');
    if (!folie) return;
    var nr = seite.querySelector('.slide-number-pdf');
    nr = nr ? nr.textContent.trim() : '';
    var titel = folie.querySelector('h1, h2');
    var name = 'Folie ' + (nr ? nr + ' ' : '') + '(' + (titel ? titel.textContent.trim() : 'ohne Titel') + '): ';
    if (seite.offsetHeight > hoehe + toleranz) {
      out.push(name + 'belegt ' + Math.ceil(seite.offsetHeight / hoehe) + ' PDF-Seiten');
      return;
    }
    var fuss = seite.querySelector('.footer');
    var grenze = fuss ? fuss.getBoundingClientRect().top : seite.getBoundingClientRect().top + hoehe;
    var unten = 0;
    folie.querySelectorAll('*').forEach(function (e) {
      if (e.closest('aside')) return; // Sprechernotizen
      var r = e.getBoundingClientRect();
      if (!(r.height > 0 && r.width > 0) || r.bottom <= unten) return;
      var st = getComputedStyle(e);
      if (st.visibility === 'hidden') return;
      if (e.children.length && st.backgroundColor === 'rgba(0, 0, 0, 0)' &&
          !(parseFloat(st.borderBottomWidth) > 0)) return;
      unten = r.bottom;
    });
    var zuviel = Math.round(unten - grenze);
    if (zuviel > toleranz) out.push(name + zuviel + ' px in der Fußzeile');
  });
  return out.join('\\n');
})(2)"

ueberlauf_pruefen <- function(html) {
  b <- druckansicht(html)
  on.exit(b$close(), add = TRUE)
  res <- b$Runtime$evaluate(JS_UEBERLAUF)$result$value
  if (is.character(res) && nzchar(res)) {
    message("\npost-render: Folie zu voll in ", basename(html), " (ragt im Vortrag in die Fußzeile,\n",
            "  im Handout ggf. abgeschnitten oder auf zwei Seiten verteilt):\n",
            paste0("  ", strsplit(res, "\n")[[1]], collapse = "\n"), "\n")
  }
}

for (f in dateien) {
  if (is.na(foliensatz_qmd(f)) || !chrome_da()) next
  tryCatch(ueberlauf_pruefen(f), error = function(e) NULL)
}
