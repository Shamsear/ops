import psycopg2
import os

DATABASE_URL = os.environ.get(
    'DATABASE_URL',
    'postgresql://neondb_owner:npg_9iqIZwNHmo1p@ep-curly-darkness-b3di7l7f-pooler.c-4.ap-southeast-1.aws.neon.tech/neondb?sslmode=require'
)

print("Connecting to Neon PostgreSQL to apply Schema V2 (Excel Parity)...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

alter_statements = [
    # Stores columns
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS customer_code VARCHAR(50);",
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS chain VARCHAR(100);",
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS city VARCHAR(50);",
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS smn_contact VARCHAR(150);",
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS merchandiser_lead VARCHAR(150);",
    
    # Promoters role
    "ALTER TABLE promoters ADD COLUMN IF NOT EXISTS staff_role VARCHAR(50) DEFAULT 'PROMOTER';",
    
    # Schedules extension for multi-role and session counts
    "ALTER TABLE timemap_schedules ADD COLUMN IF NOT EXISTS staff_role VARCHAR(50) DEFAULT 'PROMOTER';",
    "ALTER TABLE timemap_schedules ADD COLUMN IF NOT EXISTS session_count INT DEFAULT 1;",
    "ALTER TABLE timemap_schedules ADD COLUMN IF NOT EXISTS notes TEXT;",
]

for stmt in alter_statements:
    print(f"Executing: {stmt}")
    cur.execute(stmt)

conn.commit()
cur.close()
conn.close()
print("Schema V2 applied successfully to Neon PostgreSQL!")
