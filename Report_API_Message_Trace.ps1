# Custom Values >>>
$TenantID = "“
$ClientID = ""
$ClientSecret = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://outlook.office365.com"


# Custom Values <<<

## OAuth to get Access token >>>
# Application Permission for OAuth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}

$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$TenantID/oauth2/token?api-version=1.0" -Body $body
$headers = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}

## OAuth to get Access token <<<
#Send Mail    
$GetUri = "https://reports.office365.com/ecp/ReportingWebService/Reporting.svc/MessageTrace?"
$event= Invoke-RestMethod -Uri $GetUri -Headers $headers -Method GET
$event.content.properties