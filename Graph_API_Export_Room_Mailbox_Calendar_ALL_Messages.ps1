$ClientID = ""
$ClientSecret = ""
$TenantId = "1608350e-92d5-431a-8ea2-bd2f76141620"
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"

#修改email地址，修改成对应的room mailbox的地址
$emailaddress = ""
$starttime = '2024-02-19T08:00:00.00Z'
$endtime = '2024-02-20T08:00:00.00Z'


## OAuth to get Access token >>>
# Application Permission for OAuth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}


$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$TenantID/oauth2/token?api-version=1.0" -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
## OAuth to get Access token <<<


# MS Graph API - Get evenets
$url = "$resource/v1.0/users/$emailaddress/calendar/events" +'?$filter'+ "=start/dateTime gt `'$starttime`' and end/dateTime lt `'$endtime`'"

while ($url)
{
    $Data = (Invoke-RestMethod -Headers $headerParams -Method Get -Uri $url);
    $data.value | foreach {
        [PSCustomObject]@{
            "StartTime" = $_.start.dateTime
            "EndTime" = $_.end.dateTime
            "Organizer" = $_.organizer.emailAddress.name
            "Organizer_Address" = $_.organizer.emailAddress.address
            "Subject" = $_.subject
       } | Export-Csv -Path "C:/temp/meeting.csv" -NoTypeInformation -Encoding UTF8 -Append
    }
    $url = $data.'@odata.nextLink'
}
