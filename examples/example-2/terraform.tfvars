# OCI Authentication
tenancy_ocid = "<tenancy OCID>"
user_ocid = "<user OCID>"
fingerprint = "<PEM key fingerprint>"
private_key_path = "<path to the private key that matches the fingerprint above>"

# Region
region = "<region in which to operate, example: us-ashburn-1, us-phoenix-1>"

# Compartment
compartment_ocid = "<compartment OCID>"

# Instance Configration
ssh_authorized_keys = "<path to public key>"
ssh_private_key = "<path to private key>"

# MySQL Configration
#Set a initial MySQL password for the account 'root@localhost'
#MySQL's validate_password plugin is installed by default.
#This will require that passwords contain at least one upper case letter,
#one lower case letter, one digit, and one special character,
#and that the total password length is at least 8 characters.
master_mysql_root_password = "<password of 'root@localhost' on the master node>"
slaves_mysql_root_password = "<password of 'root@localhost' on the slave nodes>"
master_slaves_replicate_acount = "<mysql account for replication between the master node and the slave nodes>"
master_slaves_replicate_password = "<password of the mysql replication account>"