# Step 1: Authenticate to Microsoft Graph API
$clientId = ""
$tenantId = ""
$clientSecret = ""
$scopes = @("https://graph.microsoft.com/.default")

# Use MSAL to acquire the token
$body = @{
    client_id     = $clientId
    tenant_id     = $tenantId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}

# Get the token
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $tokenResponse.access_token
$header = @{
    Authorization = "Bearer $accessToken"
}


# Step 2: Get Users from a csv list
$CSVFilePath = "C:\temp\UserList.csv"

# 2. 导入 CSV 文件。Import-Csv 会将每一行转换为一个 PowerShell 对象
Write-Host "正在从 $CSVFilePath 导入用户数据..."
try {
    $Users = Import-Csv -Path $CSVFilePath -header "UserPrincipalName"
}
catch {
    Write-Error "导入文件失败: $($_.Exception.Message)"
    return
}

Write-Host "成功导入 $($Users.Count) 个用户。"

# 3. 遍历用户列表并处获取对应用户meeting id
$dict1 = New-Object System.Collections.Generic.Dictionary"[String,String]" 

foreach ($User in $Users) {
    # 从当前用户对象中获取 'UserPrincipalName' (UPN)
    # 注意：这里的属性名必须和 CSV 文件中的标题行完全一致
    $UPN = $User.UserPrincipalName

    Write-Host "---"
    Write-Host "正在处理用户: $UPN"
    # ----------------------------------------------------
    # **这里是您可以执行操作的地方
    $GetgraphUri = "https://graph.microsoft.com/v1.0/users/$UPN/calendar/events?`$filter=subject eq 'SeriesMeeting'"
    $GetResult = Invoke-RestMethod -Uri $GetgraphUri -Headers $header -Method Get
    $GetResult.value.id
    $dict1.Add("$UPN", "$($GetResult.value.id)")   
    # ----------------------------------------------------
}

Write-Host "---"
Write-Host "获取所有id处理完毕。"

foreach ($CURUPN in $dict1.keys){
       $eventid = $dict1[$CURUPN]
       $DeletegraphUri = "https://graph.microsoft.com/v1.0/users/$CURUPN/calendar/events/$eventid"
       $DeleteResult = Invoke-RestMethod -Uri $DeletegraphUri -Headers $header -Method delete
}


Write-Host "---"
Write-Host "删除meeting完毕。"