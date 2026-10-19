-- Nummeriert die Abschnitte (# Überschrift) fortlaufend: Attribut nr="01", "02", …
-- Landet als data-nr an der Abschnittsfolie; das Theme kann die Nummer anzeigen.

local n = 0

return {
  {
    Header = function(h)
      if h.level == 1 and not h.attributes["nr"] then
        n = n + 1
        h.attributes["nr"] = string.format("%02d", n)
        return h
      end
    end,
  },
}
