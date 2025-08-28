#!/bin/bash

# Generate realistic test scenarios with actual base64 content
# This script creates complete, production-ready test cases

echo "🌾 Generating realistic DSSAT test scenarios..."

BASE_DIR="/mnt/ssd/dssat-lambda-pro/tests/realistic_scenarios"

# Function to encode file to base64
encode_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        base64 -w 0 "$file_path"
    else
        echo "ERROR: File not found: $file_path"
        return 1
    fi
}

# Generate complete wheat test
echo "🌾 Creating complete wheat scenario..."
WHEAT_DIR="$BASE_DIR/complete_wheat"

cat > "$BASE_DIR/test_wheat_complete_realistic.json" << EOF
{
  "comment": "REALISTIC TEST: Complete Wheat Simulation - Kansas State University",
  "description": "Real wheat experiment (KSAS8101) with all required files from DSSAT database",
  "experiment_info": {
    "location": "Kansas State University, Ashland, KS",
    "crop": "Wheat (Newton variety)",
    "year": "1981",
    "treatments": "6 treatments (irrigation × nitrogen levels)",
    "weather_station": "KSAS", 
    "soil_type": "IBWH980018"
  },
  "individual_files": {
    "KSAS8101.WHX": "$(encode_file "$WHEAT_DIR/KSAS8101.WHX")",
    "KSAS8101.WTH": "$(encode_file "$WHEAT_DIR/KSAS8101.WTH")",
    "SOIL.SOL": "$(encode_file "$WHEAT_DIR/SOIL.SOL")",
    "WHCER048.CUL": "$(encode_file "$WHEAT_DIR/WHCER048.CUL")",
    "WHCER048.ECO": "$(encode_file "$WHEAT_DIR/WHCER048.ECO")",
    "WHCER048.SPE": "$(encode_file "$WHEAT_DIR/WHCER048.SPE")"
  },
  "output_format": "individual_files",
  "return_outputs": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT", "Warning.OUT"],
  "debug": true,
  "expected_results": {
    "crop_detected": "WH",
    "module_used": "CSCER048",
    "treatments_run": 6,
    "files_expected": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT"]
  }
}
EOF

# Generate complete rice test
echo "🌾 Creating complete rice scenario..."
RICE_DIR="$BASE_DIR/complete_rice"

cat > "$BASE_DIR/test_rice_complete_realistic.json" << EOF
{
  "comment": "REALISTIC TEST: Complete Rice Simulation - IRRI Philippines",
  "description": "Real rice experiment (IRPL8501) with all required files from DSSAT database",
  "experiment_info": {
    "location": "International Rice Research Institute, Philippines",
    "crop": "Rice (IR 58 variety)",
    "year": "1985", 
    "treatments": "Multiple planting dates and management",
    "weather_station": "IRPI",
    "soil_type": "IBRI910001"
  },
  "individual_files": {
    "IRPL8501.RIX": "$(encode_file "$RICE_DIR/IRPL8501.RIX")",
    "IRPI8501.WTH": "$(encode_file "$RICE_DIR/IRPI8501.WTH")",
    "SOIL.SOL": "$(encode_file "$RICE_DIR/SOIL.SOL")",
    "RICER048.CUL": "$(encode_file "$RICE_DIR/RICER048.CUL")",
    "RICER048.SPE": "$(encode_file "$RICE_DIR/RICER048.SPE")"
  },
  "output_format": "individual_files",
  "return_outputs": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT", "Warning.OUT"],
  "debug": true,
  "expected_results": {
    "crop_detected": "RI",
    "module_used": "RICER048", 
    "files_expected": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT"]
  }
}
EOF

# Generate complete soybean test  
echo "🌾 Creating complete soybean scenario..."
SOYBEAN_DIR="$BASE_DIR/complete_soybean"

cat > "$BASE_DIR/test_soybean_complete_realistic.json" << EOF
{
  "comment": "REALISTIC TEST: Complete Soybean Simulation - University of Florida",
  "description": "Real soybean experiment (UFGA7801) with all required files from DSSAT database",
  "experiment_info": {
    "location": "University of Florida, Gainesville, FL",
    "crop": "Soybean (Bragg variety)",
    "year": "1978",
    "treatments": "Multiple nitrogen and planting treatments",
    "weather_station": "UFGA",
    "soil_type": "IBSB910015"
  },
  "individual_files": {
    "UFGA7801.SBX": "$(encode_file "$SOYBEAN_DIR/UFGA7801.SBX")",
    "UFGA7801.WTH": "$(encode_file "$SOYBEAN_DIR/UFGA7801.WTH")",
    "SOIL.SOL": "$(encode_file "$SOYBEAN_DIR/SOIL.SOL")",
    "SBGRO048.CUL": "$(encode_file "$SOYBEAN_DIR/SBGRO048.CUL")",
    "SBGRO048.ECO": "$(encode_file "$SOYBEAN_DIR/SBGRO048.ECO")",
    "SBGRO048.SPE": "$(encode_file "$SOYBEAN_DIR/SBGRO048.SPE")"
  },
  "output_format": "individual_files",
  "return_outputs": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT", "Warning.OUT"],
  "debug": true,
  "expected_results": {
    "crop_detected": "SB",
    "module_used": "CRGRO048",
    "files_expected": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT"]
  }
}
EOF

# Generate complete maize test
echo "🌾 Creating complete maize scenario..."
MAIZE_DIR="$BASE_DIR/complete_maize"

cat > "$BASE_DIR/test_maize_complete_realistic.json" << EOF
{
  "comment": "REALISTIC TEST: Complete Maize Simulation - University of Florida",
  "description": "Real maize experiment (UFGA8201) with all required files from DSSAT database", 
  "experiment_info": {
    "location": "University of Florida, Gainesville, FL",
    "crop": "Maize (Corn)",
    "year": "1982",
    "treatments": "Multiple planting and management treatments",
    "weather_station": "UFGA",
    "soil_type": "Standard"
  },
  "individual_files": {
    "UFGA8201.MZX": "$(encode_file "$MAIZE_DIR/UFGA8201.MZX")",
    "UFGA8201.WTH": "$(encode_file "$MAIZE_DIR/UFGA8201.WTH")",
    "SOIL.SOL": "$(encode_file "$MAIZE_DIR/SOIL.SOL")",
    "MZCER048.CUL": "$(encode_file "$MAIZE_DIR/MZCER048.CUL")",
    "MZCER048.ECO": "$(encode_file "$MAIZE_DIR/MZCER048.ECO")",
    "MZCER048.SPE": "$(encode_file "$MAIZE_DIR/MZCER048.SPE")"
  },
  "output_format": "individual_files",
  "return_outputs": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT", "Warning.OUT"],
  "debug": true,
  "expected_results": {
    "crop_detected": "MZ",
    "module_used": "MZCER048",
    "files_expected": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT"]
  }
}
EOF

echo "✅ Generated realistic test scenarios:"
echo "   - test_wheat_complete_realistic.json"  
echo "   - test_rice_complete_realistic.json"
echo "   - test_soybean_complete_realistic.json"
echo "   - test_maize_complete_realistic.json"
echo ""
echo "🎯 These tests represent real-world scenarios with:"
echo "   - Actual experiment files from DSSAT database"
echo "   - Proper weather data for each location"
echo "   - Correct genotype files for each crop"
echo "   - Realistic soil profiles"
echo "   - Expected output validation"
