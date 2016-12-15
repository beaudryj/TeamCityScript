function Get-TeamCityChangeIds{
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Server,
    [string]$buildId
)
    
    $uri = "$Server/httpAuth/app/rest/changes?build=id:$buildId"
    
    try{
    $ID = Invoke-RestMethod -Uri $uri -Method GET -Credential $credential 
    $IDList = $Id.changes.change.id
    }
    catch{
        $result = $_.Exception.Response | out-string 
        write-error "$result"
    }
return $IDList
}

function Get-TeamCityChanges{
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Server,
    [string]$changeId
)
    
    $uri = "$Server/httpAuth/app/rest/changes/id:$changeId"
    
    try{
    $change = Invoke-RestMethod -Uri $uri -Method GET -Credential $credential 
    }
    catch{
        $result = $_.Exception.Response | out-string 
        write-error "$result"
    }
    $Time = $change.change.date
    $truncatedstring = $Time.split("-")[0]                      
    $truncatedstring = $truncatedstring.Insert(4,"-").Insert(7,"-").Insert(10,"-").Insert(14,":").Insert(17,":")
    $change.change.date = $truncatedstring
    $commitID = $change.change.version
    $ChangeList = $change.change | format-list @{Name="Date/Time";expression={$_.date}},@{Name="commitId";expression={$_.version}},@{Name="Author";expression={$_.username}},comment | Out-String
    $FileChanges = $change.change.files.file | format-list changeType,File | Out-string

    $CommitString = @"

    -------------
    Changes Made in commit:
    commitID: $commitID
    -------------

    $ChangeList

    Files Changed in commit:
    $FileChanges
"@
     
     write-output $CommitString

}

function Get-TeamCityChanges{
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Server,
    [string]$changeId
)
    
    $uri = "$Server/httpAuth/app/rest/changes/id:$changeId"
    
    try{
    $change = Invoke-RestMethod -Uri $uri -Method GET -Credential $credential 
    }
    catch{
        $result = $_.Exception.Response | out-string 
        write-error "$result"
    }
    $Time = $change.change.date
    $truncatedstring = $Time.split("-")[0]                      
    $truncatedstring = $truncatedstring.Insert(4,"-").Insert(7,"-").Insert(10,"-").Insert(14,":").Insert(17,":")
    $change.change.date = $truncatedstring
    $commitID = $change.change.version
    $ChangeList = $change.change | format-list @{Name="Date/Time";expression={$_.date}},@{Name="commitId";expression={$_.version}},@{Name="Author";expression={$_.username}},comment | Out-String
    $FileChanges = $change.change.files.file | format-list changeType,File | Out-string

    $CommitString = @"

    -------------
    Changes Made in commit:
    commitID: $commitID
    -------------

    $ChangeList

    Files Changed in commit:
    $FileChanges
"@
     
     write-output $CommitString

}

$Changes = Get-TeamCityChangeIds -credential $Credential -Server $Server -buildId $buildID

New-File Changelog.txt 



Foreach ($changeID in $Changes){
Get-TeamCityChanges -credential $Credential -Server $Server -changeId $changeID | out-file -append Changelog.txt 
}

