$branch = "%teamcity.build.branch%"

if ($branch.contains("master")){
	$branch = $branch.split("/")[2]
    $JiraKey = $branch
}
elseif ($branch.contains("feature")){
    write-output "using $branch"
    $JiraKey = ($branch | Select-String -Pattern '((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)' | % matches).value
    if ($JiraKey -eq $null){
        $branch = $branch.split("/")[1]
        Write-Host "##teamcity[setParameter name='env.JiraKey' value='$JiraKey']"
    }else{
    Write-Host "##teamcity[setParameter name='env.JiraKey' value='$JiraKey']"
    }
}
elseif ($branch.contains("hotfix")){
    write-output "using $branch"
    $JiraKey = ($branch | Select-String -Pattern '((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)' | % matches).value
    if ($JiraKey -eq $null){
        $branch = $branch.split("/")[1]
        Write-Host "##teamcity[setParameter name='env.JiraKey' value='$JiraKey']"
    }else{
    Write-Host "##teamcity[setParameter name='env.JiraKey' value='$JiraKey']"
    }
}
elseif ($branch.contains("bugfix")){
    write-output "using $branch"
    $JiraKey = ($branch | Select-String -Pattern '((?<!([A-Z]{1,10})-?)[A-Z]+-\d+)' | % matches).value
    if ($JiraKey -eq $null){
        $branch = $branch.split("/")[1]
        Write-Host "##teamcity[setParameter name='env.JiraKey' value='$JiraKey']"
    }else{
    Write-Host "##teamcity[setParameter name='env.JiraKey' value='$JiraKey']"
    }
}
elseif ($branch.contains("develop")){
	$branch = $branch.split("/")[2]
    $JiraKey = $branch
}
else{
    write-output "using $branch"
}

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
    $commitID = $change.change.version
    $ChangeList = $change.change | format-list @{Name="Date/Time";expression={$_.date}},@{Name="commitId";expression={$_.version}},@{Name="Author";expression={$_.username}},comment | Out-String
    $FileChanges = $change.change.files.file | format-list changeType,File | Out-string


    $CommitString = @"

# Changes Made in commit:

``````
    $ChangeList
``````

# Files Changed in commit:
``````
    $FileChanges
``````
"@
     
     
     write-output $CommitString

}

$tcUser = "%tcuser%"
$tcPassword = "%tcpassword%"
$secpasswd = ConvertTo-SecureString $tcPassword -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($tcUser, $secpasswd)
$Credential = $mycreds  
$Server = "%teamcity.serverUrl%"
$buildID = "%teamcity.build.id%"


$Intro = @"

# Link to Jira Story
[Link to Jira Story $JiraKey](/browse/$JiraKey)


## Changes for %system.teamcity.projectName%


### On: %teamcity.build.branch%


"@


Write-Output $Intro | Out-file "%system.teamcity.build.tempDir%\changelog.txt" 

$Changes = Get-TeamCityChangeIds -credential $Credential -Server $Server -buildId $buildID
Write-Output "Using $Changes to build Changelog"

Foreach ($changeID in $Changes){
write-output "Appending $changeID to %system.teamcity.build.tempDir%\changelog.txt "
Get-TeamCityChanges -credential $Credential -Server $Server -changeId $changeID | out-file -Append -filepath "%system.teamcity.build.tempDir%\changelog.txt"
}

Get-Content "%system.teamcity.build.tempDir%\changelog.txt"
