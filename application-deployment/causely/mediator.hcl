# config.hcl
mediator_image   = "docker.io/causelyai/mediator:v1.0.107-0-gf1ea7ea6bdbd72d1"
mediator_cpu    = 2000
mediator_memory = 1024

ml_image   = "docker.io/causelyai/ml:v1.0.107-0-gf1ea7ea6bdbd72d1"
ml_cpu    = 4000
ml_memory = 8192

nfs_server = "nfs.example.com"
nfs_path = "/exported/path"
