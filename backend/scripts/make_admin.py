"""Make a user admin by email — run from backend/ directory."""
from sqlalchemy import create_engine, text

engine = create_engine("sqlite:///./vibecircle.db")

EMAIL = "amitk15042003@gmail.com"

with engine.connect() as conn:
    row = conn.execute(
        text("SELECT id, name, email, role FROM users WHERE email = :e"),
        {"e": EMAIL},
    ).fetchone()

    if not row:
        print(f"❌ User not found: {EMAIL}")
    else:
        print(f"Found: id={row[0]}, name={row[1]}, email={row[2]}, role={row[3]}")
        conn.execute(
            text("UPDATE users SET role = 'admin' WHERE email = :e"),
            {"e": EMAIL},
        )
        conn.commit()
        # Verify
        updated = conn.execute(
            text("SELECT role FROM users WHERE email = :e"),
            {"e": EMAIL},
        ).fetchone()
        print(f"✅ Role updated → {updated[0]}")
