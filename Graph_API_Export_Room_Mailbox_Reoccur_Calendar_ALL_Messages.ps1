$ClientID = ""
$ClientSecret = ""
$TenantId = ""
$loginURL = "https://login.microsoftonline.com/"
$resource = "https://graph.microsoft.com"
 
#修改email地址，修改成对应的room mailbox的地址
$emailaddress = "TW.HY.5F.509@foxconn.com"
$starttime = '2024-06-09T00:00:00'
$endtime = '2024-07-09T00:00:00.00'

 
## OAuth to get Access token >>>
# Application Permission for OAuth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
 
 
$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$TenantID/oauth2/token?api-version=1.0" -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
## OAuth to get Access token <<<
 
 
# MS Graph API - Get evenets
$url = "$resource/v1.0/users/$emailaddress/calendarView"
<# $data = Invoke-RestMethod -Headers $headerParams -Method Get -Uri $url
$data.value #>
 
while ($url)
{
    $data = (Invoke-RestMethod -Headers $headerParams -Method Get -Uri $url);
    $data.value | foreach {
        [PSCustomObject]@{
            "StartTime" = $_.start.dateTime
            "EndTime" = $_.end.dateTime
            "Organizer" = $_.organizer.emailAddress.name
            "Organizer_Address" = $_.organizer.emailAddress.address
            "Subject" = $_.subject
            "onlineMeeting"=$_.onlineMeeting.joinUrl 
       } | Export-Csv -Path "C:\temp\meeting-HY509.csv" -NoTypeInformation -Encoding UTF8 -Append
       #这里是存储抓取数据的文件位置：D:\工作事宜\會議室統計分析\PowerBI分析MTR會議室數據\RawData\HY-5F-MeetingRoom\meeting-HY508.csv，csv文件也可以修改名称
    }
    $url = $data.'@odata.nextLink'
}