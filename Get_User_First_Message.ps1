$connectiondetails = @{
    "ClientID" = ""
    "ClientSecret" = "" | ConvertTo-SecureString -AsPlainText -Force
    "TenantId" = ""
}
$resource = "https://graph.microsoft.com"
$emailaddress = ""

## OAuth to get Access token >>>
# Application Permission for OAuth
$token = Get-MsalToken @connectiondetails
$accesstoken = $token.AccessToken


# MS Graph API - Get Users
$uri = "$resource/v1.0/users/$emailaddress/mailFolders/inbox/messages?top=1"

$msgqury = $uri + "?`$select=Id&`$filter=HasAttachments eq true"

$msgs = Invoke-RestMethod $msgqury -Headers @{Authentication=("bear {0}" -f $accesstoken)} 


while ($msgs.value){
    foreach ($m in $msgs.value){

    $query = $uri + "/" + $m.Id + "/attachments"

    $attachment = Invoke-RestMethod $query -Headers @{Authentication=("bear {0}" -f $accesstoken)} 
    
    foreach ($attachemnt in $attachments.value){
        $fname = "C:\temp\attahcments\" + $attachment.name
        $content = [System.Convert]::FromBase64String($attachment.ContentBytes)
        Set-Content -Path $fname -Value $content -Encoding Byte
    }        
    }

    $msgqury = $msgs.'@odata.nextlink'
    if ($msqury){
        $msgs = Invoke-RestMethod $query -Headers @{Authentication=("bear {0}" -f $accesstoken)}
        }
        else{
        $msgs.value = ''
        } 

}






