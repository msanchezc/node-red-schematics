resource "null_resource" "prepare_app_zip" {
  provisioner "local-exec" {
    command = <<EOF
        mkdir -p /tmp/app
        cd /tmp/app
        git init
        git remote add origin https://github.com/msanchezc/node-red-app
        git fetch
        git checkout -t origin/master
        zip -r /tmp/app.zip *
        
EOF

  }
}

data "ibm_space" "space" {
  name = var.space
  org = var.org
}

resource "ibm_service_instance" "cloudant-service" {
  name       = "cloudant"
  space_guid = data.ibm_space.space.id
  service    = "cloudantNoSQLDB"
  plan       = "lite"
  tags       = ["cluster-service", "cluster-bind"]
}

resource "ibm_service_key" "cloudant-key" {
  name                  = "cloudant-key"
  service_instance_guid = ibm_service_instance.cloudant-service.id
}

data "ibm_app_domain_shared" "domain" {
  name = "mybluemix.net"
}

resource "random_pet" "hostname" {
  length    = 3
  prefix    = var.app_name
  separator = "-"
}

resource "ibm_app_route" "route" {
  domain_guid = data.ibm_app_domain_shared.domain.id
  space_guid  = data.ibm_space.space.id
  host        = random_pet.hostname.id
}

resource "ibm_app" "app" {
  depends_on = [
    ibm_service_key.cloudant-key,
    null_resource.prepare_app_zip,
  ]
  name              = var.app_name
  space_guid        = data.ibm_space.space.id
  app_path          = "/tmp/app.zip"
  wait_time_minutes = 30

  buildpack  = "https://github.com/cloudfoundry/nodejs-buildpack.git"
  
  memory                = 256
  instances             = 1
  disk_quota            = 512
  route_guid            = [ibm_app_route.route.id]
  service_instance_guid = [ibm_service_instance.cloudant-service.id]
  app_version           = "1"
  command               = "npm start"
}