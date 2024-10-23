# Database Environment Check Script

A comprehensive Bash script for validating system requirements and configurations prior to Oracle database installation.

## Overview

This script performs various system checks to ensure your environment meets the prerequisites for Oracle database installation. It validates network connectivity, required packages, system configurations, and user/group settings.

## Prerequisites

- Bash version 4 or higher
- Root or sudo access
- `jq` package installed
- RHEL/CentOS-based system (uses `yum` package manager)

## Installation

1. Clone or download the script files to your target system
2. Ensure the script has executable permissions:
   ```bash
   chmod +x db_check.sh
   ```
3. Verify the following directory structure:
   ```
   .
   ├── db_check.sh
   ├── checklist
   │   ├── list.txt
   │   └── conf.json
   ```

## Usage

Run the script with the Oracle version as an argument:

```bash
./db_check.sh <version>
```

Example:
```bash
./db_check.sh 19c
```

### Debug Mode
To run in debug mode:
```bash
./db_check.sh -v
```

## Features

The script performs the following checks:

1. **Network Connectivity**
   - Interactive network interface selection
   - Ping test to verify connectivity

2. **Package Verification**
   - Oracle pre-install package check
   - Required package dependencies check

3. **System Configuration**
   - sysctl parameters validation
   - Security limits configuration check
   - SELinux configuration verification

4. **User and Group Setup**
   - Oracle user existence check
   - Required groups verification (oinstall, dba, oper)

## Configuration Files

### checklist/list.txt
Contains the list of required packages if the Oracle pre-install package is not present.

### checklist/conf.json
Contains the required system configurations:
- sysctl parameters
- Security limits settings

## Output

The script provides:
- Color-coded status output (green for OK, red for NOT OK)
- Detailed error messages for failed checks
- Log file at `/tmp/log.out`

## Directory Structure

The script uses the following directories:
- `/tmp/dir` - Working directory
- `/etc/sysctl.conf` - System configuration
- `/etc/security/limits.d/oracle-database-preinstall-19c.conf` - Security limits
- `/etc/selinux/config` - SELinux configuration

