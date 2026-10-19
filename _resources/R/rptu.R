# R-Grafiken im RPTU-Design (optional): Farben, ggplot2-Theme, Schrift Lato
#
# Einbinden im Setup-Chunk eines Foliensatzes (Pfad relativ zur qmd-Datei):
#   source("_resources/R/rptu.R")        # qmd im Projektordner
#   source("../_resources/R/rptu.R")     # qmd in einem Unterordner
#
# Braucht ggplot2; für Lato in Grafiken zusätzlich ragg. Lato muss nicht installiert
# sein: Fehlt sie im System, nimmt das Skript die Schriftdateien der Extension
# (_extensions/.../rptu/fonts/). Ohne ggplot2 werden nur die Farben angelegt.

# Farben (RPTU-CI, wie im Folien-Theme)
rptu_farben <- c(
  navy     = "#042C58",  # Dunkelblau, Leitfarbe
  hellblau = "#6AB2E7",
  blaugrau = "#507289",
  petrol   = "#77B6BA",  # Grüngrau
  teal     = "#006B6B",  # Dunkelgrün
  gruen    = "#00703C",  # dunkles Grün (wie Text im Theme)
  orange   = "#FFA252",
  rot      = "#C00000",  # dunkles Rot (wie Text im Theme)
  grau     = "#6B7A86"
)

# Reihenfolge für Gruppen in Abbildungen
rptu_palette <- unname(rptu_farben[c("navy", "hellblau", "orange", "teal", "blaugrau", "grau")])

# Schrift: Lato aus dem System oder aus der Extension, sonst Standardschrift
rptu_schrift <- local({
  if (!requireNamespace("ragg", quietly = TRUE)) return("")
  if ("Lato" %in% systemfonts::system_fonts()$family) return("Lato")
  # Extension im Projektordner suchen (beim Rendern gesetzt) bzw. ab dem
  # Arbeitsordner aufwärts
  ordner <- c(Sys.getenv("QUARTO_PROJECT_DIR"), ".", "..", "../..")
  ordner <- ordner[ordner != "" & dir.exists(file.path(ordner, "_extensions"))]
  dateien <- unlist(lapply(ordner, function(o) {
    list.files(file.path(o, "_extensions"), pattern = "^lato-400[.]woff2$",
               recursive = TRUE, full.names = TRUE)
  }))
  dateien <- dateien[basename(dirname(dirname(dateien))) == "rptu"]
  if (length(dateien) == 0) return("")
  fonts <- dirname(dateien[1])
  systemfonts::register_font(
    name       = "Lato",
    plain      = file.path(fonts, "lato-400.woff2"),
    bold       = file.path(fonts, "lato-700.woff2"),
    italic     = file.path(fonts, "lato-400-italic.woff2"),
    bolditalic = file.path(fonts, "lato-700-italic.woff2")
  )
  "Lato"
})

# Abbildungen mit ragg rendern, damit Lato sicher verwendet wird
if (requireNamespace("ragg", quietly = TRUE)) {
  knitr::opts_chunk$set(dev = "ragg_png")
}

if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)

  theme_rptu <- function(base_size = 16, base_family = rptu_schrift) {
    theme_minimal(base_size = base_size, base_family = base_family) +
      theme(
        text             = element_text(colour = "#1B1F24"),
        axis.text        = element_text(colour = "#4A5560"),
        axis.title       = element_text(colour = "#1B1F24"),
        plot.title       = element_text(face = "bold", size = rel(1.1)),
        plot.title.position = "plot",
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#E3E8EC", linewidth = 0.4),
        axis.line        = element_line(colour = "#9AA5AE", linewidth = 0.4),
        legend.position  = "bottom",
        strip.text       = element_text(face = "bold", hjust = 0),
        plot.background  = element_rect(fill = "white", colour = NA)
      )
  }

  theme_set(theme_rptu())

  update_geom_defaults("point",  list(colour = rptu_farben[["navy"]]))
  update_geom_defaults("line",   list(colour = rptu_farben[["navy"]], linewidth = 0.9))
  update_geom_defaults("smooth", list(colour = rptu_farben[["navy"]]))
  update_geom_defaults("bar",    list(fill = rptu_farben[["navy"]]))
  update_geom_defaults("col",    list(fill = rptu_farben[["navy"]]))

  options(
    ggplot2.discrete.colour = rptu_palette,
    ggplot2.discrete.fill   = rptu_palette
  )
} else {
  message("rptu.R: ggplot2 ist nicht installiert, nur die Farben (rptu_farben) sind angelegt")
}
