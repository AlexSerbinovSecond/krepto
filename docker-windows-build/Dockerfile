# Krepto Windows Bitcoin Qt GUI Build Container
# Uses Windows Server Core with Visual Studio Build Tools and Qt5

FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Set shell to PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey package manager
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install essential build tools
RUN choco install -y git --version=2.41.0.3
RUN choco install -y cmake --version=3.27.1
RUN choco install -y python3 --version=3.11.4
RUN choco install -y 7zip --version=23.1.0

# Install Visual Studio Build Tools 2019
RUN choco install -y visualstudio2019buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows10SDK.19041"

# Install Qt5 for Windows
RUN choco install -y qt5-default --version=5.15.2

# Set environment variables
ENV QTDIR="C:\\Qt\\5.15.2\\msvc2019_64"
ENV PATH="$env:QTDIR\\bin;$env:PATH"
ENV CMAKE_PREFIX_PATH="$env:QTDIR"

# Install additional dependencies
RUN choco install -y boost-msvc-14.2 --version=1.82.0
RUN choco install -y openssl --version=1.1.1.2100

# Create working directory
WORKDIR C:\\build

# Copy build script
COPY build-windows-gui.ps1 C:\\build\\

# Set default command
CMD ["powershell", "-File", "C:\\build\\build-windows-gui.ps1"] 