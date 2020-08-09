# Import Active Directory module so that you can run the Active Directory cmdlets in this script
Import-Module ActiveDirectory
  
#Create the variable $ImportADUsers and then import the information from the CSV file and store it in the $ImportADUsers variable.
$ImportADUsers = Import-Csv C:\PSTemp\UserImport.csv

#Each row has a new user...this loop will go row by row and create each user account one at a time
foreach ($User in $ImportADUsers)
{
	#Read user data from each field in each row and assign the data to a variable as below
		
	$FName = $User.FName
	$LName = $User.LName
  	$Username = $User.username
	$Email = $User.Email
  	$Phone = $User.Phone
  	$Dept = $User.Dept
  	$Password = $User.password
  	$Title = $User.Title
	$OU = $User.OU

	#First part of the loop checks to see if the user already exists in Active Directory
	if (Get-ADUser -Filter {SamAccountName -eq $Username})
	{
		 #If the user account does exist, this warning will be "printed" onto the screen
		 Write-Warning "This user account already exists in Active Directory: $Username"
	}
	else
	{
		#Assuming the user does not exist, the script continues to this next part where the account is actually created.
		
        #This command will create the new user with the parameters specified. There are many more that you can use. 
        #See the documentation on this command for all the fields available, URL is below
        #https://docs.microsoft.com/en-us/powershell/module/addsadministration/new-aduser?view=win10-ps
        
		New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@sometestorg.com" `
            -Name "$FName $LName" `
            -GivenName $FName `
            -Surname $LName `
            -Enabled $True `
            -DisplayName "$LName, $FName" `
            -Path $OU `
            -OfficePhone $Phone `
            -EmailAddress $Email `
            -Title $Title `
            -Department $Dept `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True
            
	}
}
