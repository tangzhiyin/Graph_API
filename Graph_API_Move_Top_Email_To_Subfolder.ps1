$AppId = ""
$AppSecret = ""
$TenantId = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"
$useremail = "zhiyintang@yokoto.onmicrosoft.com"


# Construct URI and body needed for authentication
$uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$body = @{
   client_id     = $AppId
   scope         = "https://graph.microsoft.com/.default"
   client_secret = $AppSecret
   grant_type    = "client_credentials"
}
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
$Headers = @{
           'Content-Type'  = "application/json"
           'Authorization' = "Bearer $Token" 
}
 
 
# Define your variables (replace with actual values)
$mailFolderId = "Inbox"  # Replace with the source folder ID
$graphfirstemail = Invoke-RestMethod -Headers $Headers -Uri "$resource/v1.0/users/$useremail/mailFolders/$mailFolderId/messages?`$top=1"
 
# Extract the message ID of the top email
$messageId = $graphfirstemail.value.id

# Get the SubFolder Id what you have get from the previous command
$destinationId = "<id>"

# Construct the move URI
$moveUri = "https://graph.microsoft.com/v1.0/users/$useremail/mailFolders/$mailFolderId/messages/$messageId/move"
 
# Create the request body
$body = @{
    "destinationId" = $destinationId
} | ConvertTo-Json
 
# Send the request to move the email
try {
    Invoke-RestMethod -Headers $Headers -Method POST -Uri $moveUri -ContentType "application/json" -Body $body
    Write-Host "Top email moved successfully!"
} catch {
    Write-Host "Error moving the top email: $($_.Exception.Message)"
}