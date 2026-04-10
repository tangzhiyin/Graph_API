$TenantID = "“
$ClientID = ""
$ClientSecret = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"

# Construct URI and body needed for authentication
$uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$body = @{
  client_id    = $AppId
  scope        = "https://graph.microsoft.com/.default"
  client_secret = $AppSecret
  grant_type   = "client_credentials"
}
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
 
# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
$Headers = @{
          'Content-Type'  = "application/json"
          'Authorization' = "Bearer $Token"
}
 
# Step 3: Get the ID of the first email in the Inbox
$graphfirstemail = Invoke-RestMethod -Headers $Headers -Uri "$resource/v1.0/users/$useremail/mailFolders/Inbox/messages?`$top=1"
# Output the email body
# The body content is available in $response.body.content (HTML format by default)
$graphfirstemail.value.body.content > C:\temp\output.html
# Extract the body of the email
$regex= '<[^>]+>'
$emailBody= [regex]::Replace($htmlContent, $regex, '')
$source = Get-Content -Path "C:\temp\output.html" -Raw
# Remove all HTML tags
$TextContent = $Source -replace '<.*?>', ''
$source = Get-Content -Path "C:\temp\output.html" -Raw
# Remove all CSS and font-related tags
$CleanedContent = $Source -replace '<style.*?>.*?</style>|<link.*?>|<font.*?>', ''
$EmailBody = [System.Text.RegularExpressions.Regex]::Match($CleanedContent, '<div class="WordSection1">(.*?)</div>').Groups[1].Value
# Remove all HTML tags
$cleaned_text = $emailBody -replace '<.*?>', ''
# Print the extracted text
$cleaned_text.Trim() | Out-File -FilePath "C:\temp\output.txt"