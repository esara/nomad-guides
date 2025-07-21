# config.hcl
datacenters = ["dc1"]

executor_image = "docker.io/causelyai/executor:v1.0.90-0-g0dfd785a724a1715"
executor__cpu    = 4000
executor__memory = 8192
