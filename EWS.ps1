<!-- 示例配置文件片段 -->
<key>RibbonSettings</key>
<dict>
    <key>DisableCustomization</key>
    <true/>
    <key>HiddenTabs</key>
    <array>
        <string>TabName</string>
    </array>
</dict>$uri=[system.URI]"https://outlook.office365.com/EWS/Exchange.asmx";
$sleepSeconds = 10;
$dllpath = "C:\temp\Microsoft.Exchange.WebServices.dll"
Add-Type -Path $dllpath;

$TenantId = '';
$clientId = '';
$authority= "https://login.microsoftonline.com/$TenantId";
$clientSecret = '';
$secureSecret = (ConvertTo-SecureString $clientSecret -AsPlainText -Force);
$scope = 'https://outlook.office365.com/.default';
$result = Get-MsalToken -ClientId $clientId -ClientSecret $secureSecret -TenantId $TenantId -Scope $scope -Authority $authority;

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
# Set Exchange Version
$ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1;
$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion);
$service.Credentials = New-Object Microsoft.Exchange.WebServices.Data.OAuthCredentials -ArgumentList $result.AccessToken;
$service.UserAgent = "zhiyintang@yokoto.onmicrosoft.com";
$service.Url = $uri;

$mailbox = "zhiyintang@yokoto.onmicrosoft.com";
$service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SMTPAddress,$mailbox);
$service.HttpHeaders.Add("X-AnchorMailbox", $mailbox);

$sourceFolderID = New-Object Microsoft.Exchange.WebServices.Data.FolderId(`
[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot, $mailbox);
$sourceFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, $sourceFolderID);

$ItemsView = 200;
$folderView = New-Object Microsoft.Exchange.WebServices.Data.FolderView -ArgumentList $ItemsView;
$folders = $sourceFolder.FindFolders($folderView);
$folders.TotalCount;

#Create the email message and set the Subject and Body
$message = New-Object Microsoft.Exchange.WebServices.Data.EmailMessage -ArgumentList $service
$null = $message.ToRecipients.Add('admin@qif313.onmicrosoft.com');
$message.Subject = "3-HelloWorld with attachments";
$message.Body = New-Object Microsoft.Exchange.WebServices.Data.MessageBody -ArgumentList "This is the first email I've sent by using the EWS Managed API";
$message.Save([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Drafts);

#Define Property Set  
$PidTagClientActivelyEditingUntil = new-object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x3700,[Microsoft.Exchange.WebServices.Data.MapiPropertyType]::SystemTime);  
$untilDatetime = (get-date).AddMinutes(15).ToUniversalTime();
$message.SetExtendedProperty($PidTagClientActivelyEditingUntil, $untilDatetime);
$message.Update([Microsoft.Exchange.WebServices.Data.ConflictResolutionMode]::AlwaysOverwrite);

$files = Get-ChildItem -Path "C:\Temp\" -File;
$files | foreach{
    $message.Attachments.AddFileAttachment($psitem.VersionInfo.FileName) | Out-Null;
    Start-Sleep -Seconds $sleepSeconds;
}

$message.SendAndSaveCopy();