# Remove Windows 10 Bloatware.
#
get-appxpackage | where { $_.name -like "*bing*"} | remove-appxpackage
get-appxpackage | where { $_.name -like "*advertising*"} | remove-appxpackage
get-appxpackage | where { $_.name -like "*zune*"} | remove-appxpackage
get-appxpackage | where { $_.name -like "*office*"} | remove-appxpackage
get-appxpackage | where { $_.name -like "*Xbox*"} | remove-appxpackage
get-appxpackage | where { $_.name -like "*onenote*"} | remove-appxpackage
get-appxpackage | where { $_.name -like "*skype*"} | remove-appxpackage