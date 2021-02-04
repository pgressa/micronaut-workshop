#!/usr/bin/env bash

echo "Generate setup schema script ..."
cat >/home/opc/example/setup_schema.sh <<EOL
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
echo "Creating schema 'mnocidemo' on ATP instance..."
echo "CREATE USER mnocidemo IDENTIFIED BY \"${user_password}\";" | sqlplus -s admin/${admin_password}@${db_name}
echo "GRANT CONNECT, RESOURCE TO mnocidemo;" | sqlplus -s admin/${admin_password}@${db_name}
echo "GRANT UNLIMITED TABLESPACE TO mnocidemo;" | sqlplus -s admin/${admin_password}@${db_name}
echo "Schema 'mnocidemo' created!"
EOL

chown opc:opc /home/opc/example/setup_schema.sh
chmod u+x /home/opc/example/setup_schema.sh


echo  "Add prerouting rule to forward 8887 to 443 ..."
iptables -t nat -A PREROUTING -p tcp -i ens3 --dport 443 -j DNAT --to-destination $(ifconfig ens3 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2):8887

echo "Cleanup jidea config.."
rm -fr /home/opc/example/.idea
rm -rf /home/opc/.config/JetBrains/IdeaIC2020.3/workspace/*

rm -rf /home/opc/.bash_history