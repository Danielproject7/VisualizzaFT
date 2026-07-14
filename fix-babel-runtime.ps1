# =============================================================
# Fix Babel runtime — risolve "Timeout: lo script React/Babel
# non si è avviato"
#
# Causa: babel-standalone usa il nuovo JSX runtime "automatic"
# che emette `import { jsx } from "react/jsx-runtime"`, NON
# eseguibile come script classico nel browser.
#
# Soluzione: registra un preset React con runtime classico
# prima del <script type="text/babel">.
#
# Uso: clic destro → "Esegui con PowerShell"
#      (oppure: powershell -ExecutionPolicy Bypass -File fix-babel-runtime.ps1)
# =============================================================

$ErrorActionPreference = 'Stop'
$file = 'C:\Apps\VisualizzaXML\index.html'

Write-Host ''
Write-Host '=== Fix Babel runtime ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $file)) {
  Write-Host "[ERRORE] File non trovato: $file" -ForegroundColor Red
  Write-Host 'Modifica la variabile $file in questo script se il percorso e diverso.' -ForegroundColor Yellow
  Read-Host 'Premi INVIO per uscire'
  exit 1
}

# Backup con timestamp
$backup = "$file.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $file $backup
Write-Host "[OK] Backup creato: $backup" -ForegroundColor Green

# Leggi file intero
$content = Get-Content $file -Raw -Encoding UTF8

# === PATCH 1: data-presets="react" -> "react-classic" ===
$oldTag = '<script type="text/babel" data-presets="react">'
$newTag = '<script type="text/babel" data-presets="react-classic">'

if ($content -notmatch [regex]::Escape($oldTag)) {
  if ($content -match [regex]::Escape($newTag)) {
    Write-Host '[INFO] Patch gia applicata (data-presets="react-classic" gia presente).' -ForegroundColor Yellow
  } else {
    Write-Host '[ERRORE] Tag <script type="text/babel" data-presets="react"> non trovato nel file.' -ForegroundColor Red
    Write-Host 'Il file potrebbe essere stato modificato manualmente. Patch annullata.' -ForegroundColor Yellow
    exit 1
  }
} else {
  $content = $content.Replace($oldTag, $newTag)
  Write-Host '[OK] Tag babel aggiornato a runtime classico.' -ForegroundColor Green
}

# === PATCH 2: rimpiazza il blocco diagnostico per registrare il preset ===
$oldBlock = @'
<script>
  // Show error if React/Babel fail to bootstrap within 5s
  window.addEventListener('error', function(e){
    var box = document.getElementById('boot-error');
    if (box) { box.style.display='block'; box.textContent = 'Errore di caricamento: '+(e.message||e.error||e); }
  });
  setTimeout(function(){
    var fb = document.getElementById('boot-fallback');
    if (fb && fb.parentNode && fb.parentNode.id === 'root') {
      var box = document.getElementById('boot-error');
      if (box) { box.style.display='block'; box.textContent = 'Timeout: lo script React/Babel non si è avviato. Possibili cause: CDN bloccato, errore di sintassi, network restrittiva. Apri il file localmente o controlla la console (F12).'; }
    }
  }, 8000);
</script>
'@

$newBlock = @'
<script>
  window.__bootErrors = [];
  window.addEventListener('error', function(e){
    if (e.target && e.target.src) {
      window.__bootErrors.push('CDN fallito: ' + e.target.src);
    } else {
      var box = document.getElementById('boot-error');
      if (box) { box.style.display='block'; box.textContent = 'Errore JS: '+(e.message||e.error||e); }
    }
  }, true);

  // Registra un preset React con runtime CLASSIC.
  // Necessario perche babel-standalone di default usa "automatic" che emette
  // import { jsx } from "react/jsx-runtime" — non eseguibile in un browser
  // senza type="module".
  function registerClassicPreset() {
    if (typeof Babel === 'undefined') { setTimeout(registerClassicPreset, 30); return; }
    Babel.registerPreset('react-classic', {
      presets: [ [Babel.availablePresets['react'], { runtime: 'classic' }] ]
    });
  }
  registerClassicPreset();

  // Diagnostica dopo 10s: dice precisamente cosa manca
  setTimeout(function(){
    var fb = document.getElementById('boot-fallback');
    if (!fb || !fb.parentNode || fb.parentNode.id !== 'root') return;
    var box = document.getElementById('boot-error');
    if (!box) return;
    box.style.display='block';
    var missing = [];
    if (typeof React === 'undefined')    missing.push('React (unpkg)');
    if (typeof ReactDOM === 'undefined') missing.push('ReactDOM (unpkg)');
    if (typeof Babel === 'undefined')    missing.push('Babel (unpkg)');
    if (typeof XLSX === 'undefined')     missing.push('SheetJS (jsdelivr)');
    if (typeof jspdf === 'undefined')    missing.push('jsPDF (cdnjs)');
    if (typeof JSZip === 'undefined')    missing.push('JSZip (cdnjs)');
    var msg = 'Timeout: app non avviata in 10s.\n\n';
    if (missing.length) {
      msg += 'CDN non caricati: ' + missing.join(', ') + '\n\nAdblocker o rete restrittiva? Ricarica (Ctrl+F5), disabilita estensioni, prova altra rete.';
    } else {
      msg += 'Tutti i CDN caricati ma app non parte.\nProbabile errore JS. Apri F12 → Console.\n';
      if (window.__bootErrors.length) msg += '\nErrori catturati:\n' + window.__bootErrors.join('\n');
    }
    box.textContent = msg;
  }, 10000);
</script>
'@

if ($content -notmatch [regex]::Escape($oldBlock)) {
  if ($content -match 'registerClassicPreset') {
    Write-Host '[INFO] Blocco diagnostico gia patchato.' -ForegroundColor Yellow
  } else {
    Write-Host '[WARN] Blocco diagnostico originale non trovato — la patch del tag basta.' -ForegroundColor Yellow
  }
} else {
  $content = $content.Replace($oldBlock, $newBlock)
  Write-Host '[OK] Blocco diagnostico aggiornato (registra preset classico + diagnostica CDN dettagliata).' -ForegroundColor Green
}

# Salva
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($file, $content, $utf8NoBom)

Write-Host ''
Write-Host '=== FATTO ===' -ForegroundColor Cyan
Write-Host 'File aggiornato. Ricarica il browser (Ctrl+F5) per vedere il fix.' -ForegroundColor Green
Write-Host "Backup in: $backup" -ForegroundColor Gray
Write-Host ''
Read-Host 'Premi INVIO per chiudere'
