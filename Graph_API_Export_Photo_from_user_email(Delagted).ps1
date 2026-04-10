Install-Module Microsoft.Graph.Users -Scope CurrentUser


$TenantId = "";
$ApplicationId = "";
$resource = "https://login.microsoftonline.com/$TenantId";
$loginUPN = '';
$outFileId = "C:\temp\$loginUPN.jpg"

 
$scopes = "offline_access","openid profile","User.Read.All";
$redirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient';
$Token = Get-MsalToken -ClientId $ApplicationId -Scope $scopes -LoginHint $loginUPN -RedirectUri $redirectUri -Interactive -Authority $resource;
$AccessToken = $Token.AccessToken | ConvertTo-SecureString -AsPlainText -Force

Connect-MgGraph -AccessToken $AccessToken;

Get-MgUserPhotoContent -UserId $loginUPN -OutFile $outFileId