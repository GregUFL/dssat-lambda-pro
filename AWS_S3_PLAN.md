# AWS S3 Integration Plan - DSSAT Lambda Pro

## Architecture Overview

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────┐
│   DSSATIN   │───▶│  Lambda Function │───▶│  DSSATOUT   │
│ S3 Bucket   │    │                  │    │ S3 Bucket   │
│ (inputs.zip)│    │  ┌─────────────┐ │    │ (outputs)   │
└─────────────┘    │  │   DSSAT     │ │    └─────────────┘
                   │  │ Simulation  │ │            │
                   │  └─────────────┘ │            │
                   └──────────────────┘            ▼
                                                ┌─────────────┐
                                                │ Unzipped    │
                                                │ Output      │
                                                │ Files       │
                                                └─────────────┘
```

## Implementation Plan

### Phase 1: Enhanced Lambda Handler ✅
- [x] Support both base64 and S3 input methods
- [x] S3 output upload capability
- [x] Error handling for S3 operations

### Phase 2: S3 Input/Output Structure
- [ ] **DSSATIN bucket**: Store input ZIP files
- [ ] **DSSATOUT bucket**: Store output files (unzipped)
- [ ] Organized folder structure by simulation ID/timestamp

### Phase 3: Enhanced Functionality
- [ ] Automatic unzipping of outputs to S3
- [ ] Metadata storage (simulation parameters, timing, etc.)
- [ ] Presigned URLs for easy access
- [ ] CloudWatch logging and monitoring

## S3 Folder Structure

### DSSATIN Bucket
```
dssatin-bucket/
├── inputs/
│   ├── simulation-001/
│   │   └── inputs.zip
│   ├── simulation-002/
│   │   └── inputs.zip
│   └── batch-runs/
│       ├── 2025-08-12/
│       │   ├── run-001.zip
│       │   └── run-002.zip
```

### DSSATOUT Bucket
```
dssatout-bucket/
├── outputs/
│   ├── simulation-001/
│   │   ├── Summary.OUT
│   │   ├── PlantGro.OUT
│   │   ├── Evaluate.OUT
│   │   ├── metadata.json
│   │   └── results.zip
│   ├── simulation-002/
│   │   ├── Summary.OUT
│   │   ├── PlantGro.OUT
│   │   └── metadata.json
```

## Lambda Event Formats

### Option 1: S3 Input
```json
{
  "s3_input_bucket": "dssatin-bucket",
  "s3_input_key": "inputs/simulation-001/inputs.zip",
  "s3_output_bucket": "dssatout-bucket", 
  "s3_output_prefix": "outputs/simulation-001",
  "unzip_outputs": true,
  "return_outputs": ["Summary.OUT", "PlantGro.OUT"]
}
```

### Option 2: Direct Base64 (existing)
```json
{
  "zip_b64": "UEsDBAoAAAAAAKii...",
  "s3_output_bucket": "dssatout-bucket",
  "s3_output_prefix": "outputs/simulation-001", 
  "return_zip_b64": false
}
```

## Implementation Steps

1. **Update Lambda Handler** - Enhanced S3 operations
2. **Create S3 Buckets** - DSSATIN and DSSATOUT
3. **Update IAM Roles** - S3 permissions for Lambda
4. **Test with Real Data** - Upload test files to S3
5. **Add Monitoring** - CloudWatch logs and metrics
6. **Documentation** - Updated deployment guide

## Benefits

✅ **Scalability**: Handle large datasets via S3  
✅ **Persistence**: Outputs stored permanently  
✅ **Organization**: Structured data management  
✅ **Accessibility**: Easy download/sharing of results  
✅ **Monitoring**: Full audit trail of simulations  
✅ **Cost-Effective**: Pay only for storage used  

## Next Steps

1. Implement enhanced Lambda handler
2. Create AWS deployment scripts
3. Test S3 integration locally
4. Deploy to AWS and validate
5. Create user documentation

---

**Ready to implement S3 integration! 🚀**
