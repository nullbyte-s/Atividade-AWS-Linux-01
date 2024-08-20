<h1 align="center">Atividade Prática de Linux na AWS</h1>

As seguintes instruções foram passadas como atividade prática no contexto da AWS e do Linux:

    𝐑𝐞𝐪𝐮𝐢𝐬𝐢𝐭𝐨𝐬 𝐀𝐖𝐒:

        • Gerar uma chave pública para acesso ao ambiente;
        • Criar 1 instância EC2 com o sistema operacional Amazon Linux 2 (Família t3.small, 16 GB SSD);
        • Gerar 1 elastic IP e anexar à instância EC2;
        • Liberar as portas de comunicação para acesso público: (22/TCP, 111/TCP e UDP, 2049/TCP/UDP, 80/TCP, 443/TCP).

    𝐑𝐞𝐪𝐮𝐢𝐬𝐢𝐭𝐨𝐬 𝐧𝐨 𝐋𝐢𝐧𝐮𝐱:

        • Configurar o NFS entregue;
        • Criar um diretório dentro do filesystem do NFS com seu nome;
        • Subir um apache no servidor - o apache deve estar online e rodando;
        • Criar um script que valide se o serviço esta online e envie o resultado da validação para o seu diretorio no nfs;
        • O script deve conter - Data HORA + nome do serviço + Status + mensagem personalizada de ONLINE ou offline;
        • O script deve gerar 2 arquivos de saida: 1 para o serviço online e 1 para o serviço OFFLINE;
        • Preparar a execução automatizada do script a cada 5 minutos.
        • Fazer o versionamento da atividade;
        • Fazer a documentação explicando o processo de instalação do Linux.

Nesse sentido, o presente documento atenderá a essas demandas, ao descrever todos os passos necessários para a configuração de um ambiente Linux na AWS, utilizando uma instância EC2 com Amazon Linux 2. As etapas incluem a criação de uma VPC, configuração de NFS, instalação do Apache, criação de um script de monitoramento e automatização de tarefas. Foram utilizados nomes de exemplos, para facilitar a compreensão da associação entre os recursos.

## Sumário

1. **[Parte I: Configuração na AWS](#parte-i-configuração-na-aws)**
    * [1. Criar uma VPC](#1-criar-uma-vpc)
    * [2. Criar e associar uma Subnet pública](#2-criar-e-associar-uma-subnet-pública)
    * [3. Criar um Internet Gateway e associar à VPC recém-criada](#3-criar-um-internet-gateway-e-associar-à-vpc-recém-criada)
    * [4. Criar e configurar uma Route Table](#4-criar-e-configurar-uma-route-table)
    * [5. Criar uma Instância EC2](#5-criar-uma-instância-ec2)
    * [6. Configurar o Security Group](#6-configurar-o-security-group)
    * [7. Rodar Instância EC2 e Anexar um Elastic IP](#7-rodar-instância-ec2-e-anexar-um-elastic-ip)

2. **[Parte II: Configuração no Linux](#parte-ii-configuração-no-linux)**
    * [1. Acessar a Instância EC2 via SSH](#1-acessar-a-instância-ec2-via-ssh)
    * [2. Criar um Sistema de Arquivos EFS](#2-criar-um-sistema-de-arquivos-efs)
    * [3. Montar o Filesystem NFS](#3-montar-o-filesystem-nfs)
    * [4. Criar um Diretório no NFS com "Meu Nome"](#4-criar-um-diretório-no-nfs-com-meu-nome)
    * [5. Instalar o Apache](#5-instalar-o-apache)
    * [6. Iniciar e Habilitar o Apache](#6-iniciar-e-habilitar-o-apache)
    * [7. Criar um Script de Verificação do Apache](#7-criar-um-script-de-verificação-do-apache)
    * [8. Ajustar Permissões e Fuso Horário](#8-ajustar-permissões-e-fuso-horário)
    * [9. Automatizar a Execução do Script](#9-automatizar-a-execução-do-script)

3. **[Parte III: Versionamento e Documentação](#parte-iii-versionamento-e-documentação)**
    * [1. Inicializar um Repositório Git](#1-inicializar-um-repositório-git)
    * [2. Subir o Código para o Repositório Remoto](#2-subir-o-código-para-o-repositório-remoto)

4. **[Parte IV: Acessando o servidor Apache](#parte-iv-acessando-o-servidor-apache)**
    * [1. Preparando um site de exemplo](#1-preparando-um-site-de-exemplo)
    * [2. Configurando acesso seguro e exclusivo ao HTTPS](#2-configurando-acesso-seguro-e-exclusivo-ao-https)

5. **[Finalizando](#finalizando)**
    * [Testes de Acesso Público](#testes-de-acesso-público)
    * [Garantindo a Consistência](#garantindo-a-consistência)

## Parte I: Configuração na AWS

### 1. Criar uma VPC
Criar uma Virtual Private Cloud (VPC) para o ambiente:

- **Nome**: `atividade-linux-VPC`
- **IPv4 CIDR block**: Escolher um bloco CIDR (ex: `10.0.0.0/16`).

### 2. Criar e associar uma Subnet pública
- **Nome**: `atividade-linux-subnet`
- **VPC**: Selecionar `atividade-linux-VPC`
- **IPv4 CIDR block**: Escolher um bloco CIDR (ex: `10.0.1.0/24`).

### 3. Criar um Internet Gateway e associar à VPC recém-criada
- **Nome**: `atividade-linux-IGW`
- **VPC**: Selecionar `atividade-linux-VPC`
- **Ação**: Clicar em "Attach to VPC".

### 4. Criar e configurar uma Route Table
- **Nome**: `atividade-linux-RouteTable`
- **VPC**: Selecionar `atividade-linux-VPC`
- **Editar Rota**: Adicionar uma rota para `0.0.0.0/0` apontando para `atividade-linux-IGW`.
- **Associar Subnet**: Adicionar a subnet `atividade-linux-subnet` à Route Table.

### 5. Criar uma Instância EC2
- **Nome**: `atividade-linux-EC2`
- **Tipo de instância**: `t3.small`
- **Sistema Operacional**: Amazon Linux 2
- **Armazenamento**: 16 GB SSD
- **Par de chaves**: `atividade-linux-KeyPair` (armazenar a chave privada em local seguro)
- **VPC**: `atividade-linux-VPC`
- **Subnet**: `atividade-linux-subnet`

### 6. Configurar o Security Group
- **Nome**: `AtividadeLinuxSGP`
- **Regras de Inbound**:
  - Porta 22/TCP: Acesso SSH
  - Porta 111/TCP e UDP: Acesso NFS
  - Porta 2049/TCP e UDP: Acesso NFS
  - Porta 80/TCP: Acesso HTTP
  - Porta 443/TCP: Acesso HTTPS

### 7. Rodar Instância EC2 e Anexar um Elastic IP
- Iniciar a instância `atividade-linux-EC2`.
- Gerar um Elastic IP e anexar à instância `atividade-linux-EC2`.

## Parte II: Configuração no Linux

### 1. Acessar a Instância EC2 via SSH

**Linux**:
```bash
ssh -i ~/.ssh/atividade-linux-KeyPair.pem ec2-user@<Elastic_IP>
```

**Windows**:
```bat
REM Variável de ambiente: %USERPROFILE% (cmd) ou $env:USERPROFILE (powershell)
ssh -i "%USERPROFILE%\.ssh\atividade-linux-KeyPair.pem" ec2-user@<Elastic_IP>
```

- Observação: no Windows, é necessário limitar as permissões de acesso ao arquivo .PEM apenas para o usuário pertinente, sem o que o servidor SSH acusará o erro `bad permissions` e não permitirá a conexão. Nesse sentido, a seguinte configuração é recomendada: *Usuário Atual*: Controle Total ("Leitura e Execução", "Leitura" e "Gravação"); *Administradores, Sistema e outros usuários*: remover as permissões atribuídas por herança.

### 2. Criar um Sistema de Arquivos EFS
- Acessar o serviço **EFS (Elastic File System)** na AWS.
- Clicar em "Create file system".
- (Opcional) Nomear o sistema de arquivos, ex: **Atividade-Linux-NFS**.
- Selecionar a VPC `atividade-linux-VPC`.

### 3. Montar o Filesystem NFS
Criar o ponto de montagem e montar o sistema de arquivos EFS:
```bash
sudo mkdir /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <IP_EFS>:/ /mnt/efs

# Verificar estado da montagem
mount | grep nfs
```
Configuração para montagem automática no `/etc/fstab`:
```bash
echo "<IP_EFS>:/ /mnt/efs nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab
```

### 4. Criar um Diretório no NFS com "Meu Nome"
```bash
sudo mkdir /mnt/efs/<My_Name>
```

### 5. Instalar o Apache
```bash
sudo yum install -y httpd
```

### 6. Iniciar e Habilitar o Apache
```bash
sudo systemctl start httpd && sudo systemctl enable httpd
```

### 7. Criar um Script de Verificação do Apache
Criar o script de verificação em `/usr/local/bin/check_apache_status.sh`:
```bash
sudo nano /usr/local/bin/check_apache_status.sh
```

Conteúdo do script:
```bash
#!/bin/bash

STATUS=$(systemctl is-active httpd)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ONLINE_FILE="/mnt/efs/<My_Name>/apache_status_online.txt"
OFFLINE_FILE="/mnt/efs/<My_Name>/apache_status_offline.txt"

if [ "$STATUS" = "active" ]; then
    echo "$TIMESTAMP Apache ONLINE" > "$ONLINE_FILE"
    [ -e "$OFFLINE_FILE" ] && rm "$OFFLINE_FILE"
else
    echo "$TIMESTAMP Apache OFFLINE" > "$OFFLINE_FILE"
    [ -e "$ONLINE_FILE" ] && rm "$ONLINE_FILE"
fi
```

Tornar o script executável:
```bash
sudo chmod +x /usr/local/bin/check_apache_status.sh
```

### 8. Ajustar Permissões e Fuso Horário
```bash
sudo chown ec2-user:ec2-user /mnt/efs/<My_Name>
sudo timedatectl set-timezone America/Recife
```

### 9. Automatizar a Execução do Script
Abrir o modo de edição do `crontab`:
```bash
crontab -e
```
Adicionar a seguinte linha para rodar o script a cada 5 minutos:
```bash
*/5 * * * * /usr/local/bin/check_apache_status.sh
```
Sendo o Vim o editor de textos padrão, pressionar CTRL+C para preparar o encerramento da aplicação, digitar `!wq` para salvar a alteração e sair do editor.

## Parte III: Versionamento e Documentação

### 1. Inicializar um Repositório Git
```bash
cd /caminho/para/projeto
git init
git add .
git commit -m "Primeiro commit"
```

### 2. Subir o Código para o Repositório Remoto
Configurar o repositório remoto e enviar o código:
```bash
git remote add origin <url_do_repositorio>
git push -u origin master
```

## Parte IV: Acessando o servidor Apache

### 1. Preparando um site de exemplo

O site será armazenado no diretório Web do Apache.

```bash
wget -q -O /tmp/encryptor-remastered.zip https://github.com/nullbyte-s/Encryptor-Remastered/archive/refs/heads/main.zip
sudo -i
unzip /tmp/encryptor-remastered.zip -d /var/www/html
mv /var/www/html/Encryptor-Remastered-main/* /var/www/html/
rm -rf /var/www/html/Encryptor-Remastered-main
rm -f /tmp/encryptor-remastered.zip

# Garantir as permissões necessárias para o usuário e grupo do Apache
sudo chown apache:apache /var/www/html/*
```

O site estará acessível diretamente pelo IP público associado à instância EC2, na porta 80. Considerando que o tráfego dessa porta não oferece criptografia própria do protocolo, convém configurar o acesso via HTTPS com certificado válido em substituição ao acesso via HTTP, para atender as melhores práticas de segurança nesse contexto.

Existem muitas maneiras de realizar esse procedimento. O exemplo a seguir não gera custos, atendendo bem ao propósito demonstrativo.

### 2. Configurando acesso seguro e exclusivo ao HTTPS

- Criar uma Conta e Configurar o DDNS no No-IP:
    - Acessar "Dynamic DNS > Add a Hostname".
    - Escolher um hostname único e selecionar um dos domínios gratuitos disponíveis.
    - No campo IPv4 Address, inserir o Elastic IP da instância EC2.
- Instalar o Cliente No-IP para atualizar automaticamente o IP associado ao hostname:
```bash
sudo -i
yum install gcc make
cd /usr/local/src/
wget https://www.no-ip.com/client/linux/noip-duc-linux.tar.gz
tar xf noip-duc-linux.tar.gz
cd noip-*
make

# Inserir usuário e senha do No-IP, quando solicitado.
make install

# Rodar o binário do No-IP para atualizar o DDNS pela primeira vez
/usr/local/bin/noip2

# Iniciar o Cliente No-IP com o sistema
sh -c 'echo "/usr/local/bin/noip2" >> /etc/rc.local'
```
- Instalar o Certbot e Configurar o SSL com Let's Encrypt:
```bash
sudo -i
yum update -y

# Instalar o repositório EPEL (Extra Packages for Enterprise Linux)
amazon-linux-extras install epel -y
yum --enablerepo=extras install epel-release

yum install -y certbot python2-certbot-apache

# O certbot solicitará a criação de um arquivo com conteúdo gerado automaticamente
mkdir /var/www/html/.well-known
mkdir /var/www/html/.well-known/acme-challenge
certbot --manual --preferred-challenges http certonly -d <DDNS_NoIP>

# Em outra sessão do SSH, criar o arquivo solicitado
sudo nano /var/www/html/.well-known/acme-challenge/<Generated_Filename>
    # Conteúdo do Script
    `<Generated_Content>`
```
- Redirecionar HTTP para HTTPS:
```bash
sudo nano /etc/httpd/conf.d/ssl.conf
    # Adicionar o conteúdo bloco, antes de `<VirtualHost _default_:443>`:
    <VirtualHost *:80>
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    </VirtualHost>

    # Substituir as linhas a seguir para usar o certificado SSL válido
    --SSLCertificateFile /etc/pki/tls/certs/localhost.crt
    --SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
    ++SSLCertificateFile /etc/letsencrypt/live/<DDNS_NoIP>/fullchain.pem
    ++SSLCertificateKeyFile /etc/letsencrypt/live/<DDNS_NoIP>/privkey.pem

# Reiniciar o Apache
sudo systemctl restart httpd
```

Por fim, temos o servidor Apache rodando uma aplicação Web com tráfego seguro.

**Nota:** A renovação automática do certificado SSL é possível, no entanto, o escopo demonstrativo desse guia finaliza aqui.

## Finalizando

### Testes de Acesso Público

Finalizadas todas as etapas descritas, é crucial realizar testes para garantir que o servidor Apache esteja acessível publicamente e que o script de monitoramento esteja funcionando corretamente.

1. **Acessar o servidor Apache pelo navegador:** Utilizar o Elastic IP da instância EC2 para acessar o servidor Apache. A página padrão do Apache deverá ser exibida.

2. **Verificar os arquivos de status do Apache:** Acessar o diretório `/mnt/efs/<My_Name>` no servidor. Deverá haver o arquivo `apache_status_online.txt` ou `apache_status_offline.txt` com a data, hora e status do Apache.

3. **Simular uma falha no Apache:** Parar o serviço do Apache com o comando `sudo systemctl stop httpd` e aguardar 5 minutos para que o script de monitoramento seja executado. Após, verificar se o arquivo `apache_status_offline.txt` foi atualizado. Em seguida, iniciar o Apache novamente com `sudo systemctl start httpd` e verificar se o arquivo `apache_status_online.txt` é atualizado após a próxima execução do script.

### Garantindo a Consistência

O passo-a-passo trazido aqui fornece uma base inicial para a configuração de um ambiente Linux na AWS. No entanto, para garantir a consistência e a segurança em um ambiente de produção, recomenda-se considerar as seguintes práticas:

* **Utilizar Infrastructure as Code (IaC):** Ferramentas como o AWS CloudFormation ou Terraform permitem automatizar a criação e gerenciamento da infraestrutura, garantindo a replicabilidade e consistência do ambiente.
* **Implementar monitoramento detalhado:** Utilizar serviços como o Amazon CloudWatch para monitorar o desempenho da instância EC2, o status do Apache e outros indicadores relevantes. Configurar alertas para notificar sobre problemas em potencial.
* **Aplicar o princípio do menor privilégio:** Configurar o Security Group da instância EC2 para permitir apenas o tráfego essencial. Utilizar usuários IAM com permissões específicas para acessar os recursos da AWS.
* **Manter o sistema atualizado:** Atualizar regularmente o sistema operacional e os pacotes de software para garantir a segurança e a estabilidade do ambiente, através do comando `sudo yum update -y`, seguido de `sudo yum upgrade -y`.

Somente após estas práticas adicionais, pode-se considerar o ambiente Linux recém-configurado na AWS mais seguro e pronto para produção.

---

<h5 align="center">Made with 💜 by <a href="https://github.com/nullbyte-s/">nullbyte-s</a><br>