 <#
.SYNOPSIS
  Provide script with a foldername, file types and destination folder. With this information the script will get all relevant files older than one month,
  archive them to the destination folder and move the original files to backup folder.

.PARAMETER FolderName
    The directory that we will be working with to archive

.PARAMETER DestinationPath
    Destination path for the archive.

.PARAMETER Filetype
    File type to filter for.

.INPUTS
  Invoke-Function -FolderName "C:\data" -DestinationPath "C:\Archive" -FileType "RTP"

.OUTPUTS
  File outputs error if any, using $Error[0].

.NOTES
  Version:        1.0
  Author:         Shahid Ahmed
  Creation Date:  October 20th, 2020
  Purpose/Change: Initial script development

.EXAMPLE
  Invoke-Function -FolderName "C:\data" -DestinationPath "C:\Archive" -FileType "RTP"
#>

function Invoke-Archive {

  [cmdletbinding()]
      # Parameters 
      param (
          [validateScript({test-path $_ -PathType 'Container'})]
          [parameter(Mandatory=$true)]
          [string]
          $FolderName
      ,
          [validateScript({test-path $_ -PathType 'Container'})]
          [parameter(Mandatory=$true)]
          [string]
          $DestinationPath
      ,
          [parameter(Mandatory=$true)]
          [string[]]
          $Filetype
      )
  begin {
          # Variable setup.
          $hostname = $env:COMPUTERNAME 
          $backupfolder = "\\mixs-share\Software\Script file backup\$hostname\"
          $error.clear()

          # Verify that there is a \ at the end of the variables
          if ($FolderName -notmatch '\\$') {
              $FolderName += '\'
          }

          if ($DestinationPath -notmatch '\\$') {
              $DestinationPath += '\'
          }

          # Show which folders will be worked on & backed up to
          Write-Output "You have entered $foldername with $Filetype to analyze and $DestinationPath as the destination to archive the zip files. Please be advised that this script does not delete the original file, it moves the original file to $backupfolder"
          Start-Sleep -Seconds 5
       }
  process {
      # For each file in the directory this loop will get the files creation date and filter for files a month old. It will create the destination folder in year\month format and archive the files there.
      $Pipeline_file = Get-Childitem -Path $FolderName* -Include $Filetype* | ForEach-Object {
          #
          # Place file name in variable so I can create zip files in the original file name.
          $file = $_.FullName | Where-Object -Property LastAccessTime -lt (get-date).AddDays(-31)
          #
          # Setting up variables: 
          $file_name = $_.BaseName #place file name in variable for zip file creation.
          $date = Get-Date ($_.CreationTime) # get file creation date
          $month = $date.month # Variable for month
          $year = $date.year #variable for year
          $Archive_dir = "$DestinationPath\$year\$month\" #Destination archive folder 
          #
          # Test if direcroty exists
          if (!(Test-Path $Archive_dir)) {
              New-Item $Archive_dir -type directory # If it does not exist, the directory will be created.
          }
          $Zip_name = "$Archive_dir$file_name" # Sets path and zip file name 
          Compress-Archive -LiteralPath $file -DestinationPath $Zip_name -Force # Create archive zip file
          if (!(Test-Path "$backupfolder$year\$month")) { # Test if backup folder exists.
              New-Item "$backupfolder$year\$month" -type directory #If it does not exist; create directory.
          } # Move original file to bcakup archive folder.
          Move-Item -Path $file -Destination "$backupfolder$year\$month"
          Write-Host $Error[0]
        } 
      }

  #End block
  End {
  }
  
}
#Call Function here
Invoke-archive