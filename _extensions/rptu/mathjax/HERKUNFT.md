# MathJax (eingebettet für Formeln ohne Internet)

- Datei: `tex-svg-full.js` aus MathJax 3.2.2, unverändert
- Quelle: <https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-svg-full.js>
  (identisch mit <https://unpkg.com/mathjax@3.2.2/es5/tex-svg-full.js>)
- SHA-256: `a4354ff94fd868aea0cc6eaaa79a57fda0588646fc46ee3700a349ee0a11cbe6`
- Lizenz: Apache License 2.0, siehe `LICENSE` in diesem Ordner
  (Copyright The MathJax Consortium)

`post-render.R` bettet diese Datei in jeden Foliensatz mit Formeln ein. Die SVG-Ausgabe
bringt ihre Schriften selbst mit; so funktionieren Formeln im Vortrag und beim Drucken
des Handouts ohne Internetverbindung.
