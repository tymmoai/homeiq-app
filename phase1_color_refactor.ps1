# 🎨 Phase 1 Color Refactoring - Batch Replacement Script
# Replaces remaining hardcoded colors with AppColors constants

Write-Host ""
Write-Host "🎨 HOMEIQ COLOR REFACTORING - PHASE 1" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# New color mappings (Phase 1 - Priority colors)
$colorMappings = @(
    # Text & Icon Colors
    @{ Pattern = "Color\(0xFF9E9E9E\)"; Replacement = "AppColors.textLight" }
    @{ Pattern = "Color\(0xFF111827\)"; Replacement = "AppColors.textDark" }
    @{ Pattern = "Color\(0xFF6B7280\)"; Replacement = "AppColors.textQuaternary" }
    @{ Pattern = "Color\(0xFFB0BEC5\)"; Replacement = "AppColors.textPlaceholder" }
    
    # Status Backgrounds
    @{ Pattern = "Color\(0xFFD1FAE5\)"; Replacement = "AppColors.successBackground" }
    @{ Pattern = "Color\(0xFFFEF3C7\)"; Replacement = "AppColors.warningBackground" }
    @{ Pattern = "Color\(0xFFDBEAFE\)"; Replacement = "AppColors.infoLight" }
    
    # Accent Colors
    @{ Pattern = "Color\(0xFFFBBF24\)"; Replacement = "AppColors.amber" }
    @{ Pattern = "Color\(0xFFF3F4F6\)"; Replacement = "AppColors.borderLight" }
    
    # Material Colors → Map to existing
    @{ Pattern = "Color\(0xFF4CAF50\)"; Replacement = "AppColors.success" }
    @{ Pattern = "Color\(0xFF2196F3\)"; Replacement = "AppColors.info" }
)

# Get all Dart files
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$totalFiles = 0
$modifiedFiles = 0
$totalReplacements = 0

Write-Host "📁 Scanning Dart files..." -ForegroundColor Yellow
Write-Host ""

foreach ($file in $files) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileModified = $false
    $fileReplacements = 0
    
    # Apply all color replacements
    foreach ($mapping in $colorMappings) {
        $pattern = $mapping.Pattern
        $replacement = $mapping.Replacement
        
        # Count matches
        $matches = [regex]::Matches($content, [regex]::Escape($pattern))
        if ($matches.Count -gt 0) {
            $content = $content -replace [regex]::Escape($pattern), $replacement
            $fileReplacements += $matches.Count
            $fileModified = $true
        }
    }
    
    # Save if modified
    if ($fileModified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $modifiedFiles++
        $totalReplacements += $fileReplacements
        Write-Host "✅ $($file.Name)" -ForegroundColor Green -NoNewline
        Write-Host " - $fileReplacements replacements" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✅ PHASE 1 COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "   Files scanned: $totalFiles"
Write-Host "   Files modified: $modifiedFiles"
Write-Host "   Total replacements: $totalReplacements"
Write-Host ""

if ($modifiedFiles -gt 0) {
    Write-Host "⚠️  NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "   1. Run: flutter analyze" -ForegroundColor White
    Write-Host "   2. Check for errors" -ForegroundColor White
    Write-Host "   3. Test app on device" -ForegroundColor White
    Write-Host "   4. Review changes with: git diff" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 If app works correctly, commit changes!" -ForegroundColor Cyan
} else {
    Write-Host "ℹ️  No files needed updating." -ForegroundColor Cyan
}

Write-Host ""
