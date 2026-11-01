import openpyxl
import psycopg2
from psycopg2.extras import execute_values
import os
import sys
import datetime
import re

DATABASE_URL = os.environ.get(
    'DATABASE_URL',
    'postgresql://neondb_owner:npg_9iqIZwNHmo1p@ep-curly-darkness-b3di7l7f-pooler.c-4.ap-southeast-1.aws.neon.tech/neondb?sslmode=require'
)

CITY_TO_EMIRATE = {
    'DXB': 'Dubai',
    'AUH': 'Abu Dhabi',
    'SHJ': 'Sharjah',
    'AJM': 'Ajman',
    'ALN': 'Al Ain',
    'RAK': 'Ras Al Khaimah',
    'FUJ': 'Fujairah',
    'UAQ': 'Umm Al Quwain',
    'DUBAI': 'Dubai',
    'ABU DHABI': 'Abu Dhabi',
    'SHARJAH': 'Sharjah',
    'AL AIN': 'Al Ain',
}

def clean_time(time_str):
    if not time_str:
        return '14:00:00', '22:00:00'
    text = str(time_str).lower().replace('\n', ' ')
    m = re.search(r'(\d+)\s*(am|pm)?\s*-\s*(\d+)\s*(am|pm)?', text)
    if m:
        h1, p1, h2, p2 = m.groups()
        h1 = int(h1)
        h2 = int(h2)
        if p1 == 'pm' and h1 < 12: h1 += 12
        if p2 == 'pm' and h2 < 12: h2 += 12
        if not p1 and p2 == 'pm' and h1 < 12: h1 += 12
        return f'{h1:02d}:00:00', f'{h2:02d}:00:00'
    return '14:00:00', '22:00:00'

def import_all():
    print("Connecting to Neon PostgreSQL...", flush=True)
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    # 1. Ensure Projects
    cur.execute("""
        INSERT INTO projects (name, client_name, start_date, end_date, status)
        VALUES 
            ('OGX Roadshow 2026', 'Johnson & Johnson', '2026-09-30', '2026-10-31', 'ACTIVE'),
            ('Sadia Sampling Campaign', 'Sadia ME', '2026-10-23', '2026-11-30', 'ACTIVE')
        ON CONFLICT DO NOTHING;
    """)
    conn.commit()

    cur.execute("SELECT id, name FROM projects;")
    projects_map = {name: pid for pid, name in cur.fetchall()}
    ogx_id = projects_map.get('OGX Roadshow 2026')
    sadia_id = projects_map.get('Sadia Sampling Campaign')

    # Load existing users, promoters, stores
    cur.execute("SELECT id, name FROM users;")
    users_cache = {name.lower().strip(): uid for uid, name in cur.fetchall()}

    cur.execute("SELECT id, name FROM promoters;")
    promoters_cache = {name.lower().strip(): pid for pid, name in cur.fetchall()}

    cur.execute("SELECT id, store_name FROM stores;")
    stores_cache = {name.lower().strip(): sid for sid, name in cur.fetchall()}

    def get_or_create_supervisor(name):
        clean = (name or 'Babar Abdul Majeed').strip()
        k = clean.lower()
        if k in users_cache:
            return users_cache[k]
        email = re.sub(r'[^a-zA-Z0-9]', '', clean.lower()) + '@imlme.com'
        cur.execute("""
            INSERT INTO users (name, email, phone, password_hash, role)
            VALUES (%s, %s, '+971 50 000 0000', 'super123', 'SUPERVISOR')
            RETURNING id;
        """, (clean, email))
        uid = cur.fetchone()[0]
        users_cache[k] = uid
        return uid

    def get_or_create_promoter(name, role='PROMOTER'):
        clean = (name or 'Field Staff').strip()
        k = clean.lower()
        if k in promoters_cache:
            return promoters_cache[k]
        cur.execute("""
            INSERT INTO promoters (name, phone, staff_role)
            VALUES (%s, '+971 55 000 0000', %s)
            RETURNING id;
        """, (clean, role))
        pid = cur.fetchone()[0]
        promoters_cache[k] = pid
        return pid

    def get_or_create_store(name, retailer, emirate, branch_code=None, cus_code=None, chain=None, city=None, smn=None, lead=None):
        clean = name.strip()
        k = clean.lower()
        if k in stores_cache:
            sid = stores_cache[k]
            cur.execute("""
                UPDATE stores 
                SET customer_code = COALESCE(customer_code, %s),
                    chain = COALESCE(chain, %s),
                    city = COALESCE(city, %s),
                    smn_contact = COALESCE(smn_contact, %s),
                    merchandiser_lead = COALESCE(merchandiser_lead, %s)
                WHERE id = %s;
            """, (cus_code, chain, city, smn, lead, sid))
            return sid
        
        cur.execute("""
            INSERT INTO stores (store_name, retailer, emirate, branch_code, customer_code, chain, city, smn_contact, merchandiser_lead)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (clean, retailer, emirate, branch_code, cus_code, chain, city, smn, lead))
        sid = cur.fetchone()[0]
        stores_cache[k] = sid
        return sid

    # ==========================================
    # 2. PARSE SADIA SAMPLING PLAN
    # ==========================================
    sadia_file = 'Timemap - Sadia Oct-Nov 2026.xlsx'
    schedules_to_insert = []
    
    if os.path.exists(sadia_file):
        print(f"Reading {sadia_file}...", flush=True)
        wb = openpyxl.load_workbook(sadia_file, data_only=True)
        ws = wb['Sampling Plan']
        
        header_row = [c for c in next(ws.iter_rows(min_row=2, max_row=2, values_only=True))]
        date_cols = {}
        for col_idx in range(15, len(header_row)):
            val = header_row[col_idx]
            if isinstance(val, (datetime.datetime, datetime.date)):
                date_cols[col_idx] = val.strftime('%Y-%m-%d')
            elif val and str(val).startswith('2026'):
                date_cols[col_idx] = str(val)[:10]

        print(f"Sadia: Found {len(date_cols)} dates.", flush=True)

        for r in range(3, ws.max_row + 1):
            row = [c for c in next(ws.iter_rows(min_row=r, max_row=r, values_only=True))]
            if not row or len(row) < 3 or not row[1] or not row[2]:
                continue
            
            cus_code = str(row[1]).strip()
            cus_name = str(row[2]).strip()
            chain = str(row[3] or 'GENERAL').strip()
            city = str(row[4] or 'DXB').strip()
            emirate = CITY_TO_EMIRATE.get(city.upper(), 'Dubai')
            smn = str(row[5] or '').strip()
            lead_name = str(row[6] or 'Babar Abdul Majeed').strip()
            merchandiser = str(row[7] or 'Abdul Jabbar').strip()
            hours_val = float(row[8] or 5.0)
            timings = str(row[9] or '5 pm - 10 pm').strip()
            staffing_desc = str(row[11] or '1 promoter').strip()

            start_t, end_t = clean_time(timings)
            sup_id = get_or_create_supervisor(lead_name)
            prom_id = get_or_create_promoter(merchandiser)
            store_id = get_or_create_store(
                name=cus_name,
                retailer=chain,
                emirate=emirate,
                cus_code=cus_code,
                chain=chain,
                city=city,
                smn=smn,
                lead=lead_name
            )

            for col_idx, date_str in date_cols.items():
                if col_idx < len(row):
                    cell_val = row[col_idx]
                    if cell_val is not None and str(cell_val).strip() not in ('', '0', '-'):
                        try:
                            sessions = int(float(str(cell_val).strip()))
                        except:
                            sessions = 1
                        
                        role = 'PROMOTER'
                        if 'chef' in staffing_desc.lower() and sessions > 1:
                            role = 'CHEF'
                        elif 'mascot' in staffing_desc.lower() and sessions == 1:
                            role = 'MASCOT'

                        schedules_to_insert.append((
                            sadia_id, store_id, prom_id, sup_id, date_str,
                            start_t, end_t, 'None', hours_val, 'SCHEDULED',
                            role, sessions, staffing_desc
                        ))

    # ==========================================
    # 3. PARSE OGX LULU PLAN
    # ==========================================
    ogx_file = 'Temp OGX Promoters in Lulu - Plan.xlsx'
    if os.path.exists(ogx_file):
        print(f"Reading {ogx_file}...", flush=True)
        wb = openpyxl.load_workbook(ogx_file, data_only=True)
        ws = wb['OGX Lulu Plan']
        
        header_row = [c for c in next(ws.iter_rows(min_row=3, max_row=3, values_only=True))]
        date_cols = {}
        for col_idx in range(8, len(header_row)):
            val = header_row[col_idx]
            if isinstance(val, (datetime.datetime, datetime.date)):
                date_cols[col_idx] = val.strftime('%Y-%m-%d')
            elif val and str(val).startswith('2026'):
                date_cols[col_idx] = str(val)[:10]

        print(f"OGX: Found {len(date_cols)} dates.", flush=True)
        sup_id = get_or_create_supervisor('Jasheer Kanhirathil')

        ogx_p_idx = 1
        for r in range(5, ws.max_row + 1):
            row = [c for c in next(ws.iter_rows(min_row=r, max_row=r, values_only=True))]
            if not row or len(row) < 3 or not row[2] or str(row[2]).strip() == 'TOTAL':
                continue
            
            store_full = str(row[2]).strip()
            emirate_str = str(row[3]).strip().upper()
            emirate = CITY_TO_EMIRATE.get(emirate_str, 'Dubai')
            timings = str(row[4] or '2PM - 10PM').strip()
            breaks = str(row[5] or '5PM - 5:45PM').strip()
            hours_val = 8.0

            branch_match = re.search(r'\((\d+)\)', store_full)
            b_code = branch_match.group(1) if branch_match else None

            prom_id = get_or_create_promoter(f'OGX Promoter {ogx_p_idx}')
            ogx_p_idx += 1
            store_id = get_or_create_store(
                name=store_full,
                retailer='Lulu',
                emirate=emirate,
                branch_code=b_code,
                chain='LULU HYPERMARKET',
                lead='Jasheer Kanhirathil'
            )
            start_t, end_t = clean_time(timings)

            for col_idx, date_str in date_cols.items():
                if col_idx < len(row):
                    cell_val = row[col_idx]
                    if cell_val is not None and str(cell_val).strip().lower() in ('x', '1', 'yes'):
                        schedules_to_insert.append((
                            ogx_id, store_id, prom_id, sup_id, date_str,
                            start_t, end_t, breaks, hours_val, 'SCHEDULED',
                            'PROMOTER', 1, 'Lulu Saver Week 2026'
                        ))

    # Commit users and stores first
    conn.commit()

    # Bulk Insert Schedules using execute_values
    print(f"Bulk inserting {len(schedules_to_insert)} shifts into Neon DB...", flush=True)
    insert_sql = """
        INSERT INTO timemap_schedules 
        (project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status, staff_role, session_count, notes)
        VALUES %s;
    """
    execute_values(cur, insert_sql, schedules_to_insert, page_size=500)
    conn.commit()

    # Verify counts
    cur.execute("SELECT count(*) FROM stores;")
    total_stores = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM timemap_schedules;")
    total_shifts = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM users WHERE role = 'SUPERVISOR';")
    total_sups = cur.fetchone()[0]

    print("\n==============================================", flush=True)
    print("SUCCESS: EXCEL INGESTION COMPLETED!", flush=True)
    print(f"Total Real Stores in Database: {total_stores}", flush=True)
    print(f"Total Active Campaign Shifts: {total_shifts}", flush=True)
    print(f"Total Field Supervisors: {total_sups}", flush=True)
    print("==============================================", flush=True)

    cur.close()
    conn.close()

if __name__ == '__main__':
    import_all()
