# Fix all remaining import paths in service booking flows
$ErrorActionPreference = "Stop"
Set-Location "D:\301io\HomeIQ_APP\lib\features\services\service_booking_flow"

Write-Host "Fixing import paths in mounting and moving folders..." -ForegroundColor Yellow

# Function to fix imports in a file
function Fix-Imports {
    param($File, $OldPattern, $NewPattern)
    if (Test-Path $File) {
        $content = Get-Content $File -Raw
        $content = $content -replace $OldPattern, $NewPattern
        Set-Content $File $content -NoNewline
        Write-Host "✓ Fixed: $File"
    }
}

# Fix mounting flow files
$mountingFiles = @(
    "mounting\step4_review.dart",
    "mounting\step5_confirmation.dart"
)

foreach ($file in $mountingFiles) {
    Fix-Imports $file "import '../../../core/constants/app_colors.dart';" "import '../../../../core/constants/app_colors.dart';"
    Fix-Imports $file "import '../../payment_screen.dart';" "import '../../../profile/payment_methods/screens/payment_screen.dart';"
    Fix-Imports $file "import '../mounting_booking_flow.dart';" "import 'mounting_booking_flow.dart';"
    Fix-Imports $file "import '../../../services/booking_service.dart';" "import '../../services/booking_service.dart';"
}

# Fix moving flow files  
$movingFiles = @(
    "moving\moving_booking_flow.dart",
    "moving\step1_select_service.dart",
    "moving\step2_furniture_type.dart",
    "moving\step2_heavy_item_type.dart",
    "moving\step2_home_moving_details.dart",
    "moving\step2_moving_details.dart",
    "moving\step2_office_details.dart",
    "moving\step2b_location_details.dart",
    "moving\step2c_addons.dart",
    "moving\step3_schedule.dart",
    "moving\step4_review.dart",
    "moving\step5_confirmation.dart"
)

foreach ($file in $movingFiles) {
    # Fix core imports
    Fix-Imports $file "import '../../../core/constants/app_colors.dart';" "import '../../../../core/constants/app_colors.dart';"
    
    # Fix relative imports to absolute
    Fix-Imports $file "import 'moving/" "import './"
    Fix-Imports $file "import '../moving_booking_flow.dart';" "import 'moving_booking_flow.dart';"
    Fix-Imports $file "import '../../payment_screen.dart';" "import '../../../profile/payment_methods/screens/payment_screen.dart';"
    Fix-Imports $file "import '../../../services/booking_service.dart';" "import '../../services/booking_service.dart';"
}

Write-Host "`n✅ All import paths fixed!" -ForegroundColor Green
