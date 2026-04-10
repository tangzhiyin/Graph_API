<#
.SYNOPSIS
    使用 Microsoft Graph API (Application Permission) 获取所有用户的 License 信息并导出 CSV。
 
.DESCRIPTION
    通过 Client Credentials Flow 获取 Access Token，调用 Graph API 获取租户内所有用户的
    许可证分配详情，包括 SKU 名称和已启用/禁用的服务计划，最终导出为 CSV 文件。
 
.NOTES
    前置条件：
    1. 在 Azure AD (Entra ID) 中注册一个 App Registration
    2. 添加 Application Permission: User.Read.All + Directory.Read.All
    3. 授予 Admin Consent
    4. 创建 Client Secret，填入下方配置区域
 
.EXAMPLE
    .\Get-UserLicenses.ps1
#>
 
# ======================== 配置区域 ========================
$TenantId     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # 租户 ID
$ClientId     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # 应用程序 (客户端) ID
$ClientSecret = "your-client-secret-value"                # 客户端密钥
 
$OutputPath   = ".\UserLicenses_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
# =========================================================
 
# SKU 友好名称映射 (常见 License)
$SkuFriendlyNames = @{
    "O365_BUSINESS_ESSENTIALS"           = "Microsoft 365 Business Basic"
    "O365_BUSINESS_PREMIUM"              = "Microsoft 365 Business Standard"
    "SPB"                                = "Microsoft 365 Business Premium"
    "ENTERPRISEPACK"                     = "Office 365 E3"
    "ENTERPRISEPREMIUM"                  = "Office 365 E5"
    "ENTERPRISEPREMIUM_NOPSTNCONF"       = "Office 365 E5 (without Audio Conferencing)"
    "DESKLESSPACK"                       = "Office 365 F3"
    "SPE_E3"                             = "Microsoft 365 E3"
    "SPE_E5"                             = "Microsoft 365 E5"
    "SPE_F1"                             = "Microsoft 365 F1"
    "FLOW_FREE"                          = "Power Automate Free"
    "POWER_BI_STANDARD"                  = "Power BI Free"
    "POWER_BI_PRO"                       = "Power BI Pro"
    "EXCHANGESTANDARD"                   = "Exchange Online Plan 1"
    "EXCHANGEENTERPRISE"                 = "Exchange Online Plan 2"
    "EMS"                                = "Enterprise Mobility + Security E3"
    "EMSPREMIUM"                         = "Enterprise Mobility + Security E5"
    "PROJECTPREMIUM"                     = "Project Plan 5"
    "VISIOCLIENT"                        = "Visio Plan 2"
    "ATP_ENTERPRISE"                     = "Microsoft Defender for Office 365 Plan 1"
    "THREAT_INTELLIGENCE"                = "Microsoft Defender for Office 365 Plan 2"
    "TEAMS_EXPLORATORY"                  = "Microsoft Teams Exploratory"
    "TEAMS_COMMERCIAL_TRIAL"             = "Microsoft Teams Trial"
    "AAD_PREMIUM"                        = "Microsoft Entra ID P1"
    "AAD_PREMIUM_P2"                     = "Microsoft Entra ID P2"
    "WIN10_PRO_ENT_SUB"                  = "Windows 10/11 Enterprise E3"
    "WIN10_VDA_E5"                       = "Windows 10/11 Enterprise E5"
    "STREAM"                             = "Microsoft Stream"
    "MCOSTANDARD"                        = "Skype for Business Online Plan 2"
    "MICROSOFT_COPILOT"                  = "Microsoft 365 Copilot"
    "M365_COPILOT"                       = "Microsoft 365 Copilot"
    "POWERAPPS_VIRAL"                    = "Power Apps Trial"
    "RIGHTSMANAGEMENT"                   = "Azure Information Protection Plan 1"
}
 
function Get-FriendlyName($skuPartNumber) {
    if ($SkuFriendlyNames.ContainsKey($skuPartNumber)) {
        return $SkuFriendlyNames[$skuPartNumber]
    }
    return $skuPartNumber
}
 
# ===================== 获取 Access Token =====================
Write-Host "[1/4] 正在获取 Access Token..." -ForegroundColor Cyan
 
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
}
 
try {
    $tokenResponse = Invoke-RestMethod -Method POST `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $tokenBody
 
    $accessToken = $tokenResponse.access_token
    Write-Host "  Access Token 获取成功。" -ForegroundColor Green
}
catch {
    Write-Host "  获取 Token 失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
 
$headers = @{
    Authorization = "Bearer $accessToken"
    ConsistencyLevel = "eventual"
}
 
# ================ 获取租户订阅的 SKU 信息 ================
Write-Host "[2/4] 正在获取租户 SKU 订阅信息..." -ForegroundColor Cyan
 
$skuMap = @{}
try {
    $skuUrl = "https://graph.microsoft.com/v1.0/subscribedSkus"
    $skuResponse = Invoke-RestMethod -Method GET -Uri $skuUrl -Headers $headers
    foreach ($sku in $skuResponse.value) {
        $skuMap[$sku.skuId] = @{
            SkuPartNumber = $sku.skuPartNumber
            FriendlyName  = Get-FriendlyName $sku.skuPartNumber
        }
    }
    Write-Host "  共发现 $($skuMap.Count) 个订阅 SKU。" -ForegroundColor Green
}
catch {
    Write-Host "  获取 SKU 信息失败: $($_.Exception.Message)" -ForegroundColor Yellow
}
 
# ================ 获取所有用户及 License ================
Write-Host "[3/4] 正在获取所有用户 License 信息（可能需要几分钟）..." -ForegroundColor Cyan
 
$allUsers = [System.Collections.Generic.List[object]]::new()
$userUrl = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,accountEnabled,assignedLicenses&`$top=999%22
 
while ($userUrl) {
    try {
        $response = Invoke-RestMethod -Method GET -Uri $userUrl -Headers $headers
        if ($response.value) {
            $allUsers.AddRange($response.value)
        }
        $userUrl = $response.'@odata.nextLink'
 
        if ($userUrl) {
            Write-Host "  已获取 $($allUsers.Count) 个用户，继续翻页..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  请求失败: $($_.Exception.Message)" -ForegroundColor Red
        break
    }
}
 
Write-Host "  共获取 $($allUsers.Count) 个用户。" -ForegroundColor Green
 
# ================ 整理数据并导出 ================
Write-Host "[4/4] 正在整理数据并导出 CSV..." -ForegroundColor Cyan
 
$results = [System.Collections.Generic.List[object]]::new()
 
foreach ($user in $allUsers) {
    $licenses = $user.assignedLicenses
 
    if (-not $licenses -or $licenses.Count -eq 0) {
        # 无 License 的用户也记录
        $results.Add([PSCustomObject]@{
            DisplayName       = $user.displayName
            UserPrincipalName = $user.userPrincipalName
            AccountEnabled    = $user.accountEnabled
            LicenseCount      = 0
            Licenses          = "None"
            SkuPartNumbers    = "None"
        })
    }
    else {
        $licenseNames = @()
        $skuParts = @()
 
        foreach ($lic in $licenses) {
            $skuId = $lic.skuId
            if ($skuMap.ContainsKey($skuId)) {
                $licenseNames += $skuMap[$skuId].FriendlyName
                $skuParts += $skuMap[$skuId].SkuPartNumber
            }
            else {
                $licenseNames += $skuId
                $skuParts += $skuId
            }
        }
 
        $results.Add([PSCustomObject]@{
            DisplayName       = $user.displayName
            UserPrincipalName = $user.userPrincipalName
            AccountEnabled    = $user.accountEnabled
            LicenseCount      = $licenses.Count
            Licenses          = ($licenseNames -join "; ")
            SkuPartNumbers    = ($skuParts -join "; ")
        })
    }
}
 
# 导出 CSV
$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
 
# ================ 输出统计摘要 ================
$licensed   = ($results | Where-Object { $_.LicenseCount -gt 0 }).Count
$unlicensed = ($results | Where-Object { $_.LicenseCount -eq 0 }).Count
 
Write-Host "`n====== 完成 ======" -ForegroundColor Green
Write-Host "  总用户数:       $($results.Count)"
Write-Host "  有 License:     $licensed"
Write-Host "  无 License:     $unlicensed"
Write-Host "  导出文件:       $OutputPath"
Write-Host "==================`n" -ForegroundColor Green