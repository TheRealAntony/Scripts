# Script to Install Development Tools Using Chocolatey
# This script installs Git, Node.js, Yara, Make, and Wails 3.
# Ensure the script is executed with Administrator privileges.


# Clone the repository and build the project
$PAT = "change-me" # Replace with your GitHub Personal Access Token
$repo = "clientagent-v2"
$branch = "stage"
$repoUrl = "https://$PAT@github.com/kitecyber/$repo.git"

# Check if Chocolatey is installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey is not installed. Proceeding with installation..."
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script must be run as an Administrator to install Chocolatey."
        exit 1
    }
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey installation failed. Please check the logs."
        exit 1
    }
    Write-Host "Chocolatey installation completed."
} else {
    Write-Host "Chocolatey is already installed."
}

# Install Git if not installed
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git for both user and admin levels..."
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not installed. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Installing Git for the current user..."
        choco install git -y --ignore-detected-reboot --params "/InstallDir:C:\Users\$env:USERNAME\AppData\Local\Programs\Git"
    } else {
        Write-Host "Installing Git for all users (Administrator level)..."
        choco install git -y --ignore-detected-reboot
    }
    Write-Host "Verifying Git installation..."
    git --version
} else {
    Write-Host "Git is already installed."
}

# Add Python Scripts and Python directory to user and system PATH
Write-Host "Adding Python Scripts and Python directory to user and system PATH..."
$pythonPaths = @(
    "C:\Users\devops\AppData\Local\Programs\Python\Python311\Scripts\",
    "C:\Users\devops\AppData\Local\Programs\Python\Python311\"
)

foreach ($path in $pythonPaths) {
    # Add to user PATH
    if (-not ($env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $path })) {
        [System.Environment]::SetEnvironmentVariable("Path", "$($env:Path);$path", [System.EnvironmentVariableTarget]::User)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
        Write-Host "Added $path to user PATH."
    } else {
        Write-Host "$path is already in user PATH."
    }

    # Add to system PATH
    if (-not ($env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $path })) {
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "This script must be run as an Administrator to modify system environment variables."
            exit 1
        }
        [System.Environment]::SetEnvironmentVariable("Path", "$($env:Path);$path", [System.EnvironmentVariableTarget]::Machine)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        Write-Host "Added $path to system PATH."
    } else {
        Write-Host "$path is already in system PATH."
    }
}



# Installing python3 and python3-pip if not installed
# Check if Python is already installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python is not installed. Proceeding with installation..."
    # Install Python 3.11.4 silently using the provided URL
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"
    $pythonInstallerPath = "$env:TEMP\python-3.11.4-amd64.exe"

    Write-Host "Downloading Python installer..."
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $pythonInstallerPath -UseBasicParsing

    Write-Host "Installing Python silently..."
    Start-Process -FilePath $pythonInstallerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

    Write-Host "Verifying Python installation..."
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "Python installed successfully."
        python --version
    } else {
        Write-Host "Python installation failed."
    }
} else {
    Write-Host "Python is already installed."
    python --version
}

# checking python version
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source

# Install Node.js and npm if not installed
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js and npm..."
    choco install nodejs.install -y --ignore-detected-reboot
    Write-Host "Verifying Node.js installation..."
    node --version
    Write-Host "Verifying npm installation..."
    npm --version
} else {
    Write-Host "Node.js and npm are already installed."
}


# Install Make if not installed
if (!(Get-Command make -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Make..."
    choco install make -y --ignore-detected-reboot
    Write-Host "Verifying Make installation..."
    make --version
} else {
    Write-Host "Make is already installed."
}

# Install Yara from source
Write-Host "Installing Yara from source using MSYS2..."
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'git clone https://github.com/VirusTotal/yara.git && cd yara && ./bootstrap.sh && ./configure --prefix=/mingw64 && make && make install'" -Wait

# Install missing dependencies for Yara and gosseract
Write-Host "Installing missing dependencies for Yara and gosseract..."
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'yes | pacman -S mingw-w64-x86_64-leptonica mingw-w64-x86_64-tesseract mingw-w64-x86_64-pkg-config mingw-w64-x86_64-gcc --noconfirm'" -Wait

# Set PKG_CONFIG_PATH environment variable
Write-Host "Setting PKG_CONFIG_PATH environment variable..."
$pkgConfigPath = "/mingw64/lib/pkgconfig"
if (-not ($env:PKG_CONFIG_PATH -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $pkgConfigPath })) {
    [System.Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", "$($env:PKG_CONFIG_PATH);$pkgConfigPath", [System.EnvironmentVariableTarget]::Machine)
    $env:PKG_CONFIG_PATH = [System.Environment]::GetEnvironmentVariable("PKG_CONFIG_PATH", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Added $pkgConfigPath to PKG_CONFIG_PATH."
} else {
    Write-Host "$pkgConfigPath is already in PKG_CONFIG_PATH."
}

Write-Host "Yara installation completed."

# Install Go if not installed
if (!(Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Go..."
    choco install golang -y --ignore-detected-reboot
    Write-Host "Verifying Go installation..."
    go version
} else {
    Write-Host "Go is already installed."
}

# Install Wails 3 using Go
Write-Host "Installing Wails 3 using Go..."
go install -v github.com/wailsapp/wails/v3/cmd/wails3@latest
Write-Host "Refreshing environment variables..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

# Add Go binary path to environment variables
Write-Host "Adding Go binary path to environment variables..."
$goPath = "$($env:USERPROFILE)\go\bin"
if (-not ($env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $goPath })) {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script must be run as an Administrator to modify system environment variables."
        exit 1
    }
    [System.Environment]::SetEnvironmentVariable("Path", "$($env:Path);$goPath", [System.EnvironmentVariableTarget]::Machine)
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Go binary path added to environment variables."
} else {
    Write-Host "Go binary path is already in environment variables."
}

# Verify Wails 3 installation
Write-Host "Verifying Wails 3 installation..."
$wails3Path = (Get-Command wails3 -ErrorAction SilentlyContinue).Source
if ($wails3Path) {
    Write-Host "Wails 3 is installed at: $wails3Path"
    Write-Host "Running 'wails3 doctor'..."
    & $wails3Path doctor
    # Write-Host "Running 'wails3 build'..."
    # & $wails3Path build
} else {
    Write-Host "Wails 3 executable not found in the system path. Please ensure Go binaries are in your PATH."
}

# Install MSYS2 if not installed
if (!(Test-Path "C:\tools\msys64")) {
    Write-Host "Installing MSYS2..."
    choco install msys2 -y --ignore-detected-reboot
    Write-Host "Verifying MSYS2 installation..."
    if (Test-Path "C:\tools\msys64") {
        Write-Host "MSYS2 installed successfully."
    } else {
        Write-Host "MSYS2 installation failed. Please check the logs."
    }
} else {
    Write-Host "MSYS2 is already installed."
}

# Add MSYS2 paths to environment variables
Write-Host "Adding MSYS2 paths to environment variables..."
$msys64Paths = @("C:\tools\msys64\mingw64\bin", "C:\tools\msys64\usr\bin")
foreach ($path in $msys64Paths) {
    if (-not ($env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $path })) {
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "This script must be run as an Administrator to modify system environment variables."
            exit 1
        }
        [System.Environment]::SetEnvironmentVariable("Path", "$($env:Path);$path", [System.EnvironmentVariableTarget]::Machine)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        Write-Host "Added $path to environment variables."
    } else {
        Write-Host "$path is already in environment variables."
    }
}

# Run MSYS2 as Administrator and execute the required commands
Write-Host "Running MSYS2 as Administrator to execute package installations..."
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'yes | pacman -Syu --noconfirm'" -Wait
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'yes | pacman -S mingw-w64-x86_64-go --noconfirm'" -Wait
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'yes | pacman -S pkg-config --noconfirm'" -Wait
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'yes | pacman -S mingw-w64-x86_64-gcc make git --noconfirm'" -Wait
Start-Process -FilePath "C:\tools\msys64\usr\bin\bash.exe" -ArgumentList "-c 'yes | pacman -S autoconf automake libtool flex bison --noconfirm'" -Wait

Write-Host "MSYS2 package installations completed."


# Ensure pip is installed and upgraded
Write-Host "Ensuring pip is installed and upgraded..."
& $pythonPath -m ensurepip --upgrade
& $pythonPath -m pip install --upgrade pip
# Install TensorFlow using pip
Write-Host "Installing TensorFlow using pip..."
& $pythonPath -m pip install tensorflow --upgrade
Write-Host "Verifying TensorFlow installation..."
& $pythonPath -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)"


Write-Host "Cloning the repository..."
git clone --branch $branch $repoUrl > $null 2>&1

if (Test-Path $repo) {
    Write-Host "Repository cloned successfully. Navigating to the project directory..."
    Set-Location $repo

    Write-Host "Building the UI using Wails 3..."
    Set-Location "ui"
    wails3 task build

    Write-Host "Returning to the root directory and running Make..."
    Set-Location ".."
    make
} else {
    Write-Host "Failed to clone the repository. Please check the credentials and repository URL."
}
