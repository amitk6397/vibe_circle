"""
Clean up all dummy users and their related records from the database.
Run from backend/ directory:
    python scripts/remove_dummy_data.py
"""
from sqlalchemy import create_engine, text

engine = create_engine("sqlite:///./vibecircle.db")

with engine.connect() as conn:
    # 1. Find dummy user IDs
    rows = conn.execute(
        text("SELECT id, name, email FROM users WHERE id LIKE 'dummy-%' OR email LIKE '%@vibecam.app'")
    ).fetchall()
    
    if not rows:
        print("No dummy users found in the database.")
    else:
        dummy_ids = [r[0] for r in rows]
        print(f"Found {len(rows)} dummy users to remove:")
        for r in rows:
            print(f" - ID: {r[0]}, Name: {r[1]}, Email: {r[2]}")
        
        # 2. Delete related records first to respect foreign keys / logic consistency
        tables_with_user_id = [
            ("user_subscriptions", "user_id"),
            ("user_wallets", "user_id"),
            ("wallet_transactions", "user_id"),
            ("creator_profiles", "user_id"),
            ("creator_applications", "user_id"),
            ("withdrawal_requests", "creator_id"),
            ("communities", "owner_id"),
            ("reports", "reporter_id"),
            ("audit_logs", "actor_id"),
            ("users", "id")
        ]
        
        for table, col in tables_with_user_id:
            # Check table existence in sqlite
            table_exists = conn.execute(
                text("SELECT name FROM sqlite_master WHERE type='table' AND name=:t"),
                {"t": table}
            ).fetchone()
            
            if table_exists:
                res = conn.execute(
                    text(f"DELETE FROM {table} WHERE {col} IN ({','.join([':id_' + str(i) for i in range(len(dummy_ids))])})"),
                    {f"id_{i}": val for i, val in enumerate(dummy_ids)}
                )
                print(f"Deleted {res.rowcount} rows from '{table}' table.")
        
        conn.commit()
        print("\nCleanup completed successfully!")
