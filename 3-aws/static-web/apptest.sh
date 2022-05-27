#!/bin/bash
yum update -y
amazon-linux-extras install epel -y
yum install stress -y
yum install -y httpd php
systemctl start httpd
systemctl enable httpd
echo '<center><h0><?php echo $_SERVER["SERVER_ADDR"]; ?></h1></center><br><br><?php phpinfo(); ?>' > /var/www/html/index.php
echo '<?php error_reporting(E_ERROR); $fp = fsockopen("9.0.2.165", 80, $errno, $errstr, 1);   if (!$fp) {echo "<h1>Success</h1>";} else {echo "<h1>Fail</h1>"; fclose($fp);}?>' > /var/www/html/appservertest.php

#!/bin/bash
yum update -y
amazon-linux-extras install epel -y
yum install stress -y
yum install -y httpd php
systemctl start httpd
systemctl enable httpd
echo '<center><h1><?php echo $_SERVER["SERVER_ADDR"]; ?></h1></center><br><br><?php phpinfo(); ?>' > /var/www/html/index.php

#!/bin/bash
yum update -y
sudo amazon-linux-extras install epel -y
sudo yum install stress -y
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum install -y httpd
systemctl start httpd
systemctl enable httpd
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo '<center><h1>Welcome to Server: <?php echo $_SERVER["SERVER_ADDR"]; ?></h1><br><br></center>' > /var/www/html/index.php