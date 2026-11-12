# makes a macOS configuration profile with nekozame os's helium settings (chromium
# on macOS only takes forced settings from a profile the person approves)
#   profile.py POLICY_JSON_URL OUT.mobileconfig
import json, plistlib, sys, urllib.request, uuid

policy = json.load(urllib.request.urlopen(sys.argv[1]))
payload = {"PayloadType": "net.imput.helium", "PayloadIdentifier": "nekozame.helium.settings",
           "PayloadUUID": str(uuid.uuid4()).upper(), "PayloadVersion": 1, **policy}
profile = {"PayloadType": "Configuration", "PayloadVersion": 1,
           "PayloadIdentifier": "nekozame.helium", "PayloadUUID": str(uuid.uuid4()).upper(),
           "PayloadDisplayName": "nekozame: Helium settings",
           "PayloadDescription": "The same extensions and privacy settings as Zen in nekozame os.",
           "PayloadScope": "User", "PayloadContent": [payload]}
plistlib.dump(profile, open(sys.argv[2], "wb"))
