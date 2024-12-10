# config.hcl
mediator_image   = "docker.io/causelyai/mediator:v1.0.83-0-g6559d4c064695c5b"
mediator_cpu    = 2000
mediator_memory = 1024

ml_image   = "docker.io/causelyai/mediator_ml:v1.0.83-0-g6559d4c064695c5b"
ml_cpu    = 4000
ml_memory = 8192

nfs_server = "nfs.example.com"
nfs_path = "/exported/path"
