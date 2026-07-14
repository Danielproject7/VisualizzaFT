# =============================================================
# Fix Babel runtime — parte 2
# Aggiunge SOLO la registrazione del preset "react-classic"
# necessaria dopo aver applicato la prima patch.
# =============================================================

$ErrorActionPreference = 'Stop'
$file = 'C:\Apps\VisualizzaXML\index.html'

Write-Host ''
Write-Host '=== Fix Babel runtime (parte 2) ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $file)) {
  Write-Host "[ERRORE] File non trovato: $file" -ForegroundColor Red
  Read-Host 'Premi INVIO per uscire'
  exit 1
}

$backup = "$file.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $file $backup
Write-Host "[OK] Backup: $backup" -ForegroundColor Green

$content = Get-Content $file -Raw -Encoding UTF8

# Verifica se gia patchato
if ($content -match 'registerClassicPreset') {
  Write-Host '[INFO] Registrazione preset gia presente. Niente da fare.' -ForegroundColor Yellow
  Read-Host 'Premi INVIO per chiudere'
  exit 0
}

# Cerca il tag babel (dovrebbe essere gia react-classic dopo la patch 1)
$anchor = '<script type="text/babel" data-presets="react-classic">'
if ($content -notmatch [regex]::Escape($anchor)) {
  # Fallback: forse la patch 1 non e stata applicata
  $anchor = '<script type="text/babel" data-presets="react">'
  if ($content -notmatch [regex]::Escape($anchor)) {
    Write-Host '[ERRORE] Non trovo il tag <script type="text/babel">. Il file non e nel formato atteso.' -ForegroundColor Red
    Read-Host 'Premi INVIO per uscire'
    exit 1
  }
  Write-Host '[INFO] Tag ancora "react", lo cambio in "react-classic".' -ForegroundColor Yellow
  $content = $content.Replace($anchor, '<script type="text/babel" data-presets="react-classic">')
  $anchor = '<script type="text/babel" data-presets="react-classic">'
}

# Inserisce il blocco di registrazione preset PRIMA del tag babel
$preset = @'
<script>
  // Registra un preset React con runtime CLASSIC (senza import automatici).
  // Necessario perche babel-standalone di default emette
  // `import { jsx } from "react/jsx-runtime"` — non eseguibile senza type="module".
  (function registerClassicPreset() {
    if (typeof Babel === 'undefined') { setTimeout(registerClassicPreset, 30); return; }
    if (Babel.availablePresets && Babel.availablePresets['react-classic']) return;
    Babel.registerPreset('react-classic', {
      presets: [ [Babel.availablePresets['react'], { runtime: 'classic' }] ]
    });
  })();
</script>

'@

$content = $content.Replace($anchor, $preset + $anchor)
Write-Host '[OK] Registrazione preset "react-classic" aggiunta prima del tag babel.' -ForegroundColor Green

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($file, $content, $utf8NoBom)

Write-Host ''
Write-Host '=== FATTO ===' -ForegroundColor Cyan
Write-Host 'Ricarica il browser con Ctrl+F5.' -ForegroundColor Green
Write-Host ''
Read-Host 'Premi INVIO per chiudere'
