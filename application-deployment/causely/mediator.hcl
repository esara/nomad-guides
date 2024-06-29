# config.hcl
datacenters = ["dc1"]
cluster_name = "XXX"
gateway_host = "gw.causely.app"
gateway_token = "ZZZ"

mediator_image   = "docker.io/esara/mediator:0.0.41-0-gf8286156069e40a3"
mediator_cpu    = 2000
mediator_memory = 1024

ml_image   = "docker.io/esara/mediator_ml:0.0.41-0-gf8286156069e40a3"
ml_cpu    = 4000
ml_memory = 8192

nfs_server = "nfs.example.com"
nfs_path = "/exported/path"
