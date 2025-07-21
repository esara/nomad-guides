# config.hcl
mediator_image   = "docker.io/causelyai/mediator:v1.0.90-0-g0dfd785a724a1715"
mediator_cpu    = 2000
mediator_memory = 1024

ml_image   = "docker.io/causelyai/ml:v1.0.90-0-g0dfd785a724a1715"
ml_cpu    = 4000
ml_memory = 8192

nfs_server = "nfs.example.com"
nfs_path = "/exported/path"
