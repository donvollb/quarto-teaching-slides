-- Pausen (". . .") überall in Fragmente umwandeln.
-- Pandoc erkennt Pausen nur direkt auf Folienebene; sobald eine Folie
-- ###-Zwischenüberschriften oder Spalten enthält, bleiben sie als Text stehen.
-- Alles nach einer Pause (bis zur nächsten Folie) wird in ein Fragment gepackt.

local function ist_pause(b)
  return b.t == "Para" and pandoc.utils.stringify(b) == ". . ."
end

local function folienende(b)
  return (b.t == "Header" and b.level <= 2) or b.t == "HorizontalRule"
end

local function umwandeln(blocks)
  local out = pandoc.List()
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    if ist_pause(b) then
      local rest = pandoc.List()
      local j = i + 1
      while j <= #blocks and not folienende(blocks[j]) do
        rest:insert(blocks[j])
        j = j + 1
      end
      out:insert(pandoc.Div(umwandeln(rest), pandoc.Attr("", { "fragment" })))
      i = j
    else
      out:insert(b)
      i = i + 1
    end
  end
  return out
end

return {
  {
    Div = function(d)
      d.content = umwandeln(d.content)
      return d
    end,
    Pandoc = function(doc)
      doc.blocks = umwandeln(doc.blocks)
      return doc
    end,
  },
}
