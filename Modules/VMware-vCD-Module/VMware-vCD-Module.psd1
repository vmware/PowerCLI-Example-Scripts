#
# Modulmanifest f�r das Modul "PSGet_VMware-vCD-Module"
#
# Generiert von: Markus
#
# Generiert am: 6/11/2017
#

@{

# Die diesem Manifest zugeordnete Skript- oder Bin�rmoduldatei.
# RootModule = ''

# Die Versionsnummer dieses Moduls
ModuleVersion = '1.3.0'

# ID zur eindeutigen Kennzeichnung dieses Moduls
GUID = '1ef8a2de-ca22-4c88-8cdb-e00f35007d2a'

# Autor dieses Moduls
Author = 'Markus Kraus'

# Unternehmen oder Hersteller dieses Moduls
CompanyName = 'mycloudrevolution.com'

# Urheberrechtserkl�rung f�r dieses Modul
Copyright = '(c) 2017 Markus. Alle Rechte vorbehalten.'

# Beschreibung der von diesem Modul bereitgestellten Funktionen
Description = 'This a POwerShell Module based on VMware PowerCLI vCloud Director Module to extend its function'

# Die f�r dieses Modul mindestens erforderliche Version des Windows PowerShell-Moduls
# PowerShellVersion = ''

# Der Name des f�r dieses Modul erforderlichen Windows PowerShell-Hosts
# PowerShellHostName = ''

# Die f�r dieses Modul mindestens erforderliche Version des Windows PowerShell-Hosts
# PowerShellHostVersion = ''

# Die f�r dieses Modul mindestens erforderliche Microsoft .NET Framework-Version
# DotNetFrameworkVersion = ''

# Die f�r dieses Modul mindestens erforderliche Version der CLR (Common Language Runtime)
# CLRVersion = ''

# Die f�r dieses Modul erforderliche Prozessorarchitektur ("Keine", "X86", "Amd64").
# ProcessorArchitecture = ''

# Die Module, die vor dem Importieren dieses Moduls in die globale Umgebung geladen werden m�ssen
RequiredModules = @('VMware.VimAutomation.Cloud')

# Die Assemblys, die vor dem Importieren dieses Moduls geladen werden m�ssen
# RequiredAssemblies = @()

# Die Skriptdateien (PS1-Dateien), die vor dem Importieren dieses Moduls in der Umgebung des Aufrufers ausgef�hrt werden.
# ScriptsToProcess = @()

# Die Typdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# TypesToProcess = @()

# Die Formatdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# FormatsToProcess = @()

# Die Module, die als geschachtelte Module des in "RootModule/ModuleToProcess" angegebenen Moduls importiert werden sollen.
NestedModules = @('functions\Invoke-MyOnBoarding.psm1',
               'functions\New-MyEdgeGateway.psm1',
               'functions\New-MyOrg.psm1',
               'functions\New-MyOrgAdmin.psm1',
               'functions\New-MyOrgVdc.psm1',
               'functions\New-MyOrgNetwork.psm1'
               )

# Aus diesem Modul zu exportierende Funktionen
FunctionsToExport = 'Invoke-MyOnBoarding', 'New-MyEdgeGateway', 'New-MyOrg', 'New-MyOrgAdmin', 'New-MyOrgVdc', 'New-MyOrgNetwork'

# Aus diesem Modul zu exportierende Cmdlets
CmdletsToExport = '*'

# Die aus diesem Modul zu exportierenden Variablen
VariablesToExport = '*'

# Aus diesem Modul zu exportierende Aliase
AliasesToExport = '*'

# Aus diesem Modul zu exportierende DSC-Ressourcen
# DscResourcesToExport = @()

# Liste aller Module in diesem Modulpaket
# ModuleList = @()

# Liste aller Dateien in diesem Modulpaket
# FileList = @()

# Die privaten Daten, die an das in "RootModule/ModuleToProcess" angegebene Modul �bergeben werden sollen. Diese k�nnen auch eine PSData-Hashtabelle mit zus�tzlichen von PowerShell verwendeten Modulmetadaten enthalten.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('VMware', 'vCloud', 'PowerCLI', 'vCloudDirector', 'Automation', 'EdgeGateway', 'OrgNetwork')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/mycloudrevolution/VMware-vCD-Module/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/mycloudrevolution/VMware-vCD-Module'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/mycloudrevolution/VMware-vCD-Module/blob/master/media/vCD_Small.png'

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # External dependent modules of this module
        ExternalModuleDependencies = 'VMware.VimAutomation.Cloud'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo-URI dieses Moduls
# HelpInfoURI = ''

# Standardpr�fix f�r Befehle, die aus diesem Modul exportiert werden. Das Standardpr�fix kann mit "Import-Module -Prefix" �berschrieben werden.
# DefaultCommandPrefix = ''

}

