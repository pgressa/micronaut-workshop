#!/usr/bin/env bash

echo "Extending projector env ..."
mkdir -p /etc/systemd/system/projector.service.d
cat >/etc/systemd/system/projector.service.d/local.conf <<EOL
[Service]
Environment=TNS_ADMIN=/tmp/wallet
Environment=DB_USER=mnocidemo
Environment=DB_PASSWORD=${user_password}
Environment=DB_NAME=${db_name}
Environment=DB_SCHEMA=mnocidemo
Environment=DB_ADMIN_PASSWORD=${admin_password}
Environment=ATP_ID=${db_id}
EOL

echo "Reloading projector ..."
systemctl daemon-reload
systemctl restart projector.service

echo "Generate setup schema script ..."
export OCI_CLI_AUTH=instance_principal
cat >/home/opc/setup_schema.sh <<EOL
#!/usr/bin/env bash

set -e
set -o pipefail


# download wallet
echo "Downloading wallet..."
oci db autonomous-database generate-wallet --autonomous-database-id ${db_id} --file /tmp/wallet.zip --password ${wallet_password}
echo "Wallet downloaded!"

# unzip wallet
unzip /tmp/wallet.zip -d /tmp/wallet

echo "Creating schema..."
# fix the sqlnet.ora file
sed -i 's/?\/network\/admin/\/tmp\/wallet/g' /tmp/wallet/sqlnet.ora
export TNS_ADMIN=/tmp/wallet

# create schema user
echo "Creating user 'mnocidemo' on ATP instance..."
echo "CREATE USER mnocidemo IDENTIFIED BY \"${user_password}\";" | sqlplus -s admin/${admin_password}@${db_name}
echo "GRANT CONNECT, RESOURCE TO mnocidemo;" | sqlplus -s admin/${admin_password}@${db_name}
echo "GRANT UNLIMITED TABLESPACE TO mnocidemo;" | sqlplus -s admin/${admin_password}@${db_name}
echo "User 'mnocidemo' created!"
EOL

chown opc:opc /home/opc/setup_schema.sh
chmod u+x /home/opc/setup_schema.sh

sh /home/opc/setup_schema.sh > /home/opc/setup_schema.out

echo  "Add prerouting rule to forward 8887 to 443 ..."
iptables -t nat -A PREROUTING -p tcp -i ens3 --dport 443 -j DNAT --to-destination $(ifconfig ens3 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2):8887

echo "Cleanup jidea config.."
rm -fr /home/opc/example/.idea
rm -rf /home/opc/.config/JetBrains/IdeaIC2020.3/workspace/*

rm -rf /home/opc/.bash_history