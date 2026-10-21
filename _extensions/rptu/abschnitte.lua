-- Nummeriert die Abschnitte (# Überschrift) fortlaufend: Attribut nr="01", "02", …
-- Landet als data-nr an der Abschnittsfolie; das Theme kann die Nummer anzeigen.
--
-- Mit abschnitt-anzeige: true (englisch section-indicator: true) bekommen die
-- Folien (##) eines Abschnitts zusätzlich data-abschnitt (Titel des Abschnitts
-- oder dessen Kurzform kurz="…"/short="…") und data-abschnitt-nr; das Theme zeigt
-- beides klein über dem Folientitel. Folien vor dem ersten Abschnitt und
-- .vor-titel-Folien bleiben ohne Anzeige.

local n = 0
local anzeige = false
local titel, nr = nil, nil

local function vor_titel(h)
  return h.classes:includes("vor-titel") or h.classes:includes("before-title")
end

return {
  {
    Meta = function(meta)
      anzeige = meta["abschnitt-anzeige"] == true or meta["section-indicator"] == true
    end,
  },
  {
    Header = function(h)
      if h.level == 1 then
        if not h.attributes["nr"] then
          n = n + 1
          h.attributes["nr"] = string.format("%02d", n)
        end
        nr = h.attributes["nr"]
        titel = h.attributes["kurz"] or h.attributes["short"] or pandoc.utils.stringify(h.content)
        return h
      elseif h.level == 2 and anzeige and titel and not vor_titel(h) then
        h.attributes["abschnitt"] = titel
        h.attributes["abschnitt-nr"] = nr
        return h
      end
    end,
  },
}
