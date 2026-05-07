# VisualizzaFT

Applicazione web client-only per la gestione, riconciliazione e visualizzazione di **fatture elettroniche italiane (FatturaPA)** e **registri IVA**.

Tutto gira nel browser: nessun upload verso server, nessuna dipendenza backend. Il file `index.html` contiene React + Babel + Tailwind via CDN, oltre a SheetJS, jsPDF e JSZip.

## Funzionalità

- **Carica XML / P7M / ZIP** — supporta file FatturaPA singoli, multipli, cartelle e archivi compressi. Estrae l'XML dagli envelope firmati CAdES-BES (`.p7m`, sia DER sia PEM) e ignora automaticamente i file di metadato SDI.
- **Database analitico** — una riga per ogni combinazione fattura · riga di dettaglio · riepilogo IVA. Filtri liberi, oltre 50 colonne configurabili e raggruppabili, font/dimensione/wrap personalizzabili, blocca riquadri (header sticky + freeze colonne), raggruppamento per fattura con separatori, anteprima PDF a popup, esportazione Excel.
- **Documenti** — vista per documento con riga espandibile (anagrafiche cedente/cessionario, righe di dettaglio, riepiloghi IVA). Stesse personalizzazioni del Database analitico (font, colori, freeze, ecc.) e contrasto configurabile per la riga di dettaglio aperta.
- **Lista fatture ricevute (Agenzia delle Entrate)** — caricamento del CSV scaricato dal portale "Fatture e Corrispettivi" per arricchire i documenti con `Data ricezione`, `Data trasmissione`, `SDI/file`, `Bollo virtuale`. Sort automatico per data ricezione.
- **Registri IVA** — importazione di registri IVA Excel/CSV con riconoscimento automatico del formato:
  - Riassuntivo per periodo · sezionale · codice IVA
  - Per documento (mappatura colonne flessibile)
  - **JasperReports** (`Registro delle fatture di acquisto/vendita`, layout multi-riga) parser dedicato senza wizard
- **Riconciliazione** XML ↔ Registro con tolleranza configurabile, controlli su aliquote, nature, arrotondamenti.
- **Visualizzatore PDF** — anteprima PDF inline (originale incorporato nel p7m oppure generato on-the-fly da jsPDF).
- **Export Excel/PDF/ZIP** — esportazione di qualsiasi vista, batch-download dei PDF di tutte le fatture.

## Avvio

Apri `index.html` direttamente in un browser moderno (Chrome, Edge, Firefox). I dati restano nella tab corrente — nessuna persistenza server-side.

## Privacy

Tutti i dati restano nel browser dell'utente. Le impostazioni di personalizzazione (font, colori, colonne, larghezze, ecc.) sono salvate in `localStorage`. Nessun file viene caricato verso server esterni.
