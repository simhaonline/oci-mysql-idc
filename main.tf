############################################
# MySQL Master Instance
############################################
module "mysql-master" {
  source              = "./modules/mysql-master"
  number_of_master    = "${var.master_count}"
  availability_domain = "${var.master_ad}"
  compartment_ocid    = "${var.compartment_ocid}"
  master_display_name = "${var.master_display_name}"
  image_id            = "${var.master_image_id}"
  shape               = "${var.master_shape}"
  label_prefix        = "${var.label_prefix}"
  subnet_id           = "${var.master_subnet_id}"
  http_port           = "${var.http_port}"
  mysql_root_password = "${var.master_mysql_root_password}"
  replicate_acount    = "${var.master_slaves_replicate_acount}"
  replicate_password  = "${var.master_slaves_replicate_password}"

  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  user_data           = "${var.master_user_data}"
}

############################################
# MySQL Slave Instance(s)
############################################
module "mysql-slave" {
  source               = "./modules/mysql-slave"
  number_of_slaves     = "${var.slave_count}"
  availability_domains = "${var.slave_ads}"
  compartment_ocid     = "${var.compartment_ocid}"
  slave_display_name   = "${var.slave_display_name}"
  image_id             = "${var.slave_image_id}"
  shape                = "${var.slave_shape}"
  label_prefix         = "${var.label_prefix}"
  subnet_ids           = "${var.slave_subnet_ids}"
  http_port            = "${var.http_port}"
  master_public_ip     = "${module.mysql-master.public_ip}"

  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  ssh_private_key            = "${var.ssh_private_key}"
  slaves_mysql_root_password = "${var.slaves_mysql_root_password}"
  replicate_acount           = "${var.master_slaves_replicate_acount}"
  replicate_password         = "${var.master_slaves_replicate_password}"
}