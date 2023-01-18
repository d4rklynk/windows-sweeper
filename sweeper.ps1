# Action du script
# calcule la volumétrie du disque avant le passage du script
# Supprime les profils utilisateurs non connecté depuis plus de X jours
# Suppression des fichiers TEMP windows
# Optimisation du WinSxS avec la commande dism.exe
# Vérifie la compression du dossier WinSxS
# Compresse le dossier WinSxS si ce n'est pas déja le cas
# charger la liste des utilisateurs (c:\users\)
# Purge des fichiers temporaire de chaque utilisateur
# - Fichier temporaire systéme de l'utilisateur
# - Fichier temporaire Internet Explorer
# - Fichier temporaire Chrome
# - Fichier temporaire Firefox
# - Fichier temporaire Java
# Vide la corbeille Windows
# Vérifie la presente d'un fichier pagefiles.sys
# Affiche la localisation et la taille du Pagefiles.sys
# Affiche la volumétrie avant et apres le passage du script
# Donne le pourcentage d'espace libre du disque C:
 
#Calcule de la taille des disques avant le script
    Write-Host "taille des disques avant purge"
    get-wmiobject win32_logicaldisk | where {$_.drivetype -eq 3} | tee-object -variable disques_avant |
    select-object @{e={$_.name};n="Disque"},
              @{e={[math]::round($_.size/1GB,2)};n="Capacité (Go)"},
              @{e={[math]::round($_.freespace/1GB,1)};n="Disponible (Go)"}
               
#calcule le pourcentage d'espace libre sur le disque c avant le script:        
$espacelibre_avant = Get-WmiObject -Class Win32_logicalDisk | ? {$_.DriveType -eq '3'}
$drive_avant = ($espacelibre_avant.DeviceID).Split("=")
$pourcentage_avant=(($espacelibre_avant.FreeSpace / $espacelibre_avant.Size)*100)
 
"Le disque C: à un espace libre de {0:P2}" -f ($espacelibre_avant.FreeSpace / $espacelibre_avant.Size)
"$pourcentage_avant"
 
#lancement de la suite du script si l'espace disque est suppérieur a 80%
#If ($pourcentage_avant -lt 80)
#{"inférieur à 80% fin du script"
#Exit
#}
 
#else
#{"supérieur a 80% lancement du script"}
 
#suppression des profils non ouvert depuis plus de 1000 jours
    Get-ChildItem "C:\Users" | Where {$_.LastWriteTime.Date -le (Get-Date).AddDays(-1000).Date} | Remove-Item -Force -Recurse
 
 
#Suppression des fichiers temporaire windows
    Write-Host "Suppression du contenu du répertoire Windows\Temp"   
    Get-childitem C:\Windows\Temp\* -force -recurse | remove-item -force -recurse
     
    Write-Host "Suppression du contenu du répertoire Windows\SoftwareDistribution\Download"   
    Get-childitem C:\Windows\SoftwareDistribution\Download\* -force -recurse | remove-item -force -recurse
 
#optimisation du WinSxS
    dism.exe /online /cleanup-image /startcomponentcleanup # retire tous les anciennes version de fichiers non utilisé ou remplacé suite à l'installation de patchs KB
 
#compression du WinSxS
$NTFSCompression = Get-Item -Path C:\users -Force | Select-Object -ExpandProperty Attributes
$NTFSCompressionfiles = ($NTFSCompression -band [IO.FileAttributes]::Compressed) -eq [IO.FileAttributes]::Compressed
if ($NTFSCompressionfiles -eq $true)
    {write-host "Compression NTFS de WINSXS déja active"}
else
    {write-host "Compression NTFS de WINSXS NON active"
        write-host "activation de la compression NTFS pour le WinSXS"
        #Stop-Service -Name msiserver #stopper Windows Installer
        #Stop-Service -Name TrustedInstaller #stopper Windows Module Installer
        cmd /c icacls "%WINDIR%\WinSxS" /save "%WINDIR%\WinSxS.acl /t" # archiver les droits du dossier WinSxS
        cmd /c takeown /f "%WINDIR%\WinSxS" /r #récupération des droits sur le fichier WinSxS
        cmd /c icacls "%WINDIR%\WinSxS" /grant "%USERDOMAIN%\%USERNAME%":(F) /t # recopie des droits sur le dossier WinSxS
        cmd /c compact /c /s:"%WINDIR%\WinSxS" /i # Compactage du dossier WinSxS
        cmd /c icacls "%WINDIR%\WinSxS" /setowner "NT SERVICE\TrustedInstaller" /t #Restaurer les droits sur TrustedInstaller
        cmd /c icacls "%WINDIR%" /restore "%WINDIR%\WinSxS.acl" #restaurer les ACLs pour WinSxS
        cmd /c del "%WINDIR%\WinSxS.acl"} # supprimer l'archive des droits WinSxS
        #Start-Service -Name msiserver #Réactiver le service Windows Installer à la demande
        #Start-Service -Name TrustedInstaller} #Réactiver le service Windows Module Installer à la demande
 
 
 #### Purge des Profils ###
    # Lister les profils
    $ListProfils = Get-ChildItem "C:\Users\" -Name
    # Enlever All users
    $ListProfils = $ListProfils -ne "Public"
    # Pour chaque profil
    ForEach ( $Profil in $ListProfils )
    {
         
        Write-Host "Suppression des temporaires de $Profil"
        Get-ChildItem "C:\Users\$Profil\AppData\Local\Temp\*" -force -recurse | remove-item -force -recurse
         
        if (Test-Path -path "C:\Users\$Profil\AppData\Local\Microsoft\Windows\Temporary Internet Files\")
        {Write-Host "Suppression du cache Internet Explorer de $Profil"
        Get-ChildItem "C:\Users\$Profil\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -force -recurse | remove-item -force -recurse
        else
        {Write-Host "Pas de fichier temporaire IE sur $Profil"}
         
        Write-Host "Suppression du cache Explorer de $Profil"
        Get-ChildItem "C:\Users\$Profil\AppData\Local\Microsoft\Windows\Explorer\*" -force -recurse | remove-item -force -recurse
         
        # Lister dossiers générés par Chrome
        if (Test-Path -path "C:\Users\$Profil\AppData\Local\Google\Chrome\User Data\Default\Cache\")
        {Write-Host "Suppression du cache de Chrome de $Profil"
        Get-childitem "C:\Users\$Profil\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -force -recurse | remove-item -force -recurse}
        else
        {Write-Host "Pas de Chrome sur $Profil"}
         
        if (Test-Path -path "C:\Users\$Profil\AppData\LocalLow\Google\")
        {Write-Host "Suppression du cache de Google Earth de $Profil"
        Get-ChildItem "C:\Users\$Profil\AppData\LocalLow\Google\GoogleEarth\dbCache*.dat" -force -recurse | remove-item -force -recurse
        Get-ChildItem "C:\Users\$Profil\AppData\LocalLow\Google\GoogleEarthPlugin\dbCache*.dat" -force -recurse | remove-item -force -recurse}
        else
        {Write-Host "Pas de Chrome sur $Profil"}
         
        # Lister dossiers générés par FireFox
        if (Test-Path -path "C:\Users\$Profil\AppData\Roaming\Mozilla\Firefox\")
        {Write-Host "Suppression des crash FireFox de $Profil"
        Get-ChildItem "C:\Users\$Profil\AppData\Roaming\Mozilla\Firefox\Crash Reports\pending\*" -force -recurse | remove-item -force -recurse}
        else
        {Write-Host "Pas de FireFox sur $Profil"}
         
        # Lister dossiers générés par Firefox dans le profil utilisateur
        if (Test-Path -path "C:\Users\$Profil\AppData\Local\Mozilla\Firefox\")
        {$ListFolders = Get-ChildItem "C:\Users\$Profil\AppData\Local\Mozilla\Firefox\Profiles\" -Name
        ForEach ($Folder in $ListFolders)
        {Write-Host "Suppression du cache de FireFox de $Profil"
        Get-ChildItem "C:\Users\$Profil\AppData\Local\Mozilla\Firefox\Profiles\$Folder\Cache\*" -force -recurse | remove-item -force -recurse}
        else
        {}  
        # Lister dossiers générés par Java
        if(Test-Path -path "C:\Users\$Profil\AppData\sun\java\deployment\cache\")
        {Write-Host "Suppression du cache de Java de $Profil"
        Get-childitem "C:\Users\$Profil\AppData\sun\java\deployment\cache\*" -force -recurse | remove-item -force -recurse}
        else
        {Write-Host "Pas de Java sur $Profil"}}
         
        Write-Host "Suppression des logs de Windows Update"
        Get-ChildItem "C:\Users\$Profil\AppData\Local\Microsoft\Windows\WindowsUpdate.log" -force -recurse | remove-item -force -recurse
         
        }
    }
 
# Lancement du nettoyage des disques
 
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$Section
)
 
$sections = @(
    'Active Setup Temp Folders',
    'BranchCache',
    'Content Indexer Cleaner',
    'Device Driver Packages',
    'Downloaded Program Files',
    'GameNewsFiles',
    'GameStatisticsFiles',
    'GameUpdateFiles',
    'Internet Cache Files',
    'Memory Dump Files',
    'Offline Pages Files',
    'Old ChkDsk Files',
    'Previous Installations',
    'Recycle Bin',
    'Service Pack Cleanup',
    'Setup Log Files',
    'System error memory dump files',
    'System error minidump files',
    'Temporary Files',
    'Temporary Setup Files',
    'Temporary Sync Files',
    'Thumbnail Cache',
    'Update Cleanup',
    'Upgrade Discarded Files',
    'User file versions',
    'Windows Defender',
    'Windows Error Reporting Archive Files',
    'Windows Error Reporting Queue Files',
    'Windows Error Reporting System Archive Files',
    'Windows Error Reporting System Queue Files',
    'Windows ESD installation files',
    'Windows Upgrade Log Files'
)
 
if ($PSBoundParameters.ContainsKey('Section')) {
    if ($Section -notin $sections) {
        throw "The section [$($Section)] is not available. Available options are: [$($Section -join ',')]."
    }
} else {
    $Section = $sections
}
 
Write-Verbose -Message 'Lancement du nettoyage de disque windows.'
 
$getItemParams = @{
    Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
    Name        = 'StateFlags0001'
    ErrorAction = 'SilentlyContinue'
}
Get-ItemProperty @getItemParams | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue
 
Write-Verbose -Message 'Ajout de sections de nettoyage de disque...'
foreach ($keyName in $Section) {
    $newItemParams = @{
        Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
        Name         = 'StateFlags0001'
        Value        = 1
        PropertyType = 'DWord'
        ErrorAction  = 'SilentlyContinue'
    }
    $null = New-ItemProperty @newItemParams
}
 
Write-Verbose -Message 'Lancement du CleanMgr.exe...'
Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait
 
Write-Verbose -Message 'processus CleanMgr et DismHost en cours de traitement...'
Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process
 
# Vider la corbeile windows
    Write-host "vider la corbeile windows"
    Clear-RecycleBin -Force
     
# Afficher les espaces disque:
    Write-Host "Espace disque après nettoyage"
    get-wmiobject -computer $poste win32_logicaldisk | where {$_.drivetype -eq 3} | tee-object -variable disques_apres |
    select-object @{e={$_.name};n="Disque"},
                  @{e={[math]::round($_.size/1GB,2)};n="Capacité (Go)"},
                  @{e={[math]::round($_.freespace/1GB,1)};n="Disponible (Go)"}  
                   
#calcule le pourcentage d'espace libre sur le disque c apres le script:        
    $espacelibre_apres = Get-WmiObject -Class Win32_logicalDisk | ? {$_.DriveType -eq '3'}
    $drive_apres = ($espacelibre_apres.DeviceID).Split("=")
    "Le disque $drive à un espace libre de {0:P2}" -f ($espacelibre_apres.FreeSpace / $espacelibre_apres.Size)
         
#Rapport final     
    Write-Host "============Récapitulatif============"
    Write-Host ""
    Write-Host "Etat du disque C avant le passage du script"
    Write-Host "$disques_apres"
    "Le disque $drive à un espace llibre de {0:P2}" -f ($espacelibre_avant.FreeSpace / $espacelibre_avant.Size)
    Write-Host ""
    Write-Host ""
    Write-Host "Etat du disque C apres le passage du script"
    Write-Host "$disques_apres"
    "Le disque $drive à un espace libre de {0:P2}" -f ($espacelibre_apres.FreeSpace / $espacelibre_apres.Size)
    Write-Host ""
    Write-Host ""
# un fichier Pagefile.sys
    $swapsystem = Get-CimInstance Win32_PageFileUsage | select-object Name, AllocatedBaseSize | Format-Table
    Write-Host "$swapsystem"
    Write-Host ""
    Write-Host "============Récapitulatif============"
