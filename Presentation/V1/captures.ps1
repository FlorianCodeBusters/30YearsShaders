# Capture chaque slide du deck en PNG (contrôle visuel, ou PDF de secours).
#   powershell -File captures.ps1 [-Slides 1,5,7] [-Largeur 1920] [-Sortie dossier]
# Le deck doit être servi en local, depuis ce dossier :  python -m http.server 8765
# (le serveur sert apercu.html, la copie du deck que build.py écrit ici)
param(
    [int[]]$Slides = (1..23),
    [int]$Largeur = 1920,
    [string]$Sortie = (Join-Path $PSScriptRoot 'captures'),
    [string]$Page = 'http://localhost:8765/apercu.html'
)
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path $chrome)) { $chrome = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' }
$hauteur = [int]($Largeur * 9 / 16)
New-Item -ItemType Directory -Force $Sortie | Out-Null
$profil = Join-Path $env:TEMP 'deck-captures-profil'
$version = Get-Date -Format 'HHmmss'   # contourne le cache du navigateur
foreach ($n in $Slides) {
    $png = Join-Path $Sortie ('d{0:d2}.png' -f $n)
    $arguments = @('--headless=new', '--hide-scrollbars', "--window-size=$Largeur,$hauteur", '--force-device-scale-factor=1',
        '--virtual-time-budget=6000', "--user-data-dir=$profil", "--screenshot=$png", "$Page`?v=$version#d$n")
    Start-Process -FilePath $chrome -ArgumentList $arguments -Wait -WindowStyle Hidden
}
Get-ChildItem $Sortie -Filter 'd*.png' | Measure-Object | ForEach-Object { "$($_.Count) captures dans $Sortie" }
