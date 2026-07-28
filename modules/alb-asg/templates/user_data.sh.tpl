#!/bin/bash

dnf update -y
dnf install -y nginx mariadb105 jq

systemctl enable nginx
systemctl start nginx

############################################
# Instance Metadata (IMDSv2)
############################################

REGION="${aws_region}"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

############################################
# Database Configuration Check
############################################

if [ -n "${db_secret_arn}" ]; then

    echo "Database secret found. Configuring database connection..."

    SECRET_JSON=$(aws secretsmanager get-secret-value \
      --region "${aws_region}" \
      --secret-id "${db_secret_arn}" \
      --query SecretString \
      --output text)

    DB_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
    DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')
    DB_ENDPOINT=$(echo "$SECRET_JSON" | jq -r '.endpoint')

    mysql -h "$DB_ENDPOINT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "
      CREATE TABLE IF NOT EXISTS appdb.visits (
        id INT AUTO_INCREMENT PRIMARY KEY,
        region VARCHAR(20),
        instance_id VARCHAR(30),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      INSERT INTO appdb.visits (region, instance_id) VALUES ('$REGION', '$INSTANCE_ID');
    "

    RESULTS=$(mysql -h "$DB_ENDPOINT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -N -e "SELECT region, instance_id, created_at FROM appdb.visits ORDER BY id DESC LIMIT 10;")

    ROWS_HTML=""
    while IFS=$'\t' read -r r i t; do
      ROWS_HTML="$ROWS_HTML<li>$r | $i | $t</li>"
    done <<< "$RESULTS"

    cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Project 5 Resilient Architecture</title></head>
<body>
<h1>Project 5 Multi-Region Failover Test</h1>
<p>Region: $REGION</p>
<p>Instance ID: $INSTANCE_ID</p>
<h2>Recent database writes (proves DB read+write):</h2>
<ul>$ROWS_HTML</ul>
</body>
</html>
EOF

else

    echo "Database not configured yet. Skipping database connection."

    cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Project 5 Resilient Architecture</title></head>
<body>
<h1>Project 5 Multi-Region Failover Test</h1>
<p>Region: $REGION</p>
<p>Instance ID: $INSTANCE_ID</p>
<p>Database Status: not yet configured (bootstrap phase)</p>
</body>
</html>
EOF

fi

systemctl restart nginx
