import os
import requests
import json

api_key = os.environ.get('JULES_API_KEY')
url = "https://jules.googleapis.com/v1alpha/sessions"
repo = "JMartynov/julespipeline"

payload = {
    "prompt": "test",
    "sourceContext": {
        "source": f"sources/github/{repo}",
        "githubRepoContext": {"startingBranch": "main"}
    },
    "automationMode": "AUTO_PUSH_BRANCH" # Speculative mode
}

headers = {"Content-Type": "application/json", "x-goog-api-key": api_key}
r = requests.post(url, headers=headers, data=json.dumps(payload))
print(r.status_code)
print(r.text)
