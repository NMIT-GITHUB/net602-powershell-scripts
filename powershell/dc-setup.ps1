Rename-Computer -NewName InterTrode_DC1 -Force -PassThru
# Renames the computer to 'InterTrode_DC1'
# Can also be done though sconfig

New-NetIPAddress -InterfaceIndex 6 -AddressFamily IPv4 -IPAddress "10.0.0.101" -PrefixLength 24 -DefaultGateway "10.0.0.1"
# set IP address [10.0.0.101/24], gateway [10.0.0.1] static
# can be done (not scripted) through sconfig

Restart-Computer -Force 
# Restarts the computer

Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses "10.0.0.10" -PassThru
# for example, set DNS [10.0.0.10]
# can be done through sconfig

# https://www.server-world.info/en/note?os=Windows_Server_2019&p=initial_conf&f=4

New-NetFirewallRule `
-Name 'ICMPv4' `
-DisplayName 'ICMPv4' `
-Description 'Allow ICMPv4' `
-Profile Any `
-Direction Inbound `
-Action Allow `
-Protocol ICMPv4 `
-Program Any `
-LocalAddress Any `
-RemoteAddress Any
# Allow ping requests

Restart-Computer -Force 
# Restarts the computer

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
# AD DS install with admin tools
# Assumption is made that there are onscreen prompts at this point that will guide in the 

Restart-Computer -Force 
# Restarts the computer

Install-ADDSForest -DomainName "InterTrode.local.lan" `
-ForestMode WinThreshold `
-DomainMode WinThreshold `
-DomainNetbiosName InterTrode `
-SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd01" -Force) `
-InstallDNS 
# DC2 Only from here
# Prerequisite: DC2 static IP

add-computer –domainname "InterTrode.local.lan"  -restart
# Need to provide domain admin credentials

