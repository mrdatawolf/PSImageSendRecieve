Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

# Function to create a thumbnail from an image
function Create-Thumbnail {
    param (
        [string]$imagePath,
        [int]$thumbnailSize = 100
    )

    $image = [System.Drawing.Image]::FromFile($imagePath)
    $thumbnail = $image.GetThumbnailImage($thumbnailSize, $thumbnailSize, $null, $null)
    return $thumbnail
}

# Function to display thumbnails in a GUI
function Display-Thumbnails {
    param (
        [string[]]$imagePaths
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Uploaded Images"
    $form.Size = New-Object System.Drawing.Size(800, 600)

    $flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $form.Controls.Add($flowLayoutPanel)

    foreach ($imagePath in $imagePaths) {
        $thumbnail = Create-Thumbnail -imagePath $imagePath
        $pictureBox = New-Object System.Windows.Forms.PictureBox
        $pictureBox.Image = $thumbnail
        $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::AutoSize
        $flowLayoutPanel.Controls.Add($pictureBox)
    }

    [void]$form.ShowDialog()
}

# Function to download an image from a URL
function Download-Image {
    param (
        [string]$url,
        [string]$outputPath
    )

    Invoke-WebRequest -Uri $url -OutFile $outputPath
}

# Load environment variables
Get-Dotenv

# Retrieve the variables
$uriList = "https://api.bytescale.com/v2/accounts/W142iob/folders/list?folderPath=/uploads"
$auth = [System.Environment]::GetEnvironmentVariable('READAUTH')

# Retrieve the list of uploaded files
$response = Invoke-RestMethod -Uri $uriList -Method Get -Headers @{
    Authorization = "Bearer $auth"
}

# Assuming the response contains a list of file paths
$imageUrls = $response.files | ForEach-Object { "https://upcdn.io/W142iob/raw/$_" }

# Download images to a temporary directory
$tempDir = [System.IO.Path]::GetTempPath()
$imagePaths = @()

foreach ($url in $imageUrls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    $outputPath = [System.IO.Path]::Combine($tempDir, $fileName)
    Download-Image -url $url -outputPath $outputPath
    $imagePaths += $outputPath
}

# Display the thumbnails
Display-Thumbnails -imagePaths $imagePaths
