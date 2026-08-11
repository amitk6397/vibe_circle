"""
Seed 10 dummy users into the VibeCam database.
Run from the backend directory:
    python scripts/seed_dummy_users.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from pwdlib import PasswordHash
from app.core.database import engine
from app.modules.users.models import User
from sqlalchemy.orm import Session

pwd_hasher = PasswordHash.recommended()

DUMMY_USERS = [
    {
        "id": "dummy-001",
        "email": "arjun.sharma@vibecam.app",
        "name": "Arjun Sharma",
        "username": "arjun_sharma",
        "age": 24,
        "bio": "Tech enthusiast, coffee lover ☕ | Building things one line at a time",
        "city": "Bangalore",
        "languages": ["English", "Hindi", "Kannada"],
        "interests": ["Technology", "Gaming", "Music"],
        "purposes": ["Friends", "Learn"],
        "is_online": True,
        "is_verified": True,
    },
    {
        "id": "dummy-002",
        "email": "priya.nair@vibecam.app",
        "name": "Priya Nair",
        "username": "priya_nair",
        "age": 22,
        "bio": "Artist & dreamer 🎨 | Spreading good vibes",
        "city": "Mumbai",
        "languages": ["English", "Hindi", "Malayalam"],
        "interests": ["Art", "Travel", "Photography"],
        "purposes": ["Friends", "Fun"],
        "is_online": True,
        "is_verified": True,
    },
    {
        "id": "dummy-003",
        "email": "rahul.verma@vibecam.app",
        "name": "Rahul Verma",
        "username": "rahul_v",
        "age": 27,
        "bio": "Fitness freak & foodie 💪🍕 | Delhi boy",
        "city": "Delhi",
        "languages": ["Hindi", "English"],
        "interests": ["Fitness", "Food", "Sports"],
        "purposes": ["Talk", "Friends"],
        "is_online": False,
        "is_verified": True,
    },
    {
        "id": "dummy-004",
        "email": "sneha.reddy@vibecam.app",
        "name": "Sneha Reddy",
        "username": "sneha_r",
        "age": 23,
        "bio": "Book worm 📚 | Aspiring writer | Hyderabad",
        "city": "Hyderabad",
        "languages": ["Telugu", "English", "Hindi"],
        "interests": ["Books", "Writing", "Movies"],
        "purposes": ["Learn", "Support"],
        "is_online": True,
        "is_verified": False,
    },
    {
        "id": "dummy-005",
        "email": "karan.mehta@vibecam.app",
        "name": "Karan Mehta",
        "username": "karan_m",
        "age": 25,
        "bio": "Music producer 🎵 | Always in the studio",
        "city": "Pune",
        "languages": ["Hindi", "English", "Marathi"],
        "interests": ["Music", "Technology", "Gaming"],
        "purposes": ["Fun", "Friends"],
        "is_online": True,
        "is_verified": True,
    },
    {
        "id": "dummy-006",
        "email": "ananya.das@vibecam.app",
        "name": "Ananya Das",
        "username": "ananya_das",
        "age": 21,
        "bio": "Kolkata girl 🌸 | Dance & fashion obsessed",
        "city": "Kolkata",
        "languages": ["Bengali", "English", "Hindi"],
        "interests": ["Dance", "Fashion", "Travel"],
        "purposes": ["Fun", "Friends"],
        "is_online": False,
        "is_verified": True,
    },
    {
        "id": "dummy-007",
        "email": "vikram.singh@vibecam.app",
        "name": "Vikram Singh",
        "username": "vikram_s",
        "age": 29,
        "bio": "Entrepreneur | Startup addict 🚀 | Jaipur",
        "city": "Jaipur",
        "languages": ["Hindi", "English"],
        "interests": ["Business", "Technology", "Fitness"],
        "purposes": ["Learn", "Talk"],
        "is_online": True,
        "is_verified": True,
    },
    {
        "id": "dummy-008",
        "email": "divya.krishna@vibecam.app",
        "name": "Divya Krishna",
        "username": "divya_k",
        "age": 26,
        "bio": "Yoga instructor 🧘 | Spreading peace & wellness",
        "city": "Chennai",
        "languages": ["Tamil", "English", "Hindi"],
        "interests": ["Yoga", "Health", "Nature"],
        "purposes": ["Support", "Talk"],
        "is_online": False,
        "is_verified": False,
    },
    {
        "id": "dummy-009",
        "email": "rishi.patel@vibecam.app",
        "name": "Rishi Patel",
        "username": "rishi_p",
        "age": 28,
        "bio": "Traveller | 30 countries & counting ✈️ | Ahmedabad",
        "city": "Ahmedabad",
        "languages": ["Gujarati", "Hindi", "English"],
        "interests": ["Travel", "Photography", "Food"],
        "purposes": ["Friends", "Fun", "Advice"],
        "is_online": True,
        "is_verified": True,
    },
    {
        "id": "dummy-010",
        "email": "meera.iyer@vibecam.app",
        "name": "Meera Iyer",
        "username": "meera_i",
        "age": 20,
        "bio": "Engineering student 🎓 | Coding & gaming on weekends",
        "city": "Coimbatore",
        "languages": ["Tamil", "English"],
        "interests": ["Technology", "Gaming", "Anime"],
        "purposes": ["Learn", "Friends"],
        "is_online": True,
        "is_verified": False,
    },
]

def seed():
    password_hash = pwd_hasher.hash("DummyPass@123")
    now = datetime.now(timezone.utc)

    with Session(engine) as session:
        added = 0
        for data in DUMMY_USERS:
            existing = session.get(User, data["id"])
            if existing:
                print(f"  >> Skipping {data['username']} (already exists)")
                continue
            user = User(
                id=data["id"],
                email=data["email"],
                password_hash=password_hash,
                name=data["name"],
                username=data["username"],
                age=data["age"],
                bio=data["bio"],
                city=data["city"],
                languages=data["languages"],
                interests=data["interests"],
                purposes=data["purposes"],
                is_online=data["is_online"],
                is_verified=data["is_verified"],
                status="active",
                role="user",
                last_active_at=now,
                created_at=now,
                updated_at=now,
            )
            session.add(user)
            added += 1
            print(f"  OK Added {data['name']} (@{data['username']})")

        session.commit()
        print(f"\nDone! {added} dummy users added.")

if __name__ == "__main__":
    seed()
