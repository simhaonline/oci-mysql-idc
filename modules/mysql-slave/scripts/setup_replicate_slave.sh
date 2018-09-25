#!/bin/bash
set -e -x

function getMysqlMasterStatus() {
  base_dir="/home/opc"
  keyfile="mysql_keyfile"
  statusfile="master_status"

  sudo chmod 0600 $base_dir/$keyfile
  ssh -oStrictHostKeyChecking=no -i $base_dir/$keyfile opc@${master_private_ip} 'sudo cat ~/master_mysql_status' >/home/opc/master_status
  sleep 3
  mysqlstatus=$(sudo cat $base_dir/$statusfile)
  delimeter1=':'
  temp1=`echo $mysqlstatus | cut -d "$delimeter1" -f 2`
  temp2=`echo $mysqlstatus | cut -d "$delimeter1" -f 3`
  delimeter2=' '
  master_log_filename=`echo $temp1 | cut -d "$delimeter2" -f 1`
  master_log_fileposition=`echo $temp2 | cut -d "$delimeter2" -f 1`

  while [ -f $base_dir/$keyfile ]; do
    sudo rm $base_dir/$keyfile
  done

  while [ -f $base_dir/$master_status ]; do
    sudo rm $base_dir/$master_status
  done
}

# Install Mysql
# Using Latest version： https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
sudo wget -O /etc/yum.repos.d/mysql.rpm https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
cd /etc/yum.repos.d
sudo rpm -Uvh mysql.rpm

sudo yum install -y mysql-community-server

# Set httpport on firewall
sudo firewall-cmd --zone=public --permanent --add-port=3306/tcp
sudo firewall-cmd --reload

#At the initial start-up of the server, the server is initializeda superuser
#and account’root’@’localhost’ is created, when MySQL data directory is empty.
sudo systemctl start mysqld.service
sudo systemctl status mysqld.service

echo "MySQL installed successfully!"

sudo chmod 666 /etc/my.cnf
command sudo cat >>/etc/my.cnf <<'EOF'

skip-grant-tables
EOF
sudo chmod 644 /etc/my.cnf

sudo systemctl restart mysqld.service

mysql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Admin@1235';
EOF

sudo systemctl stop mysqld.service

##delete the last row
sudo sed -i '$d' /etc/my.cnf

sudo systemctl start mysqld.service
echo "MySQL started successfully."

mysql -uroot -pAdmin@1235 -e "SET sql_log_bin=OFF;"
mysql -uroot -pAdmin@1235 -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${mysql_root_password}';"
mysql -uroot -p${mysql_root_password} -e "SET sql_log_bin=ON;"
sudo systemctl stop mysqld.service


#Connect to MySQL Master Host to get MySQL Status Infromation.
getMysqlMasterStatus
if [ $master_log_filename ]&&[ $master_log_fileposition ]; then
  echo "MySQl Master Status infromation(File and Postion):"
  echo $master_log_filename
  echo $master_log_fileposition
else
  echo "Error: Can not get MySQL Master Status. Can not get status file"
fi

#Config my.cnf on MySQL Slave to connect with the Master
#server-id should be an Integer number between 1 and 2^32 – 1
#server-id should be different from any other server-ids in the same MySQL cluster.
#---------Attention---------
#In this program, the server-id of the Mysql Slave will begin with 3001
sudo chmod 666 /etc/my.cnf

command sudo echo "server-id=$1" >>/etc/my.cnf
sudo chmod 644 /etc/my.cnf

#Start mysql service
sudo systemctl start mysqld.service
echo "MySQL started successfully."
#waitForMysql

mysql -uroot -p${mysql_root_password} <<EOF
stop slave;
EOF

mysql -uroot -p${mysql_root_password} -e "change master to master_host='${master_private_ip}', master_user='${replicate_acount}', master_password='${replicate_password}',master_log_file='$master_log_filename',master_log_pos=$master_log_fileposition;"
mysql -uroot -p${mysql_root_password} <<EOF
start slave;
EOF

sleep 5

mysql -u ${replicate_acount} -h ${master_private_ip} -p${replicate_password} -s -e "exit"
if [ $? -ne 0 ]; then
    echo "Failed! MySQL Slave can not connect to Master. Please check your network."
else
    echo "Succeed! MySQL Slave can connect to Master"
fi

sleep 5

mysql -uroot -p${mysql_root_password} <<EOF
show slave status \G;
EOF
