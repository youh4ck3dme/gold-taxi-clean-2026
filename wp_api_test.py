import urllib.request
import base64
import json

url = "https://larsenevans.com/wp-json/wp/v2/users/me"
username = "magnusevans"
password = "KkjO iCRF N2nQ udoz YjSl VSyW"

auth_str = f"{username}:{password}"
auth_bytes = auth_str.encode('utf-8')
auth_b64 = base64.b64encode(auth_bytes).decode('utf-8')

req = urllib.request.Request(url)
req.add_header("Authorization", f"Basic {auth_b64}")
req.add_header("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

try:
    with urllib.request.urlopen(req) as response:
        status = response.getcode()
        body = response.read().decode('utf-8')
        print(f"Status: {status}")
        print("Response Body:")
        print(json.dumps(json.loads(body), indent=2))
except Exception as e:
    print(f"Error: {e}")
