# Changelog

All notable changes to DSSAT Lambda Pro will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0.0] - 2025-08-28

### Added
- Individual file processing capability - no ZIP archives required
- Enhanced S3 integration with direct object processing
- Multiple input format support: ZIP, individual files, direct content
- Comprehensive business and technical documentation suite
- Executive summary and stakeholder presentation materials
- Automated deployment scripts and workflows
- Realistic test scenarios with actual DSSAT data
- Cross-platform adaptation documentation

### Fixed
- Critical bug in file extension handler affecting multiple crop types (.WHX, .RIX, .SBX, .COX)
- Python import issues in deployment pipeline
- Cross-platform file system compatibility between Windows and Linux
- File classification logic in `_place_by_ext()` function

### Changed
- Enhanced Docker containerization with multi-stage builds
- Improved error handling and user feedback
- Updated .gitignore for better repository hygiene
- Enhanced logging and monitoring capabilities

### Security
- Improved input validation and sanitization
- Enhanced error message handling to prevent information leakage

## [4.0.0] - 2025-08-13

### Added
- Production-ready AWS Lambda deployment
- Multi-crop support for 20+ crop types
- Complete S3 input/output integration
- Automatic crop type detection
- Comprehensive test suite
- Docker containerization
- Complete documentation suite

### Fixed
- AWS Lambda compatibility issues
- StandardData symlink problems
- Environment configuration for DSSAT

### Changed
- Optimized performance for serverless execution
- Enhanced error handling and logging

## [2.0.0] - Previous Release

### Added
- Basic DSSAT integration
- S3 I/O capabilities
- Module execution framework
- Data staging system

---

## Version History Summary

- **v5.0** (Current): Major enhancement with individual file support and comprehensive documentation
- **v4.0**: Production-ready multi-crop platform
- **v2.0**: Basic DSSAT integration with S3 support
- **v1.0**: Initial release

## Upgrade Notes

### v4.0 → v5.0
- **Backward Compatible**: All existing v4.0 functionality preserved
- **New Capabilities**: Individual file processing available alongside existing ZIP format
- **Enhanced Documentation**: Comprehensive business and technical guides added
- **No Breaking Changes**: Existing API endpoints and formats unchanged

### Migration Guide
No migration required - v5.0 maintains full backward compatibility with v4.0 implementations.
