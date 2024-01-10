Function Info($msg) {
  Write-Host -ForegroundColor DarkGreen "`n$msg`n"
}

Function Error($msg) {
  Write-Host `n`n
  Write-Error $msg
  exit 1
}

Function CheckReturnCodeOfPreviousCommand($msg) {
  if(-Not $?) {
    Error "${msg}. Error code: $LastExitCode"
  }
}

Function CreateFileWithContent([System.IO.FileInfo] $file, [string] $content) {
  Info "Create file '$file' filled with provided string"
  New-Item -Force -ItemType directory $file.Directory.FullName > $null
  [System.IO.File]::WriteAllText($file, $content)
}

Function AssertStringsAreEqual([string] $str1, [string] $str2) {
  if($str1 -ne $str2) {
    Error "Test failed`n$str1`nshould be equal to`n$str2"
  }
}

Function RunScript([string] $branchName) {
  & $bash -x $prepareCommitMessageHook $commitMessageFile empty empty $branchName
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$root = Resolve-Path "$PSScriptRoot"
$bash = "C:/Program Files/Git/bin/bash.exe"
$prepareCommitMessageHook = "$root/prepare-commit-msg"
$commitMessageFile = "$env:TEMP/CommitMessage.txt"

### Test 1 ###
Info @"
Test1: Should add a JiraId to the beginning of the commit message if
* The branch name contains the JiraId
* The commit message doesn't already contain this JiraId
"@

# Arrange
CreateFileWithContent $commitMessageFile "Commit message without JiraId"

# Act
RunScript "PRJID-12 my branch name"

# Assert
$newCommitMessage = Get-Content $commitMessageFile
AssertStringsAreEqual $newCommitMessage "PRJID-12 - Commit message without JiraId"

### Test 2 ###
Info @"
Test2: Should NOT add a JiraId to the beginning of the commit message if
* The branch name contains the JiraId
* The commit message already contains this JiraId
"@

# Arrange
CreateFileWithContent $commitMessageFile "PRJID-12 - Commit message with JiraId"

# Act
RunScript "PRJID-12-my-branch-name"

# Assert
$newCommitMessage = Get-Content $commitMessageFile
AssertStringsAreEqual $newCommitMessage "PRJID-12 - Commit message with JiraId"

### Test 3 ###
Info @"
Test3: Should NOT add a JiraId to the beginning of the commit message if
* The branch does not contain the JiraId
"@

# Arrange
CreateFileWithContent $commitMessageFile "Commit message without JiraId"

# Act
RunScript "Some branch"

# Assert
$newCommitMessage = Get-Content $commitMessageFile
AssertStringsAreEqual $newCommitMessage "Commit message without JiraId"

### Test 4 ###
Info @"
Test4: Should add a JiraId to the beginning of the commit message if
* The branch name contains the JiraId
* The commit message contains different JiraId
"@

# Arrange
CreateFileWithContent $commitMessageFile "PRJID-11 - Commit message with wrong JiraId"

# Act
RunScript "PRJID-12 branch name"

# Assert
$newCommitMessage = Get-Content $commitMessageFile
AssertStringsAreEqual $newCommitMessage "PRJID-12 - PRJID-11 - Commit message with wrong JiraId"

### Test 5 ###
Info @"
Test5: Should add a JiraId to the beginning of the commit message if
* The branch name starts with "feature/JiraId"
* The commit message doesn't already contain this JiraId
"@

# Arrange
CreateFileWithContent $commitMessageFile "Commit message without JiraId"

# Act
RunScript "bugfix/PRJID-12 branch name"

# Assert
$newCommitMessage = Get-Content $commitMessageFile
AssertStringsAreEqual $newCommitMessage "PRJID-12 - Commit message without JiraId"
