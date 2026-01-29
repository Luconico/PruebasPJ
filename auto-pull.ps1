# Auto Pull Script para PruebasPJ
# Solo hace pull si no hay cambios locales pendientes

$projectPath = "d:\GITHUB\RobloxV2\PruebasPJ"

Set-Location $projectPath

# Verificar si hay cambios locales sin commitear
$status = git status --porcelain

if ($status) {
    Write-Host "Hay cambios locales sin commitear. Saltando pull." -ForegroundColor Yellow
    exit 0
}

# Hacer fetch para ver si hay cambios
git fetch origin master

# Comparar local con remoto
$behind = git rev-list --count HEAD..origin/master

if ($behind -gt 0) {
    Write-Host "Hay $behind commit(s) nuevo(s). Haciendo pull..." -ForegroundColor Green
    git pull origin master
    Write-Host "Pull completado." -ForegroundColor Green
} else {
    Write-Host "Ya estás actualizado." -ForegroundColor Cyan
}