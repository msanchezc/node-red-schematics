resource "null_resource" "prepare_app_zip" {
  provisioner "local-exec" {
    command = <<EOF
        mkdir -p /tmp/app
        cd /tmp/app
        git init
        git remote add origin https://github.com/msanchezc/node-red-app
        git fetch
        git checkout -t origin/master
        zip -r app.zip *
        
EOF

  }
}

data "ibm_iam_user_profile" "user_profile" {
  iam_id = var.iam_id
}

data "ibm_space" "space" {
  name = "dev"
  org = data.ibm_iam_user_profile.user_profile.email
}

resource "ibm_service_instance" "service-instance" {
  name       = "cloudant"
  space_guid = data.ibm_space.space.id
  service    = "cloudantNoSQLDB"
  plan       = "lite"
  tags       = ["cluster-service", "cluster-bind"]
}

resource "ibm_service_key" "service-key" {
  name                  = "cloudant-key"
  service_instance_guid = ibm_service_instance.service-instance.id
}

resource "ibm_app" "app" {
  depends_on = [
    ibm_service_key.service-key,
    null_resource.prepare_app_zip,
  ]
  name              = var.app_name
  space_guid        = data.ibm_space.space.id
  app_path          = "/tmp/app.zip"
  wait_time_minutes = 10

  buildpack  = "https://github.com/cloudfoundry/nodejs-buildpack.git"
  
  memory                = 256
  instances             = 1
  disk_quota            = 512
  service_instance_guid = [ibm_service_instance.service-instance.id]
  app_version           = "1"
  command               = "npm start"
}