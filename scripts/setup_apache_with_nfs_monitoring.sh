#!/bin/bash

# Solicitar ao usuário o IP do EFS e o nome para o diretório
read -p "Informe o IP do EFS: " IP_EFS_Input
read -p "Informe o seu nome: " MY_NAME_Input

# Tratar espaços e caracteres especiais
IP_EFS=$(echo "$IP_EFS_Input" | sed 's/[^a-zA-Z0-9]/_/g')
MY_NAME=$(echo "$MY_NAME_Input" | sed 's/[^a-zA-Z0-9]/_/g')

# Montar o Filesystem NFS
sudo mkdir /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${IP_EFS}:/ /mnt/efs
echo "${IP_EFS}:/ /mnt/efs nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Criar um Diretório no NFS com "Meu Nome"
sudo mkdir /mnt/efs/${MY_NAME}

# Instalar o Apache
sudo yum install -y httpd

# Iniciar e Habilitar o Apache
sudo systemctl start httpd && sudo systemctl enable httpd

# Criar um Script de Verificação do Apache
cat << 'EOF' | sudo tee /usr/local/bin/check_apache_status.sh
#!/bin/bash

STATUS=$(systemctl is-active httpd)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ONLINE_FILE="/mnt/efs/${MY_NAME}/apache_status_online.txt"
OFFLINE_FILE="/mnt/efs/${MY_NAME}/apache_status_offline.txt"

if [ "$STATUS" = "active" ]; then
    echo "$TIMESTAMP Apache ONLINE" > "$ONLINE_FILE"
    [ -e "$OFFLINE_FILE" ] && rm "$OFFLINE_FILE"
else
    echo "$TIMESTAMP Apache OFFLINE" > "$OFFLINE_FILE"
    [ -e "$ONLINE_FILE" ] && rm "$ONLINE_FILE"
fi
EOF

sudo chmod +x /usr/local/bin/check_apache_status.sh

# Ajustar Permissões e Fuso Horário
sudo chown ec2-user:ec2-user /mnt/efs/${MY_NAME}
sudo timedatectl set-timezone America/Recife

# Automatizar a Execução do Script
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check_apache_status.sh") | crontab -