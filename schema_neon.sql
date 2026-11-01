-- TimeMaps Platform: Neon PostgreSQL Database Schema
-- Optimized for Neon Serverless PostgreSQL with SSL

-- 1. USERS & ROLES
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('OPS_ADMIN', 'SUPERVISOR', 'PROMOTER')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. PROJECTS (CAMPAIGNS)
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE' CHECK (status IN ('PLANNING', 'ACTIVE', 'COMPLETED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. STORES & RETAILERS
CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    store_name VARCHAR(150) NOT NULL,
    retailer VARCHAR(100) NOT NULL,
    emirate VARCHAR(50) NOT NULL CHECK (emirate IN ('Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Al Ain', 'Ras Al Khaimah', 'Fujairah', 'Umm Al Quwain')),
    branch_code VARCHAR(50),
    location_address TEXT,
    contact_person VARCHAR(100),
    contact_phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_store_emirate ON stores(emirate);

-- 4. PROMOTERS (IML FIELD STAFF)
CREATE TABLE IF NOT EXISTS promoters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(150),
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE')),
    nationality VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. TIMEMAP SCHEDULES (THE CORE ROSTER)
CREATE TABLE IF NOT EXISTS timemap_schedules (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    store_id INT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    promoter_id INT NOT NULL REFERENCES promoters(id) ON DELETE CASCADE,
    supervisor_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_timings VARCHAR(100),
    total_hours DECIMAL(4, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'ACTIVE', 'COMPLETED', 'ABSENT')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shift_lookup ON timemap_schedules(shift_date, store_id, project_id);

-- 6. INDEPENDENT LOGISTICS: DROPS
CREATE TABLE IF NOT EXISTS logistics_drops (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id),
    store_id INT NOT NULL REFERENCES stores(id),
    assigned_supervisor_id INT NOT NULL REFERENCES users(id),
    scheduled_drop_date DATE NOT NULL,
    items_manifest TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'DELIVERED')),
    delivered_at TIMESTAMP WITH TIME ZONE,
    delivery_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. INDEPENDENT LOGISTICS: RETURN COLLECTIONS (SEPARATE OPTION)
CREATE TABLE IF NOT EXISTS logistics_collections (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id),
    store_id INT NOT NULL REFERENCES stores(id),
    assigned_supervisor_id INT NOT NULL REFERENCES users(id),
    scheduled_collection_date DATE NOT NULL,
    items_to_collect TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COLLECTED')),
    collected_at TIMESTAMP WITH TIME ZONE,
    collection_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. SUPERVISOR IN-STORE EVALUATIONS (PROMOTER RATINGS)
CREATE TABLE IF NOT EXISTS store_evaluations (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id),
    store_id INT NOT NULL REFERENCES stores(id),
    promoter_id INT NOT NULL REFERENCES promoters(id),
    supervisor_id INT NOT NULL REFERENCES users(id),
    visit_date DATE NOT NULL,
    grooming_score SMALLINT NOT NULL CHECK (grooming_score BETWEEN 1 AND 5),
    pitch_score SMALLINT NOT NULL CHECK (pitch_score BETWEEN 1 AND 5),
    engagement_score SMALLINT NOT NULL CHECK (engagement_score BETWEEN 1 AND 5),
    punctuality_score SMALLINT NOT NULL CHECK (punctuality_score BETWEEN 1 AND 5),
    overall_rating DECIMAL(3, 1) NOT NULL,
    feedback_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. STORE PHOTOS (STRUCTURED REPOSITORY)
CREATE TABLE IF NOT EXISTS store_photos (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id),
    store_id INT NOT NULL REFERENCES stores(id),
    shift_date DATE NOT NULL,
    supervisor_id INT NOT NULL REFERENCES users(id),
    photo_type VARCHAR(50) NOT NULL CHECK (photo_type IN ('SETUP', 'PROMOTER_ACTION', 'DELIVERY_PROOF', 'COLLECTION_PROOF')),
    promoter_id INT REFERENCES promoters(id),
    file_path VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_photo_project_store_date ON store_photos(project_id, store_id, shift_date);

-- 10. OPERATIONAL TASKS & NOTES (STICKY BOARD)
CREATE TABLE IF NOT EXISTS operational_tasks (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    store_id INT REFERENCES stores(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(50) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'URGENT')),
    is_completed BOOLEAN DEFAULT FALSE,
    created_by_user_id INT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- SEED INITIAL DATA (BASED ON YOUR REAL FILES)
-- ==========================================

-- 1. Seed Ops Director + 9 Permanent Field Supervisors
INSERT INTO users (name, email, phone, password_hash, role) VALUES
('Operations Director', 'ops@imlme.com', '+971501111111', 'admin123', 'OPS_ADMIN'),
('Babar Abdul Majeed', 'babar@imlme.com', '+971502222201', 'super123', 'SUPERVISOR'),
('Jasheer Kanhirathil', 'jasheer@imlme.com', '+971502222202', 'super123', 'SUPERVISOR'),
('Sivakumar Kishnagopal', 'sivakumar@imlme.com', '+971502222203', 'super123', 'SUPERVISOR'),
('Cesar R Dela Cruz Jr', 'cesar@imlme.com', '+971502222204', 'super123', 'SUPERVISOR'),
('Mukunda Kumar', 'mukunda@imlme.com', '+971502222205', 'super123', 'SUPERVISOR'),
('Jithu Chandran', 'jithu@imlme.com', '+971502222206', 'super123', 'SUPERVISOR'),
('Mohammad Thanveer', 'thanveer@imlme.com', '+971502222207', 'super123', 'SUPERVISOR'),
('Abdullah Fouzee Ali', 'fouzee@imlme.com', '+971502222208', 'super123', 'SUPERVISOR'),
('Yuliya Valentinovna', 'yuliya@imlme.com', '+971502222209', 'super123', 'SUPERVISOR')
ON CONFLICT (email) DO NOTHING;

-- 2. Seed Projects
INSERT INTO projects (name, client_name, start_date, end_date, status) VALUES
('OGX Roadshow 2026', 'Johnson & Johnson / OGX', '2026-10-01', '2026-11-15', 'ACTIVE'),
('Sadia Sampling Plan', 'Sadia Middle East', '2026-10-23', '2026-11-30', 'ACTIVE'),
('Nutella x FiLLi Cafe Activation', 'Ferrero / Nutella', '2026-10-18', '2026-10-31', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- 3. Seed Stores
INSERT INTO stores (store_name, retailer, emirate, branch_code, location_address) VALUES
('Lulu Hypermarket - Al Barsha', 'Lulu', 'Dubai', '2100', 'Al Barsha 1, Dubai'),
('Lulu Hypermarket - Al Wahda Mall', 'Lulu', 'Abu Dhabi', '2370', 'Al Wahda Mall, Abu Dhabi'),
('Union Coop - Mirdif (Etihad Mall)', 'Union Coop', 'Dubai', '7168834', 'Etihad Mall, Mirdif, Dubai'),
('Life Pharmacy - Silicon Central Mall', 'Life Pharmacy', 'Dubai', 'LP101', 'Silicon Central Mall, DSO, Dubai'),
('Life Pharmacy - Dubai Hills Mall', 'Life Pharmacy', 'Dubai', 'LP102', 'Dubai Hills Mall, Dubai'),
('FiLLi Cafe - City Walk', 'FiLLi Cafe', 'Dubai', 'FC01', 'City Walk, Dubai'),
('FiLLi Cafe - Al Heera', 'FiLLi Cafe', 'Sharjah', 'FC02', 'Al Heera Beach, Sharjah')
ON CONFLICT DO NOTHING;

-- 4. Seed Promoters
INSERT INTO promoters (name, phone, email, gender, nationality) VALUES
('Sony', '+971551234567', 'sony@promoter.me', 'FEMALE', 'Indian'),
('Prachi', '+971552345678', 'prachi@promoter.me', 'FEMALE', 'Indian'),
('Abdul Jabbar', '+971553456789', 'abdul@promoter.me', 'MALE', 'Pakistani'),
('Muhammed Mahfoodh', '+971554567890', 'mahfoodh@promoter.me', 'MALE', 'Indian'),
('Shyju Venga', '+971555678901', 'shyju@promoter.me', 'MALE', 'Indian')
ON CONFLICT DO NOTHING;
