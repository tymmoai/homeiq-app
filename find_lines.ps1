# Read the file
$lines = Get-Content "D:\301io\app\lib\features\assets\add_asset_flow\screens\step2_identify_screen.dart"

# We need to keep:
# Lines 1-304 (imports through the NEW _buildPhotoUploadArea delegate, up to its closing brace)
# Skip lines 305-607 (the old _buildPhotoUploadArea_MARKER / _REMOVED method)
# Lines 608-907 (_showImageSourceDialog through _buildTextField end, before _buildGuidanceSection)
# Replace _buildGuidanceSection (lines 908-1202) with a delegate
# Remove _buildNameplateGuidance (lines 1204-1378)
# Keep lines 1379-1567 (_fetchDynamicBrands through end)

# Let's find the exact line numbers by searching
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '_buildPhotoUploadArea_MARKER') {
        Write-Host "MARKER at line $($i+1): $($lines[$i])"
    }
    if ($lines[$i] -match 'void _showImageSourceDialog') {
        Write-Host "showImageSourceDialog at line $($i+1): $($lines[$i])"
    }
    if ($lines[$i] -match 'Widget _buildGuidanceSection') {
        Write-Host "buildGuidanceSection at line $($i+1): $($lines[$i])"
    }
    if ($lines[$i] -match 'Widget _buildNameplateGuidance') {
        Write-Host "buildNameplateGuidance at line $($i+1): $($lines[$i])"
    }
    if ($lines[$i] -match 'Future<void> _fetchDynamicBrands') {
        Write-Host "fetchDynamicBrands at line $($i+1): $($lines[$i])"
    }
    if ($lines[$i] -match 'Widget _buildContinueButton') {
        Write-Host "buildContinueButton at line $($i+1): $($lines[$i])"
    }
}
