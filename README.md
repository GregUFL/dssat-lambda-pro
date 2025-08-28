# DSSAT Lambda Pro - AWS Serverless Crop Simulation Platform ✅

A production-ready AWS Lambda function for running DSSAT (Decision Support System for Agrotechnology Transfer) crop simulation models in a serverless environment. Enterprise-grade agricultural simulation platform with multiple input methods and comprehensive crop support.

## 🚀 Latest Enhancements (v5.0)

### ✨ New Features
- **Individual File Processing**: Process single files directly without ZIP archives
- **Enhanced S3 Integration**: Direct S3 object processing with flexible input methods
- **Multiple Input Formats**: ZIP files, individual files, or direct content uploads
- **Backward Compatibility**: All existing functionality preserved

### 🔧 Critical Fixes
- **Universal Crop Support**: Fixed file extension handling for all crop types (.WHX, .RIX, .SBX, .COX)
- **Deployment Reliability**: Resolved import issues and enhanced cross-platform compatibility
- **Error Handling**: Improved validation and user feedback

## 🎯 Features

- **Multi-Crop Support**: 20+ crops including Maize, Wheat, Rice, Soybean, Cotton, etc.
- **Flexible Input Methods**: 
  - Base64 ZIP upload
  - Individual file uploads  
  - Direct content submission
  - S3 integration
- **Auto-Detection**: Automatically detects crop type from input files
- **Scalable**: Serverless architecture with AWS Lambda
- **Complete Output**: All DSSAT output files (Summary, PlantGro, Evaluate, etc.)
- **Production Ready**: Error handling, logging, and monitoring
- **Enterprise Documentation**: Comprehensive technical and business documentation

## 🏗️ Architecture

```
┌─────────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│    Input Sources        │───▶│  Lambda Handler  │───▶│  Output Options │
│  • Base64 ZIP          │    │  • Auto-detect   │    │  • Base64 ZIP   │
│  • Individual Files    │    │  • Multi-format  │    │  • S3 Storage   │
│  • Direct Content      │    │  • Enhanced      │    │  • JSON Response│
│  • S3 Objects          │    │    Error Handle  │    └─────────────────┘
└─────────────────────────┘    └──────────────────┘
                                      │
                                      ▼
                            ┌──────────────────┐
                            │  DSSAT Execution │
                            │  Cross-Platform  │
                            │  20+ Crop Models │
                            │  Complete Data   │
                            └──────────────────┘
```

## 🚀 Quick Start

### Method 1: Individual Files (New in v5.0!)
```json
{
  "individual_files": {
    "UFGA8201.MZX": "<base64_content>",
    "UFGA8201.WTH": "<base64_content>",
    "SOIL.SOL": "<base64_content>",
    "MZCER048.CUL": "<base64_content>",
    "MZCER048.ECO": "<base64_content>",
    "MZCER048.SPE": "<base64_content>"
  },
  "s3_output_bucket": "your-output-bucket",
  "s3_output_prefix": "results/test-individual",
  "return_zip_b64": true
}
```

### Method 2: S3 Integration
```json
{
  "s3_input_bucket": "your-input-bucket",
  "s3_input_key": "experiments/your-experiment.zip",
  "s3_output_bucket": "your-output-bucket", 
  "s3_output_prefix": "results/test-001",
  "unzip_outputs": true
}
```

### Method 3: Direct Content (New in v5.0!)
```json
{
  "direct_content": {
    "UFGA8201.MZX": "*EXPERIMENTS\n@N R O C TNAME...",
    "UFGA8201.WTH": "@ INSI      LAT     LONG  ELEV   TAV   AMP...",
    "SOIL.SOL": "*SOILS: General DSSAT Soil Input File..."
  },
  "return_zip_b64": true
}
```

### Expected Response
```json
{
  "status": "OK",
  "exit_code": 0,
  "mode": "A",
  "runs": 1,
  "module": "MZCER048",
  "s3_results_zip": "s3://bucket/results/test-001/results.zip",
  "artifacts": ["Summary.OUT", "PlantGro.OUT", "Evaluate.OUT"],
  "results_zip_b64": "UEsDBBQAAAAIANQE..."
}
```

## 🧪 Testing

### New Automated Deployment
```bash
# Complete deployment to AWS (New!)
./scripts/update_lambda.sh

# Run comprehensive test suite
./scripts/test_comprehensive.sh

# Validate code quality  
./scripts/validate_code.sh

# Test realistic scenarios
python tests/realistic_scenarios/test_improvements.py
```

### Manual Testing Examples
```bash
# Test individual file processing (New in v5.0!)
aws lambda invoke \
  --function-name dssat-lambda-pro \
  --cli-binary-format raw-in-base64-out \
  --payload file://tests/test_wheat_individual.json \
  response.json

# Test traditional ZIP method
aws lambda invoke \
  --function-name dssat-lambda-pro \
  --cli-binary-format raw-in-base64-out \
  --payload file://tests/sample_event.json \
  response.json
```

### Test Data Available
- **Maize**: Complete realistic scenario with UFGA8201.MZX
- **Wheat**: Individual file testing with KSAS8101.WHX  
- **Rice**: IRPL8501.RIX with full genotype data
- **Soybean**: UFGA7801.SBX with environmental files

### Performance Benchmarks
- **Execution Time**: 30-60 seconds typical
- **Memory Usage**: ~1GB peak  
- **Docker Image**: 776MB optimized with multi-stage builds
- **Cold Start**: < 10 seconds
- **Supported Crops**: 20+ including Maize, Wheat, Rice, Soybean, Cotton
- **File Formats**: All DSSAT experiment files (.MZX, .WHX, .RIX, .SBX, .COX, etc.)

## � Comprehensive Documentation

### 📋 Executive & Business Documentation
- **[Executive Summary](EXECUTIVE_SUMMARY.md)** - Project overview and business impact
- **[Cross-Platform Technical Guide](DSSAT_CROSS_PLATFORM_ADAPTATION.md)** - Windows→Linux adaptation details
- **[Conversational Walkthrough](CONVERSATIONAL_WALKTHROUGH.md)** - Step-by-step implementation explanation

### 📈 Presentation Materials  
- **[Slide Summary](DSSAT_SLIDE_SUMMARY.md)** - Executive presentation format
- **[Improvements Analysis](IMPROVEMENTS_ANALYSIS.md)** - Detailed enhancement breakdown

### 🔧 Technical Documentation
- **[Deployment Guide](DEPLOYMENT.md)** - AWS deployment instructions
- **[Usage Guide](USAGE.md)** - API usage and examples
- **[Release Notes](RELEASE_NOTES.md)** - Version history and changes
- **[Changelog](CHANGELOG.md)** - Semantic versioning changelog
- **[Contributing Guide](CONTRIBUTING.md)** - Development guidelines

### 📋 Additional Resources
- **[Git Improvements Summary](GIT_IMPROVEMENTS_SUMMARY.md)** - Repository modernization details

## 📊 Production Status

✅ **Fully Enhanced**: v5.0 major improvements complete  
✅ **AWS Deployed**: Production-ready on AWS Lambda  
✅ **Multi-Input**: ZIP, individual files, direct content  
✅ **Multi-Crop**: 20+ crop types with universal file support  
✅ **Error Handling**: Robust error management and validation  
✅ **Enterprise Documentation**: Complete technical and business docs  
✅ **Performance**: Optimized for serverless execution  

## 🚀 Getting Started

1. **Review Documentation**
   - [Deployment Guide](DEPLOYMENT.md)
   - [Usage Guide](USAGE.md)
   - [Release Notes](RELEASE_NOTES.md)

2. **Deploy to AWS**
   ```bash
   # Build and deploy
   docker build -t dssat-lambda-pro -f infra/Dockerfile .
   # Follow DEPLOYMENT.md for complete steps
   ```

3. **Test Your Function**
   ```bash
   ./scripts/test_comprehensive.sh
   ```
- ZIP archive creation
- Artifact listing and metadata

## Test Infrastructure ✅

### Test Data
- Complete DSSAT experiment setup
- **FileX**: `TEST01.MZX` (maize simulation)
- **Weather**: `UFGA7901.WTH` (Gainesville, FL)
- **Soil**: `IBPN910015.SOL` (Millhopper Fine Sand)
- **Genotype**: MZCER048 cultivar files (.CUL, .ECO, .SPE)

### Test Scripts
- `scripts/local_invoke.sh` - Simple container runner
- `scripts/test_local.sh` - Automated testing
- `scripts/final_test.sh` - Comprehensive test suite

## Sample API Usage

### Input Event
```json
{
  "zip_b64": "UEsDBAoAAAAAAKii...", 
  "csv": true,
  "return_outputs": ["Summary.OUT", "PlantGro.OUT"],
  "return_zip_b64": true
}
```

### Response
```json
{
  "status": "OK",
  "mode": "A", 
  "runs": 1,
  "exit_code": 0,
  "artifacts": ["Summary.OUT", "PlantGro.OUT"],
  "results_zip_b64": "UEsDBBQAAAAIANQE..."
}
```

## 🏗️ File Structure
```
dssat-lambda-pro/
├── src/
│   ├── handler.py          # Enhanced Lambda entry point (v5.0)
│   ├── stage_inputs.py     # Universal file processing (fixed)
│   ├── run_dssat.py        # Cross-platform execution
│   └── collect_outputs.py  # Output handling
├── tests/
│   ├── realistic_scenarios/ # New comprehensive test data
│   ├── sample_event.json   # Test event examples
│   └── inputs/             # Test datasets
├── scripts/
│   ├── update_lambda.sh    # New deployment automation
│   ├── test_comprehensive.sh
│   └── local_invoke.sh
├── infra/
│   ├── Dockerfile          # Multi-stage optimized build
│   └── Dockerfile.enhanced # Production variant
└── docs/
    ├── EXECUTIVE_SUMMARY.md
    ├── CHANGELOG.md
    └── CONTRIBUTING.md
```

## ✅ Current Status - v5.0 Production Ready

### 🎯 **Fully Operational**
- ✅ **AWS Lambda Deployed**: Production function `dssat-lambda-pro` active
- ✅ **Multi-Input Support**: ZIP, individual files, direct content all working
- ✅ **Universal Crop Support**: All crop types (.MZX, .WHX, .RIX, .SBX, .COX) supported
- ✅ **Cross-Platform Success**: Windows DSSAT running seamlessly on Linux Lambda
- ✅ **Enterprise Documentation**: Complete business and technical documentation
- ✅ **Automated Testing**: Comprehensive test suite with realistic scenarios

### 🚀 **Recent Achievements (v5.0)**
- **Individual File Processing**: No more ZIP archive requirements
- **Enhanced Error Handling**: Better validation and user feedback
- **Deployment Automation**: One-script AWS deployment
- **Bug Fixes**: Critical file extension handling issues resolved
- **Documentation Suite**: Executive summaries and technical guides added

### 🎯 **Production Metrics**
- **Function Name**: `dssat-lambda-pro` 
- **Region**: us-east-1
- **Runtime**: Python 3.11 with Docker
- **Memory**: 10GB allocated
- **Timeout**: 15 minutes
- **Container**: ECR `332451669482.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro`

## 🚀 How to Use

### Local Development
```bash
# Clone and test
git clone https://github.com/GregUFL/dssat-lambda-pro.git
cd dssat-lambda-pro

# Run comprehensive tests
./scripts/test_comprehensive.sh

# Deploy to your AWS account
./scripts/update_lambda.sh
```

### Production Usage
```bash
# Test individual file method (recommended)
aws lambda invoke \
  --function-name dssat-lambda-pro \
  --payload file://tests/test_wheat_individual.json \
  response.json

# Monitor results
cat response.json | jq .
```

## 📈 Deployment Architecture

The system uses a sophisticated cross-platform approach:

1. **Windows DSSAT → Linux Lambda**: Established Fortran models adapted for serverless
2. **Multi-Stage Docker**: Optimized builds separating compilation from runtime
3. **Compatibility Layer**: Windows/Linux file system bridge for seamless operation
4. **Enterprise Ready**: Professional documentation and automated deployment

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for:
- Development setup instructions
- Code standards and guidelines  
- Testing requirements
- Pull request process

## 📞 Support & Documentation

For detailed information:
- **Technical Issues**: Check [Usage Guide](USAGE.md) and test examples
- **Deployment Help**: See [Deployment Guide](DEPLOYMENT.md)
- **Business Overview**: Read [Executive Summary](EXECUTIVE_SUMMARY.md)
- **Implementation Details**: Review [Cross-Platform Guide](DSSAT_CROSS_PLATFORM_ADAPTATION.md)

---

**🌾 DSSAT Lambda Pro v5.0** - Bringing 30 years of agricultural research to the cloud with enterprise-grade scalability and professional documentation.

**Status**: ✅ **PRODUCTION READY** | **Latest**: v5.0 Major Enhancement Release
