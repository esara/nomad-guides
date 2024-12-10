# config.hcl
datacenters = ["dc1"]

executor_image = "docker.io/causelyai/executor:v1.0.83-0-g6559d4c064695c5b"
executor__cpu    = 4000
executor__memory = 8192
