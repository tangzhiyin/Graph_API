$ClientID = ""
$ClientSecret = ""
$TenantId = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"
$emailaddress = ""


## OAuth to get Access token >>>
# Application Permission for OAuth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}


$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$TenantID/oauth2/token?api-version=1.0" -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
## OAuth to get Access token <<<


# MS Graph API - Get evenets
$Data = (Invoke-RestMethod -Headers $headerParams -Method Get -Uri "$resource/v1.0/users/$emailaddress/calendar/events").value


$ruleList2 = @()
foreach ($i in $Data)
 
{
$start = $i.start
$end = $i.end
$location = $i.location
$organizer = $i.organizer
 
@"
$start
$end
$location
$organizer
"@

   $CustObj = [PSCustomObject]@{
        "StartTime" = $start
        "EndTime" = $end
        "Location" = $location
        "Organizer" = $organizer
}
 
$ruleList2 += $CustObj
 

}
 
$ruleList2 | Export-Csv -NoTypeInformation -Path "C:\temp\123.csv"
