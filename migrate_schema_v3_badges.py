import psycopg2
import os

DATABASE_URL = os.environ.get(
    'DATABASE_URL',
    'postgresql://neondb_owner:npg_9iqIZwNHmo1p@ep-curly-darkness-b3di7l7f-pooler.c-4.ap-southeast-1.aws.neon.tech/neondb?sslmode=require'
)

print("Connecting to Neon PostgreSQL to apply Schema V3 (Store Badge Tracker)...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Create store_badges table
create_badges_sql = """
CREATE TABLE IF NOT EXISTS store_badges (
    id SERIAL PRIMARY KEY,
    promoter_name VARCHAR(150) NOT NULL,
    promoter_id INTEGER REFERENCES promoters(id) ON DELETE SET NULL,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    store_id INTEGER REFERENCES stores(id) ON DELETE CASCADE,
    emirate VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Documents ready for collection',
    submitted_by VARCHAR(100),
    badge_number VARCHAR(100),
    valid_from DATE,
    valid_until DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_badges_store ON store_badges(store_id);
CREATE INDEX IF NOT EXISTS idx_badges_project ON store_badges(project_id);
CREATE INDEX IF NOT EXISTS idx_badges_status ON store_badges(status);
"""
cur.execute(create_badges_sql)
print("Table store_badges created or verified.")

# 2. Ensure promoter login account exists in users table with password_hash
promoter_user_sql = """
INSERT INTO users (name, email, password_hash, role, phone)
VALUES 
    ('Sony Mathew', 'sony@imlme.com', 'admin123', 'PROMOTER', '+971501112233'),
    ('Prachi Sharma', 'prachi@imlme.com', 'admin123', 'PROMOTER', '+971502223344')
ON CONFLICT (email) DO UPDATE SET role = 'PROMOTER';
"""
cur.execute(promoter_user_sql)
print("Promoter demo user accounts verified.")

# 3. Insert realistic initial badge applications for UAE hypermarkets across all 6 stages
seed_badges_sql = """
DO $$
DECLARE
    sadia_id INT;
    ogx_id INT;
    barsha_id INT;
    wahda_id INT;
    mirdif_id INT;
    alain_id INT;
BEGIN
    SELECT id INTO sadia_id FROM projects WHERE name ILIKE '%Sadia%' LIMIT 1;
    SELECT id INTO ogx_id FROM projects WHERE name ILIKE '%OGX%' LIMIT 1;
    SELECT id INTO barsha_id FROM stores WHERE store_name ILIKE '%Barsha%' LIMIT 1;
    SELECT id INTO wahda_id FROM stores WHERE store_name ILIKE '%Wahda%' LIMIT 1;
    SELECT id INTO mirdif_id FROM stores WHERE store_name ILIKE '%Mirdif%' OR retailer ILIKE '%Union%' LIMIT 1;
    SELECT id INTO alain_id FROM stores WHERE emirate ILIKE '%Al Ain%' OR store_name ILIKE '%Al Ain%' LIMIT 1;

    -- If no projects exist, create fallback IDs
    IF sadia_id IS NULL THEN sadia_id := 1; END IF;
    IF ogx_id IS NULL THEN ogx_id := 2; END IF;
    IF barsha_id IS NULL THEN barsha_id := 1; END IF;
    IF wahda_id IS NULL THEN wahda_id := 2; END IF;
    IF mirdif_id IS NULL THEN mirdif_id := 3; END IF;
    IF alain_id IS NULL THEN alain_id := 4; END IF;

    -- Only seed if empty
    IF NOT EXISTS (SELECT 1 FROM store_badges LIMIT 1) THEN
        INSERT INTO store_badges (promoter_name, project_id, store_id, emirate, status, submitted_by, badge_number, notes)
        VALUES
        ('Sony Mathew', ogx_id, barsha_id, 'Dubai', 'Approved', 'Babar (Lead)', 'LULU-DXB-9842', 'EID & Health Card verified. Valid till Dec 2026'),
        ('Prachi Sharma', ogx_id, barsha_id, 'Dubai', 'Approved', 'Babar (Lead)', 'LULU-DXB-9843', 'Gate pass issued by security office'),
        ('Amina Al Balushi', sadia_id, wahda_id, 'Abu Dhabi', 'Pending with security', 'Jasheer (Lead)', NULL, 'Submitted to Mall CID security desk on Oct 12'),
        ('Rahul Verma', sadia_id, mirdif_id, 'Dubai', 'Pending with HR', 'Cesar (Lead)', NULL, 'Union Coop HR checking quota clearance'),
        ('Fatima Noor', sadia_id, alain_id, 'Al Ain', 'Documents ready for collection', 'Sivakumar (Lead)', NULL, 'EID copy collected, awaiting occupational health card stamp'),
        ('Arjun Nair', ogx_id, wahda_id, 'Abu Dhabi', 'Rejected', 'Jasheer (Lead)', NULL, 'Visa designation rejected by mall security; resubmitting with NOC');
    END IF;
END $$;
"""
cur.execute(seed_badges_sql)
print("Seed badges inserted.")

conn.commit()
cur.close()
conn.close()
print("Migration Schema V3 (Store Badges) completed successfully!")
