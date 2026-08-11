from collections.abc import Generator
import re

from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings


class Base(DeclarativeBase):
    pass


connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}
engine = create_engine(settings.database_url, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def ensure_database_exists() -> None:
    """Validate the configured database and create a missing MySQL database."""
    url = make_url(settings.database_url)
    if url.get_backend_name() != "mysql":
        # SQLite creates its database file on first connection.
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return

    database_name = url.database
    if not database_name:
        raise RuntimeError("DATABASE_URL must include a MySQL database name.")
    if not re.fullmatch(r"[A-Za-z0-9_$]+", database_name):
        raise RuntimeError("MySQL database name contains unsupported characters.")

    server_engine = create_engine(
        url.set(database=None),
        pool_pre_ping=True,
        isolation_level="AUTOCOMMIT",
    )
    try:
        with server_engine.connect() as connection:
            exists = connection.execute(
                text(
                    "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA "
                    "WHERE SCHEMA_NAME = :database_name"
                ),
                {"database_name": database_name},
            ).scalar_one_or_none()
            if exists is None:
                connection.execute(
                    text(
                        f"CREATE DATABASE `{database_name}` "
                        "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                    )
                )
    except Exception as error:
        raise RuntimeError(
            "Could not connect to MySQL or create the configured database. "
            "Check DATABASE_URL and ensure the user has CREATE DATABASE permission."
        ) from error
    finally:
        server_engine.dispose()

    # Fail startup immediately if the newly checked database is not accessible.
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
