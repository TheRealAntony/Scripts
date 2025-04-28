# Script to Install Development Tools Using Chocolatey
# This script installs Git, Node.js, Yara, Make, and Wails 3.
# Ensure the script is executed with Administrator privileges.

# Check if Chocolatey is installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey is not installed. Proceeding with installation..."
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script must be run as an Administrator. Please restart the script with elevated privileges."
        exit 1
    }
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installation completed."
} else {
    Write-Host "Chocolatey is already installed."
}

# Install Git if not installed
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    choco install git -y --ignore-detected-reboot
    Write-Host "Verifying Git installation..."
    git --version
} else {
    Write-Host "Git is already installed."
}

# Replace 'C:\Python313\python.exe' with the actual path to your Python executable
$pythonPath = "C:\Python313\python.exe"

# Add Python full path to environment variables
Write-Host "Adding Python full path to environment variables..."
$pythonDir = Split-Path -Parent $pythonPath
if (-not ($env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $pythonDir })) {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script must be run as an Administrator to modify system environment variables."
        exit 1
    }
    [System.Environment]::SetEnvironmentVariable("Path", "$($env:Path);$pythonDir", [System.EnvironmentVariableTarget]::Machine)
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Python path added to environment variables."
} else {
    Write-Host "Python path is already in environment variables."
}

# Installing python3 and python3-pip if not installed
if (!(Get-Command python3 -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python 3..."
    choco install python3 -y --ignore-detected-reboot
    Write-Host "Verifying Python 3 installation..."
    python --version
} else {
    Write-Host "Python 3 is already installed."
}



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

# Install Yara if not installed
if (!(Get-Command yara -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Yara..."
    choco install yara -y --ignore-detected-reboot
    Write-Host "Refreshing environment variables..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Verifying Yara installation..."
    $yaraPath = (Get-Command yara -ErrorAction SilentlyContinue).Source
    if ($yaraPath) {
        & $yaraPath --version
    } else {
        Write-Host "Yara executable not found in the system path."
    }
} else {
    Write-Host "Yara is already installed."
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

Write-Host "Environment variable updates completed."


# Verifying Python 3 installation
if (!(Get-Command $pythonPath -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python 3..."
    choco install python3 -y --ignore-detected-reboot
    Write-Host "Verifying Python 3 installation..."
    & $pythonPath --version
} else {
    Write-Host "Python 3 is already installed."
}

# Download and extract TensorFlow C library
Write-Host "Downloading and extracting TensorFlow C library..."
$libTensorFlowUrl = "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-2.15.0.tar.gz"
$libTensorFlowArchive = "libtensorflow-cpu-linux-x86_64-2.15.0.tar.gz"
Invoke-WebRequest -Uri $libTensorFlowUrl -OutFile $libTensorFlowArchive -UseBasicParsing
Write-Host "Extracting TensorFlow C library to /usr/local..."
tar -C /usr/local -xzf $libTensorFlowArchive
Write-Host "TensorFlow C library installation completed."
# Ensure pip is installed and upgraded
Write-Host "Ensuring pip is installed and upgraded..."
& $pythonPath -m ensurepip --upgrade
& $pythonPath -m pip install --upgrade pip
# Install TensorFlow using pip
Write-Host "Installing TensorFlow using pip..."
& $pythonPath -m pip install tensorflow --upgrade
Write-Host "Verifying TensorFlow installation..."
& $pythonPath -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)"
