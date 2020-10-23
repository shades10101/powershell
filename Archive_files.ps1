 <#
.SYNOPSIS
  Provide script with a foldername, file types and destination folder. With this information the script will get all relevant files older than one month,
  archive them to the destination folder and move the original files to backup folder. As per the ticket that I was working with, this searches for wildcards in the filename.
  The use case for this file is to clean up the AQS folder on the app servers that are running out of space: https://hd.univeris.com/browse/INF-10621

.PARAMETER FolderName
    The directory that we will be working with to archive

.PARAMETER DestinationPath
    Destination path for the archive.

.PARAMETER Filetype
    File type to filter for.
    
.PARAMETER Archive_file_older_than_days
	How old should the files be?

.INPUTS
  Invoke-archive -FolderName "C:\data" -DestinationPath "C:\Archive" -FileType "RTP"

.OUTPUTS
  File outputs error if any, using $Error[0].

.NOTES
  Version:        1.0
  Author:         Shahid Ahmed
  Creation Date:  October 20th, 2020
  Purpose/Change: Initial script development

.EXAMPLE
  Open powershell: . .\Archive_files
  It will ask for values, provide values
  
#>
#
# Using a function allows us to provide custom parameters, with these parameters we can set
# a custom source folder, custom destination directory folder for the archived files, custom backup folder so we have some fault tolerance for this script/server, and
# we can proivde a file wildcard - this is not for the file extenxtion, but the first letter wildcards for AQS folder. 
#
function Invoke-archive {

    [cmdletbinding()]
        # Parameters 
        param (
            [validateScript({test-path $_ -PathType 'Container'})]
            [parameter(Mandatory=$true)]
            [string]
            $FolderName # Source folder to analyze, director existance is tested.
        ,
            [validateScript({test-path $_ -PathType 'Container'})]
            [parameter(Mandatory=$true)]
            [string]
            $DestinationPath # Destination folder to archive files too, director existance is tested.
        ,
            [validateScript({test-path $_ -PathType 'Container'})]
            [parameter(Mandatory=$true)]
            [string]
            $Backupfolder # Backup folder to move the original files to, director existance is tested.
        ,
            [parameter(Mandatory=$true)]
            [string]
            $Filetype # File wildcard to analyze
        ,
            [parameter(Mandatory=$true)]
            [Int]
            $Archive_file_older_than_days
        )
    begin {
            # variables
            $Hostname = $env:COMPUTERNAME # Map hostname to a variable
            $Error.clear() #Clear the last Powershell log.

            #Verify that there is a \ at the end of the directory name, if not: add one.
            if ($FolderName -notmatch '\\$') {
                $FolderName += '\'
            }
            if ($DestinationPath -notmatch '\\$') {
                $DestinationPath += '\'
            }
            if ($Backupfolder -notmatch '\\$') {
                $Backupfolder += '\'
            }
            
            # Advise user which folders will be worked, where it will archived, and where the original files will move to.
            Write-Output "You have entered $Foldername with $Filetype to analyze and $DestinationPath as the destination to archive the zip files. Please be advised that this script does not delete the original file, it moves the original file to $Backupfolder"
            Start-Sleep -Seconds 5
         }
    process {
        # For each file in the directory that matches the wild card, this loop will get its creation date (MM:YY) and place the file in destination directory as archive. It will also move the original file to a backup folder.
        $File = Get-Childitem -Path $FolderName* -Include $Filetype* | Where-Object -Property LastAccessTime -lt (get-date).AddDays(-$Archive_file_older_than_days) | ForEach-Object { # Filter folder for wildcard files and files that are older than 31 days.
            # Mapping file path to Path, file name to file_name, file creation date to Date, month of creation to Month, Year of creation to Year, and Mapping archive directory to archive_dir.
            $Path = $_.FullName
            $File_name = $_.BaseName
            $Date = Get-Date ($_.CreationTime)
            $Month = $Date.month
            $Year = $Date.year
            $Archive_dir = "$DestinationPath$Year\$Month\" 
      		
            # Test if the directories exist, if they dont create the directores.
            if (!(Test-Path $Archive_dir)) {
                New-Item $Archive_dir -type directory
            }
            # Zip_name creates the archives destination path and name
            $Zip_name = "$Archive_dir$File_name"
            Compress-Archive -LiteralPath $Path -DestinationPath $Zip_name -Force # Compress file and place to destination, -Force makes sure there will be no prompts.
            # Test existance of backup folder, if none it will create it. 
            if (!(Test-Path "$Backupfolder$Hostname\$Year\$Month")) {
                New-Item "$Backupfolder$Hostname\$year\$Month" -type directory
            }
            # Move original item to the backup folder.
            Move-Item -Path $Path -Destination "$Backupfolder$Hostname\$Year\$Month"
            # Error catching and clearing. 0 displays the newest error, since we are in a loop we need to clear the error once the loop cycle is complete.
            Write-Host $Error[0]
            $Error.clear()
      } 
      }
    # End block
    End {
    }
}
# Calls the Function
Invoke-archive
