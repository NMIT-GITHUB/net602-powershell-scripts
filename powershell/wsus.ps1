<#  
# Source: https://gallery.technet.microsoft.com/scriptcenter/Install-WSUSServerps1-40a8169b
# Date accessed: 5 August 2020
.SYNOPSIS  
    Downloads (if needed) and performs an unattended installation of WSUS Server with SP2 on a local or remote system. Requires psexec.exe to be in the same
    location as the script in order to run properly.

.DESCRIPTION
    Downloads (if needed) and performs an unattended installation of WSUS Server with SP2 on a local or remote system. Requires psexec.exe to be in the same
    location as the script in order to run properly. Also optional to have the installation files in the same location as the script, otherwise the files will
    be downloaded from the internet.
     
.PARAMETER Computername
    Name of computer to install WSUS server on.

.PARAMETER ConsoleOnlyServer
    Switch used to only install the console without installing the server application.

.PARAMETER StoreUpdatesLocally
    Switch used to determine if updates will be downloaded and saved to system locally.

.PARAMETER ContentDirectory
    Path to the local content folder holding update files. Default location is: %rootdrive%\WSUS\WSUSContent where the root drive is the largest local drive on the system.

.PARAMETER InternalDatabasePath
    Path to install the internal database
    
.PARAMETER CreateDatabase
    Create a database on the SQL server. Will not create database and attempt to use existing database if switch not used.

.PARAMETER WebsitePort
    Determine the port of the WSUS Site. Accepted Values are "80" and "8530". 

.PARAMETER SQLInstance
    Name of the SQL Instance to connect to for database
    
.PARAMETER IsFrontEndServer
    This server will be a front end server in an NLB

.NOTES  
    Name: Install-WSUSServer
    Author: Boe Prox
    DateCreated: 29NOV2011 
           
.LINK  
    https://learn-powershell.net
    
.EXAMPLE
Install-WSUSServer.ps1 -ConsoleOnly

Description
-----------
Installs the WSUS Console on the local system

.EXAMPLE
Install-WSUSServer.ps1 -ConsoleOnly -Computername Server1

Description
-----------
Installs the WSUS Console on the remote system Server1

.EXAMPLE
Install-WSUSServer.ps1 -Computername TestServer -StoreUpdatesLocally -ContentDirectory "D:\WSUS" -InternalDatabasePath "D:\" -CreateDatabase

Description
-----------
Installs WSUS server on TestServer and stores content locally on D:\WSUS and installs an internal database on D:\

.EXAMPLE
Install-WSUSServer.ps1 -Computername A24 -StoreUpdatesLocally -ContentDirectory "D:\WSUS" -SQLInstance "Server1\Server1" -CreateDatabase

Description
-----------
Installs WSUS server on TestServer and stores content locally on D:\WSUS and creates a database on Server1\Server1 SQL instance

.EXAMPLE
Install-WSUSServer.ps1 -Computername A24 -StoreUpdatesLocally -ContentDirectory "D:\WSUS" -SQLInstance "Server1\Server1"

Description
-----------
Installs WSUS server on TestServer and stores content locally on D:\WSUS and uses an existing WSUS database on Server1\Server1 SQL instance
#> 
[cmdletbinding(
    DefaultParameterSetName = 'Console',
    SupportsShouldProcess = $True
)]
Param (
    [parameter(ValueFromPipeLine = $True)]
    [string]$Computername = $Env:Computername,
    [parameter(ParameterSetName = 'Console')]
    [switch]$ConsoleOnly,
    [parameter(ParameterSetName = 'SQLInstanceDatabase')]
    [parameter(ParameterSetName = 'InternalDatabase')]
    [switch]$StoreUpdatesLocally,
    [parameter(ParameterSetName = 'SQLInstanceDatabase')]
    [parameter(ParameterSetName = 'InternalDatabase')]
    [string]$ContentDirectory,
    [parameter(ParameterSetName = 'InternalDatabase')]
    [string]$InternalDatabasePath, 
    [parameter(ParameterSetName = 'SQLInstanceDatabase')]
    [parameter(ParameterSetName = 'InternalDatabase')]
    [ValidateSet("80","8530")]
    [string]$WebsitePort,
    [parameter(ParameterSetName = 'SQLInstanceDatabase')]
    [parameter(ParameterSetName = 'InternalDatabase')]
    [switch]$CreateDatabase,
    [parameter(ParameterSetName = 'SQLInstanceDatabase')]
    [string]$SQLInstance,
    [parameter(ParameterSetName = 'SQLInstanceDatabase')]
    [parameter(ParameterSetName = 'InternalDatabase')]
    [switch]$IsFrontEndServer    
    
)
Begin {
    If (-NOT (Test-Path psexec.exe)) {
        Write-Warning ("Psexec.exe is not in the current directory! Please copy psexec to this location: {0} or change location to where psexec.exe is currently at.`nPsexec can be downloaded from the following site:`
        http://download.sysinternals.com/Files/SysinternalsSuite.zip" -f $pwd)
        Break
    }
    
    #Source Files for X86 and X64
    Write-Verbose "Setting source files"
    $x86 = Join-Path $pwd "WSUS30-KB972455-x86.exe"
    $x64 = Join-Path $pwd "WSUS30-KB972455-x64.exe"
        
    #Menu items for later use if required
    Write-Verbose "Building scriptblock for later use"
    $sb = {$title = "WSUS File Required"
    $message = "The executable you specified needs to be downloaded from the internet. Do you wish to allow this?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Download the file."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Do not download the file. I will download it myself."    
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    Write-Verbose "Launching menu for file download"
    $Host.ui.PromptForChoice($title, $message, $options, 0)}             
    
    Write-Verbose "Adding URIs for installation files"
    #URI of specified files if needed to download        
    $WSUS_X86 = "http://download.microsoft.com/download/B/0/6/B06A69C3-CF97-42CF-86BF-3C59D762E0B2/WSUS30-KB972455-x86.exe"
    $WSUS_X64 = "http://download.microsoft.com/download/B/0/6/B06A69C3-CF97-42CF-86BF-3C59D762E0B2/WSUS30-KB972455-x64.exe"
    
    #Define Quiet switch first
    $arg = "/q "
    
    #Process parameters
    If ($PSBoundParameters['ConsoleOnly']) {
        Write-Verbose "Setting argument to Console Install Only"
        $arg += "CONSOLE_INSTALL=1 "
    }
    If ($PSBoundParameters['StoreUpdatesLocally']){
        $arg += "CONTENT_LOCAL=1 "
        If ($PSBoundParameters['ContentDirectory']) {
            $arg += "CONTENT_DIR=$ContentDirectory "
        }
    }
    If ($PSBoundParameters['WebsitePort']) {
            Switch ($WebsitePort) {
            "80" {
                $arg += "DEFAULT_WEBSITE=1 "
            }
            "8530" {
                $arg += "DEFAULT_WEBSITE=0 "
            }
            Default {
                $arg += "DEFAULT_WEBSITE=1 "
            }
        }
    }
    If ($PSBoundParameters['InternalDatabasePath']) {
        $arg += "WYUKON_DATA_DIR=$InternalDatabasePath "
    }
    If ($PSBoundParameters['CreateDatabase']) {
        $arg += "CREATE_DATABASE=1 "
    } ElseIf ($PSCmdlet.ParameterSetName -ne 'Console') {
        #Use default database
        $arg += "CREATE_DATABASE=0 "
    }
    If ($PSBoundParameters['SQLInstance']) {
        $arg += "SQLINSTANCE_NAME=$SQLInstance "
    }
    If ($PSBoundParameters['IsFrontEndServer']) {
        $arg += "FRONTEND_SETUP=1 "
    }
}
Process {
    Try {
        $OSArchitecture = Get-WmiObject Win32_OperatingSystem -ComputerName $Computername | Select -Expand OSArchitecture -EA Stop
    } Catch {
        Write-Warning ("{0}: Unable to perform lookup of operating system!`n{1}" -f $Computername,$_.Exception.Message)
    }  
    If ($OSArchitecture -eq "64-bit") {
        Write-Verbose ("{0} using 64-bit" -f $Computername)
        If (-NOT (Test-Path $x64)) {
            Write-Verbose ("{0} not found, download from internet" -f $x64)
            switch (&$sb) {
                0 {
                    If ($pscmdlet.ShouldProcess($WSUS_X64,"Download File")) {
                        Write-Verbose "Configuring webclient to download file"
                        $wc = New-Object Net.WebClient
                        $wc.UseDefaultCredentials = $True              
                        Write-Host -ForegroundColor Green -BackgroundColor Black ("Downloading from {0} to {1} prior to installation. This may take a few minutes" -f $WSUS_X64,$x64)
                        Try {
                            $wc.DownloadFile($WSUS_X64,$x64)                                                                                    
                        } Catch {
                            Write-Warning ("Unable to download file!`nReason: {0}" -f $_.Exception.Message)
                            Break
                        } 
                    }                   
                }
                1 {
                    #Cancel action
                    Break
                }                
            }
        } 
        #Copy file to root drive
        If (-NOT (Test-Path ("\\$Computername\c$\{0}" -f (Split-Path $x64 -Leaf)))) {
            Write-Verbose ("Copying {0} to {1}" -f $x64,$Computername)
            If ($pscmdlet.ShouldProcess($Computername,"Copy File")) {                                
                Try {
                    Copy-Item -Path $x64 -Destination "\\$Computername\c$" -EA Stop
                } Catch {
                    Write-Warning ("Unable to copy {0} to {1}`nReason: {2}" -f $x64,$Computername,$_.Exception.Message)
                }
            }
        } Else {Write-Verbose ("{0} already exists on {1}" -f (Split-Path $x64 -Leaf),$Computername)}
        #Perform the installation
        Write-Verbose ("Begin installation on {0} using specified options" -f $Computername)
        If ($pscmdlet.ShouldProcess($Computername,"Install WSUS")) {
            .\psexec.exe -accepteula -i -s \\$Computername cmd /c ("C:\{0} $arg" -f (Split-Path $x64 -Leaf))                                
        }
    } Else {
        Write-Verbose ("{0} using 32-bit" -f $Computername)
        If (-NOT (Test-Path $x86)) {
            Write-Verbose ("{0} not found, download from internet" -f $x86)
            switch (&$sb) {
                0 {
                    If ($pscmdlet.ShouldProcess($WSUS_X86,"Download File")) {
                        Write-Verbose "Configuring webclient to download file"
                        $wc = New-Object Net.WebClient
                        $wc.UseDefaultCredentials = $True              
                        Write-Host -ForegroundColor Green -BackgroundColor Black ("Downloading from {0} to {1} prior to installation. This may take a few minutes" -f $WSUS_X86,$x86)
                        Try {
                            $wc.DownloadFile($WSUS_X86,$x86)                                                                                          
                        } Catch {
                            Write-Warning ("Unable to download file!`nReason: {0}" -f $_.Exception.Message)
                            Break
                        }
                    }                    
                }
                1 {
                    #Cancel action
                    Break
                }                                
            }
        }
        #Copy file to root drive
        If (-NOT (Test-Path ("\\$Computername\c$\{0}" -f (Split-Path $x86 -Leaf)))) {
            Write-Verbose ("Copying {0} to {1}" -f $x86,$Computername) 
            If ($pscmdlet.ShouldProcess($Computername,"Copy File")) {
                Try {
                    Copy-Item -Path $x86 -Destination "\\$Computername\c$" -EA Stop
                } Catch {
                    Write-Warning ("Unable to copy {0} to {1}`nReason: {2}" -f $x86,$Computername,$_.Exception.Message)
                }
            }
        } Else {Write-Verbose ("{0} already exists on {1}" -f $x86,$Computername)}
        #Perform the installation
        Write-Verbose ("Begin installation on {0} using specified options" -f $Computername)
        If ($pscmdlet.ShouldProcess($Computername,"Install WSUS")) {
            .\psexec.exe -accepteula -i -s \\$Computername cmd /c ("C:\{0} $arg" -f (Split-Path $x86 -Leaf))
        }
    }   
}