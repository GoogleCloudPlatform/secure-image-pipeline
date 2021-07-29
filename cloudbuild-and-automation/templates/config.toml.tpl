dryrun = false
scanner = "metadata"
failon = "critical"
metadata_client = "containeranalysis"
image_project = "${project_id}"
binauth_project = "${project_id}"
signer = "kms"
valid_repos = [
    "gcr.io/path/to/my/project",
]

trusted_builder-identities = [
    "email@example.com",
    "idcloudbuild.gserviceaccount.com"
]

trusted_projects = [
    "trusted-builds"
]

[checks]
diy      = false
nobody   = false
provenance = false
snakeoil = true

[server]
port = 8080
require_auth = false
username = "username here"
password = "bcrypt hash of your password"

[ejson]
dir = "/key"
secrets = "/etc/voucher/secrets.production.ejson"

[clair]
address = "localhost:6060"

[statsd]
addr = "localhost:8125"
sample_rate = 0.1
tags = []

[repository.grafeas]
org-url = "https://github.com/grafeas"

[[kms_keys]]
check = "snakeoil"
path = "${kms_key_name}"
algo = "SHA512"