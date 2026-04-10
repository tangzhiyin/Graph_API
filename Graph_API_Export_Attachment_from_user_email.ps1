$ClientID = ""
$ClientSecret = ""
$TenantId = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"
 
# Construct URI and body needed for authentication
$uri = "$loginURL/$TenantId/oauth2/v2.0/token"
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
          'Authorization' = "Bearer $token"
}
 
# MS Graph API - Get Users
$uri = "$resource/v1.0/users/$emailaddress/mailFolders/inbox/messages"
 
$msgqury = $uri + "?`$select=Id&`$filter=HasAttachments eq true"
 
$msgs = Invoke-RestMethod -Uri $msgqury -Headers $Headers
 
 
while ($msgs.value){
   foreach ($m in $msgs.value){
 
   $query = $uri + "/" + $m.Id + "/attachments"
 
   $attachment = Invoke-RestMethod $query -Headers $Headers
 
   foreach ($attachment in $attachment.value){
       $fname = "C:\Temp\" + $attachment.name
       $content = [System.Convert]::FromBase64String($attachment.ContentBytes)
       Set-Content -Path $fname -Value $content -Encoding Byte
   }       
   }
 
   $msgqury = $msgs.'@odata.nextlink'
   if ($msqury){
       $msgs = Invoke-RestMethod $query -Headers $Headers
       }
       else{
       $msgs.value = ''
       }
 
}