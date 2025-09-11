# config.hcl
datacenters = ["dc1"]

executor_image = "docker.io/causelyai/executor:v1.0.107-0-gf1ea7ea6bdbd72d1"
executor__cpu    = 4000
executor__memory = 8192
