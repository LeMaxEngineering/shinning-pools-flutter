# Data Management Tools Documentation

## Overview

This document describes the data management tools and scripts used in the Shinning Pools project for database backup, data standardization, and cross-platform data processing.

## Python Scripts

### standardize_pools_json.py

**Purpose**: Standardizes pool data exported from Firestore for backup and migration purposes.

**Location**: `test/DB_backups/standardize_pools_json.py`

#### Features

- **Cross-Platform Encoding Support**: Handles UTF-16 LE, UTF-8, and BOM characters
- **JSON Standardization**: Converts non-standard JSON format to valid JSON
- **Image Data Processing**: Truncates long base64 image data to prevent parsing errors
- **Error Handling**: Robust error handling with debugging output
- **Data Validation**: Ensures data integrity during processing

#### Usage

```bash
# Run the script from the project root
python test/DB_backups/standardize_pools_json.py
```

#### Input Format

The script expects a file named `pools_output.json` in the `test/DB_backups/` directory with the following characteristics:

- **Encoding**: UTF-16 LE with BOM
- **Format**: Non-standard JSON with single quotes and unquoted keys
- **Structure**: Starts with "Pools: [" prefix
- **Content**: Pool data with base64 image data

#### Output Format

The script generates a file named `standardized_pools.json` with:

- **Encoding**: UTF-8
- **Format**: Valid JSON with double quotes and proper structure
- **Content**: Standardized pool data with truncated image data

#### Technical Details

##### Encoding Handling
```python
# Remove BOM character and soft hyphen if present
raw = raw.lstrip('\ufeff\u00ad')
```

##### JSON Standardization
```python
# Remove 'Pools: ' prefix
raw = re.sub(r'^\s*Pools:\s*', '', raw)

# Convert single quotes to double quotes
raw = raw.replace("'", '"')

# Quote unquoted keys
raw = re.sub(r'([,{\[])(\s*)([a-zA-Z0-9_]+)(\s*):', r'\1\2"\3"\4:', raw)
```

##### Image Data Truncation
```python
def truncate_base64(match):
    base64_data = match.group(1)
    if len(base64_data) > 1000:  # Truncate if longer than 1000 chars
        return f'"{base64_data[:1000]}..."'
    return match.group(0)

raw = re.sub(r'"data:image/[^"]+;base64,([^"]+)"', truncate_base64, raw)
```

#### Error Handling

The script includes comprehensive error handling:

1. **Encoding Errors**: Detects and handles UTF-16 LE BOM and soft hyphen characters
2. **JSON Parsing Errors**: Provides detailed error messages and debugging output
3. **File I/O Errors**: Graceful handling of file reading and writing operations
4. **Data Validation**: Ensures output data meets expected format requirements

#### Troubleshooting

##### Common Issues

1. **UnicodeDecodeError**: 
   - **Cause**: File has unexpected encoding
   - **Solution**: Script automatically detects and handles UTF-16 LE encoding

2. **JSON Parsing Errors**:
   - **Cause**: Malformed JSON or very long base64 data
   - **Solution**: Script truncates long image data and provides debugging output

3. **File Not Found**:
   - **Cause**: Missing input file
   - **Solution**: Ensure `pools_output.json` exists in `test/DB_backups/` directory

##### Debugging

The script provides detailed debugging output:

```bash
--- RAW INPUT START ---
# Shows first 1000 characters of input
--- RAW INPUT END ---

--- PRE-PARSE JSON ---
# Shows processed JSON before parsing
--- END PRE-PARSE ---
```

## Database Backup Process

### Export Process

1. **Export from Firestore**: Use Firebase Console or Admin SDK to export pool data
2. **Save as pools_output.json**: Place in `test/DB_backups/` directory
3. **Run Standardization**: Execute `standardize_pools_json.py`
4. **Verify Output**: Check `standardized_pools.json` for data integrity

### Import Process

1. **Review Standardized Data**: Verify `standardized_pools.json` format
2. **Import to Firestore**: Use Firebase Admin SDK or Console
3. **Validate Data**: Ensure all records imported correctly
4. **Update References**: Update any related data references

## Cross-Platform Compatibility

### Supported Platforms

- **Windows**: Tested on Windows 10/11 with PowerShell
- **macOS**: Compatible with Python 3.7+
- **Linux**: Compatible with Python 3.7+

### Requirements

- **Python**: Version 3.7 or higher
- **Dependencies**: Standard library only (json, re)
- **File System**: Read/write access to project directory

### Platform-Specific Notes

#### Windows
- Handles UTF-16 LE encoding common in Windows applications
- Compatible with PowerShell and Command Prompt
- Supports long file paths

#### macOS/Linux
- Handles UTF-8 encoding by default
- Compatible with bash/zsh shells
- Unix-style line endings

## Data Format Specifications

### Input Data Structure

```json
Pools: [
  {
    id: 'pool_id',
    customerId: 'customer_id',
    status: 'active',
    monthlyCost: 120,
    photoUrl: 'data:image/jpeg;base64,long_base64_data...',
    // ... other fields
  }
]
```

### Output Data Structure

```json
[
  {
    "id": "pool_id",
    "customerId": "customer_id",
    "status": "active",
    "monthlyCost": 120,
    "photoUrl": "data:image/jpeg;base64,truncated_base64_data...",
    // ... standardized fields
  }
]
```

## Best Practices

### Data Management

1. **Regular Backups**: Export data regularly for backup purposes
2. **Version Control**: Keep track of data format changes
3. **Testing**: Test import/export processes in development environment
4. **Documentation**: Document any custom data transformations

### Script Maintenance

1. **Error Handling**: Always include comprehensive error handling
2. **Logging**: Add logging for debugging and monitoring
3. **Validation**: Validate input and output data formats
4. **Testing**: Test with various data formats and sizes

### Security Considerations

1. **Data Privacy**: Ensure sensitive data is handled securely
2. **Access Control**: Limit access to backup scripts and data
3. **Encryption**: Consider encrypting backup files for sensitive data
4. **Audit Trail**: Maintain logs of data processing activities

## Future Enhancements

### Planned Improvements

1. **Automated Backup**: Schedule regular automated backups
2. **Incremental Backups**: Support for incremental data updates
3. **Compression**: Add data compression for large datasets
4. **Validation**: Enhanced data validation and integrity checks
5. **GUI Interface**: Web-based interface for data management

### Integration Opportunities

1. **CI/CD Pipeline**: Integrate with deployment pipelines
2. **Monitoring**: Add monitoring and alerting for backup processes
3. **Analytics**: Data analytics and reporting capabilities
4. **API Integration**: REST API for data management operations

---

**Last Updated**: June 2025  
**Version**: 1.0.0  
**Maintainer**: Development Team 