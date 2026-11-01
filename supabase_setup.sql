-- TimeMaps Platform: Complete Supabase Migration & Setup
-- Project URL: https://ulpacsvtlkxspncgnuwd.supabase.co

-- Drop existing tables to start clean
DROP TABLE IF EXISTS store_photos CASCADE;
DROP TABLE IF EXISTS store_evaluations CASCADE;
DROP TABLE IF EXISTS logistics_collections CASCADE;
DROP TABLE IF EXISTS logistics_drops CASCADE;
DROP TABLE IF EXISTS operational_tasks CASCADE;
DROP TABLE IF EXISTS store_badges CASCADE;
DROP TABLE IF EXISTS timemap_schedules CASCADE;
DROP TABLE IF EXISTS promoters CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. USERS & ROLES
CREATE TABLE users (
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
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE' CHECK (status IN ('PLANNING', 'ACTIVE', 'COMPLETED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. STORES & RETAILERS
CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    store_name VARCHAR(150) NOT NULL,
    retailer VARCHAR(100) NOT NULL,
    emirate VARCHAR(50) NOT NULL,
    branch_code VARCHAR(50),
    location_address TEXT,
    contact_person VARCHAR(100),
    contact_phone VARCHAR(50),
    customer_code VARCHAR(50),
    chain VARCHAR(100),
    city VARCHAR(50),
    smn_contact VARCHAR(150),
    merchandiser_lead VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_store_emirate ON stores(emirate);

-- 4. PROMOTERS (IML FIELD STAFF)
CREATE TABLE promoters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(150),
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE')),
    nationality VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    staff_role VARCHAR(50) DEFAULT 'PROMOTER',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. TIMEMAP SCHEDULES
CREATE TABLE timemap_schedules (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id) ON DELETE CASCADE,
    store_id INT REFERENCES stores(id) ON DELETE CASCADE,
    promoter_id INT REFERENCES promoters(id) ON DELETE CASCADE,
    supervisor_id INT REFERENCES users(id) ON DELETE SET NULL,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_timings VARCHAR(100),
    total_hours DECIMAL(4, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'SCHEDULED',
    staff_role VARCHAR(50) DEFAULT 'PROMOTER',
    session_count INT DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shift_lookup ON timemap_schedules(shift_date, store_id, project_id);

-- 6. STORE BADGES (6-STAGE TRACKER)
CREATE TABLE store_badges (
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

-- 7. INDEPENDENT LOGISTICS: DROPS
CREATE TABLE logistics_drops (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    store_id INT REFERENCES stores(id),
    assigned_supervisor_id INT REFERENCES users(id),
    scheduled_drop_date DATE NOT NULL,
    items_manifest TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'DELIVERED')),
    delivered_at TIMESTAMP WITH TIME ZONE,
    delivery_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. INDEPENDENT LOGISTICS: COLLECTIONS
CREATE TABLE logistics_collections (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    store_id INT REFERENCES stores(id),
    assigned_supervisor_id INT REFERENCES users(id),
    scheduled_collection_date DATE NOT NULL,
    items_to_collect TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COLLECTED')),
    collected_at TIMESTAMP WITH TIME ZONE,
    collection_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. SUPERVISOR EVALUATIONS
CREATE TABLE store_evaluations (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    store_id INT REFERENCES stores(id),
    promoter_id INT REFERENCES promoters(id),
    supervisor_id INT REFERENCES users(id),
    visit_date DATE NOT NULL,
    grooming_score SMALLINT NOT NULL CHECK (grooming_score BETWEEN 1 AND 5),
    pitch_score SMALLINT NOT NULL CHECK (pitch_score BETWEEN 1 AND 5),
    engagement_score SMALLINT NOT NULL CHECK (engagement_score BETWEEN 1 AND 5),
    punctuality_score SMALLINT NOT NULL CHECK (punctuality_score BETWEEN 1 AND 5),
    overall_rating DECIMAL(3, 1) NOT NULL,
    feedback_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. STORE PHOTOS
CREATE TABLE store_photos (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    store_id INT REFERENCES stores(id),
    shift_date DATE NOT NULL,
    supervisor_id INT REFERENCES users(id),
    photo_type VARCHAR(50) NOT NULL,
    promoter_id INT REFERENCES promoters(id),
    file_path VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11. OPERATIONAL TASKS
CREATE TABLE operational_tasks (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    store_id INT REFERENCES stores(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(50) DEFAULT 'MEDIUM',
    is_completed BOOLEAN DEFAULT FALSE,
    created_by_user_id INT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable full read/write access for Supabase anon and authenticated roles
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE stores DISABLE ROW LEVEL SECURITY;
ALTER TABLE promoters DISABLE ROW LEVEL SECURITY;
ALTER TABLE timemap_schedules DISABLE ROW LEVEL SECURITY;
ALTER TABLE store_badges DISABLE ROW LEVEL SECURITY;
ALTER TABLE logistics_drops DISABLE ROW LEVEL SECURITY;
ALTER TABLE logistics_collections DISABLE ROW LEVEL SECURITY;
ALTER TABLE store_evaluations DISABLE ROW LEVEL SECURITY;
ALTER TABLE store_photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE operational_tasks DISABLE ROW LEVEL SECURITY;

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;


-- =============================================
-- DATA IMPORT FROM NEON POSTGRESQL
-- =============================================

-- Table: users (13 rows)
INSERT INTO users (id, name, email, phone, password_hash, role, is_active, created_at) VALUES
(1, 'Operations Director', 'ops@imlme.com', '+971501111111', 'admin123', 'OPS_ADMIN', True, '2026-10-14 16:08:18.570269+00:00'),
(2, 'Babar Abdul Majeed', 'babar@imlme.com', '+971502222201', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(3, 'Jasheer Kanhirathil', 'jasheer@imlme.com', '+971502222202', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(4, 'Sivakumar Kishnagopal', 'sivakumar@imlme.com', '+971502222203', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(5, 'Cesar R Dela Cruz Jr', 'cesar@imlme.com', '+971502222204', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(6, 'Mukunda Kumar', 'mukunda@imlme.com', '+971502222205', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(7, 'Jithu Chandran', 'jithu@imlme.com', '+971502222206', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(8, 'Mohammad Thanveer', 'thanveer@imlme.com', '+971502222207', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(9, 'Abdullah Fouzee Ali', 'fouzee@imlme.com', '+971502222208', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(10, 'Yuliya Valentinovna', 'yuliya@imlme.com', '+971502222209', 'super123', 'SUPERVISOR', True, '2026-10-14 16:08:18.570269+00:00'),
(21, 'Abdulrahman Omar', 'abdulrahmanomar@imlme.com', '+971 50 000 0000', 'super123', 'SUPERVISOR', True, '2026-10-15 07:45:40.235120+00:00'),
(22, 'Sony Mathew', 'sony@imlme.com', '+971501112233', 'admin123', 'PROMOTER', True, '2026-10-15 09:24:39.841091+00:00'),
(23, 'Prachi Sharma', 'prachi@imlme.com', '+971502223344', 'admin123', 'PROMOTER', True, '2026-10-15 09:24:39.841091+00:00');
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));

-- Table: projects (10 rows)
INSERT INTO projects (id, name, client_name, start_date, end_date, status, created_at) VALUES
(1, 'OGX Roadshow 2026', 'Johnson & Johnson / OGX', '2026-10-01', '2026-11-15', 'ACTIVE', '2026-10-14 16:08:18.679292+00:00'),
(2, 'Sadia Sampling Plan', 'Sadia Middle East', '2026-10-23', '2026-11-30', 'ACTIVE', '2026-10-14 16:08:18.679292+00:00'),
(3, 'Nutella x FiLLi Cafe Activation', 'Ferrero / Nutella', '2026-10-18', '2026-10-31', 'ACTIVE', '2026-10-14 16:08:18.679292+00:00'),
(4, 'OGX Roadshow 2026', 'Johnson & Johnson / OGX', '2026-10-01', '2026-11-15', 'ACTIVE', '2026-10-14 16:09:52.136950+00:00'),
(5, 'Sadia Sampling Plan', 'Sadia Middle East', '2026-10-23', '2026-11-30', 'ACTIVE', '2026-10-14 16:09:52.136950+00:00'),
(6, 'Nutella x FiLLi Cafe Activation', 'Ferrero / Nutella', '2026-10-18', '2026-10-31', 'ACTIVE', '2026-10-14 16:09:52.136950+00:00'),
(7, 'OGX Roadshow 2026', 'Johnson & Johnson', '2026-09-30', '2026-10-31', 'ACTIVE', '2026-10-15 07:43:54.421210+00:00'),
(8, 'Sadia Sampling Campaign', 'Sadia ME', '2026-10-23', '2026-11-30', 'ACTIVE', '2026-10-15 07:43:54.421210+00:00'),
(9, 'OGX Roadshow 2026', 'Johnson & Johnson', '2026-09-30', '2026-10-31', 'ACTIVE', '2026-10-15 07:45:39.935504+00:00'),
(10, 'Sadia Sampling Campaign', 'Sadia ME', '2026-10-23', '2026-11-30', 'ACTIVE', '2026-10-15 07:45:39.935504+00:00');
SELECT setval('projects_id_seq', (SELECT MAX(id) FROM projects));

-- Table: stores (74 rows)
INSERT INTO stores (id, store_name, retailer, emirate, branch_code, location_address, contact_person, contact_phone, created_at, customer_code, chain, city, smn_contact, merchandiser_lead) VALUES
(1, 'Lulu Hypermarket - Al Barsha', 'Lulu', 'Dubai', '2100', 'Al Barsha 1, Dubai', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(2, 'Lulu Hypermarket - Al Wahda Mall', 'Lulu', 'Abu Dhabi', '2370', 'Al Wahda Mall, Abu Dhabi', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(3, 'Union Coop - Mirdif (Etihad Mall)', 'Union Coop', 'Dubai', '7168834', 'Etihad Mall, Mirdif, Dubai', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(4, 'Life Pharmacy - Silicon Central Mall', 'Life Pharmacy', 'Dubai', 'LP101', 'Silicon Central Mall, DSO, Dubai', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(5, 'Life Pharmacy - Dubai Hills Mall', 'Life Pharmacy', 'Dubai', 'LP102', 'Dubai Hills Mall, Dubai', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(6, 'FiLLi Cafe - City Walk', 'FiLLi Cafe', 'Dubai', 'FC01', 'City Walk, Dubai', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(7, 'FiLLi Cafe - Al Heera', 'FiLLi Cafe', 'Sharjah', 'FC02', 'Al Heera Beach, Sharjah', NULL, NULL, '2026-10-14 16:08:18.794485+00:00', NULL, NULL, NULL, NULL, NULL),
(8, 'Lulu Hypermarket - Al Barsha', 'Lulu', 'Dubai', '2100', 'Al Barsha 1, Dubai', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(9, 'Lulu Hypermarket - Al Wahda Mall', 'Lulu', 'Abu Dhabi', '2370', 'Al Wahda Mall, Abu Dhabi', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(10, 'Union Coop - Mirdif (Etihad Mall)', 'Union Coop', 'Dubai', '7168834', 'Etihad Mall, Mirdif, Dubai', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(11, 'Life Pharmacy - Silicon Central Mall', 'Life Pharmacy', 'Dubai', 'LP101', 'Silicon Central Mall, DSO, Dubai', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(12, 'Life Pharmacy - Dubai Hills Mall', 'Life Pharmacy', 'Dubai', 'LP102', 'Dubai Hills Mall, Dubai', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(13, 'FiLLi Cafe - City Walk', 'FiLLi Cafe', 'Dubai', 'FC01', 'City Walk, Dubai', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(14, 'FiLLi Cafe - Al Heera', 'FiLLi Cafe', 'Sharjah', 'FC02', 'Al Heera Beach, Sharjah', NULL, NULL, '2026-10-14 16:09:52.136950+00:00', NULL, NULL, NULL, NULL, NULL),
(15, 'MARKANDSAVE HYPERMARKET SPS LLC-BR3 AL TALAH', 'MARK AND SAVE', 'Ajman', NULL, NULL, NULL, NULL, '2026-10-15 07:43:54.691083+00:00', '9569383', 'MARK AND SAVE', 'AJM', 'ABDULLAH  FOUZEE ALI', 'Sivakumar Kishnagopal'),
(16, 'MARKANDSAVE HYPERMARKET SPS LLC MUHAISNAH', 'MARK AND SAVE', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:00.807607+00:00', '9601468', 'MARK AND SAVE', 'DXB', 'JITHU CHANDRAN', 'Babar Abdul Majeed'),
(17, 'Al Ain Co Operative Soc - Al Yahar', 'MAIR GROUP', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:44:02.972891+00:00', '7175351', 'MAIR GROUP', 'ALN', 'MOHAMMAD THANVEER', 'Cesar R Dela Cruz Jr'),
(18, 'Al Ain Co Operative Soc - Bateen', 'MAIR GROUP', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:44:03.333906+00:00', '7175353', 'MAIR GROUP', 'ALN', 'MOHAMMAD THANVEER', 'Cesar R Dela Cruz Jr'),
(19, 'Al Ain Co Operative Soc - Zakhir', 'MAIR GROUP', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:44:06.022829+00:00', '7175368', 'MAIR GROUP', 'ALN', 'MOHAMMAD THANVEER', 'Cesar R Dela Cruz Jr'),
(20, 'Abudhabi Co Op Soc Auh Mall - Tca', 'MAIR GROUP', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:07.665984+00:00', '7177441', 'MAIR GROUP', 'AUH', 'JASHEER KANHIRATHIL', 'Cesar R Dela Cruz Jr'),
(21, 'Abu Dhabi Co-Op Soc Branch - Bateen', 'MAIR GROUP', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:09.309239+00:00', '7177442', 'MAIR GROUP', 'AUH', 'JASHEER KANHIRATHIL', 'Cesar R Dela Cruz Jr'),
(22, 'Abudhabi Co Op Soc - Mina Center', 'MAIR GROUP', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:10.967052+00:00', '7177449', 'MAIR GROUP', 'AUH', 'JASHEER KANHIRATHIL', 'Cesar R Dela Cruz Jr'),
(23, 'Abudhabi Co Op Soc - Muroor', 'MAIR GROUP', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:11.323908+00:00', '7177451', 'MAIR GROUP', 'AUH', 'JASHEER KANHIRATHIL', 'Cesar R Dela Cruz Jr'),
(24, 'UNION CO OPERATIVE SOC - MIRDIF, ETIHAD MALL', 'UNION COOP', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:12.821291+00:00', '7168834', 'UNION COOP', 'DXB', 'YULIYA VALENTINOVNA', 'Babar Abdul Majeed'),
(25, 'UNION CO OPERATIVE SOC - BARSHA', 'UNION COOP', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:15.727642+00:00', '7174905', 'UNION COOP', 'DXB', 'YULIYA VALENTINOVNA', 'Mukunda Kumar'),
(26, 'UNION CO OPERATIVE SOC - Warqa', 'UNION COOP', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:16.235262+00:00', '7762176', 'UNION COOP', 'DXB', 'YULIYA VALENTINOVNA', 'Babar Abdul Majeed'),
(27, 'UNION CO OPERATIVE SOC - AL WASL', 'UNION COOP', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:19.008974+00:00', '7174903', 'UNION COOP', 'DXB', 'YULIYA VALENTINOVNA', 'Mukunda Kumar'),
(28, 'UNION CO OPERATIVE SOC - JUMEIRAH', 'UNION COOP', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:20.212449+00:00', '7174906', 'UNION COOP', 'DXB', 'YULIYA VALENTINOVNA', 'Mukunda Kumar'),
(29, 'Lulu Hypermarket - Silicon Oasis', 'EMKE', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:21.390161+00:00', '7890144', 'EMKE', 'DXB', 'EMILIO MOUSSI', 'Babar Abdul Majeed'),
(30, 'LULU HYPERMARKET SANAIYA', 'EMKE', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:44:23.504211+00:00', '7174406', 'EMKE', 'ALN', 'MOHAMMAD THANVEER', 'Cesar R Dela Cruz Jr'),
(31, 'LULU WARQA', 'EMKE', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:25.709180+00:00', '7478382', 'EMKE', 'DXB', 'EMILIO MOUSSI', 'Babar Abdul Majeed'),
(32, 'LULU HYPERMARKET LLC,SHAMKHA', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:27.809107+00:00', '8172678', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(33, 'LULU HM HAZANA', 'EMKE', 'Sharjah', NULL, NULL, NULL, NULL, '2026-10-15 07:44:29.960818+00:00', '7426115', 'EMKE', 'SHJ', 'ABDULLAH NAUSHAD NAZIR', 'Sivakumar Kishnagopal'),
(34, 'LULU HYPERMARKET MUSAFFA', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:32.853405+00:00', '7177215', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(35, 'LULU HYPERMARKET AL WAHDA', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:35.376430+00:00', '7177223', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(36, 'LULU HYPERMARKET KUWAITAT', 'EMKE', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:44:37.552331+00:00', '7174407', 'EMKE', 'ALN', 'MUHAMMED RAFEEQ', 'Cesar R Dela Cruz Jr'),
(37, 'LULU HYPERMARKET WTC', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:37.922274+00:00', '7480037', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(38, 'LULU HYPERMARKET RAK MALL', 'EMKE', 'Ras Al Khaimah', NULL, NULL, NULL, NULL, '2026-10-15 07:44:41.482691+00:00', '7168728', 'EMKE', 'RAK', 'NASRUDHEEN RAHMAN', 'Sivakumar Kishnagopal'),
(39, 'LULU HYPERMARKET KHALIDIYA', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:43.593968+00:00', '7177222', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(40, 'LULU-ARABIAN', 'EMKE', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:45.937105+00:00', '7176960', 'EMKE', 'DXB', 'EMILIO MOUSSI', 'Babar Abdul Majeed'),
(41, 'LULU HYPER  BARSHA', 'EMKE', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:48.022832+00:00', '7176961', 'EMKE', 'DXB', 'EMILIO MOUSSI', 'Mukunda Kumar'),
(42, 'LULU AL FALAH CENTER MALL', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:48.376931+00:00', '8431639', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(43, 'LULU HYPERMARKET KHALIFA CITY', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:50.322335+00:00', '7789622', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(44, 'LULU HYPERMARKET MUSHRIFF', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:44:53.981477+00:00', '7177220', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(45, 'LULU HYPER GHUSAIS', 'EMKE', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:44:54.333471+00:00', '7176963', 'EMKE', 'DXB', 'EMILIO MOUSSI', 'Babar Abdul Majeed'),
(46, 'LULU HYPERMARKET SAMNAN', 'EMKE', 'Sharjah', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '8027029', 'EMKE', 'SHJ', 'ABDULLAH NAUSHAD NAZIR', 'Sivakumar Kishnagopal'),
(47, 'LULU HYPERMARKET Muweilah', 'EMKE', 'Sharjah', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7861101', 'EMKE', 'SHJ', 'ABDULLAH NAUSHAD NAZIR', 'Sivakumar Kishnagopal'),
(48, 'LULU HYPERMARKET SHAWAMEK', 'EMKE', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '9255201', 'EMKE', 'AUH', 'ANWAR ALI', 'Cesar R Dela Cruz Jr'),
(49, 'LULU HYPERMARKET SP LLC BR MAQAM', 'EMKE', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '8272459', 'EMKE', 'ALN', 'MOHAMMAD THANVEER', 'Cesar R Dela Cruz Jr'),
(50, 'Lulu Barari', 'EMKE', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7174405', 'EMKE', 'ALN', 'MUHAMMED RAFEEQ', 'Cesar R Dela Cruz Jr');
INSERT INTO stores (id, store_name, retailer, emirate, branch_code, location_address, contact_person, contact_phone, created_at, customer_code, chain, city, smn_contact, merchandiser_lead) VALUES
(51, 'CARREFOUR CITY CENTER - ZAHIA', 'CARREFOUR', 'Sharjah', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7875032', 'CARREFOUR', 'SHJ', 'Arun', 'Abdulrahman Omar'),
(52, 'CARREFOUR CITY CENTER - SHARJAH', 'CARREFOUR', 'Sharjah', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177480', 'CARREFOUR', 'SHJ', 'Arun', 'Abdulrahman Omar'),
(53, 'CARREFOUR CITY CENTER - MIRDIF', 'CARREFOUR', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177479', 'CARREFOUR', 'DXB', 'Piere', 'Abdulrahman Omar'),
(54, 'CARREFOUR DEIRA CITY CENTER', 'CARREFOUR', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177545', 'CARREFOUR', 'DXB', 'Piere', 'Abdulrahman Omar'),
(55, 'CARREFOUR  BANIYAS - ABU DHABI', 'CARREFOUR', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7174151', 'CARREFOUR', 'AUH', 'Alex', 'Abdulrahman Omar'),
(56, 'CARREFOUR  DEERFIELD SHAHAMA', 'CARREFOUR', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7174153', 'CARREFOUR', 'AUH', 'Alex', 'Abdulrahman Omar'),
(57, 'CARREFOUR AL GHURAIR', 'CARREFOUR', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177543', 'CARREFOUR', 'DXB', 'Arun', 'Abdulrahman Omar'),
(58, 'CARREFOUR MALL OF THE EMIRATES', 'CARREFOUR', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177546', 'CARREFOUR', 'DXB', 'Piere', 'Abdulrahman Omar'),
(59, 'CARREFOUR IBN BATTUTA', 'CARREFOUR', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177040', 'CARREFOUR', 'DXB', 'Piere', 'Abdulrahman Omar'),
(60, 'CARREFOUR SAQR', 'CARREFOUR', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7174150', 'CARREFOUR', 'AUH', 'Alex', 'Abdulrahman Omar'),
(61, 'CARREFOUR  YAS MALL', 'CARREFOUR', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7174160', 'CARREFOUR', 'AUH', 'Alex', 'Abdulrahman Omar'),
(62, 'CARREFOUR CITY CENTER - AJMAN', 'CARREFOUR', 'Ajman', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7177476', 'CARREFOUR', 'AJM', 'Arun', 'Abdulrahman Omar'),
(63, 'CARREFOUR  DALMA MALL - MUSSAFAH', 'CARREFOUR', 'Abu Dhabi', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', '7174152', 'CARREFOUR', 'AUH', 'Alex', 'Abdulrahman Omar'),
(64, 'LULU AL WAHDA MALL (2370)', 'Lulu', 'Abu Dhabi', '2370', NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(65, 'LULU KHALIDIYA MALL (2220)', 'Lulu', 'Abu Dhabi', '2220', NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(66, 'LULU KHALIFA CITY (2532)', 'Lulu', 'Abu Dhabi', '2532', NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(67, 'LULU AL FALAHA CENTRAL MALL (2600)', 'Lulu', 'Abu Dhabi', '2600', NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(68, 'LULU KUWAITAT', 'Lulu', 'Al Ain', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(69, 'LULU HM Qusais', 'Lulu', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(70, 'LULU HM Silicon', 'Lulu', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(71, 'LULU HM RAK Mall', 'Lulu', 'Ras Al Khaimah', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(72, 'LULU HM Arabian Center', 'Lulu', 'Dubai', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(73, 'LULU FUJAIRAH', 'Lulu', 'Fujairah', NULL, NULL, NULL, NULL, '2026-10-15 07:45:40.235120+00:00', NULL, 'LULU HYPERMARKET', NULL, NULL, 'Jasheer Kanhirathil'),
(74, 'Test Automation Branch', 'Lulu Hypermarket', 'Dubai', NULL, NULL, NULL, NULL, '2026-11-01 17:29:19.164356+00:00', NULL, 'Lulu Hypermarket', NULL, NULL, NULL);
SELECT setval('stores_id_seq', (SELECT MAX(id) FROM stores));

-- Table: promoters (45 rows)
INSERT INTO promoters (id, name, phone, email, gender, nationality, is_active, created_at, staff_role) VALUES
(1, 'Sony', '+971551234567', 'sony@promoter.me', 'FEMALE', 'Indian', True, '2026-10-14 16:08:18.904008+00:00', 'PROMOTER'),
(2, 'Prachi', '+971552345678', 'prachi@promoter.me', 'FEMALE', 'Indian', True, '2026-10-14 16:08:18.904008+00:00', 'PROMOTER'),
(3, 'Abdul Jabbar', '+971553456789', 'abdul@promoter.me', 'MALE', 'Pakistani', True, '2026-10-14 16:08:18.904008+00:00', 'PROMOTER'),
(4, 'Muhammed Mahfoodh', '+971554567890', 'mahfoodh@promoter.me', 'MALE', 'Indian', True, '2026-10-14 16:08:18.904008+00:00', 'PROMOTER'),
(5, 'Shyju Venga', '+971555678901', 'shyju@promoter.me', 'MALE', 'Indian', True, '2026-10-14 16:08:18.904008+00:00', 'PROMOTER'),
(6, 'Sony', '+971551234567', 'sony@promoter.me', 'FEMALE', 'Indian', True, '2026-10-14 16:09:52.136950+00:00', 'PROMOTER'),
(7, 'Prachi', '+971552345678', 'prachi@promoter.me', 'FEMALE', 'Indian', True, '2026-10-14 16:09:52.136950+00:00', 'PROMOTER'),
(8, 'Abdul Jabbar', '+971553456789', 'abdul@promoter.me', 'MALE', 'Pakistani', True, '2026-10-14 16:09:52.136950+00:00', 'PROMOTER'),
(9, 'Muhammed Mahfoodh', '+971554567890', 'mahfoodh@promoter.me', 'MALE', 'Indian', True, '2026-10-14 16:09:52.136950+00:00', 'PROMOTER'),
(10, 'Shyju Venga', '+971555678901', 'shyju@promoter.me', 'MALE', 'Indian', True, '2026-10-14 16:09:52.136950+00:00', 'PROMOTER'),
(11, 'Percival Ignacio', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:43:59.235344+00:00', 'PROMOTER'),
(12, 'Lakshman Chandranath', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:01.174179+00:00', 'PROMOTER'),
(13, 'Othman Masoud', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:04.704146+00:00', 'PROMOTER'),
(14, 'Hammad Tanveer Musarat Tanveer', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:06.381106+00:00', 'PROMOTER'),
(15, 'Shine Sujathan', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:08.034537+00:00', 'PROMOTER'),
(16, 'Dexter Esguerra Diaz', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:09.679426+00:00', 'PROMOTER'),
(17, 'Mohamed Irfan', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:14.498585+00:00', 'PROMOTER'),
(18, 'Mohammad Ajmal', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:17.983158+00:00', 'PROMOTER'),
(19, 'Santa Bahadur', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:19.376490+00:00', 'PROMOTER'),
(20, 'Janice Baldove Gianzon', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:20.569855+00:00', 'PROMOTER'),
(21, 'Sherej Puthen Veettil', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:21.748458+00:00', 'PROMOTER'),
(22, 'Dipen Magar', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:23.868441+00:00', 'PROMOTER'),
(23, 'Tara Prasas', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:26.066028+00:00', 'PROMOTER'),
(24, 'Riaz Abdul Razaq', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:28.180684+00:00', 'PROMOTER'),
(25, 'Younus Abdulla', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:30.329454+00:00', 'PROMOTER'),
(26, 'Khourshid Alam', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:33.212520+00:00', 'PROMOTER'),
(27, 'Archie Pabayo', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:35.732644+00:00', 'PROMOTER'),
(28, 'Irshad Usman Ibrahim', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:39.737606+00:00', 'PROMOTER'),
(29, 'Eduardo Jr Niegas Balitayo', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:41.837388+00:00', 'PROMOTER'),
(30, 'Zahid Ahmad Khan', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:44.191450+00:00', 'PROMOTER'),
(31, 'Kanchha Lal Syangtan', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:46.300770+00:00', 'PROMOTER'),
(32, 'Edwin Inofre', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:44:52.261101+00:00', 'PROMOTER'),
(33, 'Prem Nazeer', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(34, 'Fahad Rasheed', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(35, 'NARAYAN', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(36, 'OGX Promoter 1', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(37, 'OGX Promoter 2', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(38, 'OGX Promoter 3', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(39, 'OGX Promoter 4', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(40, 'OGX Promoter 5', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(41, 'OGX Promoter 6', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(42, 'OGX Promoter 7', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(43, 'OGX Promoter 8', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(44, 'OGX Promoter 9', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER'),
(45, 'OGX Promoter 10', '+971 55 000 0000', NULL, NULL, NULL, True, '2026-10-15 07:45:40.235120+00:00', 'PROMOTER');
SELECT setval('promoters_id_seq', (SELECT MAX(id) FROM promoters));

-- Table: timemap_schedules (933 rows)
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(1, 1, 1, 1, 2, '2026-10-14', '14:00:00', '22:00:00', '5:00 PM - 5:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:48.849206+00:00', 'PROMOTER', 1, NULL),
(2, 1, 1, 1, 2, '2026-10-15', '14:00:00', '22:00:00', '5:00 PM - 5:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:49.011751+00:00', 'PROMOTER', 1, NULL),
(3, 1, 1, 1, 2, '2026-10-16', '14:00:00', '22:00:00', '5:00 PM - 5:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:49.108167+00:00', 'PROMOTER', 1, NULL),
(4, 1, 1, 1, 2, '2026-10-17', '14:00:00', '22:00:00', '5:00 PM - 5:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:49.204164+00:00', 'PROMOTER', 1, NULL),
(5, 2, 1, 3, 2, '2026-10-14', '17:00:00', '22:00:00', '7:00 PM - 7:30 PM', '5.00', 'SCHEDULED', '2026-10-14 16:33:49.312410+00:00', 'PROMOTER', 1, NULL),
(6, 2, 1, 3, 2, '2026-10-15', '17:00:00', '22:00:00', '7:00 PM - 7:30 PM', '5.00', 'SCHEDULED', '2026-10-14 16:33:49.413387+00:00', 'PROMOTER', 1, NULL),
(7, 2, 1, 3, 2, '2026-10-16', '17:00:00', '22:00:00', '7:00 PM - 7:30 PM', '5.00', 'SCHEDULED', '2026-10-14 16:33:49.511905+00:00', 'PROMOTER', 1, NULL),
(8, 1, 2, 2, 3, '2026-10-14', '14:00:00', '22:00:00', '6:00 PM - 6:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:49.614290+00:00', 'PROMOTER', 1, NULL),
(9, 1, 2, 2, 3, '2026-10-15', '14:00:00', '22:00:00', '6:00 PM - 6:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:49.714658+00:00', 'PROMOTER', 1, NULL),
(10, 1, 2, 2, 3, '2026-10-16', '14:00:00', '22:00:00', '6:00 PM - 6:45 PM', '8.00', 'SCHEDULED', '2026-10-14 16:33:49.810136+00:00', 'PROMOTER', 1, NULL),
(11, 8, 15, 5, 4, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(12, 8, 15, 5, 4, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(13, 8, 15, 5, 4, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(14, 8, 15, 5, 4, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(15, 8, 15, 5, 4, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(16, 8, 15, 5, 4, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(17, 8, 15, 5, 4, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(18, 8, 15, 5, 4, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(19, 8, 15, 5, 4, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(20, 8, 15, 5, 4, '2026-11-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(21, 8, 15, 5, 4, '2026-11-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(22, 8, 15, 5, 4, '2026-11-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:43:59.235344+00:00', 'PROMOTER', 2, '2'),
(23, 8, 16, 11, 2, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(24, 8, 16, 11, 2, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(25, 8, 16, 11, 2, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(26, 8, 16, 11, 2, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(27, 8, 16, 11, 2, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(28, 8, 16, 11, 2, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(29, 8, 16, 11, 2, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(30, 8, 16, 11, 2, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(31, 8, 16, 11, 2, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(32, 8, 16, 11, 2, '2026-11-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(33, 8, 16, 11, 2, '2026-11-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(34, 8, 16, 11, 2, '2026-11-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:01.174179+00:00', 'PROMOTER', 2, '2'),
(35, 8, 17, 12, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(36, 8, 17, 12, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(37, 8, 17, 12, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(38, 8, 17, 12, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(39, 8, 17, 12, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(40, 8, 17, 12, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(41, 8, 17, 12, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(42, 8, 17, 12, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(43, 8, 17, 12, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:03.333906+00:00', 'PROMOTER', 1, '1'),
(44, 8, 18, 12, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(45, 8, 18, 12, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(46, 8, 18, 12, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(47, 8, 18, 12, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(48, 8, 18, 12, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(49, 8, 18, 12, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(50, 8, 18, 12, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(51, 8, 18, 12, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(52, 8, 18, 12, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:04.704146+00:00', 'PROMOTER', 1, '1'),
(53, 8, 19, 13, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(54, 8, 19, 13, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(55, 8, 19, 13, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(56, 8, 19, 13, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(57, 8, 19, 13, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(58, 8, 19, 13, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(59, 8, 19, 13, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(60, 8, 19, 13, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(61, 8, 19, 13, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:06.381106+00:00', 'PROMOTER', 2, '2'),
(62, 8, 20, 14, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(63, 8, 20, 14, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(64, 8, 20, 14, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(65, 8, 20, 14, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(66, 8, 20, 14, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(67, 8, 20, 14, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(68, 8, 20, 14, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(69, 8, 20, 14, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(70, 8, 20, 14, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:08.034537+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(71, 8, 21, 15, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(72, 8, 21, 15, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(73, 8, 21, 15, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(74, 8, 21, 15, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(75, 8, 21, 15, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(76, 8, 21, 15, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(77, 8, 21, 15, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(78, 8, 21, 15, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(79, 8, 21, 15, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:09.679426+00:00', 'PROMOTER', 1, '1'),
(80, 8, 22, 16, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(81, 8, 22, 16, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(82, 8, 22, 16, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(83, 8, 22, 16, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(84, 8, 22, 16, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(85, 8, 22, 16, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(86, 8, 22, 16, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(87, 8, 22, 16, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(88, 8, 22, 16, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:11.323908+00:00', 'PROMOTER', 1, '1'),
(89, 8, 23, 14, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(90, 8, 23, 14, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(91, 8, 23, 14, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'PROMOTER', 2, '1 promoter 9 days 
1 mascot 1 day'),
(92, 8, 23, 14, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(93, 8, 23, 14, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(94, 8, 23, 14, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(95, 8, 23, 14, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(96, 8, 23, 14, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(97, 8, 23, 14, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:12.821291+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(98, 8, 24, 3, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:14.498585+00:00', 'CHEF', 2, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(99, 8, 24, 3, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:14.498585+00:00', 'CHEF', 4, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(100, 8, 24, 3, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:14.498585+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(101, 8, 24, 3, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:14.498585+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(102, 8, 25, 17, 6, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:16.235262+00:00', 'CHEF', 2, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(103, 8, 25, 17, 6, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:16.235262+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(104, 8, 25, 17, 6, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:16.235262+00:00', 'CHEF', 4, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(105, 8, 25, 17, 6, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:16.235262+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(106, 8, 26, 4, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:17.983158+00:00', 'CHEF', 2, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(107, 8, 26, 4, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:17.983158+00:00', 'CHEF', 4, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(108, 8, 26, 4, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:17.983158+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(109, 8, 26, 4, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:17.983158+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(110, 8, 27, 18, 6, '2026-10-29', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:19.376490+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(111, 8, 27, 18, 6, '2026-10-30', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:19.376490+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(112, 8, 27, 18, 6, '2026-10-31', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:19.376490+00:00', 'PROMOTER', 3, '2 promoters 4 days 
1 mascot 1 day'),
(113, 8, 27, 18, 6, '2026-11-01', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:19.376490+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(114, 8, 28, 19, 6, '2026-10-29', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:20.569855+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(115, 8, 28, 19, 6, '2026-10-30', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:20.569855+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(116, 8, 28, 19, 6, '2026-10-31', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:20.569855+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(117, 8, 28, 19, 6, '2026-11-01', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:44:20.569855+00:00', 'PROMOTER', 3, '2 promoters 4 days 
1 mascot 1 day'),
(118, 8, 29, 20, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(119, 8, 29, 20, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(120, 8, 29, 20, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(121, 8, 29, 20, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(122, 8, 29, 20, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(123, 8, 29, 20, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(124, 8, 29, 20, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(125, 8, 29, 20, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(126, 8, 29, 20, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(127, 8, 29, 20, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(128, 8, 29, 20, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(129, 8, 29, 20, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(130, 8, 29, 20, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(131, 8, 29, 20, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:21.748458+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(132, 8, 30, 21, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(133, 8, 30, 21, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(134, 8, 30, 21, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(135, 8, 30, 21, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(136, 8, 30, 21, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(137, 8, 30, 21, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(138, 8, 30, 21, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(139, 8, 30, 21, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(140, 8, 30, 21, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(141, 8, 30, 21, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(142, 8, 30, 21, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(143, 8, 30, 21, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(144, 8, 30, 21, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(145, 8, 30, 21, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:23.868441+00:00', 'PROMOTER', 2, '2'),
(146, 8, 31, 22, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(147, 8, 31, 22, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(148, 8, 31, 22, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(149, 8, 31, 22, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(150, 8, 31, 22, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(151, 8, 31, 22, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(152, 8, 31, 22, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(153, 8, 31, 22, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(154, 8, 31, 22, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(155, 8, 31, 22, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(156, 8, 31, 22, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(157, 8, 31, 22, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(158, 8, 31, 22, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(159, 8, 31, 22, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:26.066028+00:00', 'PROMOTER', 2, '2'),
(160, 8, 32, 23, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(161, 8, 32, 23, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(162, 8, 32, 23, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(163, 8, 32, 23, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(164, 8, 32, 23, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(165, 8, 32, 23, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(166, 8, 32, 23, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(167, 8, 32, 23, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(168, 8, 32, 23, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(169, 8, 32, 23, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(170, 8, 32, 23, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(171, 8, 32, 23, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(172, 8, 32, 23, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(173, 8, 32, 23, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:28.180684+00:00', 'PROMOTER', 2, '2'),
(174, 8, 33, 24, 4, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(175, 8, 33, 24, 4, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(176, 8, 33, 24, 4, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(177, 8, 33, 24, 4, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(178, 8, 33, 24, 4, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(179, 8, 33, 24, 4, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(180, 8, 33, 24, 4, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(181, 8, 33, 24, 4, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(182, 8, 33, 24, 4, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(183, 8, 33, 24, 4, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(184, 8, 33, 24, 4, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(185, 8, 33, 24, 4, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(186, 8, 33, 24, 4, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(187, 8, 33, 24, 4, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:30.329454+00:00', 'PROMOTER', 2, '2'),
(188, 8, 34, 25, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(189, 8, 34, 25, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(190, 8, 34, 25, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(191, 8, 34, 25, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(192, 8, 34, 25, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(193, 8, 34, 25, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(194, 8, 34, 25, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(195, 8, 34, 25, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(196, 8, 34, 25, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(197, 8, 34, 25, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(198, 8, 34, 25, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(199, 8, 34, 25, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(200, 8, 34, 25, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(201, 8, 34, 25, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:33.212520+00:00', 'PROMOTER', 2, '2'),
(202, 8, 35, 26, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(203, 8, 35, 26, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(204, 8, 35, 26, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(205, 8, 35, 26, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(206, 8, 35, 26, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(207, 8, 35, 26, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(208, 8, 35, 26, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(209, 8, 35, 26, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(210, 8, 35, 26, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(211, 8, 35, 26, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(212, 8, 35, 26, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(213, 8, 35, 26, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(214, 8, 35, 26, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(215, 8, 35, 26, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:35.732644+00:00', 'PROMOTER', 2, '2'),
(216, 8, 36, 27, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(217, 8, 36, 27, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(218, 8, 36, 27, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(219, 8, 36, 27, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(220, 8, 36, 27, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(221, 8, 36, 27, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(222, 8, 36, 27, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(223, 8, 36, 27, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(224, 8, 36, 27, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(225, 8, 36, 27, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(226, 8, 36, 27, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(227, 8, 36, 27, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(228, 8, 36, 27, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(229, 8, 36, 27, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:37.922274+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(230, 8, 37, 16, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(231, 8, 37, 16, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(232, 8, 37, 16, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(233, 8, 37, 16, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(234, 8, 37, 16, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(235, 8, 37, 16, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(236, 8, 37, 16, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(237, 8, 37, 16, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(238, 8, 37, 16, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(239, 8, 37, 16, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(240, 8, 37, 16, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(241, 8, 37, 16, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(242, 8, 37, 16, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(243, 8, 37, 16, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:39.737606+00:00', 'PROMOTER', 2, '2'),
(244, 8, 38, 28, 4, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(245, 8, 38, 28, 4, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(246, 8, 38, 28, 4, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(247, 8, 38, 28, 4, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(248, 8, 38, 28, 4, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(249, 8, 38, 28, 4, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(250, 8, 38, 28, 4, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(251, 8, 38, 28, 4, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(252, 8, 38, 28, 4, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(253, 8, 38, 28, 4, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(254, 8, 38, 28, 4, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(255, 8, 38, 28, 4, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(256, 8, 38, 28, 4, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(257, 8, 38, 28, 4, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:41.837388+00:00', 'PROMOTER', 2, '2'),
(258, 8, 39, 29, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(259, 8, 39, 29, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(260, 8, 39, 29, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(261, 8, 39, 29, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(262, 8, 39, 29, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(263, 8, 39, 29, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(264, 8, 39, 29, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(265, 8, 39, 29, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(266, 8, 39, 29, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(267, 8, 39, 29, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(268, 8, 39, 29, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(269, 8, 39, 29, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(270, 8, 39, 29, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(271, 8, 39, 29, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:44.191450+00:00', 'PROMOTER', 2, '2'),
(272, 8, 40, 30, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(273, 8, 40, 30, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(274, 8, 40, 30, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(275, 8, 40, 30, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(276, 8, 40, 30, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(277, 8, 40, 30, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(278, 8, 40, 30, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(279, 8, 40, 30, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(280, 8, 40, 30, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(281, 8, 40, 30, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(282, 8, 40, 30, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 4, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(283, 8, 40, 30, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(284, 8, 40, 30, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(285, 8, 40, 30, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:46.300770+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(286, 8, 41, 31, 6, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(287, 8, 41, 31, 6, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(288, 8, 41, 31, 6, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(289, 8, 41, 31, 6, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(290, 8, 41, 31, 6, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(291, 8, 41, 31, 6, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(292, 8, 41, 31, 6, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(293, 8, 41, 31, 6, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(294, 8, 41, 31, 6, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(295, 8, 41, 31, 6, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(296, 8, 41, 31, 6, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(297, 8, 41, 31, 6, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(298, 8, 41, 31, 6, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(299, 8, 41, 31, 6, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:48.376931+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(300, 8, 42, 23, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(301, 8, 42, 23, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(302, 8, 42, 23, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(303, 8, 42, 23, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(304, 8, 42, 23, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(305, 8, 42, 23, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(306, 8, 42, 23, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(307, 8, 42, 23, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(308, 8, 42, 23, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(309, 8, 42, 23, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(310, 8, 42, 23, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(311, 8, 42, 23, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(312, 8, 42, 23, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(313, 8, 42, 23, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:50.322335+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(314, 8, 43, 25, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(315, 8, 43, 25, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(316, 8, 43, 25, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(317, 8, 43, 25, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(318, 8, 43, 25, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(319, 8, 43, 25, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(320, 8, 43, 25, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(321, 8, 43, 25, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(322, 8, 43, 25, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(323, 8, 43, 25, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(324, 8, 43, 25, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(325, 8, 43, 25, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(326, 8, 43, 25, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(327, 8, 43, 25, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:52.261101+00:00', 'PROMOTER', 2, '2'),
(328, 8, 44, 32, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(329, 8, 44, 32, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(330, 8, 44, 32, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(331, 8, 44, 32, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(332, 8, 44, 32, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(333, 8, 44, 32, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(334, 8, 44, 32, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(335, 8, 44, 32, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(336, 8, 44, 32, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(337, 8, 44, 32, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(338, 8, 44, 32, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(339, 8, 44, 32, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(340, 8, 44, 32, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(341, 8, 44, 32, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:44:54.333471+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(356, 10, 15, 10, 4, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(357, 10, 15, 10, 4, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(358, 10, 15, 10, 4, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(359, 10, 15, 10, 4, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(360, 10, 15, 10, 4, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(361, 10, 15, 10, 4, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(362, 10, 15, 10, 4, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(363, 10, 15, 10, 4, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(364, 10, 15, 10, 4, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(365, 10, 15, 10, 4, '2026-11-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(366, 10, 15, 10, 4, '2026-11-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(367, 10, 15, 10, 4, '2026-11-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(368, 10, 16, 11, 2, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(369, 10, 16, 11, 2, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(370, 10, 16, 11, 2, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(371, 10, 16, 11, 2, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(372, 10, 16, 11, 2, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(373, 10, 16, 11, 2, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(374, 10, 16, 11, 2, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(375, 10, 16, 11, 2, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(376, 10, 16, 11, 2, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(377, 10, 16, 11, 2, '2026-11-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(378, 10, 16, 11, 2, '2026-11-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(379, 10, 16, 11, 2, '2026-11-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(380, 10, 17, 12, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(381, 10, 17, 12, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(382, 10, 17, 12, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(383, 10, 17, 12, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(384, 10, 17, 12, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(385, 10, 17, 12, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(386, 10, 17, 12, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(387, 10, 17, 12, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(388, 10, 17, 12, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(389, 10, 18, 12, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(390, 10, 18, 12, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(391, 10, 18, 12, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(392, 10, 18, 12, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(393, 10, 18, 12, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(394, 10, 18, 12, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(395, 10, 18, 12, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(396, 10, 18, 12, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(397, 10, 18, 12, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(398, 10, 19, 13, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(399, 10, 19, 13, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(400, 10, 19, 13, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(401, 10, 19, 13, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(402, 10, 19, 13, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(403, 10, 19, 13, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(404, 10, 19, 13, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(405, 10, 19, 13, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(406, 10, 19, 13, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(407, 10, 20, 14, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(408, 10, 20, 14, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(409, 10, 20, 14, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(410, 10, 20, 14, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(411, 10, 20, 14, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(412, 10, 20, 14, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(413, 10, 20, 14, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(414, 10, 20, 14, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(415, 10, 20, 14, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 9 days 
1 chef 3 days
1 mascot 1 day'),
(416, 10, 21, 15, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(417, 10, 21, 15, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(418, 10, 21, 15, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(419, 10, 21, 15, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(420, 10, 21, 15, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(421, 10, 21, 15, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(422, 10, 21, 15, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(423, 10, 21, 15, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(424, 10, 21, 15, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(425, 10, 22, 16, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(426, 10, 22, 16, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(427, 10, 22, 16, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(428, 10, 22, 16, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(429, 10, 22, 16, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(430, 10, 22, 16, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(431, 10, 22, 16, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(432, 10, 22, 16, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(433, 10, 22, 16, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, '1'),
(434, 10, 23, 14, 5, '2026-10-23', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(435, 10, 23, 14, 5, '2026-10-24', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(436, 10, 23, 14, 5, '2026-10-25', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '1 promoter 9 days 
1 mascot 1 day'),
(437, 10, 23, 14, 5, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(438, 10, 23, 14, 5, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(439, 10, 23, 14, 5, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(440, 10, 23, 14, 5, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(441, 10, 23, 14, 5, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(442, 10, 23, 14, 5, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'MASCOT', 1, '1 promoter 9 days 
1 mascot 1 day'),
(443, 10, 24, 8, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(444, 10, 24, 8, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 4, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(445, 10, 24, 8, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(446, 10, 24, 8, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(447, 10, 25, 17, 6, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(448, 10, 25, 17, 6, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(449, 10, 25, 17, 6, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 4, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(450, 10, 25, 17, 6, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(451, 10, 26, 9, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(452, 10, 26, 9, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 4, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(453, 10, 26, 9, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(454, 10, 26, 9, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 4 days 
1 chef 3 days
1 mascot 1 day'),
(455, 10, 27, 18, 6, '2026-10-29', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(456, 10, 27, 18, 6, '2026-10-30', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(457, 10, 27, 18, 6, '2026-10-31', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 4 days 
1 mascot 1 day'),
(458, 10, 27, 18, 6, '2026-11-01', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(459, 10, 28, 19, 6, '2026-10-29', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(460, 10, 28, 19, 6, '2026-10-30', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(461, 10, 28, 19, 6, '2026-10-31', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 4 days 
1 mascot 1 day'),
(462, 10, 28, 19, 6, '2026-11-01', '10:00:00', '15:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 4 days 
1 mascot 1 day'),
(463, 10, 29, 20, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(464, 10, 29, 20, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(465, 10, 29, 20, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(466, 10, 29, 20, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(467, 10, 29, 20, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(468, 10, 29, 20, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(469, 10, 29, 20, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(470, 10, 29, 20, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(471, 10, 29, 20, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(472, 10, 29, 20, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(473, 10, 29, 20, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(474, 10, 29, 20, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(475, 10, 29, 20, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(476, 10, 29, 20, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(477, 10, 30, 21, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(478, 10, 30, 21, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(479, 10, 30, 21, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(480, 10, 30, 21, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(481, 10, 30, 21, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(482, 10, 30, 21, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(483, 10, 30, 21, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(484, 10, 30, 21, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(485, 10, 30, 21, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(486, 10, 30, 21, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(487, 10, 30, 21, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(488, 10, 30, 21, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(489, 10, 30, 21, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(490, 10, 30, 21, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(491, 10, 31, 22, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(492, 10, 31, 22, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(493, 10, 31, 22, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(494, 10, 31, 22, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(495, 10, 31, 22, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(496, 10, 31, 22, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(497, 10, 31, 22, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(498, 10, 31, 22, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(499, 10, 31, 22, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(500, 10, 31, 22, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(501, 10, 31, 22, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(502, 10, 31, 22, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(503, 10, 31, 22, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(504, 10, 31, 22, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(505, 10, 32, 23, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(506, 10, 32, 23, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(507, 10, 32, 23, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(508, 10, 32, 23, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(509, 10, 32, 23, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(510, 10, 32, 23, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(511, 10, 32, 23, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(512, 10, 32, 23, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(513, 10, 32, 23, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(514, 10, 32, 23, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(515, 10, 32, 23, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(516, 10, 32, 23, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(517, 10, 32, 23, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(518, 10, 32, 23, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(519, 10, 33, 24, 4, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(520, 10, 33, 24, 4, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(521, 10, 33, 24, 4, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(522, 10, 33, 24, 4, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(523, 10, 33, 24, 4, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(524, 10, 33, 24, 4, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(525, 10, 33, 24, 4, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(526, 10, 33, 24, 4, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(527, 10, 33, 24, 4, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(528, 10, 33, 24, 4, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(529, 10, 33, 24, 4, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(530, 10, 33, 24, 4, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(531, 10, 33, 24, 4, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(532, 10, 33, 24, 4, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(533, 10, 34, 25, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(534, 10, 34, 25, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(535, 10, 34, 25, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(536, 10, 34, 25, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(537, 10, 34, 25, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(538, 10, 34, 25, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(539, 10, 34, 25, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(540, 10, 34, 25, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(541, 10, 34, 25, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(542, 10, 34, 25, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(543, 10, 34, 25, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(544, 10, 34, 25, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(545, 10, 34, 25, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(546, 10, 34, 25, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(547, 10, 35, 26, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(548, 10, 35, 26, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(549, 10, 35, 26, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(550, 10, 35, 26, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(551, 10, 35, 26, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(552, 10, 35, 26, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(553, 10, 35, 26, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(554, 10, 35, 26, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(555, 10, 35, 26, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(556, 10, 35, 26, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(557, 10, 35, 26, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(558, 10, 35, 26, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(559, 10, 35, 26, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(560, 10, 35, 26, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(561, 10, 36, 27, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(562, 10, 36, 27, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(563, 10, 36, 27, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(564, 10, 36, 27, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(565, 10, 36, 27, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(566, 10, 36, 27, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(567, 10, 36, 27, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(568, 10, 36, 27, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(569, 10, 36, 27, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(570, 10, 36, 27, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(571, 10, 36, 27, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(572, 10, 36, 27, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(573, 10, 36, 27, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(574, 10, 36, 27, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(575, 10, 37, 16, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(576, 10, 37, 16, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(577, 10, 37, 16, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(578, 10, 37, 16, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(579, 10, 37, 16, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(580, 10, 37, 16, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(581, 10, 37, 16, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(582, 10, 37, 16, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(583, 10, 37, 16, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(584, 10, 37, 16, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(585, 10, 37, 16, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(586, 10, 37, 16, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(587, 10, 37, 16, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(588, 10, 37, 16, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(589, 10, 38, 28, 4, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(590, 10, 38, 28, 4, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(591, 10, 38, 28, 4, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(592, 10, 38, 28, 4, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(593, 10, 38, 28, 4, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(594, 10, 38, 28, 4, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(595, 10, 38, 28, 4, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(596, 10, 38, 28, 4, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(597, 10, 38, 28, 4, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(598, 10, 38, 28, 4, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(599, 10, 38, 28, 4, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(600, 10, 38, 28, 4, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(601, 10, 38, 28, 4, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(602, 10, 38, 28, 4, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(603, 10, 39, 29, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(604, 10, 39, 29, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(605, 10, 39, 29, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(606, 10, 39, 29, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(607, 10, 39, 29, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(608, 10, 39, 29, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(609, 10, 39, 29, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(610, 10, 39, 29, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(611, 10, 39, 29, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(612, 10, 39, 29, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(613, 10, 39, 29, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(614, 10, 39, 29, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(615, 10, 39, 29, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(616, 10, 39, 29, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(617, 10, 40, 30, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(618, 10, 40, 30, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(619, 10, 40, 30, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(620, 10, 40, 30, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(621, 10, 40, 30, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(622, 10, 40, 30, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(623, 10, 40, 30, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(624, 10, 40, 30, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(625, 10, 40, 30, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(626, 10, 40, 30, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(627, 10, 40, 30, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 4, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(628, 10, 40, 30, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(629, 10, 40, 30, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(630, 10, 40, 30, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(631, 10, 41, 31, 6, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(632, 10, 41, 31, 6, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(633, 10, 41, 31, 6, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(634, 10, 41, 31, 6, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(635, 10, 41, 31, 6, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(636, 10, 41, 31, 6, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(637, 10, 41, 31, 6, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(638, 10, 41, 31, 6, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(639, 10, 41, 31, 6, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(640, 10, 41, 31, 6, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(641, 10, 41, 31, 6, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(642, 10, 41, 31, 6, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(643, 10, 41, 31, 6, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(644, 10, 41, 31, 6, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(645, 10, 42, 23, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(646, 10, 42, 23, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(647, 10, 42, 23, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(648, 10, 42, 23, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(649, 10, 42, 23, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(650, 10, 42, 23, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(651, 10, 42, 23, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(652, 10, 42, 23, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(653, 10, 42, 23, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(654, 10, 42, 23, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(655, 10, 42, 23, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(656, 10, 42, 23, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(657, 10, 42, 23, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(658, 10, 42, 23, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days
1 mascot 1 day'),
(659, 10, 43, 25, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(660, 10, 43, 25, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(661, 10, 43, 25, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(662, 10, 43, 25, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(663, 10, 43, 25, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(664, 10, 43, 25, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(665, 10, 43, 25, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(666, 10, 43, 25, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(667, 10, 43, 25, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(668, 10, 43, 25, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(669, 10, 43, 25, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(670, 10, 43, 25, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(671, 10, 43, 25, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(672, 10, 43, 25, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(673, 10, 44, 32, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(674, 10, 44, 32, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(675, 10, 44, 32, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(676, 10, 44, 32, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(677, 10, 44, 32, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(678, 10, 44, 32, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(679, 10, 44, 32, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(680, 10, 44, 32, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(681, 10, 44, 32, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(682, 10, 44, 32, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(683, 10, 44, 32, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(684, 10, 44, 32, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(685, 10, 44, 32, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(686, 10, 44, 32, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(687, 10, 45, 30, 2, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(688, 10, 45, 30, 2, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(689, 10, 45, 30, 2, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(690, 10, 45, 30, 2, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(691, 10, 45, 30, 2, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(692, 10, 45, 30, 2, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(693, 10, 45, 30, 2, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(694, 10, 45, 30, 2, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(695, 10, 45, 30, 2, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(696, 10, 45, 30, 2, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(697, 10, 45, 30, 2, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(698, 10, 45, 30, 2, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(699, 10, 45, 30, 2, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(700, 10, 45, 30, 2, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(701, 10, 46, 33, 4, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(702, 10, 46, 33, 4, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(703, 10, 46, 33, 4, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(704, 10, 46, 33, 4, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(705, 10, 46, 33, 4, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(706, 10, 46, 33, 4, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(707, 10, 46, 33, 4, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(708, 10, 46, 33, 4, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(709, 10, 46, 33, 4, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days'),
(710, 10, 46, 33, 4, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days'),
(711, 10, 46, 33, 4, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 3, '2 promoters 14 days 
1 chef 3 days'),
(712, 10, 46, 33, 4, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(713, 10, 46, 33, 4, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days'),
(714, 10, 46, 33, 4, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'CHEF', 2, '2 promoters 14 days 
1 chef 3 days');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(715, 10, 47, 34, 4, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(716, 10, 47, 34, 4, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(717, 10, 47, 34, 4, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(718, 10, 47, 34, 4, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(719, 10, 47, 34, 4, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(720, 10, 47, 34, 4, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(721, 10, 47, 34, 4, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(722, 10, 47, 34, 4, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(723, 10, 47, 34, 4, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(724, 10, 47, 34, 4, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(725, 10, 47, 34, 4, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(726, 10, 47, 34, 4, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 14 days 
1 mascot 1 day'),
(727, 10, 47, 34, 4, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(728, 10, 47, 34, 4, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 14 days 
1 mascot 1 day'),
(729, 10, 48, 35, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(730, 10, 48, 35, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(731, 10, 48, 35, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(732, 10, 48, 35, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(733, 10, 48, 35, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(734, 10, 48, 35, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(735, 10, 48, 35, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(736, 10, 48, 35, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(737, 10, 48, 35, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(738, 10, 48, 35, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(739, 10, 48, 35, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(740, 10, 48, 35, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(741, 10, 48, 35, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(742, 10, 48, 35, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(743, 10, 49, 12, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(744, 10, 49, 12, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(745, 10, 49, 12, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(746, 10, 49, 12, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(747, 10, 49, 12, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(748, 10, 49, 12, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(749, 10, 49, 12, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(750, 10, 49, 12, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(751, 10, 49, 12, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(752, 10, 49, 12, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(753, 10, 49, 12, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(754, 10, 49, 12, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(755, 10, 49, 12, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(756, 10, 49, 12, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(757, 10, 50, 12, 5, '2026-10-26', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(758, 10, 50, 12, 5, '2026-10-27', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(759, 10, 50, 12, 5, '2026-10-28', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(760, 10, 50, 12, 5, '2026-10-29', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(761, 10, 50, 12, 5, '2026-10-30', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(762, 10, 50, 12, 5, '2026-10-31', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(763, 10, 50, 12, 5, '2026-11-01', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(764, 10, 50, 12, 5, '2026-11-02', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(765, 10, 50, 12, 5, '2026-11-03', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(766, 10, 50, 12, 5, '2026-11-04', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(767, 10, 50, 12, 5, '2026-11-05', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(768, 10, 50, 12, 5, '2026-11-06', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(769, 10, 50, 12, 5, '2026-11-07', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(770, 10, 50, 12, 5, '2026-11-08', '16:00:00', '22:00:00', 'None', '6.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(771, 10, 51, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 7 days 
1 mascot 1 day'),
(772, 10, 51, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(773, 10, 51, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(774, 10, 51, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(775, 10, 51, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(776, 10, 51, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(777, 10, 51, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(778, 10, 52, 8, 21, '2026-10-26', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(779, 10, 52, 8, 21, '2026-10-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 9 days 
1 mascot 1 day'),
(780, 10, 52, 8, 21, '2026-10-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(781, 10, 52, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(782, 10, 52, 8, 21, '2026-11-02', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(783, 10, 52, 8, 21, '2026-11-03', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(784, 10, 52, 8, 21, '2026-11-04', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(785, 10, 52, 8, 21, '2026-11-05', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(786, 10, 52, 8, 21, '2026-11-09', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(787, 10, 53, 8, 21, '2026-10-26', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(788, 10, 53, 8, 21, '2026-10-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(789, 10, 53, 8, 21, '2026-10-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 9 days 
1 mascot 1 day'),
(790, 10, 53, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(791, 10, 53, 8, 21, '2026-11-02', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(792, 10, 53, 8, 21, '2026-11-03', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(793, 10, 53, 8, 21, '2026-11-04', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(794, 10, 53, 8, 21, '2026-11-05', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(795, 10, 53, 8, 21, '2026-11-09', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(796, 10, 54, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(797, 10, 54, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(798, 10, 54, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(799, 10, 54, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 7 days 
1 mascot 1 day'),
(800, 10, 54, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(801, 10, 54, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(802, 10, 54, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(803, 10, 55, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(804, 10, 55, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(805, 10, 55, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(806, 10, 55, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(807, 10, 55, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(808, 10, 55, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(809, 10, 55, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(810, 10, 56, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(811, 10, 56, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(812, 10, 56, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(813, 10, 56, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(814, 10, 56, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(815, 10, 56, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(816, 10, 56, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(817, 10, 57, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(818, 10, 57, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(819, 10, 57, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(820, 10, 57, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(821, 10, 57, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(822, 10, 57, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(823, 10, 57, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(824, 10, 58, 8, 21, '2026-10-26', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 9 days 
1 mascot 1 day'),
(825, 10, 58, 8, 21, '2026-10-27', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(826, 10, 58, 8, 21, '2026-10-28', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(827, 10, 58, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(828, 10, 58, 8, 21, '2026-11-02', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(829, 10, 58, 8, 21, '2026-11-03', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(830, 10, 58, 8, 21, '2026-11-04', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(831, 10, 58, 8, 21, '2026-11-05', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(832, 10, 58, 8, 21, '2026-11-09', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 9 days 
1 mascot 1 day'),
(833, 10, 59, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(834, 10, 59, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(835, 10, 59, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(836, 10, 59, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(837, 10, 59, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(838, 10, 59, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 7 days 
1 mascot 1 day'),
(839, 10, 59, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(840, 10, 60, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(841, 10, 60, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(842, 10, 60, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(843, 10, 60, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(844, 10, 60, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(845, 10, 60, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(846, 10, 60, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(847, 10, 61, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(848, 10, 61, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(849, 10, 61, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(850, 10, 61, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(851, 10, 61, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(852, 10, 61, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2 promoters 7 days 
1 mascot 1 day'),
(853, 10, 61, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 3, '2 promoters 7 days 
1 mascot 1 day'),
(854, 10, 62, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(855, 10, 62, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(856, 10, 62, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(857, 10, 62, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(858, 10, 62, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(859, 10, 62, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(860, 10, 62, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(861, 10, 63, 8, 21, '2026-10-29', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(862, 10, 63, 8, 21, '2026-10-30', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(863, 10, 63, 8, 21, '2026-10-31', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(864, 10, 63, 8, 21, '2026-11-01', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(865, 10, 63, 8, 21, '2026-11-06', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(866, 10, 63, 8, 21, '2026-11-07', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(867, 10, 63, 8, 21, '2026-11-08', '17:00:00', '22:00:00', 'None', '5.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 2, '2'),
(868, 9, 64, 36, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(869, 9, 64, 36, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(870, 9, 64, 36, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(871, 9, 64, 36, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(872, 9, 64, 36, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(873, 9, 64, 36, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(874, 9, 64, 36, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(875, 9, 64, 36, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(876, 9, 65, 37, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(877, 9, 65, 37, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(878, 9, 65, 37, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(879, 9, 65, 37, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(880, 9, 65, 37, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(881, 9, 65, 37, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(882, 9, 65, 37, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(883, 9, 65, 37, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(884, 9, 66, 38, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(885, 9, 66, 38, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(886, 9, 66, 38, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(887, 9, 66, 38, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(888, 9, 66, 38, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(889, 9, 66, 38, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(890, 9, 66, 38, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(891, 9, 66, 38, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(892, 9, 67, 39, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(893, 9, 67, 39, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(894, 9, 67, 39, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(895, 9, 67, 39, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(896, 9, 67, 39, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(897, 9, 67, 39, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(898, 9, 67, 39, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(899, 9, 67, 39, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(900, 9, 68, 40, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(901, 9, 68, 40, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(902, 9, 68, 40, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(903, 9, 68, 40, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(904, 9, 68, 40, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(905, 9, 68, 40, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(906, 9, 68, 40, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(907, 9, 68, 40, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(908, 9, 69, 41, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(909, 9, 69, 41, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(910, 9, 69, 41, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(911, 9, 69, 41, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(912, 9, 69, 41, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(913, 9, 69, 41, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(914, 9, 69, 41, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026');
INSERT INTO timemap_schedules (id, project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, created_at, staff_role, session_count, notes) VALUES
(915, 9, 69, 41, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(916, 9, 70, 42, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(917, 9, 70, 42, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(918, 9, 70, 42, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(919, 9, 70, 42, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(920, 9, 70, 42, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(921, 9, 70, 42, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(922, 9, 70, 42, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(923, 9, 70, 42, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(924, 9, 71, 43, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(925, 9, 71, 43, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(926, 9, 71, 43, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(927, 9, 71, 43, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(928, 9, 71, 43, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(929, 9, 71, 43, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(930, 9, 71, 43, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(931, 9, 71, 43, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(932, 9, 72, 44, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(933, 9, 72, 44, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(934, 9, 72, 44, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(935, 9, 72, 44, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(936, 9, 72, 44, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(937, 9, 72, 44, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(938, 9, 72, 44, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(939, 9, 72, 44, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(940, 9, 73, 45, 3, '2026-09-30', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(941, 9, 73, 45, 3, '2026-10-01', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(942, 9, 73, 45, 3, '2026-10-02', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(943, 9, 73, 45, 3, '2026-10-03', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(944, 9, 73, 45, 3, '2026-10-04', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(945, 9, 73, 45, 3, '2026-10-05', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(946, 9, 73, 45, 3, '2026-10-06', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026'),
(947, 9, 73, 45, 3, '2026-10-07', '14:00:00', '22:00:00', '5PM - 5:45PM', '8.00', 'SCHEDULED', '2026-10-15 07:45:54.170267+00:00', 'PROMOTER', 1, 'Lulu Saver Week 2026');
SELECT setval('timemap_schedules_id_seq', (SELECT MAX(id) FROM timemap_schedules));

-- Table: store_badges (6 rows)
INSERT INTO store_badges (id, promoter_name, promoter_id, project_id, store_id, emirate, status, submitted_by, badge_number, valid_from, valid_until, notes, created_at, updated_at) VALUES
(1, 'Sony Mathew', NULL, 1, 1, 'Dubai', 'Approved', 'Babar (Lead)', 'LULU-DXB-9842', NULL, NULL, 'EID & Health Card verified. Valid till Dec 2026', '2026-10-15 09:24:39.841091+00:00', '2026-10-15 09:24:39.841091+00:00'),
(2, 'Prachi Sharma', NULL, 1, 1, 'Dubai', 'Approved', 'Babar (Lead)', 'LULU-DXB-9843', NULL, NULL, 'Gate pass issued by security office', '2026-10-15 09:24:39.841091+00:00', '2026-10-15 09:24:39.841091+00:00'),
(3, 'Amina Al Balushi', NULL, 2, 2, 'Abu Dhabi', 'Pending with security', 'Jasheer (Lead)', NULL, NULL, NULL, 'Submitted to Mall CID security desk on Oct 12', '2026-10-15 09:24:39.841091+00:00', '2026-10-15 09:24:39.841091+00:00'),
(4, 'Rahul Verma', NULL, 2, 3, 'Dubai', 'Pending with HR', 'Cesar (Lead)', NULL, NULL, NULL, 'Union Coop HR checking quota clearance', '2026-10-15 09:24:39.841091+00:00', '2026-10-15 09:24:39.841091+00:00'),
(5, 'Fatima Noor', NULL, 2, 17, 'Al Ain', 'Submitted', 'Sivakumar (Lead)', NULL, NULL, NULL, 'Handed over to Al Ain Coop security desk', '2026-10-15 09:24:39.841091+00:00', '2026-10-15 09:26:49.860602+00:00'),
(6, 'Arjun Nair', NULL, 1, 2, 'Abu Dhabi', 'Rejected', 'Jasheer (Lead)', NULL, NULL, NULL, 'Visa designation rejected by mall security; resubmitting with NOC', '2026-10-15 09:24:39.841091+00:00', '2026-10-15 09:24:39.841091+00:00');
SELECT setval('store_badges_id_seq', (SELECT MAX(id) FROM store_badges));

-- Table: logistics_drops (1 rows)
INSERT INTO logistics_drops (id, project_id, store_id, assigned_supervisor_id, scheduled_drop_date, items_manifest, status, delivered_at, delivery_notes, created_at) VALUES
(1, 1, 1, 2, '2026-10-14', '1x Pop-up Display Stand, 2x Rollups, 5x Cartons', 'PENDING', NULL, NULL, '2026-10-14 16:33:49.913507+00:00');
SELECT setval('logistics_drops_id_seq', (SELECT MAX(id) FROM logistics_drops));

-- Table: logistics_collections (1 rows)
INSERT INTO logistics_collections (id, project_id, store_id, assigned_supervisor_id, scheduled_collection_date, items_to_collect, status, collected_at, collection_notes, created_at) VALUES
(1, 1, 1, 2, '2026-10-18', '1x Pop-up Display Stand, 2x Rollups', 'PENDING', NULL, NULL, '2026-10-14 16:33:50.043245+00:00');
SELECT setval('logistics_collections_id_seq', (SELECT MAX(id) FROM logistics_collections));

