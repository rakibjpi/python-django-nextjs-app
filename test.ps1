# Prompt the user to enter the project name
$projectName = Read-Host "Enter the project name:"

# Store the current location
$basedir = Get-Location

function goto {
    param (
        [string]$pathOrLevel
    )

    if ($pathOrLevel -match '^\d+$') {
        # If the input is a number, go back that many levels
        $levels = [int]$pathOrLevel
        $currentPath = Get-Location
        for ($i = 0; $i -lt $levels; $i++) {
            $currentPath = Split-Path -Path $currentPath -Parent
        }
        Set-Location -Path $currentPath
    }
    else {
        # Otherwise, treat the input as a path and navigate to it
        Set-Location -Path $pathOrLevel
    }
}

function Search-File {
    param (
        [string]$inputPath,
        [string]$rootDirectory = $basedir
    )

    if ($inputPath -like "*\*") {
        # The input contains a backslash, treat it as a path
        $Global:filePath = Join-Path -Path $rootDirectory -ChildPath $inputPath
        if (Test-Path -Path $Global:filePath) {
            Write-Output "File found: $Global:filePath"
            
        }
        else {
            Write-Output "File not found: $Global:filePath"
           
        }
    }
    else {
        # The input is just a file name, search for the file within the entire directory structure
        $foundFiles = Get-ChildItem -Path $rootDirectory -Recurse -Filter $inputPath
        if ($foundFiles) {
            foreach ($file in $foundFiles) {
                $Global:filePath = $file.FullName
                Write-Output "File found: $Global:filePath"                
                break # Exit after the first match
            }
        }
        else {
            Write-Output "File not found: $inputPath"
            $Global:filePath = $null
        }
    }
}

Function Add-NewLine {
    param(
        [string]$SearchText,
        [string]$StartTag,
        [string]$EndTag,
        [string]$NewLine
    )

    # Get the content of the Python file
    $content = Get-Content -Path $Global:filePath

    # Initialize line numbers
    $firstLine = -1
    $startLine = -1
    $endLine = -1

    # Iterate through each line to find the line numbers
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match [regex]::Escape($SearchText)) {
            $firstLine = $i
        }
        if ($firstLine -ne -1 -and $content[$i] -match [regex]::Escape($StartTag) -and $startLine -eq -1) {
            $startLine = $i
        }
        if ($startLine -ne -1 -and $content[$i] -match [regex]::Escape($EndTag)) {
            $endLine = $i
            break
        }
    }

    if ($firstLine -eq $startLine) {
        Write-Host "$SearchText and $StartTag both are on the same line"
    }

    # Add the new line before the end tag
    if ($endLine -ne -1) {
        $content = $content[0..($endLine - 1)] + "$NewLine" + $content[$endLine..($content.Length - 1)]
    }

    # Write the updated content back to the file
    $content | Set-Content -Path $Global:filePath
}


Function Add-Line {
    param(
        [string]$Line,
        [int]$LineNumber
    )

    $LineNumber = $LineNumber - 1
    # Get the content of the file
    $content = Get-Content -Path $Global:filePath

    # Ensure the LineNumber is within the valid range
    if ($LineNumber -lt 0 -or $LineNumber -gt $content.Length) {
        Write-Error "LineNumber is out of range."
        return
    }

    # Insert the new line at the specified line number
    $newContent = $content[0..($LineNumber - 1)] + $Line + $content[$LineNumber..($content.Length - 1)]

    # Write the updated content back to the file
    $newContent | Set-Content -Path $Global:filePath
}

function ReplaceLine {
    param (
        [string]$ReplaceText,
        [string]$NewText
    )

    # Get the content of the file
    $content = Get-Content -Path $Global:filePath -Raw

    # Replace the text
    $updatedContent = $content -replace [regex]::Escape($ReplaceText), $NewText

    # Write the updated content back to the file
    $updatedContent | Set-Content -Path $Global:filePath
}
function web-content {
    param (
        [string]$WebLink,
        [string]$LocalPath,
        [string]$FileName
    )
    
    # Create the full path with the specified file name
    $FullPath = Join-Path -Path $LocalPath -ChildPath $FileName
    
    try {
        # Download the content from the web link
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($WebLink, $FullPath)
        Write-Output "File downloaded successfully to $FullPath"
    }
    catch {
        Write-Error "Failed to download the file. Error: $_"
    }
}

# Function to create directories
function CreateDirectories {
    param (
        [string[]]$directories
    )
    foreach ($directory in $directories) {
        try {
            New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "Directory created: $directory"
        }
        catch {
            Write-Host "Failed to create directory: $directory" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }
}

$Projectdir = "$basedir\$projectName"

# Create main directories
$mainDirectories = @(
    "$Projectdir",
    "$Projectdir\Backends",
    "$Projectdir\Frontends"
)
CreateDirectories $mainDirectories

# Set location to project directory
goto $Projectdir

# Create virtual environment
python -m venv venv

# Activate virtual environment
$activateScript = ".\venv\Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    Write-Host "Activating virtual environment..."
    . $activateScript
}
else {
    Write-Host "Could not find activation script. Please activate the virtual environment manually." -ForegroundColor Yellow
}

# Upgrade pip
python.exe -m pip install --upgrade pip

# Install required packages
$requiredPackages = @(
    "requests",
    "colorama",
    "django",
    "djangorestframework",
    #"pygments",
    "django-cors-headers",
    #"markdown",
    "django-filter"
    #"django-oauth-toolkit",
    #"djangorestframework-oauth"
)
$requiredPackages | ForEach-Object { & .\venv\Scripts\python.exe -m pip install $_ }

$DjangoDirectory = "$Projectdir\Backends"

#$ReactDirectory = "$Projectdir\Frontends"

goto $DjangoDirectory

$AppDirectory = "$DjangoDirectory\$projectName"

# Create Django project
django-admin startproject $projectName

# Define the directory structure
$staticDirectories = @(
    "$DjangoDirectory\$projectName\static\css",
    "$DjangoDirectory\$projectName\static\js",
    "$DjangoDirectory\$projectName\static\img",
    "$DjangoDirectory\$projectName\static\vendor\bootstrap\css",
    "$DjangoDirectory\$projectName\static\vendor\bootstrap\js",
    "$DjangoDirectory\$projectName\static\vendor\bootstrap\popper\js",

    "$DjangoDirectory\$projectName\static\vendor\fontawesome\css",
    "$DjangoDirectory\$projectName\static\vendor\fontawesome\js",
    "$DjangoDirectory\$projectName\static\vendor\fontawesome\webfonts",

    "$DjangoDirectory\$projectName\static\vendor\googleapis\fonts\css",
    "$DjangoDirectory\$projectName\static\vendor\googleapis\js"
)

$mediaDirectories = @(
    "$DjangoDirectory\$projectName\media",
    "$DjangoDirectory\$projectName\media\user_images",
    "$DjangoDirectory\$projectName\media\personalise",
    "$DjangoDirectory\$projectName\media\personalise\themes"
)

$templatesBaseDirectory = "$DjangoDirectory\$projectName\templates"
$templatesDirectories = @(
    $templatesBaseDirectory,
    "$templatesBaseDirectory\components"
)

# Create directories
CreateDirectories $staticDirectories
CreateDirectories $mediaDirectories
CreateDirectories $templatesDirectories

Write-Host "Virtual environment created and Django project '$projectName' set up successfully." -ForegroundColor Green


web-content -WebLink "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" -LocalPath "$DjangoDirectory\$projectName\static\vendor\bootstrap\css" -FileName "bootstrap.min.css"
web-content -WebLink "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" -LocalPath "$DjangoDirectory\$projectName\static\vendor\bootstrap\js" -FileName "bootstrap.bundle.min.js"
web-content -WebLink "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js" -LocalPath "$DjangoDirectory\$projectName\static\vendor\bootstrap\popper\js" -FileName "popper.min.js"

# Define the URLs and the destination directory
$fontawesomecssurls = @(
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/brands.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/brands.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/fontawesome.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/fontawesome.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/regular.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/regular.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/solid.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/solid.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/svg-with-js.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/svg-with-js.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/v4-font-face.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/v4-font-face.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/v4-shims.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/v4-shims.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/v5-font-face.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/v5-font-face.min.css"
)

# Download each file
foreach ($url in $fontawesomecssurls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    web-content -WebLink $url -LocalPath "$DjangoDirectory\$projectName\static\vendor\fontawesome\css" -FileName $fileName
}


# Define the URLs and the destination directory
$fontawesomejsurls = @(
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/all.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/all.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/brands.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/brands.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/conflict-detection.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/conflict-detection.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/fontawesome.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/fontawesome.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/regular.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/regular.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/solid.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/solid.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/v4-shims.js",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/v4-shims.min.js"
)

# Download each file
foreach ($url in $fontawesomejsurls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    web-content -WebLink $url -LocalPath "$DjangoDirectory\$projectName\static\vendor\fontawesome\js" -FileName $fileName
}

# Define the URLs and the destination directory
$fontawesomewebfontUrls = @(
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-brands-400.ttf",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-brands-400.woff2",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-regular-400.ttf",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-regular-400.woff2",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-solid-900.ttf",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-solid-900.woff2",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-v4compatibility.ttf",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/webfonts/fa-v4compatibility.woff2"
)

# Download each file
foreach ($url in $fontawesomewebfontUrls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    web-content -WebLink $url -LocalPath "$DjangoDirectory\$projectName\static\vendor\fontawesome\webfonts" -FileName $fileName
}

$GoogleFontPath = "$DjangoDirectory\$projectName\static\vendor\googleapis\fonts\css"
#Google Api Font
$GoogleFont = "https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Galada&family=Mina:wght@400;700&family=Oswald:wght@200..700&family=PT+Serif:ital,wght@0,400;0,700;1,400;1,700&family=Playfair+Display:ital,wght@0,400..900;1,400..900&family=Roboto+Condensed:ital,wght@0,100..900;1,100..900&family=Tiro+Bangla:ital@0;1&display=swap"
web-content -WebLink $GoogleFont -LocalPath $GoogleFontPath -FileName "googleapisfont.css"




# Create example files for other directories
$exampleFiles = @{
    "$projectName\static\css\base.css"                 = "/* Example CSS for base styles */"
    "$projectName\static\css\styles.css"               = @"
/* Example CSS for custom styles */
body {
    background: #007bff;
    background: linear-gradient(to right, #0062E6, #33AEFF);
  }
  
  .btn-login {
    font-size: 0.9rem;
    letter-spacing: 0.05rem;
    padding: 0.75rem 1rem;
  }
  
  .btn-google {
    color: white !important;
    background-color: #ea4335;
  }
  
  .btn-facebook {
    color: white !important;
    background-color: #3b5998;
  }
  
"@
    "$projectName\static\js\main.js"                   = "// Example JavaScript for main functionality"
    "$projectName\static\js\scripts.js"                = "// Example JavaScript for additional scripts"
    "$projectName\static\img\logo.png"                 = ""
    "$projectName\static\img\background.jpg"           = ""
    "$projectName\templates\base.html"                 = @"
{% load static %} 
{% load custom_filters %}
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{% block title %}{% endblock %}</title>
    <link
      rel="stylesheet"
      href="{% static 'vendor/bootstrap/css/bootstrap.min.css' %}"
    />
    <link
      rel="stylesheet"
      href="{% static 'vendor/fontawesome/css/all.min.css' %}"
    />
    {% block head %}{% endblock %}
    
  </head>
  <body>
    {% block nav %} {% endblock %} 
    {% block header %} {% endblock %}
    <div class="container">      
       
      {% block content %}{% endblock %} 
      
    </div>
    {% block footer %}{% endblock %}
    <script src="{% static 'vendor/bootstrap/js/bootstrap.bundle.min.js' %}"></script>
    <script src="{% static 'vendor/fontawesome/js/all.min.js' %}"></script>
    {% block scripts %}{% endblock %}
  </body>
</html>


"@

    
    "$templatesBaseDirectory\components\navbar.html"   = @"
<!-- Example navbar template -->
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container-fluid">
        <a class="navbar-brand" href="{% url 'home' %}"> $projectName </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                <li class="nav-item">
                    <a class="nav-link" href="{% url 'home' %}">Home</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="{% url 'profile' %}">Profile</a>
                </li>
            </ul>
            <ul class="navbar-nav">
                {% if user.is_authenticated %}
                    <li class="nav-item">
                        <form method="post" action="{% url 'logout' %}" class="d-inline">
                            {% csrf_token %}
                            <button type="submit" class="btn btn-link nav-link" style="border: none; padding: 0;">Logout</button>
                        </form>
                    </li>
                {% else %}
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'login' %}">Login</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'login' %}">Sign Up</a>
                    </li>
                {% endif %}
            </ul>
        </div>
    </div>
</nav>

"@
    "$templatesBaseDirectory\components\header.html"   = @"
<!-- Example navbar template -->
<header class="container-fluid bg-dark py-3">
    <div class="container">
        <nav class="navbar navbar-expand-lg navbar-dark">
            <div class="container">
                <a class="navbar-brand" href="#">Welcome to My Site</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav ms-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="#">Link 1</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">Link 2</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">Link 3</a>
                        </li>
                        <!-- Add more navigation links as needed -->
                    </ul>
                </div>
            </div>
        </nav>
    </div>
</header>


"@
    "$templatesBaseDirectory\components\main.html"     = @"
<!-- Example navbar template -->
<main>
        {% block content %}{% endblock %}
</main>

"@
    "$templatesBaseDirectory\components\footer.html"   = @"
<!-- Example footer template -->

<footer class="footer mt-auto py-3 bg-dark text-light py-4">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <h5>Footer Section 1</h5>
                    <p>This is some text for the first section of the footer.</p>
                </div>
                <div class="col-md-6">
                    <h5>Footer Section 2</h5>
                    <p>This is some text for the second section of the footer.</p>
                </div>
            </div>
            <div class="row mt-3">
                <div class="col">
                    <p>&copy; 2024 Your Company. All rights reserved.</p>
                </div>
            </div>
        </div>
    </footer>
    

"@
    "$templatesBaseDirectory\components\carousel.html" = "<!-- Example carousel component -->"
    "$templatesBaseDirectory\components\sidebar.html"  = "<!-- Example sidebar component -->"
    "$templatesBaseDirectory\components\modal.html"    = "<!-- Example modal component -->"
    
}

# Create example files
foreach ($file in $exampleFiles.GetEnumerator()) {
    try {
        Set-Content -Path $file.Key -Value $file.Value -Force -ErrorAction Stop
        Write-Host "Example file created: $($file.Key)"
    }
    catch {
        Write-Host "Failed to create example file: $($file.Key)" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}






# Define the package name to append to INSTALLED_APPS
$packageName = @"
    'rest_framework',  # Django Rest Framework
    #'rest_framework.authtoken',  #token authentication
    #'oauth2_provider', #Django OAuth Toolkit package provides
    'corsheaders',      # django-cors-headers
    #'markdown',         # If you're using Markdown
    'django_filters',   # django-filter
"@

Search-File -inputPath "settings.py"
Add-NewLine -SearchText "INSTALLED_APPS" -StartTag "[" -EndTag "]" -NewLine ($packageName)
Write-Host "Django Rest Framework and other packages added to INSTALLED_APPS." -ForegroundColor Green

# Define the middleware lines for each package
$middlewareLines = @"
    #'rest_framework.authentication.SessionAuthentication',
    'corsheaders.middleware.CorsMiddleware',  
    #'django_filters.middleware.FilteringMiddleware',
"@

Search-File -inputPath "settings.py"
Add-NewLine -SearchText "MIDDLEWARE" -StartTag "[" -EndTag "]" -NewLine ($middlewareLines)
Write-Host "Middleware lines added for the packages." -ForegroundColor Green


Search-File -inputPath "settings.py"
$OldTIME = "TIME_ZONE = 'UTC'"
$newTIME = "TIME_ZONE = 'Asia/Dhaka'"
ReplaceLine -ReplaceText ($OldTIME) -NewText ($newTIME)
Write-Host "Replace Text for $OldTIME"-ForegroundColor DarkGreen

Search-File -inputPath "settings.py"
$OldDIRS = "'DIRS': [],"
$newDIRS = "'DIRS': [os.path.join(BASE_DIR, 'templates')],"
ReplaceLine -ReplaceText ($OldDIRS) -NewText ($newDIRS)
Write-Host "Replace Text for $OldDIRS"-ForegroundColor DarkGreen

Search-File -inputPath "settings.py"
$oldValueStatic = "STATIC_URL = 'static/'"
$newValueStatic = @"


CORS_ORIGIN_WHITELIST = (
	'http://localhost:3000',
    'http://192.168.100.15:3000', 
)

# CORS_ALLOW_ALL_ORIGINS = True  # Allow requests from all origins

# Alternatively, you can specify specific origins
# CORS_ALLOWED_ORIGINS = [
#     'http://example.com',
#     'https://example.com',
# ]

# Optional CORS settings

# Allow specific headers in the requests
# CORS_ALLOW_HEADERS = [
#     'Accept',
#     'Accept-Encoding',
#     'Authorization',
#     'Content-Type',
# ]

# Allow specific methods in the requests
# CORS_ALLOW_METHODS = [
#     'DELETE',
#     'GET',
#     'OPTIONS',
#     'PATCH',
#     'POST',
#     'PUT',
# ]

# Allow credentials like cookies to be included in CORS requests
# CORS_ALLOW_CREDENTIALS = True

# Set the maximum age (in seconds) for which the CORS preflight response is cached
# CORS_PREFLIGHT_MAX_AGE = 86400  # 24 hours

# Specify which response headers are exposed to the browser
# CORS_EXPOSE_HEADERS = [
#     'Content-Type',
#     'X-Custom-Header',
# ]

# Control whether the CORS headers should be exposed in error responses
# CORS_REPLACE_HTTPS_REFERER = True

# Control whether to append CORS headers to successful responses when the CORS origin is whitelisted
# CORS_REPLACE_HTTPS_REFERER = True

# Control whether the CORS headers should be appended to non-simple responses
# CORS_ALLOW_ALL_ORIGINS = True

# Control whether to include Vary: Origin header in responses
# CORS_USE_VARY_HEADER = True

# Control whether to include the X-CSRFToken header in the response
# CORS_ALLOW_CSRF_ORIGIN = True


# Static files directory
STATIC_URL = '/static/'
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'static'),
]
# Optionally, specify the location where collectstatic will gather static files.
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files directory
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Other directories
# For data files
# DATA_DIR = os.path.join(BASE_DIR, 'data')
# For uploaded files  
# UPLOADS_DIR = os.path.join(BASE_DIR, 'uploads')
# For log files  
# LOGS_DIR = os.path.join(BASE_DIR, 'logs')
# For configuration files  
# CONFIG_DIR = os.path.join(BASE_DIR, 'config')
# For custom scripts  
# SCRIPTS_DIR = os.path.join(BASE_DIR, 'scripts')   

REST_FRAMEWORK = {
    # Use Django's standard `django.contrib.auth` permissions,
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
        #'rest_framework.permissions.DjangoModelPermissionsOrAnonReadOnly',
    ],
    # or allow read-only access for unauthenticated users.
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.BasicAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        #'oauth2_provider.contrib.rest_framework.OAuth2Authentication',
        
    ],
}

# settings.py

LOGIN_URL = 'login'  # Specify the login URL name
LOGOUT_REDIRECT_URL = 'logout'  # This should be the name of the URL pattern to redirect to after logout


"@

ReplaceLine -ReplaceText ($oldValueStatic) -NewText ($newValueStatic)
Write-Host "Replace Text for $oldValueStatic"-ForegroundColor DarkGreen

Search-File -inputPath "settings.py"
$firstNewLine = "import os"
Add-Line -Line ($firstNewLine) -LineNumber 12
Write-Host " New Line added fot $firstNewLine "-ForegroundColor DarkGreen

# Check if SQL Server is being used in the Django project

function ConfigureDatabase {

    goto $basedir

    pip install django-mssql-backend pyodbc

    Write-Host "Required packages have been installed." -ForegroundColor Green

    $mydb = Read-Host "Which database do you want to use? (Enter your database)"
    $user = Read-Host "Which user do you want to use? (Enter your user)"
    $password = Read-Host "Which password do you want to use? (Enter your password)" 
    $hostname = Read-Host "Which host do you want to use? (Enter your host)"  
    $port = Read-Host "Which port do you want to use? (Enter your port)" 

    $newDatabaseConfig = @"
DATABASES = {
    'default': {
        'ENGINE': 'mssql',
        'NAME': '$mydb',
        'USER': '$user',
        'PASSWORD': '$password',
        'HOST': '$hostname',
        'PORT': '$port',
        'OPTIONS': {
            'driver': 'ODBC Driver 17 for SQL Server',
        },
    }
}
"@

    # Regex pattern to find the old DATABASES configuration
    $oldDatabasePattern = @"    
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
"@ 
    Search-File -inputPath "settings.py"    
    ReplaceLine -ReplaceText ($oldDatabasePattern) -NewText ($newDatabaseConfig)
    Write-Host "Database configuration has been updated in settings.py. $newDatabaseConfig" -ForegroundColor Green

}

# Main script
do {
    $databaseChoice = Read-Host "Do you want to configure a database? (Enter 'yes' or 'no')"

    # Convert the input to lowercase for case-insensitive comparison
    $databaseChoice = $databaseChoice.ToLower().Trim()

    if ($databaseChoice -eq "yes") {     
        
        $databaseChoice = "no"
        ConfigureDatabase  

        continue
    }    
    else {
        Write-Host "Not a valid option. It's possible that you choose to keep this default configuration." -ForegroundColor Red
    }
} until ($databaseChoice -eq "no")

#$registrationAdded = $false
function CreateApplication {

    goto $AppDirectory      
    Write-Host "Your Location is " (Get-Location) -ForegroundColor Red 


    
    if (-not $StartupApp) {
        #Initialize App
        $Application = "accounts"
        Write-Host "We have created a by default Initialize application for the account's" -ForegroundColor Magenta

    }
    else {        
        $Application = Read-Host "Do you want to create an application? (Enter the name of application)"

    }

    

    python manage.py startapp $Application
    
    $Application = $Application.ToLower().Trim()    
   
    $CapitalizedAppName = $Application.Substring(0, 1).ToUpper() + $Application.Substring(1)    
    # Define the package name to append to INSTALLED_APPS
    $AppName = @"
    '${Application}.apps.${CapitalizedAppName}Config',  # Django Application for the $Application
"@
    Write-Host "$AppName" -ForegroundColor Green

    Search-File -inputPath "settings.py"
    Add-NewLine -SearchText "INSTALLED_APPS" -StartTag "[" -EndTag "]" -NewLine ($AppName)
    Write-Host "New packages added to INSTALLED_APPS." -ForegroundColor Green 

    $AppUrls = "    path('${Application}/', include('${Application}.urls')),"

    $oldpath = "from django.urls import path"
    $Newpath = "from django.urls import path, include"

    Search-File -inputPath "$projectName\Backends\$projectName\$projectName\urls.py"
    
    # Check and update the urlpatterns if necessary
    if (-not $StartupApp) {
        ReplaceLine -ReplaceText ($oldpath) -NewText ($Newpath)        
    }
    
    Add-NewLine -SearchText "urlpatterns" -StartTag "[" -EndTag "]" -NewLine ($AppUrls)
    Write-Host "New packages added to INSTALLED_APPS." -ForegroundColor Green 
    # Navigate to the application
    #Add-Line -Line "from .views import *" -LineNumber 5

    Set-Location -Path $Application
    
    $NewLineRS = @"
from django.contrib.auth.models import Group, User
from rest_framework import permissions, viewsets

from .serializers import GroupSerializer, UserSerializer

from django.contrib.auth.decorators import login_required
#from django.views.generic import TemplateView

class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to be viewed or edited.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]


class GroupViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Group.objects.all().order_by('name')
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

@login_required(login_url='login')
def profile(request):
    return render(request, '$Application/profile.html', {'user': request.user})

"@

    $NewLine = @"

from django.http import HttpResponse

from .views import *

from django.contrib.auth.decorators import login_required

@login_required(login_url='login')  # Redirect to 'login' URL if user is not authenticated
def home(request):
    return render(request, '$Application\${Application}_home.html')

"@

    # Define the line number where the new line should be added

    #themate\Backends\themate\account\
    $LineNumber = 4
    Search-File -inputPath "$projectName\Backends\$projectName\$Application\views.py"
    if (-not $StartupApp) {     
        # Add the content of $NewLineRS at the specified line number
        Add-Line -Line $NewLineRS -LineNumber $LineNumber
        Write-Host "New line added for $NewLineRS" -ForegroundColor DarkGreen
    }
    else {        
        # Add the content of $NewLine at the specified line number
        Add-Line -Line $NewLine -LineNumber $LineNumber
        Write-Host "New line added for $NewLine" -ForegroundColor DarkGreen

    }
    # Create the urls.py file
    New-Item -Path . -Name "urls.py" -ItemType "File"

    # Define the content
    $contentRS = @"
from django.urls import include, path
from rest_framework import routers

from . import views
#from django.contrib.auth import views as auth_views

from .views import *

router = routers.DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'groups', views.GroupViewSet)

# Wire up our API using automatic URL routing.
# Additionally, we include login URLs for the browsable API.
urlpatterns = [
    path('Jeson/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('', include("django.contrib.auth.urls")),   
    path('profile/', profile, name='profile'),     
]
"@

    $content = @"
from django.urls import path

from .views import *

urlpatterns = [    
    path('', home, name='home'),
]
"@

            
    if (-not $StartupApp) {            

        # Add the content to the file
        Add-Content -Path .\urls.py -Value $contentRS
        # Display a success message
        Write-Host "You have created a new file in the Application directory for urls.py" -ForegroundColor DarkGreen
        
        # Create the urls.py file
        New-Item -Path . -Name "serializers.py" -ItemType "File"

        # Define the content
        $content = @"
from django.contrib.auth.models import Group, User
from rest_framework import serializers


class UserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = User
        fields = ['url', 'username', 'email', 'groups']


class GroupSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Group
        fields = ['url', 'name']
"@

        # Add the content to the file
        Add-Content -Path .\serializers.py -Value $content
        # Display a success message
        Write-Host "You have created a new file in the Application directory for serializers.py" -ForegroundColor DarkGreen

    }
    else {
        # Add the content to the file
        Add-Content -Path .\urls.py -Value $content
        # Display a success message
        Write-Host "You have created a new file in the Application directory for urls.py" -ForegroundColor DarkGreen

    } 

    $templatesAppDirectories = @(
        "$templatesBaseDirectory\$Application"
        
    )

    CreateDirectories $templatesAppDirectories

    if (-not $StartupApp) {

        $managementcommands = @(
            "$AppDirectory\$Application\management\commands",
            "$AppDirectory\$Application\templatetags"
            
        )
        CreateDirectories $managementcommands


        # Create the __init__.py file
        New-Item -Path "$AppDirectory\$Application\management\commands\__init__.py" -ItemType File -Force
        New-Item -Path "$AppDirectory\$Application\templatetags\__init__.py" -ItemType File -Force

        $managementcommandsFilespath = "$AppDirectory\$Application\management\commands\createsuperuser_with_password.py"
        $managementcommandsFilesContent = @"
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
        
class Command(BaseCommand):
    help = 'Create a superuser with a predefined password'
        
    def handle(self, *args, **options):
        User = get_user_model()
        username = 'rakib'
        email = 'rakibjpi@gmail.com'
        password = '123'
        
        if not User.objects.filter(username=username).exists():
            User.objects.create_superuser(username=username, email=email, password=password)
            self.stdout.write(self.style.SUCCESS(f'Successfully created superuser with username "{username}"'))
        else:
            self.stdout.write(self.style.WARNING(f'Superuser with username "{username}" already exists'))
"@
        Set-Content -Path $managementcommandsFilespath -Value $managementcommandsFilesContent -Force -ErrorAction Stop
        
                
        $customfiltersFilespath = "$AppDirectory\$Application\templatetags\custom_filters.py"

        $customfiltersFilesContent = @"
# accounts/templatetags/custom_filters.py
from django import template
from django.forms import BoundField

register = template.Library()

@register.filter(name='add_class')
def add_class(field, css_class):
    if isinstance(field, BoundField):
        return field.as_widget(attrs={"class": css_class})
    return field

@register.filter(name='add_id')
def add_id(field, element_id):
    if isinstance(field, BoundField):
        return field.as_widget(attrs={"id": element_id})
    return field



"@
    
    Set-Content -Path $customfiltersFilespath -Value $customfiltersFilesContent -Force -ErrorAction Stop
    
    }
    else {
        Write-Host "Already created superuser" -ForegroundColor Red        
    }
    
    $appRegistrationDirectory = "$templatesBaseDirectory\registration"

    CreateDirectories $appRegistrationDirectory

    if (-not $StartupApp) {
        
        $registrationExampleFiles = @{
            "$appRegistrationDirectory\login.html"                   = @"
<!-- Example login template -->
{% extends 'base.html' %}
{% load custom_filters %}
<title>{% block title %} Login {% endblock %}</title>
{% block content %}

<div class="container">
    <div class="row">
        <div class="col-sm-9 col-md-7 col-lg-5 mx-auto">
            <div class="card border-0 shadow rounded-3 my-5">
                <div class="card-body p-4 p-sm-5">
                    <h5 class="card-title text-center mb-5 fw-light fs-5">Sign In</h5>
                    <form method="post" action="{% url 'login' %}">
                        {% csrf_token %}

                        {% if form.errors %}
                            <div class="alert alert-danger" role="alert">
                                Your username and password didn't match. Please try again.
                            </div>
                        {% endif %}

                        {% if next %}
                            {% if user.is_authenticated %}
                                <div class="alert alert-warning" role="alert">
                                    Your account doesn't have access to this page. To proceed, please login with an account that has access.
                                </div>
                            {% else %}
                                <div class="alert alert-info" role="alert">
                                    Please login to see this page.
                                </div>
                            {% endif %}
                        {% endif %}

                        <div class="form-floating mb-3">
                            {{ form.username|add_class:"form-control"|add_id:"floatingInput" }}
                            <label for="floatingInput">Username</label>
                        </div>
                        <div class="form-floating mb-3">
                            {{ form.password|add_class:"form-control"|add_id:"floatingPassword" }}
                            <label for="floatingPassword">Password</label>
                        </div>

                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" value="" id="rememberPasswordCheck">
                            <label class="form-check-label" for="rememberPasswordCheck">
                                Remember password
                            </label>
                        </div>
                        <div class="d-grid">
                            <button class="btn btn-primary btn-login text-uppercase fw-bold" type="submit">Sign in</button>
                        </div>
                        <hr class="my-4">
                        <div class="d-grid mb-2">
                          <button class="btn btn-google btn-login text-uppercase fw-bold" type="submit">
                            <i class="fab fa-google me-2"></i> Sign in with Google
                          </button>
                        </div>
                        <div class="d-grid">
                          <button class="btn btn-facebook btn-login text-uppercase fw-bold" type="submit">
                            <i class="fab fa-facebook-f me-2"></i> Sign in with Facebook
                          </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}


"@

            "$appRegistrationDirectory\logged_out.html"              = @"
<!-- Example logged out template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Logged Out{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="alert alert-info" role="alert">
        <p>You have been logged out. <a href="{% url 'login' %}" class="alert-link">Log in again?</a></p>
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_reset_email.html"    = @"
<!-- Example password reset email template -->

{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Password Reset Email{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="card">
        <div class="card-body">
            <p>You're receiving this email because you requested a password reset for your user account at {{ site_name }}.</p>
            <p>Please go to the following page and choose a new password:</p>
            <p><a href="{{ protocol }}://{{ domain }}{% url 'password_reset_confirm' uidb64=uid token=token %}" class="btn btn-primary">{{ protocol }}://{{ domain }}{% url 'password_reset_confirm' uidb64=uid token=token %}</a></p>
            <p>Your username, in case you've forgotten: {{ user.get_username }}</p>
            <p>Thanks for using our site!</p>
            <p>The {{ site_name }} team</p>
        </div>
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_reset_form.html"     = @"
<!-- Example password reset form template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Reset Password{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="card">
        <div class="card-header">
            <h2>Reset Your Password</h2>
        </div>
        <div class="card-body">
            <form method="post">
                {% csrf_token %}
                {{ form.as_p|safe|add_class:"form-control" }}
                <button type="submit" class="btn btn-primary mt-3">Reset my password</button>
            </form>
        </div>
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_reset_done.html"     = @"
<!-- Example password reset done template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Password Reset Instructions Sent{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="alert alert-info" role="alert">
        We've emailed you instructions for setting your password. You should receive the email shortly!
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_reset_confirm.html"  = @"
<!-- Example password reset confirm template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Enter New Password{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="card">
        <div class="card-header">
            <h2>Enter New Password</h2>
        </div>
        <div class="card-body">
            <form method="post">
                {% csrf_token %}
                {{ form.as_p|safe|add_class:"form-control" }}
                <button type="submit" class="btn btn-primary mt-3">Change my password</button>
            </form>
        </div>
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_reset_complete.html" = @"
<!-- Example password reset complete template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Password Reset Complete{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="alert alert-success" role="alert">
        Your password has been set. You can now <a href="{% url 'login' %}" class="alert-link">log in</a> with the new password.
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_change_form.html"    = @"
<!-- Example password change form template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Change Password{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="card">
        <div class="card-header">
            <h2>Change Password</h2>
        </div>
        <div class="card-body">
            <form method="post">
                {% csrf_token %}
                {{ form.as_p|safe|add_class:"form-control" }}
                <button type="submit" class="btn btn-primary mt-3">Change my password</button>
            </form>
        </div>
    </div>
</div>
{% endblock %}

"@

            "$appRegistrationDirectory\password_change_done.html"    = @"
<!-- Example password change done template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Password Change Successful{% endblock %}

{% block content %}
<div class="container mt-5">
    <div class="alert alert-success" role="alert">
        Your password has been successfully changed.
    </div>
</div>
{% endblock %}

"@
            "$templatesBaseDirectory\$Application\profile.html"    = @"
<!-- Example password change done template -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}User Profile{% endblock %}
{% block nav %}{% include "components/navbar.html" %}{% endblock nav %}
{% block content %}
<div class="container mt-5">
    <div class="card">
        <div class="card-header">
            <h2>User Profile</h2>
        </div>
        <div class="card-body">
            <p><strong>Username:</strong> {{ user.username }}</p>
            <p><strong>Email:</strong> {{ user.email }}</p>
            <!-- Add any other user information you want to display -->
        </div>
    </div>
</div>
{% endblock %}

{% block footer %}{% include "components/footer.html" %}{% endblock footer %}

"@
        }

        foreach ($appFile in $registrationExampleFiles.GetEnumerator()) {
            $appFilePath = $appFile.Key
            $appFileContent = $appFile.Value

            try {
                Set-Content -Path $appFilePath -Value $appFileContent -Force -ErrorAction Stop
                Write-Host "Example file created: $appFilePath"
            }
            catch {
                Write-Host "Failed to create example file: $appFilePath" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        }






    }
    else {

        $registrationExampleFiles = @{
            "$templatesBaseDirectory\$Application\${Application}_home.html" = @"
<!-- home.html -->
{% extends 'base.html' %}
{% load custom_filters %}

{% block title %}Home{% endblock %}

{% block content %}
<main>
    {% if user.is_authenticated %}
        <h1>Welcome, {{ user.username }}!</h1>
        <p>You are logged in.</p>
    {% else %}
        <h1>Welcome to Our Site!</h1>
        <p>Please <a href='{% url 'login' %}'>login</a> to access more features.</p>
    {% endif %}
</main>
{% endblock %}
"@
        }

        foreach ($appFile in $registrationExampleFiles.GetEnumerator()) {
            $appFilePath = $appFile.Key
            $appFileContent = $appFile.Value

            try {
                Set-Content -Path $appFilePath -Value $appFileContent -Force -ErrorAction Stop
                Write-Host "Example file created: $appFilePath"
            }
            catch {
                Write-Host "Failed to create example file: $appFilePath" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        }
        
    }

    $global:StartupApp = $true
    Write-Host "Application creation has been completed." -ForegroundColor Green

}
# Initial setup
$global:StartupApp = $false

do {

    if (-not $StartupApp) {
        #Initialize App
        $applicationChoice = "yes"       

    }
    else {        
        $applicationChoice = Read-Host "Do you want to create a application? (Enter 'yes' or 'no')"

    }
    

    # Convert the input to lowercase for case-insensitive comparison
    $applicationChoice = $applicationChoice.ToLower().Trim()

    if ($applicationChoice -eq "yes") {       
        #$applicationChoice = "no"
        CreateApplication
        goto $AppDirectory
        continue

    }
    else {
        Write-Host "Not a valid option. It's possible that you choose to keep this default configuration." -ForegroundColor Red
    }

  

} until ($applicationChoice -eq "no")


goto $AppDirectory

python manage.py makemigrations
python manage.py migrate
py manage.py createsuperuser_with_password

# Start the Django development server
$serverProcess = Start-Process -FilePath "py" -ArgumentList "manage.py", "runserver" -PassThru -NoNewWindow

# Wait for the server to start (adjust the delay as needed)
Start-Sleep -Seconds 5

# Open the web browser to the server address
Start-Process -FilePath "http://127.0.0.1:8000/accounts/login/"

# Open the web browser to the admin address
#Start-Process -FilePath "http://127.0.0.1:8000/admin/"

# Exit the script
exit