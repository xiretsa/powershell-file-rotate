<#
    Module Permettant d'effectuer une rotation de fichiers dans un dossier
#>

<#

.SYNOPSIS
Suppression de fichiers dans un dossier par tri alphab�tique.


.DESCRIPTION
Supprime tous les fichiers par ordre alphab�tique ou par ordre inverse
pour ne conserver que le nombre de fichiers indiqu�s.
Possibilit� d'effectuer des filtres sur le nom des fichiers avec wildcards.

.PARAMETER $Descending
Switch permettant d'indiquer si le tri doit �tre fait par order alphab�tique inverse.
Si le switch n'est pas indiqu� ou vaut false, alors on tri par ordre alphab�tique.
S'il est indiqu� ou qu'il vaut true, alors on tri par ordre alphab�tique inverse.

.PARAMETER $NumberOfFilesToKeep
Nombre de fichiers � conserver dans le dossier.

.PARAMETER $DirectoryPath
Chemin du dossier dans lequel effectuer le traitement

.PARAMETER $Filter
Facultatif. Permet d'ajouter un filtre sur le nom de fichier comme par exemple *.log

.EXAMPLE
Remove-ByAlphabeticalFileName -NumberOfFilesToKeep 10 -DirectoryPath C:\temp -Verbose

.EXAMPLE
Remove-ByAlphabeticalFileName -NumberOfFilesToKeep 10 -DirectoryPath C:\temp -Verbose -Filter *.txt

.EXAMPLE
Remove-ByAlphabeticalFileName -NumberOfFilesToKeep 10 -DirectoryPath C:\temp -Verbose -Filter *.txt -Descending
#>
function Remove-ByAlphabeticalFileName {
    Param (
        [parameter(Mandatory=$false)]
        [alias("DESC")]
        [switch] $Descending,

        [parameter(Mandatory=$true)]
        [alias("Keep")]
        [ValidateScript({if($_ -gt 0) {
            $True
        } Else {
            Throw "NumberOfFilesToKeep must be greater than 0"
        }})]
        [int] $NumberOfFilesToKeep,

        [parameter(Mandatory=$true)]
        [alias("Folder", "Directory", "Path")]
        [ValidateScript({If(Test-Path $_ -PathType Container) {
            $True
        } Else {
            Throw "$_ isn't a valid directory"
        }})]
        [string] $DirectoryPath,

        [parameter(Mandatory=$false)]
        [string] $Filter

    )

    Process {
        Write-Verbose $([string]::Format( `
            "D�marrage du nettoyage du dossier [{0}] par tri alphab�tique [inverse : {1}]. Nombre de fichiers conserv�s [{2}]", `
            $DirectoryPath, `
            $Descending.IsPresent, `
            $NumberOfFilesToKeep))
        if($Filter.Length -gt 0) {
            $files = @(Get-ChildItem -Path $DirectoryPath -File -Filter $Filter | Sort-Object name -Descending:$Descending.IsPresent)
        } else {
            $files = @(Get-ChildItem -Path $DirectoryPath -File | Sort-Object name -Descending:$Descending.IsPresent)
        }
        Write-Verbose $([string]::Format("Il y a [{0}] fichier dans le dossier actuellement", $files.Length))
        if($files.Length -le $NumberOfFilesToKeep) {
            Write-Host "Le dossier contient un nombre de fichiers inf�rieur ou �gal au nombre de fichier � conserver, le traitement est inutile"
            return
        }
        $filesNumber = $files.Length
        foreach($file in $files) {
            Write-Verbose $([string]::Format("Suppresion du fichier [{0}]", $file.fullName))
            Remove-Item $file.fullName
            if(--$filesNumber -le $NumberOfFilesToKeep) {
                return
            }
        }
    }
}

<#

.SYNOPSIS
Suppression de fichiers dans un dossier par date de modification.


.DESCRIPTION
Supprime tous les fichiers dont la date de modification date de plus du nombre de jours indiqu�s

.PARAMETER $NumberOfDaysToKeep
Nombre de jours � conserveur. Tous les fichiers dont la date de modification est inf�reure �
aujourd'hui moins ce nombre de jours seront supprim�s

.PARAMETER $DirectoryPath
Chemin du dossier dans lequel effectuer le traitement

.PARAMETER $Filter
Facultatif. Permet d'ajouter un filtre sur le nom de fichier comme par exemple *.log

.EXAMPLE
Remove-ModificationDateMoreThanNumberDays -DirectoryPath "C:\Temp" -NumberOfDaysToKeep 50 -Filter *.tmp -Verbose

#>
function Remove-ModificationDateMoreThanNumberDays {
    Param (

        [parameter(Mandatory=$true)]
        [alias("Folder", "Directory", "Path")]
        [ValidateScript({If(Test-Path $_ -PathType Container) {
            $True
        } Else {
            Throw "$_ isn't a valid directory"
        }})]
        [string] $DirectoryPath,

        [parameter(Mandatory=$true)]
        [alias("Days")]
        [ValidateScript({if($_ -gt 0) {
            $True
        } Else {
            Throw "NumberOfDaysToKeep must be greater than 0"
        }})]
        [int] $NumberOfDaysToKeep,

        [parameter(Mandatory=$false)]
        [string] $Filter
    )

    Process {
        Write-Verbose $([string]::Format( `
            "D�marrage du nettoyage du dossier [{0}] datant de plus de [{1}] jours.", `
            $DirectoryPath, `
            $NumberOfDaysToKeep))

        if($Filter.Length -gt 0) {
            $files = @(Get-ChildItem -Path $DirectoryPath -File -Filter $Filter | Where-Object {$_.LastWriteTime -lt (Get-Date).addDays($NumberOfDaysToKeep * -1)} | Sort-Object LastWriteTime)
        } else {
            $files = @(Get-ChildItem -Path $DirectoryPath -File | Where-Object {$_.LastWriteTime -lt (Get-Date).addDays($NumberOfDaysToKeep * -1)} | Sort-Object LastWriteTime)
        }
        Write-Verbose $([string]::Format("Il y a [{0}] fichier dans le dossier actuellement", $files.Length))
        foreach($file in $files) {
            Write-Verbose $([string]::Format("Suppresion du fichier [{0}]", $file.fullName))
            Remove-Item $file.fullName
        }
    }
}