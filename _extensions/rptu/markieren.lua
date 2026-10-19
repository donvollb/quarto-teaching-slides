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

local function html_escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Output-Text mit <span>-Markierungen als HTML
local function markiert(text, stellen, gefunden)
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
      html[#html + 1] = string.format('<span class="markierung m%d" data-nr="%d">%s</span>',
        t.nr, t.nr, html_escape(text:sub(t.a, t.e)))
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

local function markierter_block(div)
  if not (div.classes:includes("markiert") or div.classes:includes("highlighted")) then
    return nil
  end

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
          return pandoc.RawBlock("html", markiert(b.text, stellen, gefunden))
        end
        return b
      end)
      return d
    end
  })

  for _, st in ipairs(stellen) do
    if not gefunden[st.nr] then
      io.stderr:write(string.format(
        'WARNUNG (markieren.lua): Markierung m%d "%s" nicht im Output gefunden\n', st.nr, st.text))
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
        el.classes:insert("m" .. nr)
        local naechstes = inlines[i + 1]
        if naechstes and naechstes.t == "Space" then naechstes = inlines[i + 2] end
        if naechstes and naechstes.t == "Strong" then
          local idx = (inlines[i + 1].t == "Space") and i + 2 or i + 1
          inlines[idx] = pandoc.Span({ naechstes }, pandoc.Attr("", { "nr-text", "m" .. nr }))
        end
      end
    end
  end
  return inlines
end

return {
  { Div = markierter_block },
  { Inlines = nummern },
}
