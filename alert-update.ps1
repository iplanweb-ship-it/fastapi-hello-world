# Your API token
$ApiToken = "<TOKEN>"

# Alert ID
$AlertId = "<ALERTID>"

# API endpoint (adjust region if needed)
$Url = "https://api.logz.io/v1/alerts/$AlertId"

# Headers
$Headers = @{
    "X-API-TOKEN"  = $ApiToken
    "Content-Type" = "application/json"
}

# ===== CONFIGURATION =====
$token = "<TOKEN>"
$alertId = "<ALERTID>"
$baseUrl = "https://api.logz.io/v1"
$newThreshold = 50   # <-- change threshold here

# ===== HEADERS =====
$headers = @{
  "X-API-TOKEN" = $token
  "Content-Type" = "application/json"
}


# ===== GET existing alert =====
Write-Host "Fetching current alert definition..."
$alert = Invoke-RestMethod -Uri "$baseUrl/alerts/$alertId" -Method Get -Headers $headers

# ===== UPDATE THRESHOLDS =====
$alert.threshold = 50.0
if ($alert.severityThresholdTiers -and $alert.severityThresholdTiers.Count -gt 0) {
    $alert.severityThresholdTiers[0].threshold = 50.0
}

# ===== CONVERT TO JSON AND PUT =====
$body = $alert | ConvertTo-Json -Depth 10

Write-Host "Updating alert threshold to 50..."
$response = Invoke-RestMethod -Uri "$baseUrl/alerts/$alertId" -Method Put -Headers $headers -Body $body

Write-Host "✅ Alert updated successfully!"
$response
