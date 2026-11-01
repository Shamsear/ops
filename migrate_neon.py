import psycopg2
import sys

CONN_STR = "postgresql://neondb_owner:npg_9iqIZwNHmo1p@ep-curly-darkness-b3di7l7f-pooler.c-4.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"

def run_migration():
    print("Connecting to Neon PostgreSQL...")
    try:
        conn = psycopg2.connect(CONN_STR)
        conn.autocommit = True
        cur = conn.cursor()
        print("Connected successfully!")
        
        with open(r"c:\ops\schema_neon.sql", "r", encoding="utf-8") as f:
            sql_script = f.read()
        
        print("Executing schema_neon.sql...")
        cur.execute(sql_script)
        print("Schema and Seed executed successfully!")
        
        # Verify tables created
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        tables = cur.fetchall()
        print("\nCreated Tables in Neon:")
        for t in tables:
            print(f" - {t[0]}")
            
        # Verify seeded users
        cur.execute("SELECT id, name, role, email FROM users;")
        users = cur.fetchall()
        print(f"\nSeeded Users ({len(users)}):")
        for u in users:
            print(f" - ID {u[0]}: {u[1]} ({u[2]}) - {u[3]}")
            
        cur.close()
        conn.close()
        print("\nAll database tables and seed data are ready in Neon!")
    except Exception as e:
        print(f"Error connecting or migrating: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_migration()
