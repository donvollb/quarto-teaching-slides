-- Handout-Version der Folien (Metadatum handout: true, z. B. quarto render -M handout:true)
--
-- Normal (Vortrag) bleibt alles, wie es ist. Im Handout gilt:
--   ![](bild.png){.no-handout}       Bild wird ausgeblendet, sein Platz bleibt frei
--   ::: {.no-handout} ... :::        Block/Spalte wird ausgeblendet, Platz bleibt frei
--   ## Titel {.no-handout}           ganze Folie entfällt
--   Animationen entfallen: Pausen (. . .), .fragment und .incremental
--
-- Freie Flächen (Klasse .handout-blank, visibility: hidden) halten das Layout
-- in beiden Versionen gleich. Das PDF erzeugt post-render.R.

local handout = false

local function ist_pause(b)
  return b.t == "Para" and pandoc.utils.stringify(b) == ". . ."
end

local function no_handout_folie(b)
  return b.t == "Header" and b.level <= 2 and b.classes:includes("no-handout")
end

-- Ende einer Folie: nächste Folienüberschrift oder von Quarto angehängte Blöcke
-- (u. a. die Fußzeile in .quarto-auto-generated-content)
local function folienende(b)
  return (b.t == "Header" and b.level <= 2)
    or (b.t == "Div" and (b.classes:includes("quarto-auto-generated-content")
                          or b.classes:includes("footer")
                          or b.classes:includes("hidden")))
end

local function folien_filtern(blocks)
  local out = pandoc.List()
  local i = 1
  while i <= #blocks do
    if no_handout_folie(blocks[i]) then
      i = i + 1
      while i <= #blocks and not folienende(blocks[i]) do
        i = i + 1
      end
    else
      out:insert(blocks[i])
      i = i + 1
    end
  end
  return out
end

local function klassen_entfernen(classes, namen)
  return classes:filter(function(c) return not namen[c] end)
end

local ANIMATION = { fragment = true, incremental = true, nonincremental = true }

local function element(el)
  if not handout or el.classes == nil then return nil end
  el.classes = klassen_entfernen(el.classes, ANIMATION)
  if el.classes:includes("no-handout") then
    el.classes:insert("handout-blank")
  end
  return el
end

return {
  {
    Meta = function(meta)
      handout = meta.handout == true
      if handout then
        meta.incremental = false
        return meta
      end
    end,
  },
  {
    Blocks = function(blocks)
      if handout then
        return blocks:filter(function(b) return not ist_pause(b) end)
      end
    end,
    Image = element,
    Span = element,
    Div = element,
    Header = function(h)
      -- no-handout-Folien werden unten im Ganzen entfernt
      if handout then h.classes = klassen_entfernen(h.classes, ANIMATION); return h end
    end,
    Pandoc = function(doc)
      -- Foliennummer wie im Vortrag merken (data-folie), damit sie im Handout
      -- trotz entfallener Folien stimmt (druck.html setzt sie im PDF ein).
      -- Ebenso die Abschnittsnummer (nr, sonst zählt abschnitte.lua erst nach
      -- dem Entfernen und die Nummern rücken auf)
      local nr = doc.meta.title and 1 or 0
      local abschnitt = 0
      for _, b in ipairs(doc.blocks) do
        if b.t == "Header" and b.level <= 2 then
          nr = nr + 1
          b.attributes["folie"] = tostring(nr)
        end
        if b.t == "Header" and b.level == 1 and not b.attributes["nr"] then
          abschnitt = abschnitt + 1
          b.attributes["nr"] = string.format("%02d", abschnitt)
        end
      end
      if handout then
        doc.blocks = folien_filtern(doc.blocks)
      end
      return doc
    end,
  },
}
