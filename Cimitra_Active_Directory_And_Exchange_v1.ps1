﻿# Add a user to Exchange or Active Directory, Or Modify an Active Directory User
# Author: Tay Kratzer tay@cimitra.com
# Modify Date: 3/5/2021
# Change the context variable to match your system
# -------------------------------------------------


<#
.DESCRIPTION
Add a user to Active Directory or Exchange, Or Modify an Active Directory User
#>


Param(
    # Update a user object in Active Directory
    [switch] $UpdateActiveDirectoryObject, 
    # Add a user to Active Directory
    [switch] $AddToActiveDirectory,  
    # Add a user to Exchange      
    [switch] $AddToExchange, 
    # First name of a user to Add/Update              
    [string] $FirstNameIn,
    # Last name of a user to Add/Update                 
    [string] $LastNameIn,
    # Active Directory context of a user to Add/Update                  
    [string] $ContextIn, 
    # Active Directory SamAccountName for a user to Add/Update in Active Directory                  
    [string] $SamAccountNameIn,   
    # If a user's password needs to be set when being added, or the password needs to be changed, and no password is specificed, the DefaultPasswordIn will be used         
    [String] $DefaultPasswordIn,
    # New first name of a user to Update           
    [string] $NewFirstNameIn,
    # New last name of a user to Update              
    [string] $NewLastNameIn, 
    # The Exchange Account name for a new user in Exchange             
    [string] $ExchangeUserIn,
    # New SamAccountName for a user's whose SamAccountName you want to rename  
    [string] $NewSamAccountNameIn,
    # Update a user with a Manager, this is the first name of the Manager     
    [string] $ManagerFirstNameIn,
    # Update a user with a Manager, this is the last name of the Manager   
    [string] $ManagerLastNameIn,
    # Update a user with a Manager, this is the context where the Manager resides   
    [string] $ManagerContextIn,
    # Update a user with a Manager, this is the SamAccountName for that Manager  
    [string] $ManagerSamAccountNameIn,
    # Update a user's Description, can be used on Adding a user object and Updating a user object
    [string] $DescriptionIn,
    # Update a user's Mobile Phone Number, can be used on Adding a user object and Updating a user object
    [string] $DepartmentNameIn,
    # Update a user's Mobile Phone Number, can be used on Adding a user object and Updating a user object
    [string] $MobilePhoneIn,
    # Update a user's Office Phone Number, can be used on Adding a user object and Updating a user object
    [string] $OfficePhoneIn,
    # Update a user's Title, can be used on Adding a user object and Updating a user object
    [string] $TitleIn,
    # Set a user's account Expiration Date, can be used on Adding a user object and Updating a user object
    [string] $ExpirationDateIn,
    # Update a user's Password, can be used on Adding a user object and Updating a user object
    [string] $UserPasswordIn,
    # Add a user to these Groups, specify a GUIDs for the Groups in a comma seperated list like so:
    #Usage Example: -GroupGUIDSIn "cec83314-2a87-4fbf-9dc7-00a4842d67ed,c5b6dc15-5a4a-40be-a85f-7a2bcfc29301,ba363486-bc66-437e-9e2e-842443aad359"
    # Can be used on Adding a user object and Updating a user object
    [string] $GroupGUIDsIn,
    # When creating an Exchange User make a special user that the Cimitra Windows Agent Service will log in as
    # You should create a Password File while logged in as the user that will be running the Cimitra Agent
    [string] $CimitraAgentLogonAccountIn,
    # Give the path to the Password File for the account you created to run the Cimitra Windows Agent Service
    [string] $ExchangeSecurePasswordFileIn,
    # Give the path to the Exchange URI\
    # Usage Example: -ExchangeConnectionURIIn 'http://example-EXCH16.acme.internal/PowerShell/'
    [string] $ExchangeConnectionURIIn,
    # The Exchange Domain to use for a New Exchange User
    # Usage Example: -ExchangeDomainNameIn "example.com"
    [string] $ExchangeDomainNameIn,
    # Hide errors that come back from Active Directory and Exchange when trying to do Adds and Updates of user objects
    [switch] $HideErrors,
    # When setting or updating a password, this will force the password to be reset on the next user logon
    [switch] $ForcePasswordReset,
    # If you specify a user's First and Last name, but do not specify the context, this script will search for the user
    # If the search finds just one user with that First and Last name it will consider the user to be a match
    # If the -DisableSearch switch is used, then Cimitra will not look for the user specified
    [switch] $DisableSearch,
    [switch] $RemoveExpirationDate,
    [switch] $EnableAccount,
    [switch] $DisableAccount,
    [switch] $UnlockAccount,
    [switch] $CheckPasswordDate,
    [switch] $GetUserInfo,
    [switch] $RemoveUser,
    # Between Add and Update operations on new users, there is a sleep interval called
    # The default value is 5 seconds
    # This parameter allows that sleep interval to be configurable.
    [parameter(Mandatory=$false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $SleepTimeIn
 )

# These are arrays used in this script that are passed arround to functions
Set-Variable -Name ValidatedGroupGUIDList -Value @() -Option AllScope
Set-Variable -Name ArrayOfGroupGUIDs -Value @() -Option AllScope

$context = "OU=USERS,OU=DEMO,OU=CIMITRA,DC=cimitrademo,DC=com" 
 # - OR -
 # Specify the context in settings.cfg file
 # Use this format: AD_USER_CONTEXT=<ACTIVE DIRECTORY CONTEXT>
 # Example: AD_USER_CONTEXT=OU=USERS,OU=DEMO,OU=CIMITRA,DC=cimitrademo,DC=com
 # -------------------------------------------------

# Look to see if a config_reader.ps1 file exists in order to use it's functionality
# Obtain this script at this GitHub Location: 
# https://github.com/cimitrasoftware/powershell_scripts/blob/master/config_reader.ps1
if((Test-Path ${PSScriptRoot}\config_reader.ps1)){

# If a settings.cfg file exists, let's use that file to reading in variables
if((Test-Path ${PSScriptRoot}\settings.cfg))
{
# Give a short name to the config_reader.ps1 script
$CONFIG_IO="${PSScriptRoot}\config_reader.ps1"

# Source in the configuration reader script
. $CONFIG_IO

# Use the "ReadFromConfigFile" function in the configuration reader script
$CONFIG=(ReadFromConfigFile "${PSScriptRoot}\settings.cfg")

# Map the $context variable to the AD_USER_CONTEXT variable read in from the settings.cfg file
$context = "$CONFIG$AD_USER_CONTEXT"

if ($sleepTimeTest = "$CONFIG$AD_SCRIPT_SLEEP_TIME"){
$sleepTime = "$CONFIG$AD_SCRIPT_SLEEP_TIME"
}

}

}

# Reassign parameters
$global:userFirstName = $FirstNameIn
$global:userLastName = $LastNameIn
$global:sleepTime = 5
$global:createObjectWorked = $true
$global:contextIn = ""


$global:modifyAnADUser = $false
if($UpdateActiveDirectoryObject){
$global:modifyAnADUser = $true
}

# Show Help
function ShowHelp{
$scriptName = Split-Path -leaf $PSCommandpath
Write-Host ""
Write-Host "Add a User to Active Directory or Exchange, Or Update Active Directory User"
Write-Host ""
Write-Host "[ HELP ]"
Write-Host ""
Write-Host "Get-Help .\$scriptName"
Write-Host ""
Write-Host ".\$scriptName -h or -help"
Write-Host ""
exit 0
Write-Host "[ SCRIPT USAGE ]"
Write-Host ""
Write-Host ".\$scriptName"
Write-Host ""
Write-Host ""
Write-Host "[REQUIRED PARAMETERS]"
Write-Host ""
Write-Host "-FirstNameIn <user first name> (required)"
Write-Host ""
Write-Host "-LastNameIn <user last name> (required)"
Write-Host ""
Write-Host "[OPTIONAL PARAMETERS]"
Write-Host ""
Write-Host "-ContextIn <Active Directory context (required) (optional if specified in settings.cfg)>"
Write-Host ""
Write-Host "-DefaultPasswordIn <default password> (required)"
Write-Host ""
write-Host "-GroupGUIDsIn <list of AD Group GUIDS separated with a commma>"
Write-Host ""
Write-Host "-ManagerFirstNameIn <user's manager first name>"
Write-Host ""
Write-Host "-ManagerLastNameIn <user's manager last name>"
Write-Host ""
Write-Host "-ManagerSamAccountNameIn <user's manager SamAccountName>"
Write-Host ""
Write-Host "-ExchangeUserIn <user's Exchange User Account/SamAccountName>"
Write-Host ""
Write-Host "-TitleIn <user's title>"
Write-Host ""
Write-Host "-DepartmentIn <user's department>"
Write-Host ""
Write-Host "-MobilePhoneIn <user's mobile phone>"
Write-Host ""
Write-Host "-OfficePhoneIn <user's office phone>"
Write-Host ""
Write-Host "-NewFirstNameIn <user's new first name>"
Write-Host ""
Write-Host "-NewLastNameIn <user's new last name>"
Write-Host ""
Write-Host "[OPTIONS]"
Write-Host ""
Write-Host "[ ERROR HANDLING ]"
Write-Host ""
Write-Host "-HideErrors"
Write-Host ""
Write-Host "[ PREFERENCES ]"
Write-Host ""
Write-Host "-ForcePasswordReset"
Write-Host ""
Write-Host "-SearchForManager - If Manager is not found in the default context"
Write-Host ""
Write-Host "-AddToExchange - Add the user to Exchange first, and then modify the Active Directory object"
Write-Host ""
Write-Host ""
exit 0
}

if (Write-Output $args | Select-String "\-h\b|\-help\b" )
{
ShowHelp
}

if($AddToExchange -and $AddToActiveDirectory)
{
Write-Output ""
Write-Output "Use either -AddToActiveDirectory (or) -AddToExchange"
Write-Output ""
Write-Output "Using both parameters simultaneously is invalid"
Write-Output ""
exit 1
}



# Set parameters 

$SleepTimeInEmpty = [string]::IsNullOrWhiteSpace($SleepTimeIn)
if(!($SleepTimeInEmpty)){
$global:sleepTime = $sleepTime
}else{
$global:sleepTime = $SleepTimeIn
}

if($userFirstName.Length -gt 2){
$global:firstNameSet = $true
}else{
$global:firstNameSet = $false
}

if($userLastName.Length -gt 2){
$global:lastNameSet = $true
}else{
$global:lastNameSet = $false
}

# Was a SamAccountName specified
$global:samAccountNameInSet = $false
$global:samAccountName = "abc"
$SamAccountNameInEmpty = [string]::IsNullOrWhiteSpace($SamAccountNameIn)
if(!($SamAccountNameInEmpty)){
$global:samAccountNameInSet = $true
$global:samAccountName = "$SamAccountNameIn"
}

# If First and Last Names are specified then input is sufficient

if (!( $firstNameSet -and $lastNameSet)){ 

if(!($samAccountNameInSet))
{
ShowHelp
}


}

# For determing if the script creates a user first
$global:ObjectCreationActionTaken = $false

# Was manager name specified
$global:managerNameSet = $true

$ManagerFirstNameEmpty = [string]::IsNullOrWhiteSpace($ManagerFirstNameIn)
if($ManagerFirstNameEmpty){
$global:managerNameSet = $false
}

$ManagerLastNameEmpty = [string]::IsNullOrWhiteSpace($ManagerLastNameIn)
if($ManagerLastNameEmpty){
$global:managerNameSet = $false
}

$global:managerSamAccountNameSet = $false
$ManagerSamAccountNameEmpty = [string]::IsNullOrWhiteSpace($ManagerSamAccountNameIn)
if(!($ManagerSamAccountNameEmpty)){
$global:managerNameSet = $true
$global:managerSamAccountNameSet = $true
}


$global:managerContextSet = $false
$ManagerContextEmpty = [string]::IsNullOrWhiteSpace($ManagerContextIn)
if(!($ManagerContextEmpty)){
$global:managerContextSet = $true
}


# Was a default password specified
$global:defaultPasswordSet = $false
$global:defaultPassword = ""
$DefaultPasswordInEmpty = [string]::IsNullOrWhiteSpace($DefaultPasswordIn)
if($DefaultPasswordInEmpty){
$global:defaultPasswordIn = "abc_123_8-0"
}else{
$global:defaultPasswordIn = $DefaultPasswordIn
}

# Was a Password specified
$global:userPassword = ""
$UserPasswordInEmpty = [string]::IsNullOrWhiteSpace($UserPasswordIn)
if($UserPasswordInEmpty){
$global:userPassword = $defaultPasswordIn
}else{
$global:userPassword = $UserPasswordIn
}



$global:departmentNameInSet = $false
$DepartmentNameInEmpty = [string]::IsNullOrWhiteSpace($DepartmentNameIn)
if(!($DepartmentNameInEmpty)){
$global:departmentNameInSet = $true
}

$global:newFirstNameInSet = $false
$NewFirstNameInEmpty = [string]::IsNullOrWhiteSpace($NewFirstNameIn)
if(!($NewFirstNameInEmpty)){
$global:newFirstNameInSet = $true
}

$global:newLastNameInSet = $false
$NewLastNameInEmpty = [string]::IsNullOrWhiteSpace($NewLastNameIn)
if(!($NewLastNameInEmpty)){
$global:newLastNameInSet = $true
}


$global:groupGUIDsInSet = $false
$GroupGUIDsInEmpty = [string]::IsNullOrWhiteSpace($GroupGUIDsIn)
if(!($GroupGUIDsInEmpty)){
$global:groupGUIDsInSet = $true
}


$global:newSamAccountNameInSet = $false
$NewSamAccountNameInEmpty = [string]::IsNullOrWhiteSpace($NewSamAccountNameIn)
if(!($NewSamAccountNameInEmpty)){
$global:newSamAccountNameInSet = $true
}


$global:mobilePhoneInSet = $false
$MobilePhoneInEmpty = [string]::IsNullOrWhiteSpace($MobilePhoneIn)
if(!($MobilePhoneInEmpty)){
$global:mobilePhoneInSet = $true
}

$global:officePhoneInSet = $false
$OfficePhoneInEmpty = [string]::IsNullOrWhiteSpace($OfficePhoneIn)
if(!($OfficePhoneInEmpty)){
$global:officePhoneInSet = $true
}

$global:titleInSet = $false
$TitleInEmpty = [string]::IsNullOrWhiteSpace($TitleIn)
if(!($TitleInEmpty)){
$global:titleInSet = $true
}

$global:descriptionInSet = $false
$DescriptionInEmpty = [string]::IsNullOrWhiteSpace($DescriptionIn)
if(!($DescriptionInEmpty)){
$global:descriptionInSet = $true
}


$global:ShowErrors = $true
if($HideErrors){
$global:ShowErrors = $false
}


$global:SearchForUser = $true
if($DisableSearch){
$global:SearchForUser = $false
}


$global:SearchForManager = $true
if($DisableSearch){
$global:SearchForManager = $false
}

$global:ForcePasswordReset = $ForcePasswordReset

$global:verboseOutputSet = $true
if ($ShowErrors){
$global:verboseOutputSet = $true
}


$groupGUIDsInSetEmpty = [string]::IsNullOrWhiteSpace($groupGUIDsIn)
$global:groupGUIDsInSet = $false
if(!($groupGUIDsInSetEmpty)){
$global:groupGUIDsInSet = $true
}

$ContextInEmpty = [string]::IsNullOrWhiteSpace($ContextIn)

if($ContextInEmpty){
$global:contextIn = $context
}else{
if($ContextIn.Length -lt 5){
$global:contextIn = $context
}else{
$global:contextIn = $ContextIn
}
}

function  Get-DistinguishedName {
    param (
        [Parameter(Mandatory,
        ParameterSetName = 'Input')]
        [string[]]
        $CanonicalName,

        [Parameter(Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'Pipeline')]
        [string]
        $InputObject
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            $arr = $_ -split '/'
            [array]::reverse($arr)
            $output = @()
            $output += $arr[0] -replace '^.*$', '$0'
            $output += ($arr | select -Skip 1 | select -SkipLast 1) -replace '^.*$', 'OU=$0'
            $output += ($arr | ? { $_ -like '*.*' }) -split '\.' -replace '^.*$', 'DC=$0'
            $output -join ','
        }
        else {
            foreach ($cn in $CanonicalName) {
                $arr = $cn -split '/'
                [array]::reverse($arr)
                $output = @()
                $output += $arr[0] -replace '^.*$', '$0'
                $output += ($arr | select -Skip 1 | select -SkipLast 1) -replace '^.*$', 'OU=$0'
                $output += ($arr | ? { $_ -like '*.*' }) -split '\.' -replace '^.*$', 'DC=$0'
                $output -join ','
            }
        }
    }
}



function SearchForUserSamAccountName($TheFirstName, $TheLastName)
{
[hashtable]$return = @{}

$counterUp = 0
Write-Output "Searching For Users With The Name: [ $TheFirstName $TheLastName ]"
Write-Output ""
Write-Output "-----------------------------------------------------------"
try{
@($theUser = Get-ADUser -Filter "Name -like '$TheFirstName $TheLastName'" ) | Get-DistinguishedName
$SamName = $theUser.sAMAccountName
$FullName = $theUser.Name
$FullyDistinguishedName = $theUser

if($SamName.Length -gt 2)
{
$counterUp++
}

}catch{}


if($counterUp -ne 1){
$return.ErrorState = $true
return $return
}

if($counterUp -eq 1){
$return.SamName = $SamName
$return.FullName = $FullName
$return.FullyDistinguishedName = $FullyDistinguishedName
$return.ErrorState = $false
return $return
}


}

function ValidateName(){

$FoundUser = $true

$TheUser = @{}

try{
$TheUser = Get-ADUser -Identity "CN=${userFirstName} ${userLastName},$contextIn" 2> $null
}catch{
$FoundUser = $false
}

if($FoundUser){
$samAccountName = $TheUser.sAMAccountName
$samAccountNameInSet = $true
return $true
}else{
$UserSearchReturn = SearchForUserSamAccountName "$userFirstName" "$userLastName"

$UserSearchErrorState = $UserSearchReturn.ErrorState
if(!($UserSearchErrorState)){

$SAM = $UserSearchReturn.SamName

$global:samAccountName = $SAM
$global:samAccountNameInSet = $true
$UserFullName = $UserSearchReturn.FullName
$FullyDistinguishedName = $UserSearchReturn.FullyDistinguishedName
Write-Output "Found User: $UserFullName"
Write-Output "SamAccountName: $samAccountName"
Write-Output "Fully Distinguished Name: $FullyDistinguishedName"
return $true
}else{
Write-Output "Could Not Positively Identify a Unique User: $TheFirstNameIn $TheLastNameIn"
Write-Output ""
Write-Output "Try Using the User's SamAccountName"
$SearchUtilityExists = Test-Path "$PSScriptRoot\SearchForUser.ps1"
if($SearchUtilityExists)
{
. $PSScriptRoot\SearchForUser.ps1 -FirstNameIn ${userFirstNameIn} -LastNameIn ${userLastNameIn}
}
return $false

}


}


}




if(!($samAccountNameInSet)){

    if($SearchForUser)
    {

    $ValidateResult = ValidateName
        if(!($ValidateResult)){
        Write-Output "Cannot Proceed, User Not Found"
        exit 0
        }

    }

}else{

    $UserDoesNotExist = $false

    try{
        $AUSER = Get-ADUser -Identity "$samAccountName"2> $null
    }catch{
        $UserDoesNotExist = $true
    }

    if($UserDoesNotExist){
        Write-Output ""
        Write-Output "A User With The Userid: $TheSamAccountName Does No Exists"
        Write-Output ""
        exit 
    }else{

        if(!($firstNameSet -or $lastNameSet)){
            $TheUser = Get-ADUser -Identity "$samAccountName" 2> $null
            $TheFirstName = $TheUser.GivenName

            $global:userFirstName = $TheFirstName
        
            $TheLastName = $TheUser.Surname
    
            $global:userLastName = $TheLastName

        }
    # BLISS

    }

}


function CALL_SLEEP{
Write-Output ""
Write-Output "Pausing For: $sleepTime Seconds"
Write-Output ""
Start-Sleep -s $sleepTime
}

# If the SamAccountName is specified, we don't need the context for the user
if(!($SearchForUser)){

    if(!($samAccountNameInSet)){

    if($contextIn.Length -lt 3){
    ShowHelp
    }

    }
}








Function CorrelateGroupGUIDs {
# Turn list of GUIDS passed into script into an array
    param(
        [Parameter(Mandatory=$true)]
        [string]$GuidList,
        [array]$add
    )

        $GroupGUIDs = $GuidList.split(',')
        try{
        $GroupGUIDs += $add.split(' ')
        }catch{}


    return $GroupGUIDs
}



function ProcessGroupGuids(){

# Get Array of Group GUIDs passed into the script

$ArrayOfGroupGUIDs = CorrelateGroupGUIDs "$groupGUIDsIn"

# If $ArrayOfGroupGUIDs is not an array, then convert it into an array. For some reason running this script in the background doesn't create arrays correctly
try{$ArrayOfGroupGUIDs.GetUpperBound(0)}catch{
$ArrayOfGroupGUIDs = $ArrayOfGroupGUIDs.Split(" ")
}

foreach ($i in $ArrayOfGroupGUIDs) {

    $GetGroupSuccess = $true

    try{Get-ADGroup -Identity $i *> $null}catch{$GetGroupSuccess = $false} 

        if($GetGroupSuccess)
        {
            try{
            $ValidatedGroupGUIDList += $i.split(' ')
            }catch{}

        }
}

}


function IdentifyUser(){



    if((!$samAccountNameInSet))
    {
    try{
    $TheUser = Get-ADUser -Identity "CN=$userFirstName $userLastName,$contextIn"
    }catch{
    Write-Output ""
    Write-Output "Error: Cannot Positively Identify User: $userFirstName $userLastName at Context: $contextIn"
    Write-Output ""
    exit 1
    }
    $DistinguishedName = $TheUser.distinguishedName
    $SAM = $TheUser.sAMAccountName
    $global:samAccountNameInSet = $true
    $global:samAccountName = $SAM
    Write-Output ""
    Write-Output "User Distinguished Name: $DistinguishedName"
    }

}




foreach ($GroupGuid in $ValidatedGroupGUIDList) {

$TheGroupName = Get-ADGroup -Identity "$GroupGuid" #| Select-Object -Property Name | ft -HideTableHeaders
$TheGroupName =  $TheGroupName.Name



    $AddUserSuccess = $true

    if($samAccountNameInSet)
    {
    
    try{Add-ADGroupMember -Identity $GroupGuid -Members "$samAccountName" *> $null}catch{$AddUserSuccess = $false} 
    }else{
    try{Add-ADGroupMember -Identity $GroupGuid -Members "CN=$userFirstName $userLastName,$contextIn" *> $null}catch{
        $AddUserSuccess = $false
        $err = "$_"
        } 
    }

  

    if($AddUserSuccess){
    


        if($samAccountNameInSet){
        $TheUser = Get-ADUser -Identity "$samAccountName"
        $TheUser = $TheUser.Name
               
        }else{
        $TheUser = Get-ADUser -Identity "CN=$userFirstName $userLastName,$contextIn" # | Select-Object -Property Name | ft Name -HideTableHeaders
        $TheUser = $TheUser.Name
        }
                # Write-Output ""
        Write-Output "User: $TheUser | Added To Group: $TheGroupName"


    }else{
           if($samAccountNameInSet){
            Write-Output "User: $TheUser | NOT Added To Group: $TheGroupName"
            }else{
            Write-Output "User: CN=$userFirstName $userLastName,$contextIn  | NOT Added To Group: $TheGroupName"
            } 
        Write-Output ""
        Write-Output "[ERROR MESSAGE BELOW]"
        Write-Output "-----------------------------"
        Write-Output ""
        Write-Output $err
        Write-Output ""
        Write-Output "-----------------------------"

    }

}

function CreateExchangeAccount()
{

$global:createObjectWorked = $false

$CimitraAgentLognAccountInEmpty = [string]::IsNullOrWhiteSpace($CimitraAgentLogonAccountIn)
if($CimitraAgentLognAccountInEmpty){
Write-Output ""
Write-Output "To Add a User to Exchange, Specify The Parameter -CimitraAgentLognAccountIn"
Write-Output ""
Write-Output "Example: -CimitraAgentLognAccountIn 'CimitraAgent@example.com'"
Write-Output ""
return
}

$ExchangeSecurePasswordFileInEmpty = [string]::IsNullOrWhiteSpace($ExchangeSecurePasswordFileIn)
if($ExchangeSecurePasswordFileInEmpty){
Write-Output ""
Write-Output "To Add a User to Exchange, Specify The Parameter -SecurePasswordFileIn"
Write-Output ""
Write-Output "Example: -SecurePasswordFileIn 'c:\passwords\password.txt'"
Write-Output ""
return
}

if(!(Test-Path $ExchangeSecurePasswordFileIn)){
Write-Output ""
Write-Output "The Secure Password File:"
Write-Output ""
Write-Output "$ExchangeSecurePasswordFileIn"
Write-Output ""
Write-Output "Is Not Accessible to This Script"
return
}

$CimitraAgentLognAccountInEmpty = [string]::IsNullOrWhiteSpace($CimitraAgentLogonAccountIn)
if($CimitraAgentLognAccountInEmpty){
Write-Output ""
Write-Output "To Add a User to Exchange, Specify The Parameter -CimitraAgentLognAccountIn"
Write-Output ""
Write-Output "Example: -CimitraAgentLognAccountIn 'CimitraAgent@example.com'"
Write-Output ""
return
}


$ExchangeConnectionURIInEmpty = [string]::IsNullOrWhiteSpace($ExchangeConnectionURIIn)
if($ExchangeConnectionURIInEmpty){
Write-Output ""
Write-Output "To Add a User to Exchange, Specify The Parameter -ExchangeConnectionURIIn"
Write-Output ""
Write-Output "Example: -ExchangeConnectionURIIn 'http://example-EXCH16.acme.internal/PowerShell/'"
Write-Output ""
return
}

$ExchangeDomainNameInEmpty = [string]::IsNullOrWhiteSpace($ExchangeDomainNameIn)
if($ExchangeDomainNameInEmpty){
Write-Output ""
Write-Output "To Add a User to Exchange, Specify The Parameter -ExchangeDomainNameIn"
Write-Output ""
Write-Output "Example: -ExchangeDomainNameIn 'example.com'"
Write-Output ""
return
}

try{
$TheContext = Get-ADOrganizationalUnit -Identity $contextIn 2> $null
}catch{
Write-Output ""
Write-Output "To Add a User to Exchange, Specify The Parameter -ContextIn with a valid Context"
Write-Output ""
Write-Output "This should be an OU location in your Active Directory Tree"
Write-Output ""
Write-Output "Example: -ContextIn 'OU=USERS,DC=cimitra,DC=com'"
Write-Output ""
return
}


$Credentials = "$userPasswordIn"

try{
$SecureCred = $Credentials | ConvertTo-SecureString -AsPlainText -Force
}catch{
$err = "$_"

Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Not Added to Exchange"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR CONVERTING CREDENTIALS]"
    Write-Output "------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}


$username = "$CimitraAgentLognAccountIn"

$pwdTxt = Get-Content "$ExchangeSecurePasswordFileIn"

$securePwd = $pwdTxt | ConvertTo-SecureString

try{
$credObject = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePwd
}catch{
$err = "$_"

Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Not Added to Exchange"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR CREATING A CREDENTIAL OBJECT]"
    Write-Output "------------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}


try{
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeConnectionURIIn -Authentication Kerberos -Credential $credObject
}catch{
$err = "$_"

Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Not Added to Exchange"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR CREATING AN EXCHANGE SESSION]"
    Write-Output "------------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}





try{
Import-PSSession $Session -DisableNameChecking
}catch{
$err = "$_"

Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Not Added to Exchange"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR IMPORTING THE EXCHANGE SESSION]"
    Write-Output "--------------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}


# Create Mailbox

try{
New-RemoteMailbox -Name "$userFirstName $userLastName" -Password $SecureCred -UserPrincipalName "$ExchangeUserIn@$ExchangeDomainNameIn" -OnPremisesOrganizationalUnit "$contextIn" -ACLableSyncedObjectEnabled -ResetPasswordOnNextLogon $true -FirstName "$userFirstName" -LastName "$userLastName" 2>$null
}catch{
$err = "$_"

Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Not Added to Exchange"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR CREATING THE EXCHANGE MAILBOX]"
    Write-Output "-------------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}

Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Added to Exchange"

CALL_SLEEP

$TheUser = Get-ADUser -Identity "CN=${userFirstName} ${userLastName},$contextIn" 2> $null
$global:samAccountName = $TheUser.sAMAccountName
$global:samAccountNameInSet = $true

$global:createObjectWorked = $true
return 0

}


function CreateActiveDirectoryAccount(){

$global:createObjectWorked = $false

if($samAccountNameInSet){
$TheSamAccountName = $samAccountName
}else{
# Make the samAccountName variable from a combination of the user's first and last name
$TheSamAccountName = ($userFirstName+$userLastName).ToLower()
}

try{
$TheContext = Get-ADOrganizationalUnit -Identity $contextIn 2> $null
}catch{
Write-Output ""
Write-Output "To Add a User to Active Directory, Specify The Parameter -ContextIn with a Valid Context"
Write-Output ""
Write-Output "This should be an OU location in your Active Directory Tree"
Write-Output ""
Write-Output "Example: -ContextIn 'OU=USERS,DC=cimitra,DC=com'"
Write-Output ""
return
}


$UserDoesNotExist = $false

try{
Get-ADUser -Identity "$TheSamAccountName" 2> $null
}catch{
$UserDoesNotExist = $true
}

if(!($UserDoesNotExist)){
Write-Output ""
Write-Output "A User With The Userid: $TheSamAccountName Already Exists"
Write-Output ""
return

}

# Create the new user
$createUserResult = $true
try{
New-ADUser -Name "$userFirstName $userLastName" -GivenName "$userFirstName" -Surname "$userLastName" -SamAccountName "$TheSamAccountName" -AccountPassword (ConvertTo-SecureString "$userPassword" -AsPlainText -force) -passThru -path "$contextIn" -Enabled $true | out-null
}catch{
$err = "$_"
$createUserResult = $false
}

if($createUserResult){
Write-Output ""
Write-Output "New User: ${userFirstName} ${userLastName} | Created"
Write-Output ""
CALL_SLEEP
}else{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Not Created"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR CREATING THE ACTIVE DIRECTORY ACCOUNT]"
    Write-Output "----------------------------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
return
}

}

$TheUser = Get-ADUser -Identity "CN=${userFirstName} ${userLastName},$contextIn" 2> $null

 
$SAM = $TheUser.saMAccountName
$global:samAccountName = "$SAM"
$global:samAccountNameInSet = $true
$global:createObjectWorked = $true

}



function DetermineActionOrder(){

if($AddToExchange){
CreateExchangeAccount
    if(!($createObjectWorked)){
    exit 1
    }
$global:modifyAnADUser = $true
}

if($AddToActiveDirectory){
CreateActiveDirectoryAccount

    if(!($createObjectWorked)){
    exit 
    }

$global:modifyAnADUser = $true

}


}


if($AddToExchange -or $AddToActiveDirectory)
{
DetermineActionOrder
$ObjectCreationActionTaken = $true
}





function UpdateCreatedUserProperty($IDENTITY_IN,$AD_ATTRIBUTE_NAME,$AD_ATTRIBUTE_VALUE,$AD_ATTRIBUTE_LABEL)
{


# Write-Output "Set-ADUser -Identity '$IDENTITY_IN' $AD_ATTRIBUTE_NAME '$AD_ATTRIBUTE_VALUE'"
$parameterHash = @{
    "Identity"=$IDENTITY_IN
    $AD_ATTRIBUTE_NAME=$AD_ATTRIBUTE_VALUE
}

$modifyUserResult = $true
try{
Set-ADUser @parameterHash 2> $null
}catch{
$modifyUserResult = $false
$err = "$_"
}

if($modifyUserResult){
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | ${AD_ATTRIBUTE_LABEL} Changed to: ${AD_ATTRIBUTE_VALUE}"
Write-Output ""
return
}else{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | ${AD_ATTRIBUTE_LABEL} NOT Changed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR CREATING THE MODIFYING ACTIVE DIRECTORY ${AD_ATTRIBUTE_LABEL}]"
    Write-Output "----------------------------------------------------------------"
    Write-Output ""
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"

    return
}


}

}



function ChangePassword()
{

$UserPasswordInEmpty = [string]::IsNullOrWhiteSpace($UserPasswordIn)
if($UserPasswordInEmpty){
$userPasswordIn = $defaultPasswordIn
}else{
$userPasswordIn = $UserPasswordIn
}

# Modify the user
try{
Set-ADAccountPassword -Identity "$samAccountName" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "${userPasswordIn}" -Force)
}catch{
$modifyUserResult = $false
$err = "$_"
}

# See if the -forcePasswordReset variable was passed in
if ($ForcePasswordReset){
$global:forcePasswordResetSet = $true
}

# If exit code from the New-ADUser command was "True" then show a success message
if ($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Password Set"
}else{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Password Was NOT Changed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}

$modifyUserResult = $true

if($ForcePasswordReset){


# Force an immediate password reset
try{
 Set-ADUser -Identity  "$samAccountName" -ChangePasswordAtLogon $true 2>$null
 }catch{
 $modifyUserResult = $false
 }
 if($modifyUserResult){
 Write-Output ""
 Write-Output "NOTE: This user will be required to change their password the next time they log in."
 Write-Output ""
 }

$modifyUserResult = $true
 
try{
$theResult = Get-ADUser -properties PasswordLastSet  -Identity "$samAccountName" | Select-Object PasswordLastSet -ExpandProperty PasswordLastSet
 
}catch{
$modifyUserResult = $false
$err = "$_"
}

}


if($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "Password Reset for User: ${userFirstName} ${userLastName} | Was On: ${theResult}"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }

}


function DisableUserAccount()
{

$modifyUserResult = $true

# Modify the user

try{
Disable-ADAccount -Identity "$samAccountName"  
 }catch{
 $modifyUserResult = $false
 $err = "$_"
 }

 if ($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Disabled"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }else{
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Not Disabled"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }


 }

}


function EnableUserAccount()
{

$modifyUserResult = $true

# Modify the user

try{
Enable-ADAccount -Identity "$samAccountName"  
 }catch{
 $modifyUserResult = $false
 $err = "$_"
 }

 if ($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Enabled"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }else{
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Not Enabled"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }


 }

}


function RemoveUserAccountLock()
{

$modifyUserResult = $true

# Modify the user

try{

Unlock-ADAccount -Identity "$samAccountName" 
 }catch{
 $modifyUserResult = $false
 $err = "$_"
 }

 if ($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Unlocked"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }else{
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Not Unlocked"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }


 }

}



function RemoveUserExpirationDate()
{

$modifyUserResult = $true

# Modify the user

try{

Clear-ADAccountExpiration -Identity "$samAccountName"
 }catch{
 $modifyUserResult = $false
 $err = "$_"
 }

 if ($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Expiration Removed"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }else{
 Write-Output ""
 Write-Output "The User: ${userFirstName} ${userLastName} | Account Expiration NOT Removed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }


 }

}


function CheckUserPasswordDate(){

$modifyUserResult = $true
 #BLISS
try{
$theResult = Get-ADUser -properties PasswordLastSet  -Identity "$samAccountName" | Select-Object PasswordLastSet -ExpandProperty PasswordLastSet
 
}catch{
$modifyUserResult = $false
$err = "$_"
}

if($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "Password Reset for User: ${userFirstName} ${userLastName} | Was On: ${theResult}"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }else{
 Write-Output ""
    Write-Output "User: ${userFirstName} ${userLastName} | Cannot Check Password Reset Date"
    Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return

 }

 
}



function SetPassword()
{

$UserPasswordInEmpty = [string]::IsNullOrWhiteSpace($UserPasswordIn)
if($UserPasswordInEmpty){
$userPasswordIn = $defaultPasswordIn
}else{
$userPasswordIn = $UserPasswordIn
}

$modifyUserResult = $true

# Modify the user
try{
Set-ADAccountPassword -Identity "$samAccountName" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "${userPasswordIn}" -Force)
}catch{
$modifyUserResult = $false
$err = "$_"
}

# See if the -forcePasswordReset variable was passed in
if ($ForcePasswordReset){
$global:forcePasswordResetSet = $true
}

# If exit code from the New-ADUser command was "True" then show a success message
if ($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Password Set"
}else{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Password Was NOT Changed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}

$modifyUserResult = $true

if($ForcePasswordReset){


# Force an immediate password reset
try{
 Set-ADUser -Identity  "$samAccountName" -ChangePasswordAtLogon $true 2>$null
 }catch{
 $modifyUserResult = $false
 }
 if($modifyUserResult){
 Write-Output ""
 Write-Output "NOTE: This user will be required to change their password the next time they log in."
 Write-Output ""
 }

$modifyUserResult = $true
 
try{
$theResult = Get-ADUser -properties PasswordLastSet  -Identity "$samAccountName" | Select-Object PasswordLastSet -ExpandProperty PasswordLastSet
 
}catch{
$modifyUserResult = $false
$err = "$_"
}

}


if($modifyUserResult){
 Write-Output "------------------------------------------------------------------------------"
 Write-Output ""
 Write-Output "Password Reset for User: ${userFirstName} ${userLastName} | Was On: ${theResult}"
 Write-Output ""
 Write-Output "------------------------------------------------------------------------------"
 }

}

function ChangeSamAccountName(){
#BLISS

$modifyUserResult = $true

# Modify the user
try{
Set-ADUser -Identity "$samAccountName" -SamAccountName "$NewSamAccountNameIn" 2>$null
}catch{
$modifyUserResult = $false
$err = "$_"
}

# If exit code from the New-ADUser command was "True" then show a success message
if ($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Userid: $samAccountName Changed To: $NewSamAccountNameIn"
$global:samAccountName = $NewSamAccountNameIn
}else{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Userid: $samAccountName NOT Changed To: $NewSamAccountNameIn"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}



}

function ChangeFirstName(){

$modifyUserResult = $true

# Modify the user
try{
Get-ADUser -Identity "$samAccountName"  | Rename-ADObject -NewName "${NewFirstNameIn} ${userLastNameIn}" 
}catch{
$modifyUserResult = $false
$err = "$_"
}

try{
Get-ADUser -Identity "$samAccountName"  | Set-ADUser -DisplayName "${NewFirstNameIn} ${userLastNameIn}" 
}catch{
$modifyUserResult = $false
$err = "$_"
}

try{
Get-ADUser -Identity "$samAccountName"  | Set-ADUser -GivenName "${NewFirstNameIn}" 
}catch{
$modifyUserResult = $false
$err = "$_"
}


# If exit code from the New-ADUser command was "True" then show a success message
if($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Name Changed to: ${NewFirstNameIn} $userLastNameIn"
$global:userFirstNameIn = $NewFirstNameIn
}else{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | First Name NOT Changed to: $NewFirstNameIn"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}


}


function ChangeLastName(){

$modifyUserResult = $true

# Modify the user
try{
Get-ADUser -Identity "$samAccountName"  | Rename-ADObject -NewName "${userFirstNameIn} ${newLastNameIn}" 
}catch{
$modifyUserResult = $false
$err = "$_"
}

try{
Get-ADUser -Identity "$samAccountName"  | Set-ADUser -DisplayName "${userFirstNameIn} ${newLastNameIn}" 
}catch{
$modifyUserResult = $false
$err = "$_"
}

try{
Get-ADUser -Identity "$samAccountName"  | Set-ADUser -Surname "${newLastNameIn}" 
}catch{
$modifyUserResult = $false
$err = "$_"
}


# If exit code from the New-ADUser command was "True" then show a success message
if($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstName} ${userLastName} | Name Changed to: ${userFirstNameIn} $NewLastNameIn"
$global:userLastNameIn = $NewLastNameIn
}else{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Last Name NOT Changed to: $NewLastNameIn"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}


}


function ChangeUserManager(){


if($managerSamAccountNameSet){

$modifyUserResult = $true

try{
Set-ADUser -Identity $samAccountName -manager $ManagerSamAccountNameIn   2>$null
}catch{
$modifyUserResult = $false
$err = "$_"
}


if($modifyUserResult)
{

Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Manager Changed to: $ManagerSamAccountNameIn"
return
}else{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Manager NOT Changed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}

}



$modifyUserResult = $true

if($managerContextSet -and $managerNameSet){

$LookupWorked = $true
try{
$TheManager = Get-ADUser -Identity "CN=${ManagerFirstNameIn} ${ManagerLastNameIn},${ManagerContextIn}" 2> $null
}catch{
$LookupWorked = $false
$modifyUserResult = $false
$err = "$_"
}



if($LookupWorked){

try{
Set-ADUser -Identity $samAccountName  -Manager "CN=${ManagerFirstNameIn} ${ManagerLastNameIn},${ManagerContextIn}" 2>$null
}catch{
$modifyUserResult = $false
$err = "$_"
}


if($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Manager Changed to: ${ManagerFirstNameIn} ${ManagerLastNameIn}"
Write-Output ""
Write-Output "Manager Distinguished Name: CN=${ManagerFirstNameIn} ${ManagerLastNameIn},${ManagerContextIn}"
return
}else{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Manager NOT Changed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}

if(!($SearchForManager)){
return
}


#BLISS

}
    
    
}


$UserSearchReturn = SearchForUserSamAccountName "$ManagerFirstNameIn" "$ManagerLastNameIn"

$UserSearchErrorState = $UserSearchReturn.ErrorState
if(!($UserSearchErrorState)){

$SAM = $UserSearchReturn.SamName
$UserFullName = $UserSearchReturn.FullName
$FullyDistinguishedName = $UserSearchReturn.FullyDistinguishedName
Write-Output ""
Write-Output "Found Manager/User: $UserFullName"
Write-Output ""
Write-Output "The Manager Userid: $SAM"
Write-Output ""
Write-Output "Distinguished Name: $FullyDistinguishedName"
}else{
Write-Output "Could Not Positively Identify a Unique User: $ManagerFirstNameIn $ManagerLastNameIn"
Write-Output ""
Write-Output "Try Using the User's SamAccountName"
$SearchUtilityExists = Test-Path "$PSScriptRoot\SearchForUser.ps1"
if($SearchUtilityExists)
{
. $PSScriptRoot\SearchForUser.ps1 -FirstNameIn ${ManagerFirstNameIn} -LastNameIn ${ManagerLastNameIn}
}
return

}


$modifyUserResult = $true


try{
Set-ADUser -Identity $samAccountName -Manager $SAM 2>$null
}catch{
$modifyUserResult = $false
$err = "$_"
}


if($modifyUserResult)
{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Manager Changed to: $ManagerFirstNameIn $ManagerLastNameIn"
return
}else{
Write-Output ""
Write-Output "User: ${userFirstNameIn} ${userLastNameIn} | Manager NOT Changed"
Write-Output ""
    if ($verboseOutputSet){
    Write-Output "[ERROR MESSAGE BELOW]"
    Write-Output "-----------------------------"
    Write-Output ""
    Write-Output $err
    Write-Output ""
    Write-Output "-----------------------------"
    }
return
}



}

function GetUserInfoFunction(){


$theGivenName=""
$theSurname=""
$theMobilePhone=""
$theTitle=""
$theDepartment=""
$theDescription=""
$theOfficePhone=""
$theMobilePhone=""
$theExpirationDate=""
$theAccountStatus = $true
$thePasswordSetDate=""
$theCreationDate=""
$theUserSamAccounName=""
$theUserCnName=""

try{
 $theFirstName=Get-ADUser  -properties GivenName -Identity "$samAccountName" | select GivenName -ExpandProperty GivenName
}catch{}


try{
 $theLastName=Get-ADUser  -properties Surname -Identity "$samAccountName" | select Surname -ExpandProperty Surname
}catch{}


Write-Output "FULL NAME:  ${theFirstName} ${theLastName}"
Write-Output "FIRST NAME: ${theFirstName}"
Write-Output "LAST  NAME: ${theLastName}"

try{
 $theTitle=Get-ADUser  -properties title -Identity "$samAccountName" | select title -ExpandProperty title
}catch{}

if($theTitle.Length -gt 0){
Write-Output "TITLE:  $theTitle"
}else{
Write-Output "TITLE:  [NONE]"
}


try{
 $theDepartment=Get-ADUser  -properties department -Identity "$samAccountName" | select department -ExpandProperty department 
}catch{}

if($theDepartment.Length -gt 0){
Write-Output "DEPARTMENT:  $theDepartment"
}else{
Write-Output "DEPARTMENT:  [NONE]"
}


try{
 $theDescription=Get-ADUser  -properties description -Identity "$samAccountName" | select description -ExpandProperty description
}catch{}

if($theDescription.Length -gt 0){
Write-Output "DESCRIPTION:  $theDescription"
}else{
Write-Output "DESCRIPTION:  [NONE]"
}


try{
 $theOfficePhone=Get-ADUser -properties OfficePhone -Identity "$samAccountName" | select OfficePhone -ExpandProperty OfficePhone 
}catch{}

if($theOfficePhone.Length -gt 0){
Write-Output "OFFICE PHONE:  $theOfficePhone"
}else{
Write-Output "OFFICE PHONE:  [NONE]"
}


try{
 $theMobilePhone=Get-ADUser  -properties MobilePhone -Identity "$samAccountName" | select MobilePhone -ExpandProperty MobilePhone 
}catch{}

if($theMobilePhone.Length -gt 0){
Write-Output "MOBILE PHONE:  $theMobilePhone"
}else{
Write-Output "MOBILE PHONE:  [NONE]"
}

Write-Output "GROUP MEMBERSHIP"
Write-Output "----------------------------------"
Get-ADPrincipalGroupMembership  "$samAccountName" | select name | ft -HideTableHeaders | where{$_ -ne ""}
Write-Output "----------------------------------"

try{
 $theExpirationDate=Get-ADUser -properties AccountExpirationDate -Identity "$samAccountName" | select AccountExpirationDate -ExpandProperty AccountExpirationDate 
 }catch{}

if($theExpirationDate.Length -gt 0){
Write-Output "ACCOUNT EXPIRES:  $theExpirationDate"
}else{
Write-Output "ACCOUNT EXPIRES:  [NO EXPIRATION DATE]"
}


try{
 $thePasswordSetDate=Get-ADUser -properties PasswordLastSet -Identity "$samAccountName" | select PasswordLastSet -ExpandProperty PasswordLastSet 
}catch{}


if($thePasswordSetDate.Length -gt 0){
Write-Output "PASSWORD SET DATE:  $thePasswordSetDate"
}else{
Write-Output "PASSWORD SET DATE:  [NONE]"
}


try{
 $theAccountStatus=Get-ADUser -properties Enabled -Identity "$samAccountName" | select Enabled -ExpandProperty Enabled 
}catch{}

if($theAccountStatus){
Write-Output "ACCOUNT ENABLED:  YES"
}else{
Write-Output "ACCOUNT ENABLED:  NO"
}


try{
 $theCreationDate=Get-ADUser  -properties Created -Identity "$samAccountName" | select Created -ExpandProperty Created 
}catch{}

Write-Output "Account Creation Date:  $theCreationDate"


try{
 $theUserSamAccounName=Get-ADUser  -properties SamAccountName -Identity "$samAccountName" | select SamAccountName -ExpandProperty SamAccountName 
}catch{}


Write-Output "SamAccountName:  $theUserSamAccounName"


try{
 $DN=Get-ADUser  -properties DistinguishedName -Identity "$samAccountName" | select DistinguishedName -ExpandProperty DistinguishedName 
}catch{}

 
Write-Output "DISTINGUISHED NAME:  $DN"

}


# Change/Update User Properties
function IterateThroughUserPropertiesToChange(){

if(!($ObjectCreationActionTaken)){
IdentifyUser
}

if($descriptionInSet){
UpdateCreatedUserProperty "$samAccountName" "Description" "$DescriptionIn" "Description"
}

if($departmentNameInSet){
UpdateCreatedUserProperty "$samAccountName" "Department" "$DepartmentNameIn" "Department Name"
}

if($titleInSet){
UpdateCreatedUserProperty "$samAccountName" "Title" "$TitleIn" "Title"
}

if($mobilePhoneInSet){
UpdateCreatedUserProperty "$samAccountName" "MobilePhone" "$MobilePhoneIn" "Mobile Phone"
}

if($officePhoneInSet){
UpdateCreatedUserProperty "$samAccountName" "OfficePhone" "$OfficePhoneIn" "Office Phone"
}

if($managerNameSet){
ChangeUserManager
}

if($RemoveExpirationDate){
RemoveUserExpirationDate
}

if($UnlockAccount){
RemoveUserAccountLock
}

if($DisableAccount){
DisableUserAccount
}

if($EnableAccount){
EnableUserAccount
}

if($CheckPasswordDate){
CheckUserPasswordDate
}


if(!($ObjectCreationActionTaken)){

    if($userPasswordInSet){
    ChangePassword
    }

    if($newFirstNameInSet){
    ChangeFirstName
    }

    if($newLastNameInSet){
    ChangeLastName
    }

    if($newSamAccountNameInSet){
    ChangeSamAccountName
    }
}

if($GetUserInfo){
GetUserInfoFunction
}

}


IterateThroughUserPropertiesToChange




