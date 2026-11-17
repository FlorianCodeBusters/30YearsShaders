# Rend chaque slide du .pptx de la V2 en PNG avec PowerPoint, puis assemble des planches de contrôle.
#   powershell -File rendu.ps1
param([string]$Sortie = (Join-Path $env:TEMP 'v2-rendu'))
$deck = Join-Path $PSScriptRoot '30 ans de poudre de Perlin (version Corporate).pptx'
Remove-Item $Sortie -Recurse -Force -ErrorAction SilentlyContinue
$Sortie = (New-Item -ItemType Directory -Force $Sortie).FullName
$ppt = New-Object -ComObject PowerPoint.Application
try {
    $pres = $ppt.Presentations.Open($deck, $true, $false, $false)
    $pres.Export($Sortie, 'PNG', 1600, 900)
    $pres.Close()
} finally { $ppt.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) }
"$((Get-ChildItem $Sortie -Filter *.PNG).Count) slides rendues dans $Sortie"
