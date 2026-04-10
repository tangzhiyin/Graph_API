# Get Latest Email using Exchange Web Services (EWS)
# This script connects directly to Exchange on-premises to determine the latest email

# EWS Configuration
$ExchangeServer = "your-exchange-server.domain.com"  # Replace with your Exchange server
$ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2016  # Adjust version as needed
$Username = "domain\username"  # Replace with actual credentials
$Password = "password"  # Replace with actual password
$DllPath = "C:\temp\Microsoft.Exchange.WebServices.dll"  # Download from Microsoft

# Load EWS Managed API
if (Test-Path $DllPath) {
    Add-Type -Path $DllPath
} else {
    Write-Error "EWS Managed API DLL not found at $DllPath. Please download and install the EWS Managed API."
    exit
}

# Create Exchange Service
$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion)

# Set credentials
$service.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)

# Auto-discover or set URL manually
try {
    $service.AutodiscoverUrl("user@yourdomain.com")  # Replace with actual email
} catch {
    # If autodiscover fails, set URL manually
    $service.Url = "https://$ExchangeServer/EWS/Exchange.asmx"
}

# Method 1: Get latest email by received date
Write-Host "=== Method 1: Getting Latest Email using EWS ===" -ForegroundColor Green

# Define property set to include received date
$propertySet = New-Object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties)
$propertySet.Add([Microsoft.Exchange.WebServices.Data.ItemSchema]::DateTimeReceived)
$propertySet.Add([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::From)

# Create search filter and sort by received date (descending)
$searchFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.ItemSchema]::ItemClass, "IPM.Note")
$itemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(1)  # Get only the latest
$itemView.OrderBy.Add([Microsoft.Exchange.WebServices.Data.ItemSchema]::DateTimeReceived, [Microsoft.Exchange.WebServices.Data.SortDirection]::Descending)
$itemView.PropertySet = $propertySet

try {
    # Search in Inbox
    $inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox)
    $findResults = $inbox.FindItems($searchFilter, $itemView)
    
    if ($findResults.Items.Count -gt 0) {
        $latestEmail = $findResults.Items[0]
        Write-Host "Latest Email Found:" -ForegroundColor Yellow
        Write-Host "Subject: $($latestEmail.Subject)"
        Write-Host "From: $($latestEmail.From.Address)"
        Write-Host "Received: $($latestEmail.DateTimeReceived)"
        Write-Host "Message ID: $($latestEmail.Id.UniqueId)"
        
        # Store the latest email ID for comparison
        $latestEmailId = $latestEmail.Id.UniqueId
    } else {
        Write-Host "No emails found in inbox" -ForegroundColor Yellow
    }
} catch {
    Write-Error "Error retrieving latest email: $($_.Exception.Message)"
}

# Method 2: Function to check if a specific email is the latest
function Test-IsLatestEmailEWS {
    param(
        [Microsoft.Exchange.WebServices.Data.ExchangeService]$Service,
        [string]$EmailId
    )
    
    try {
        # Get the latest email
        $searchFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.ItemSchema]::ItemClass, "IPM.Note")
        $itemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(1)
        $itemView.OrderBy.Add([Microsoft.Exchange.WebServices.Data.ItemSchema]::DateTimeReceived, [Microsoft.Exchange.WebServices.Data.SortDirection]::Descending)
        
        $inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($Service, [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox)
        $findResults = $inbox.FindItems($searchFilter, $itemView)
        
        if ($findResults.Items.Count -gt 0) {
            $latestEmail = $findResults.Items[0]
            $latestEmailId = $latestEmail.Id.UniqueId
            
            if ($EmailId -eq $latestEmailId) {
                return @{
                    IsLatest = $true
                    LatestDateTime = $latestEmail.DateTimeReceived
                    LatestSubject = $latestEmail.Subject
                    Message = "This email is the latest received email"
                }
            } else {
                return @{
                    IsLatest = $false
                    LatestDateTime = $latestEmail.DateTimeReceived
                    LatestSubject = $latestEmail.Subject
                    Message = "This email is NOT the latest received email"
                }
            }
        }
    } catch {
        Write-Error "Error checking email: $($_.Exception.Message)"
    }
    
    return @{
        IsLatest = $false
        LatestDateTime = $null
        LatestSubject = $null
        Message = "Error or no emails found"
    }
}

# Method 3: Get emails received since a specific time
Write-Host "`n=== Method 3: Get Recent Emails (Last 1 hour) ===" -ForegroundColor Green

$cutoffTime = (Get-Date).AddHours(-1)
$timeFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsGreaterThanOrEqualTo([Microsoft.Exchange.WebServices.Data.ItemSchema]::DateTimeReceived, $cutoffTime)
$classFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.ItemSchema]::ItemClass, "IPM.Note")
$combinedFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection([Microsoft.Exchange.WebServices.Data.LogicalOperator]::And)
$combinedFilter.Add($timeFilter)
$combinedFilter.Add($classFilter)

$recentItemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(50)
$recentItemView.OrderBy.Add([Microsoft.Exchange.WebServices.Data.ItemSchema]::DateTimeReceived, [Microsoft.Exchange.WebServices.Data.SortDirection]::Descending)

try {
    $recentResults = $inbox.FindItems($combinedFilter, $recentItemView)
    
    if ($recentResults.Items.Count -gt 0) {
        Write-Host "Found $($recentResults.Items.Count) emails in the last hour:" -ForegroundColor Yellow
        foreach ($email in $recentResults.Items) {
            Write-Host "  - $($email.Subject) (Received: $($email.DateTimeReceived))"
        }
        
        # The first one is the latest
        Write-Host "`nMost recent email: $($recentResults.Items[0].Subject)" -ForegroundColor Cyan
    } else {
        Write-Host "No emails received in the last hour" -ForegroundColor Yellow
    }
} catch {
    Write-Error "Error retrieving recent emails: $($_.Exception.Message)"
}

# Method 4: Monitor for new emails using EWS Streaming Notifications
Write-Host "`n=== Method 4: EWS Streaming Notifications Setup ===" -ForegroundColor Green

function Start-EWSEmailMonitoring {
    param(
        [Microsoft.Exchange.WebServices.Data.ExchangeService]$Service
    )
    
    try {
        # Create streaming subscription
        $subscription = $Service.SubscribeToStreamingNotifications(
            @([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox),
            [Microsoft.Exchange.WebServices.Data.EventType]::NewMail
        )
        
        Write-Host "Starting EWS streaming notifications for new emails..."
        Write-Host "Press Ctrl+C to stop monitoring."
        
        # Create connection
        $connection = New-Object Microsoft.Exchange.WebServices.Data.StreamingSubscriptionConnection($Service, 30)
        $connection.AddSubscription($subscription)
        
        # Event handler for new mail
        $connection.add_OnNotificationEvent({
            param($sender, $args)
            
            foreach ($notification in $args.Events) {
                if ($notification.EventType -eq [Microsoft.Exchange.WebServices.Data.EventType]::NewMail) {
                    Write-Host "`n*** NEW EMAIL DETECTED ***" -ForegroundColor Green
                    Write-Host "New email received at: $(Get-Date)"
                    Write-Host "Item ID: $($notification.ItemId.UniqueId)"
                    
                    # Optionally, get more details about the new email
                    try {
                        $newEmail = [Microsoft.Exchange.WebServices.Data.EmailMessage]::Bind($Service, $notification.ItemId)
                        Write-Host "Subject: $($newEmail.Subject)"
                        Write-Host "From: $($newEmail.From.Address)"
                        Write-Host "Received: $($newEmail.DateTimeReceived)"
                    } catch {
                        Write-Host "Could not retrieve email details: $($_.Exception.Message)"
                    }
                }
            }
        })
        
        # Start the connection
        $connection.Open()
        
        # Keep the connection alive
        while ($true) {
            Start-Sleep -Seconds 1
        }
        
    } catch {
        Write-Error "Error setting up streaming notifications: $($_.Exception.Message)"
    }
}

# Uncomment to start monitoring
# Start-EWSEmailMonitoring -Service $service

Write-Host "`nScript completed. Use the Test-IsLatestEmailEWS function to check specific emails." -ForegroundColor Green
