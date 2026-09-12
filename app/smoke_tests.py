import requests
import sys
TARGET_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost"
def test_health():
    try: return requests.get(f"{TARGET_URL}/health", timeout=5).status_code == 200
    except: return False
def test_content():
    try:
        r = requests.get(f"{TARGET_URL}/", timeout=5)
        return "Welcome" in r.text
    except: return False
def run_tests():
    if test_health() and test_content():
        print("✅ ALL SMOKE TESTS PASSED")
        return True
    print("❌ SMOKE TESTS FAILED")
    return False
if __name__ == "__main__":
    if not run_tests(): sys.exit(1)