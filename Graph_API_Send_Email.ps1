# Custom Values >>>
$TenantID = ""
$ClientID = ""
$ClientSecret = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"
$senderEmail = "IPhone@MngEnvMCAP448411.onmicrosoft.com"  # 发送邮件的用户邮箱
$recipientEmail = "IPhone@MngEnvMCAP448411.onmicrosoft.com"  # 收件人邮箱

# Custom Values <<<

## OAuth to get Access token >>>
# Application Permission for OAuth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}

$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$TenantID/oauth2/token?api-version=1.0" -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
## OAuth to get Access token <<<
#Send Mail    
$URLsend = "https://graph.microsoft.com/v1.0/users/$senderEmail/sendMail"
$BodyJsonsend = @"
                    {
                        "message": {
                          "subject": "Hello World from Microsoft Graph API",
                          "body": {
                            "contentType": "Text",
                            "content": "This Mail is sent via Microsoft"
                          },
                          "toRecipients": [
                            {
                              "emailAddress": {
                                "address": "$recipientEmail"
                              }
                            }
                          ]
                          },
                        "saveToSentItems": "false"
                      }
"@

Invoke-RestMethod -Method POST -Uri $URLsend -Headers $headerParams -Body $BodyJsonsend -ContentType "application/json"