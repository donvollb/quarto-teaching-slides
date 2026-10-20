-- Stellen im R-Output farbig einrahmen und nummerieren.
--
--   ::: {.markiert m1="X-squared = 293.37" m2="df = 4" m3="p-value < 2.2e-16"}
--   ```{r}
--   chisq.test(tab_berufe, correct = FALSE)
--   ```
--   :::
--
--   - [1]{.nr} **χ²-Wert**
--   - [2]{.nr} **Freiheitsgrade:** (3 − 1) · (3 − 1) = 4
--
-- m1, m2, … sind Textstellen aus dem Output (jeweils das erste Vorkommen wird
-- markiert). [1]{.nr} ergibt die passende Nummer; fett gesetzter Text direkt
-- danach wird in derselben Farbe gesetzt. Farben: rptu.scss (Markierungen).
-- Englischer Alias für .markiert: .highlighted
--
-- Farben selbst wählen (sonst m1 Dunkelblau, m2 Dunkelgrün, …):
--   ::: {.markiert m1="1.78" m2="-0.16" farben="gruen navy"}    (Alias: colors=)
-- Der n-te Name färbt m<n>. Nummern [n]{.nr} danach auf derselben Folie
-- übernehmen die Farben des zuletzt davor stehenden markierten Blocks.
-- Statt Farbnamen gehen Rollen aus den Metadaten (_quarto.yml oder Kopf):
--   markierung-rollen:                                          (Alias: highlight-roles)
--     intercept: gruen
--     slope: navy

-- Farbnamen (wie $rptu-markierung-farben in rptu.scss)
local FARBEN = {
  navy = true, hellblau = true, blaugrau = true, petrol = true, teal = true, gruen = true,
  orange = true, violett = true, pink = true, rot = true, grau = true,
}

local rollen = {}         -- Rolle -> Farbname (aus den Metadaten)
local folien_farben = {}  -- Nummer -> Farbname, gilt bis zur nächsten Folie

local function warnung(text)
  io.stderr:write("WARNUNG (markieren.lua): " .. text .. "\n")
end

-- Farbklasse für Nummer nr: gewählte Farbe oder die feste Farbe der Nummer
local function farbklasse(nr, farben)
  local f = farben[nr]
  if f then return "farbe-" .. f end
  return "m" .. nr
end

local function html_escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Output-Text mit <span>-Markierungen als HTML
local function markiert(text, stellen, gefunden, farben)
  local treffer = {}
  for _, st in ipairs(stellen) do
    local a, e = text:find(st.text, 1, true)
    if a then
      gefunden[st.nr] = true
      treffer[#treffer + 1] = { a = a, e = e, nr = st.nr }
    end
  end
  table.sort(treffer, function(x, y) return x.a < y.a end)

  local html, pos = {}, 1
  for _, t in ipairs(treffer) do
    if t.a >= pos then -- überlappende Markierungen auslassen
      html[#html + 1] = html_escape(text:sub(pos, t.a - 1))
      html[#html + 1] = string.format('<span class="markierung %s" data-nr="%d">%s</span>',
        farbklasse(t.nr, farben), t.nr, html_escape(text:sub(t.a, t.e)))
      pos = t.e + 1
    end
  end
  html[#html + 1] = html_escape(text:sub(pos))
  return "<pre><code>" .. table.concat(html) .. "</code></pre>"
end

local function ist_output(div)
  for _, k in ipairs(div.classes) do
    if k:match("^cell%-output") then return true end
  end
  return false
end

-- farben="gruen navy" bzw. colors=: Liste Nummer -> Farbname (Rollen aufgelöst)
local function farben_lesen(div)
  local wert = div.attributes["farben"] or div.attributes["colors"]
  div.attributes["farben"] = nil
  div.attributes["colors"] = nil
  local farben = {}
  if not wert then return farben end
  local n = 0
  for name in wert:gmatch("%S+") do
    n = n + 1
    local farbe = rollen[name] or name
    if FARBEN[farbe] then
      farben[n] = farbe
    else
      warnung(string.format('unbekannte Farbe oder Rolle "%s" in farben= (m%d bleibt in der Standardfarbe)',
        name, n))
    end
  end
  return farben
end

local function markierter_block(div)
  if not (div.classes:includes("markiert") or div.classes:includes("highlighted")) then
    return nil
  end

  local farben = farben_lesen(div)
  folien_farben = farben

  local stellen = {}
  for k, v in pairs(div.attributes) do
    local nr = k:match("^m(%d+)$")
    if nr then stellen[#stellen + 1] = { nr = tonumber(nr), text = v } end
  end
  table.sort(stellen, function(x, y) return x.nr < y.nr end)

  local gefunden = {}
  div = div:walk({
    Div = function(d)
      if not ist_output(d) then return nil end
      d.content = d.content:map(function(b)
        if b.t == "CodeBlock" then
          return pandoc.RawBlock("html", markiert(b.text, stellen, gefunden, farben))
        end
        return b
      end)
      return d
    end
  })

  for _, st in ipairs(stellen) do
    if not gefunden[st.nr] then
      warnung(string.format('Markierung m%d "%s" nicht im Output gefunden', st.nr, st.text))
    end
  end
  return div
end

-- [1]{.nr}: Klasse für die Farbe ergänzen; direkt folgenden Fettdruck einfärben
local function nummern(inlines)
  for i, el in ipairs(inlines) do
    if el.t == "Span" and el.classes:includes("nr") then
      local nr = pandoc.utils.stringify(el):match("^%s*(%d+)%s*$")
      if nr then
        local klasse = farbklasse(tonumber(nr), folien_farben)
        el.classes:insert(klasse)
        local naechstes = inlines[i + 1]
        if naechstes and naechstes.t == "Space" then naechstes = inlines[i + 2] end
        if naechstes and naechstes.t == "Strong" then
          local idx = (inlines[i + 1].t == "Space") and i + 2 or i + 1
          inlines[idx] = pandoc.Span({ naechstes }, pandoc.Attr("", { "nr-text", klasse }))
        end
      end
    end
  end
  return inlines
end

-- markierung-rollen: { rolle: farbname } (Alias highlight-roles)
local function rollen_lesen(meta)
  local m = meta["markierung-rollen"] or meta["highlight-roles"]
  if type(m) ~= "table" then return end
  for rolle, wert in pairs(m) do
    local farbe = pandoc.utils.stringify(wert)
    if FARBEN[farbe] then
      rollen[rolle] = farbe
    else
      warnung(string.format('unbekannte Farbe "%s" für die Rolle "%s" in markierung-rollen', farbe, rolle))
    end
  end
end

-- Blöcke in Reihenfolge des Dokuments (topdown): ein markierter Block legt die
-- Farben für die folgenden Nummern fest, eine neue Folie setzt sie zurück
return {
  { Meta = rollen_lesen },
  {
    traverse = "topdown",
    Header = function(h)
      if h.level <= 2 then folien_farben = {} end
    end,
    Div = markierter_block,
    Inlines = nummern,
  },
}
