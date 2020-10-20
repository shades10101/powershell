$hostname = 'hostname' ## Add hostname
$Domain = '' ## put domain name here
$Credential = 'domain\administrator'

Rename-Computer $hostname
Add-Computer -Domain $Domain -NewName $hostname -Credential $Credential -Restart -Force