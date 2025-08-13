# DSSAT Lambda Pro - Usage Guide

## 📊 Input Formats

### Option 1: S3 Input (Recommended)
```json
{
  "s3_input_bucket": "your-input-bucket",
  "s3_input_key": "experiments/maize-trial.zip",
  "s3_output_bucket": "your-output-bucket",
  "s3_output_prefix": "results/trial-001"
}
```

### Option 2: Base64 ZIP Upload
```json
{
  "zip_b64": "UEsDBBQAAAAIAL...(base64 encoded ZIP)",
  "s3_output_bucket": "your-output-bucket",
  "s3_output_prefix": "results/upload-001"
}
```

### Option 3: Return Results as Base64
```json
{
  "zip_b64": "UEsDBBQAAAAIAL...",
  "return_zip_b64": true
}
```

## 🌾 Supported Crops

| Crop | Code | Module | Example File |
|------|------|--------|--------------|
| Maize | MZ | MZCER048 | experiment.MZX |
| Wheat | WH | CSCER048 | experiment.WHX |
| Rice | RI | RICER048 | experiment.RIX |
| Soybean | SB | CRGRO048 | experiment.SBX |
| Cotton | CO | CRGRO048 | experiment.COX |
| Potato | PT | PTSUB048 | experiment.PTX |
| Sugarcane | SC | SCCAN048 | experiment.SCX |
| Sorghum | SG | SGCER048 | experiment.SGX |
| Sunflower | SU | CRGRO048 | experiment.SUX |
| Tomato | TM | CRGRO048 | experiment.TMX |

*Full list: 20+ crops supported*

## 📁 Input ZIP Structure

Your input ZIP should contain:

```
experiment.zip
├── EXPERIMENT.MZX          # Main experiment file (required)
├── Weather/
│   └── STATION.WTH         # Weather data
├── Soil/
│   └── PROFILE.SOL         # Soil profile
├── Genotype/               # Optional custom genotypes
│   ├── CUSTOM.CUL         # Cultivar parameters
│   ├── CUSTOM.ECO         # Ecotype parameters
│   └── CUSTOM.SPE         # Species parameters
└── DSSBatch.v48           # Optional batch file
```

### Required Files
- **Experiment file**: `.MZX`, `.WHX`, `.RIX`, etc.
- **Weather file**: `.WTH` format
- **Soil file**: `.SOL` format

### Optional Files
- Custom genotype files (`.CUL`, `.ECO`, `.SPE`)
- Batch processing file (`DSSBatch.v48`)

## ⚙️ Configuration Options

### Basic Options
```json
{
  "s3_input_bucket": "inputs",
  "s3_input_key": "experiment.zip",
  "s3_output_bucket": "outputs",
  "s3_output_prefix": "results",
  "simulation_id": "custom-id-001"
}
```

### Advanced Options
```json
{
  "s3_input_bucket": "inputs",
  "s3_input_key": "experiment.zip",
  "s3_output_bucket": "outputs", 
  "s3_output_prefix": "results",
  "module_code": "MZCER048",
  "unzip_outputs": true,
  "return_zip_b64": false,
  "return_outputs": ["Summary.OUT", "PlantGro.OUT"],
  "simulation_id": "detailed-simulation-001"
}
```

### Parameter Details

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `s3_input_bucket` | string | Yes* | S3 bucket containing input ZIP |
| `s3_input_key` | string | Yes* | S3 key to input ZIP file |
| `zip_b64` | string | Yes* | Base64 encoded ZIP (alternative to S3) |
| `s3_output_bucket` | string | No | S3 bucket for results |
| `s3_output_prefix` | string | No | S3 prefix for output files |
| `module_code` | string | No | Force specific DSSAT module |
| `unzip_outputs` | boolean | No | Upload individual files to S3 |
| `return_zip_b64` | boolean | No | Return results as base64 |
| `return_outputs` | array | No | Specific files to prioritize |
| `simulation_id` | string | No | Custom identifier |

*Either `s3_input_*` or `zip_b64` is required

## 📤 Output Formats

### Success Response
```json
{
  "status": "OK",
  "mode": "A",
  "runs": 4,
  "exit_code": 0,
  "module": "MZCER048",
  "artifacts": [
    "Summary.OUT",
    "PlantGro.OUT", 
    "Evaluate.OUT",
    "WARNING.OUT",
    "MODEL.ERR"
  ],
  "simulation_id": "sim-abc123",
  "timestamp": "2025-08-13T21:30:00.000000",
  "s3_results_zip": "s3://outputs/results/results.zip",
  "s3_files": [
    "s3://outputs/results/Summary.OUT",
    "s3://outputs/results/PlantGro.OUT"
  ],
  "last_stdout": "RUN    TRT FLO MAT TOPWT HARWT...",
  "precheck_warnings": []
}
```

### Error Response
```json
{
  "status": "ERROR", 
  "error": "Missing s3_input_* or empty zip_b64",
  "simulation_id": "sim-error123",
  "timestamp": "2025-08-13T21:30:00.000000"
}
```

## 🔍 Common Use Cases

### 1. Single Maize Experiment
```json
{
  "s3_input_bucket": "crop-experiments",
  "s3_input_key": "maize/iowa-trial.zip",
  "s3_output_bucket": "simulation-results",
  "s3_output_prefix": "maize/iowa-2025"
}
```

### 2. Wheat Batch Processing
```json
{
  "s3_input_bucket": "wheat-studies", 
  "s3_input_key": "batch-experiments.zip",
  "s3_output_bucket": "wheat-results",
  "s3_output_prefix": "batch-run-001",
  "module_code": "CSCER048"
}
```

### 3. Quick Rice Test
```json
{
  "zip_b64": "UEsDBBQAAAAIAL...",
  "return_zip_b64": true,
  "simulation_id": "rice-quick-test"
}
```

### 4. Multi-Location Study
```json
{
  "s3_input_bucket": "multi-location",
  "s3_input_key": "study/all-locations.zip", 
  "s3_output_bucket": "study-results",
  "s3_output_prefix": "locations/summary",
  "unzip_outputs": true,
  "return_outputs": ["Summary.OUT", "Evaluate.OUT"]
}
```

## 🚨 Troubleshooting

### Common Issues

1. **"Missing s3_input_* or empty zip_b64"**
   - Ensure either S3 parameters or zip_b64 is provided
   - Check S3 bucket/key exists and is accessible

2. **"NONZERO_EXIT" with exit_code 99**
   - Check input file format
   - Verify weather/soil data is complete
   - Review WARNING.OUT for details

3. **Timeout errors**
   - Reduce simulation complexity
   - Increase Lambda timeout (max 15 minutes)

4. **Module detection issues**
   - Use explicit `module_code` parameter
   - Check experiment file extension matches crop

### Debugging
- Check `last_stdout` and `last_stderr` in response
- Download `WARNING.OUT` and `MODEL.ERR` from S3
- Enable detailed logging with `simulation_id`

## 📊 Performance Tips

1. **Optimize Input Size**: Compress ZIP files efficiently
2. **Use S3**: Prefer S3 input over base64 for large files
3. **Batch Processing**: Use DSSBatch.v48 for multiple runs
4. **Parallel Execution**: Use multiple Lambda invocations for independent experiments
5. **Monitor Costs**: Set up CloudWatch alarms for usage
