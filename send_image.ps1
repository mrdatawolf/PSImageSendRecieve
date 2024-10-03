param (
    [string]$imagePath
)

# Function to load environment variables from a .env file
function Get-Dotenv {
    param (
        [string]$envFilePath = ".env"
    )

    if (Test-Path $envFilePath) {
        Get-Content $envFilePath | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$") {
                [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
            }
        }
    } else {
        Write-Host "The .env file was not found at path: $envFilePath" -ForegroundColor Red
        exit
    }
}

# Function to open a file dialog and select a file
function Select-FileDialog {
    Add-Type -AssemblyName System.Windows.Forms
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "Image Files|*.jpg;*.jpeg;*.png;*.gif;*.bmp"
    $fileDialog.ShowDialog() | Out-Null
    return $fileDialog.FileName
}

# Load environment variables
Get-Dotenv

# Retrieve the variables
$uri = [System.Environment]::GetEnvironmentVariable('SENDURI')
$auth = [System.Environment]::GetEnvironmentVariable('SENDAUTH')
$location = [System.Environment]::GetEnvironmentVariable('LOCATION')

# Check if imagePath is provided, if not, open file dialog
if (-not $imagePath) {
    $imagePath = Select-FileDialog
    if (-not $imagePath) {
        Write-Host "No file selected. Exiting script." -ForegroundColor Red
        exit
    }
}

# Upload the file and capture the response
$response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{
    Authorization = $auth
} -Form @{
    file = Get-Item -Path $imagePath
    filePath = $location
}

# Extract the required fields from the response
$etag = $response.etag
$filePath = $response.filePath
$fileUrl = $response.fileUrl

# Create an object to store the data
$data = [PSCustomObject]@{
    etag = $etag
    filePath = $filePath
    fileUrl = $fileUrl
}

# Define the CSV file path
$csvFilePath = "output.csv"

# Check if the CSV file exists
if (-not (Test-Path $csvFilePath)) {
    # Create the CSV file with headers
    $data | Export-Csv -Path $csvFilePath -NoTypeInformation
} else {
    # Append to the existing CSV file
    $data | Export-Csv -Path $csvFilePath -NoTypeInformation -Append
}

Write-Host "Data has been saved to $csvFilePath" -ForegroundColor Green
