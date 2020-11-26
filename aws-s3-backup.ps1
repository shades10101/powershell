#Requires -Version 3
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development

.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>


#--------[Params]---------------
Param(
  [parameter(Mandatory = $True)] [string]$BucketName,
  [parameter(Mandatory = $True)] [string]$Key,
  [parameter(Mandatory = $True)] [string]$Object,
  [parameter(Mandatory = $False)] [string]$Pattern,
  [parameter(Mandatory = $False)] [string]$Tag,
  [parameter(Mandatory = $False)] [string]$ProfileName
)
#--------[Script]---------------


Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$scriptName = Split-Path -Path $PSCommandPath -Leaf
$scriptDir = Split-Path -Path $PSCommandPath -Parent
$startingLoc = Get-Location
Set-Location $scriptDir
$startingDir = [System.Environment]::CurrentDirectory
[System.Environment]::CurrentDirectory = $scriptDir


# TEMP FIX
# ENV NOT UPDATED FOR SYSTEM USER CAUSES ISSUES WITH TASK SCHEDULER
# Default Path
$PSAWSModulePath = "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell"

function TryModule() {
  param(
    [Parameter(Mandatory = $true)][string]$name,
    [Parameter(Mandatory = $false)][string]$fallback
  )

  if (-not (Get-Module | Where-Object { $_.Name -eq $name })) {
    if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $name }) {
      Import-Module $name
    }
    else {
      if ($fallback) {
        Import-Module $fallback
      }
    }
  }
}

function Backup() {
  param(
    [Parameter(Mandatory = $True)][object]$item
  )

  $itemPath = ((Split-Path -Path (Split-Path -Path $item -Parent) -NoQualifier)) -Replace "[\\]", "/"
  $itemName = Split-Path -Path $item -Leaf
  $itemKey = ("$Key/$itemPath/$itemName" -Replace "[/]{2,}", "/")

  $itemObj = Get-S3Object -BucketName $BucketName -Key $itemKey

  if (-not ($itemObj)) {
    Write-Output "Uploading: $itemKey"
    try {
      Write-S3Object -BucketName $BucketName -Key $itemKey -File $item.FullName -TagSet @{Key = "Type"; Value = $Tag }
    }
    catch [Exception] {
      Write-Output $_.Exception.GetType().FullName, $_.Exception.Message
    }
  }
  else {
    if (($item.LastWriteTime -gt $itemObj.LastModified) -or ($item.Length -gt $itemObj.Size)) {
      Write-Output "Exists (Modified): $itemKey"
      Write-Output "Uploading: $itemKey"
      try {
        Write-S3Object -BucketName $BucketName -Key $itemKey -File $item.FullName -TagSet @{Key = "Type"; Value = $Tag }
      }
      catch [Exception] {
        Write-Output $_.Exception.GetType().FullName, $_.Exception.Message
      }
    }
    else {
      Write-Output "Exists (Not Modified): $itemKey"
    }
  }
}

try {

  $transcriptsDir = "$([System.Environment]::CurrentDirectory)\transcripts\"
  if (-not (Test-Path -Path $transcriptsDir)) {
    New-Item -ItemType Directory -Force -Path $transcriptsDir
  }
  else {
    $expired = (Get-Date).AddDays(-7)
    Get-ChildItem -Recurse -Path $transcriptsDir | Where-Object { ! $_.PSIsContainer -and ($_.CreationTime -lt $expired -and $_.LastWriteTime -lt $expired -and $_.LastAccessTime -lt $expired) } | Foreach-Object -Process {
      Write-Output "Deleting, $_"
      Remove-Item -Path $_.FullName
    }
  }

  Start-Transcript -OutputDirectory $transcriptsDir

  if (-not ($ProfileName)) {
    $ProfileName = "backups"
  }

  if (-not ($Tag)) {
    $Tag = "Unknown"
  }

  TryModule -Name AWSPowerShell -fallback $PSAWSModulePath

  if ($ProfileName) {
    Set-AWSCredential -ProfileName $ProfileName
  }

  Get-STSCallerIdentity | Write-Output

  if (-not (Split-Path -Path $Object -IsAbsolute)) {
    $item = Get-Item -Path (Join-Path -Path $startingDir -ChildPath $Object)
  }
  else {
    $item = Get-Item -Path $Object
  }

  $itemDirectory = $item -is [System.IO.DirectoryInfo]
  $itemFile = $item -is [System.IO.FileInfo]

  if ($itemFile) {
    Backup -item $item
  }
  elseif ($itemDirectory) {
    $item = (Get-ChildItem -Path $item.FullName -Exclude transcripts | Get-ChildItem -Recurse | Where-Object { ! $_.PSIsContainer })

    if ($Pattern) {
      $item = $item | Where-Object { $_.FullName -Like $Pattern }
    }
    $item | Foreach-Object -Process {
      Backup -item $_
    }
  }
  else {
    throw "Item is unknown."
  }
}
catch  [Exception] {
  Write-Output $_.Exception.GetType().FullName, $_.Exception.Message
}
finally {
  Set-Location $startingLoc
  [System.Environment]::CurrentDirectory = $startingDir
  Write-Output "Done. Elapsed time: $($stopwatch.Elapsed)"

  Stop-Transcript
}
