Write-Host "**********************************************************************************************"
Write-Host "Script zum anlegen eines neuen Laravel Projekts mit MIX"
Write-Host " - Installiert Laravel UI"
Write-Host " - Installiert Bootstrap mit Authentifizierung"
Write-Host " - Installiert Laravel MIX"
Write-Host " - Installiert JQuery"
Write-Host " - Deinstalliert VITE"
Write-Host " - Passt folgende Dateien für MIX an"
Write-Host "   - webpack.mix.js anlegen"
Write-Host "   - package.json Anpassungen"
Write-Host "   - .env und .env.example Anpassungen"
Write-Host "   - app.blade.php Anpassungen"
Write-Host "   - app.js Anpassungen"
Write-Host "   - bootstrap.js Anpassungen"
Write-Host " - Führt am Ende ein npm run dev aus"
Write-Host " - Erzeugt einen APP_KEY in der .env Datei"
Write-Host ""
Write-Host "Autor: Gregor Schubert"
Write-Host "**********************************************************************************************"
Write-Host ""
Write-Host ""

# Frag nach dem Projektnamen
$projektname = Read-Host "Gib den Projektnamen ein"

# Laravel Projekt erstellen
Write-Host "**********************************************************************************************"
Write-Host "Laravel Projekt erstellen"
Write-Host "**********************************************************************************************"

composer create-project laravel/laravel --prefer-dist $projektname

# In den Projektordner wechseln
Write-Host "**********************************************************************************************"
Write-Host "In den Projektordner wechseln"
Write-Host "**********************************************************************************************"

cd $projektname

# Laravel UI installieren
Write-Host "**********************************************************************************************"
Write-Host "Laravel UI installieren"
Write-Host "**********************************************************************************************"

composer require laravel/ui --no-interaction

# Authentifizierung hinzufügen
Write-Host "**********************************************************************************************"
Write-Host "Bootstrap mit Authentifizierung hinzufügen"
Write-Host "**********************************************************************************************"

php artisan ui bootstrap --auth --no-interaction

# Node-Module und Composer-Update durchführen
Write-Host "**********************************************************************************************"
Write-Host "Node-Module installieren"
Write-Host "**********************************************************************************************"

npm install

Write-Host "**********************************************************************************************"
Write-Host "Composer Update durchführen"
Write-Host "**********************************************************************************************"

composer update

# Laravel Mix installieren
Write-Host "**********************************************************************************************"
Write-Host "Laravel Mix installieren"
Write-Host "**********************************************************************************************"

npm install --save-dev laravel-mix

# webpack.mix.js erstellen
Write-Host "**********************************************************************************************"
Write-Host "webpack.mix.js erstellen"
Write-Host "**********************************************************************************************"

echo "const mix = require('laravel-mix');

mix.js('resources/js/app.js', 'public/js')
    .sass('resources/sass/app.scss', 'public/css');
if (mix.inProduction()) {
    mix.version();
}" | Out-File -FilePath webpack.mix.js -Encoding UTF8

# package.json anpassen
Write-Host "**********************************************************************************************"
Write-Host "package.json anpassen"
Write-Host "**********************************************************************************************"

$jsonContent = Get-Content package.json -Raw | ConvertFrom-Json

# Prüfe, ob die Zeile "type" vorhanden ist, und entferne sie falls notwendig
if ($jsonContent.PSObject.Properties.Name -contains 'type') {
    $jsonContent.PSObject.Properties.Remove('type')
}

# Update der Scripts-Abschnitt
$jsonContent.scripts = @{
    "dev" = "npm run development"
    "development" = "mix"
    "watch" = "mix watch"
    "watch-poll" = "mix watch -- --watch-options-poll=1000"
    "hot" = "mix watch --hot"
    "prod" = "npm run production"
    "production" = "mix --production"
}

# Update der devDependencies-Abschnitt
$jsonContent.devDependencies = @{
    "@popperjs/core" = "^2.10.2"
    "axios" = "^1.1.2"
    "bootstrap" = "^5.2.1"
    "jquery" = "^3.7.1"
    "jquery-ui" = "^1.13.2"
    "laravel-mix" = "^6.0.49"
    "postcss" = "^8.1.14"
    "resolve-url-loader" = "^5.0.0"
    "sass" = "^1.32.11"
    "sass-loader" = "^12.1.0"
}

# Schreibe die aktualisierte JSON-Datei zurück
$jsonContent | ConvertTo-Json | Set-Content package.json


# .env anpassen
Write-Host "**********************************************************************************************"
Write-Host ".env anpassen"
Write-Host "**********************************************************************************************"

(Get-Content .env) | 
    ForEach-Object { 
        $_ -replace '^VITE(.*)$', 'MIX$1'
    } | 
    Set-Content .env


# .env.template anpassen
Write-Host "**********************************************************************************************"
Write-Host ".env.example anpassen"
Write-Host "**********************************************************************************************"

(Get-Content .env.example) | 
    ForEach-Object { 
        $_ -replace '^VITE(.*)$', 'MIX$1'
    } | 
    Set-Content .env.example

# In resources/views/layouts/app.blade.php anpassen
Write-Host "**********************************************************************************************"
Write-Host "resources/views/layouts/app.blade.php anpassen"
Write-Host "**********************************************************************************************"

(Get-Content resources/views/layouts/app.blade.php -Raw) | 
    ForEach-Object { 
        $_ -replace '@vite\(\[.*\]\)', '<link rel="stylesheet" href="{{ mix(''css/app.css'') }}"><script src="{{ mix(''js/app.js'') }}"></script>' -replace '\\', '/'
    } | 
    Set-Content resources/views/layouts/app.blade.php


# Vite und laravel-vite-plugin entfernen
Write-Host "**********************************************************************************************"
Write-Host "Vite und laravel-vite-plugin entfernen"
Write-Host "**********************************************************************************************"

npm remove vite laravel-vite-plugin
Remove-Item vite.config.js -Force

# In resources/js/app.js anpassen
Write-Host "**********************************************************************************************"
Write-Host "resources/js/app.js anpassen"
Write-Host "**********************************************************************************************"

(Get-Content resources/js/app.js -Raw) | ForEach-Object { 
    $_ -replace "import './bootstrap';", "import './bootstrap.js';"
} | Set-Content resources/js/app.js


# JQuery installieren und in bootstrap.js einbinden
Write-Host "**********************************************************************************************"
Write-Host "JQuery installieren und in bootstrap.js einbinden"
Write-Host "**********************************************************************************************"

npm install jquery

$bootstrapPath = "resources/js/bootstrap.js"
$bootstrapContent = Get-Content $bootstrapPath -Raw

# Suchen Sie nach der Zeile "window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';"
$axiosHeaderPosition = $bootstrapContent.IndexOf("window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';")

# Fügen Sie jQuery-Import direkt unter dieser Zeile ein
$updatedBootstrapContent = $bootstrapContent.Insert($axiosHeaderPosition + "window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';".Length, "`r`nimport `$ from 'jquery';`r`nwindow.`$ = window.`jQuery = `$;`r`n")

Set-Content $bootstrapPath -Value $updatedBootstrapContent



# WICHTIG: "defer" aus den Assets in der View entfernen
Write-Host "**********************************************************************************************"
Write-Host "defer aus den Assets in der View entfernen"
Write-Host "**********************************************************************************************"

(Get-Content resources/views/layouts/app.blade.php) | 
    ForEach-Object { $_ -replace '<script src="{{ mix(''js/app.js'') }}" defer></script>', '<script src="{{ mix(''js/app.js'') }}"></script>' } | 
    Set-Content resources/views/layouts/app.blade.php


# Node-Module und Composer-Update durchführen
Write-Host "**********************************************************************************************"
Write-Host "Node-Module installieren"
Write-Host "**********************************************************************************************"

npm install

Write-Host "**********************************************************************************************"
Write-Host "npm run dev ausführen"
Write-Host "**********************************************************************************************"

npm run dev

Write-Host "**********************************************************************************************"
Write-Host "App Key erzeugen"
Write-Host "**********************************************************************************************"

php artisan key:generate

Write-Host "**********************************************************************************************"
Write-Host "Setup abgeschlossen."
Write-Host "**********************************************************************************************"
