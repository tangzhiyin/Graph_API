$TenantID = ""
$ClientID = ""
$ClientSecret = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"
# Custom Values <<<

## OAuth to get Access token >>>
# Application Permission for OAuth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}

$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$TenantID/oauth2/token?api-version=1.0" -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
## OAuth to get Access token <<<

# MS Graph API - Get Users
$graph = Invoke-RestMethod -Headers $headerParams -Uri "$resource/v1.0/reports/getOffice365ActiveUserDetail(period='D180')"
$graph