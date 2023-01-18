# windows-sweeper
To clean some stuff on Windows without installing sketchy software that y'all know. Safe script

Can be used in business if you [RTFM](https://fr.wikipedia.org/wiki/RTFM_(expression)) before. Just ***read*** the script, don't do IKEA.

# Quick summon

`irm raw.githubusercontent.com/d4rklynk/windows-sweeper/main/sweeper.ps1 | iex`

or

`iwr -useb https://raw.githubusercontent.com/d4rklynk/windows-sweeper/main/sweeper.ps1 | iex`

# [FRENCH] Action du script
Calcul de la volumétrie du disque avant le passage du script
Suppression des profils utilisateurs non connecté depuis plus de X jours (1000 dans le script)
Suppression des fichiers TEMP windows
Optimisation du WinSxS avec la commande dism.exe
Vérifie la compression du dossier WinSxS
Compresse le dossier WinSxS si ce n'est pas déja le cas
Charge la liste des utilisateurs (c:\users\)
Purge des fichiers temporaires de chaque utilisateur
 - Fichier temporaire systéme de l'utilisateur
 - Fichier temporaire Internet Explorer
 - Fichier temporaire Chrome
 - Fichier temporaire Firefox
 - Fichier temporaire Java

Vide la corbeille Windows
Vérifie la presente d'un fichier pagefiles.sys
Affiche la localisation et la taille du Pagefiles.sys
Affiche la volumétrie avant et apres le passage du script
Donne le pourcentage d'espace libre du disque C:
