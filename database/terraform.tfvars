############################################
# Naming
############################################

name = "acme"

environment = "resilient"


############################################
# Database Configuration
############################################

database_name = "appdb"

engine = "aurora-mysql"

engine_version = "8.0.mysql_aurora.3.08.0"

instance_class = "db.r6g.large"


############################################
# Aurora Global Database
############################################

global_cluster_identifier = "acme-resilient-global"


############################################
# Tags
############################################

tags = {
  Project     = "Project5"
  Environment = "resilient"
  ManagedBy   = "Terraform"
}