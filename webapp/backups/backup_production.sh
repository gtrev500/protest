#!/bin/bash

# Production Supabase Backup Script
# Creates timestamped backups of production database schema and data

set -e  # Exit on any error

# Configuration
PROJECT_REF="xehrzhowmrkpfwndbclc"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Supabase Production Backup${NC}"
echo -e "${BLUE}Project: ${PROJECT_REF}${NC}"
echo -e "${BLUE}Timestamp: ${TIMESTAMP}${NC}"
echo ""

# Create backup directory
echo -e "${YELLOW}📁 Creating backup directory...${NC}"
mkdir -p "${BACKUP_DIR}"

# Check if we're linked to production
echo -e "${YELLOW}🔗 Checking Supabase connection...${NC}"
if ! npx supabase projects list | grep -q "●.*${PROJECT_REF}"; then
    echo -e "${RED}❌ Not linked to production project ${PROJECT_REF}${NC}"
    echo -e "${YELLOW}💡 Run: npx supabase link --project-ref ${PROJECT_REF}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Connected to production${NC}"

# Backup complete schema and structure
echo -e "${YELLOW}📋 Backing up complete schema...${NC}"
if npx supabase db dump --linked > "${BACKUP_DIR}/production_schema_complete.sql" 2>/dev/null; then
    SCHEMA_LINES=$(wc -l < "${BACKUP_DIR}/production_schema_complete.sql")
    echo -e "${GREEN}✅ Schema backup complete (${SCHEMA_LINES} lines)${NC}"
else
    echo -e "${RED}❌ Schema backup failed${NC}"
    exit 1
fi

# Backup data only
echo -e "${YELLOW}💾 Backing up all data...${NC}"
if npx supabase db dump --linked --data-only > "${BACKUP_DIR}/production_data_only.sql" 2>/dev/null; then
    DATA_SIZE=$(du -h "${BACKUP_DIR}/production_data_only.sql" | cut -f1)
    echo -e "${GREEN}✅ Data backup complete (${DATA_SIZE})${NC}"
else
    echo -e "${RED}❌ Data backup failed${NC}"
    exit 1
fi

# Count records for verification
echo -e "${YELLOW}📊 Counting records for verification...${NC}"
PROTEST_COUNT=$(grep -o "'[a-f0-9-]*', '202[45]" "${BACKUP_DIR}/production_data_only.sql" | wc -l || echo "0")
INSERT_COUNT=$(grep -c "INSERT INTO" "${BACKUP_DIR}/production_data_only.sql" || echo "0")

echo -e "${GREEN}✅ Found ${PROTEST_COUNT} protests in backup${NC}"
echo -e "${GREEN}✅ Found ${INSERT_COUNT} total INSERT statements${NC}"

# Create backup manifest
echo -e "${YELLOW}📝 Creating backup manifest...${NC}"
cat > "${BACKUP_DIR}/backup_manifest.txt" << EOF
Supabase Production Backup Manifest
===================================

Date: $(date)
Project Reference: ${PROJECT_REF}
Project Name: webform-public-dash
Region: us-east-2

Files Created:
- production_schema_complete.sql (${SCHEMA_LINES} lines)
- production_data_only.sql (${DATA_SIZE})

Data Summary:
- Protests: ${PROTEST_COUNT}
- Total INSERT statements: ${INSERT_COUNT}

Restoration:
1. Schema: psql [CONNECTION] < production_schema_complete.sql
2. Data: psql [CONNECTION] < production_data_only.sql

Connection String Template:
postgres://postgres:[PASSWORD]@db.${PROJECT_REF}.supabase.co:5432/postgres

Local Test Connection:
postgres://postgres:postgres@localhost:54322/postgres
EOF

# Create quick restore script
echo -e "${YELLOW}🔧 Creating restore script...${NC}"
cat > "${BACKUP_DIR}/restore_local.sh" << 'EOF'
#!/bin/bash
# Quick restore to local database

echo "🔄 Resetting local database..."
npx supabase db reset --local

echo "📋 Restoring schema..."
psql postgres://postgres:postgres@localhost:54322/postgres < production_schema_complete.sql

echo "💾 Restoring data..."
psql postgres://postgres:postgres@localhost:54322/postgres < production_data_only.sql

echo "✅ Restoration complete!"
echo "🧪 Test with: npx supabase db query 'SELECT COUNT(*) FROM protests'"
EOF

chmod +x "${BACKUP_DIR}/restore_local.sh"

# Compress backup (optional)
if command -v tar >/dev/null 2>&1; then
    echo -e "${YELLOW}📦 Compressing backup...${NC}"
    tar -czf "${BACKUP_DIR}.tar.gz" -C backups "${TIMESTAMP}"
    COMPRESSED_SIZE=$(du -h "${BACKUP_DIR}.tar.gz" | cut -f1)
    echo -e "${GREEN}✅ Compressed backup created: ${BACKUP_DIR}.tar.gz (${COMPRESSED_SIZE})${NC}"
fi

# Final summary
echo ""
echo -e "${GREEN}🎉 Backup Complete!${NC}"
echo -e "${BLUE}📁 Location: ${BACKUP_DIR}${NC}"
echo -e "${BLUE}📦 Compressed: ${BACKUP_DIR}.tar.gz${NC}"
echo -e "${BLUE}🔧 Quick restore: ${BACKUP_DIR}/restore_local.sh${NC}"
echo ""
echo -e "${YELLOW}💡 To restore to local:${NC}"
echo -e "${YELLOW}   cd ${BACKUP_DIR} && ./restore_local.sh${NC}"
echo ""
echo -e "${YELLOW}💡 To restore to production (CAREFUL!):${NC}"
echo -e "${YELLOW}   psql [PROD_CONNECTION] < production_schema_complete.sql${NC}"
echo -e "${YELLOW}   psql [PROD_CONNECTION] < production_data_only.sql${NC}"
echo ""

# Clean up old backups (keep last 5)
echo -e "${YELLOW}🧹 Cleaning up old backups (keeping last 5)...${NC}"
ls -1t backups/ | grep "^[0-9]" | tail -n +6 | while read old_backup; do
    if [[ -d "backups/${old_backup}" ]]; then
        echo -e "${YELLOW}🗑️  Removing old backup: ${old_backup}${NC}"
        rm -rf "backups/${old_backup}"
    fi
    if [[ -f "backups/${old_backup}.tar.gz" ]]; then
        rm -f "backups/${old_backup}.tar.gz"
    fi
done

echo -e "${GREEN}✨ All done!${NC}"