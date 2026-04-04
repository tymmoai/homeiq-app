#!/usr/bin/env python3
import re

# Read the file
with open('lib/routes/app_router.dart', 'r') as f:
    lines = f.readlines()

# Find and fix the ProductDetailScreen route
output_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Check if this is the ProductDetailScreen section
    if 'return ProductDetailScreen(' in line and i > 0:
        # Look back to find the initialQuantity and totalCartCount lines
        start_idx = i
        while start_idx > 0 and 'final initialQuantity' not in lines[start_idx]:
            start_idx -= 1
        
        if start_idx >= 0 and 'final initialQuantity' in lines[start_idx]:
            # Skip initialQuantity and totalCartCount lines
            while i < len(lines) and ('initialQuantity' in lines[i] or 'totalCartCount' in lines[i] or lines[i].strip().startswith('final initialQuantity') or lines[i].strip().startswith('final totalCartCount')):
                i += 1
            # Output the ProductDetailScreen call with correct parameters
            output_lines.append('          return ProductDetailScreen(\n')
            output_lines.append('            product: product,\n')
            output_lines.append('            tradeInValue: tradeInValue,\n')
            i += 1  # Skip the 'return ProductDetailScreen(' line
            # Skip old parameters
            while i < len(lines) and lines[i].strip() not in [');', ');']:
                if 'product: product' not in lines[i] and 'tradeInValue: tradeInValue' not in lines[i]:
                    i += 1
                else:
                    break
            # Find the closing );
            while i < len(lines) and ');' not in lines[i]:
                i += 1
            output_lines.append(lines[i])  # Add the );
            i += 1
        else:
            output_lines.append(line)
            i += 1
    else:
        output_lines.append(line)
        i += 1

# Write back
with open('lib/routes/app_router.dart', 'w') as f:
    f.writelines(output_lines)

print("Router fixed!")
