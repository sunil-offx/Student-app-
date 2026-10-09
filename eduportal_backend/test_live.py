import json
import urllib.request

import pytest


def _login(username, password, role):
    req = urllib.request.Request(
        "http://127.0.0.1:8000/api/auth/login",
        data=json.dumps({"username": username, "password": password, "role": role}).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read().decode())
            print(f'SUCCESS [{role.upper()}]: Logged in as "{data["user"]["full_name"]}"')
    except Exception as exc:  # pragma: no cover - smoke test only
        print(f"FAILED [{role.upper()}]:", exc)


@pytest.mark.skip(reason="Manual smoke test against a live backend; not part of the automated test suite.")
def test_login():
    _login("admin", "admin123", "admin")
    _login("priya", "priya123", "teacher")
    _login("rahul", "rahul123", "student")


if __name__ == "__main__":
    _login("admin", "admin123", "admin")
    _login("priya", "priya123", "teacher")
    _login("rahul", "rahul123", "student")
