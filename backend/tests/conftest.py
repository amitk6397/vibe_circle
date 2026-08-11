import os
from pathlib import Path


TEST_DB = Path(__file__).parent / "test_vibecircle.db"
if TEST_DB.exists():
    try:
        TEST_DB.unlink()
    except Exception:
        pass

os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB.as_posix()}"
os.environ["APP_ENV"] = "test"
os.environ["SECRET_KEY"] = "test-secret-key-that-is-long-enough-for-tests"
os.environ["AGORA_APP_ID"] = "0" * 32
os.environ["AGORA_APP_CERTIFICATE"] = "1" * 32


def pytest_sessionfinish(session, exitstatus):
    from app.core.database import engine

    engine.dispose()
    if TEST_DB.exists():
        try:
            TEST_DB.unlink()
        except Exception:
            pass
