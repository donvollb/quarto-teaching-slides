-- Kontakt links in der Fußzeile aus den Metadaten (Dokument oder _quarto.yml):
--
--   kontakt: "Vorname Nachname | name@rptu.de"
--
-- Englischer Alias: contact: (kontakt: hat Vorrang, wenn beide angegeben sind).
-- Der Text wird als CSS-Variable --rptu-kontakt in den Kopf der HTML-Datei
-- geschrieben; rptu.scss zeigt sie mit content: var(--rptu-kontakt) an.
-- Ohne Angabe bleibt die Stelle leer (bzw. zeigt $rptu-kontakt aus dem Theme).

-- Text als CSS-Zeichenkette ("…") schützen
local function css_string(s)
  s = s:gsub("\\", "\\\\")
       :gsub('"', '\\"')
       :gsub("<", "\\3C ")
       :gsub("\r?\n", " ")
  return '"' .. s .. '"'
end

return {
  {
    Meta = function(meta)
      local wert = meta.kontakt
      if wert == nil then wert = meta.contact end
      if not quarto.doc.is_format("html") or wert == nil then return nil end
      local text = pandoc.utils.stringify(wert)
      if text == "" then return nil end
      quarto.doc.include_text("in-header",
        "<style>:root { --rptu-kontakt: " .. css_string(text) .. "; }</style>")
    end,
  },
}
