curl https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
cd ~
sudo wget http://gsdview.appspot.com/dart-archive/channels/stable/release/1.24.3/linux_packages/dart_1.24.3-1_amd64.deb
sudo dpkg -i dart_1.24.3-1_amd64.deb
sudo apt-get install -f

# Modify the config file
secret_key=`openssl rand -base64 16`
password_salt=`openssl rand -base64 16`
sed -i "/SECRET_KEY =/c\SECRET_KEY = '$secret_key'" /usr/local/src/security_monkey/env-config/config.py
sed -i "/SECURITY_PASSWORD_SALT =/c\SECURITY_PASSWORD_SALT = '$password_salt'" /usr/local/src/security_monkey/env-config/config.py
# Change the default port just in case
sed -i "/API_PORT =/c\API_PORT = '$API_PORT'" /usr/local/src/security_monkey/env-config/config.py


# Build the Web UI
cd /usr/local/src/security_monkey/dart
/usr/lib/dart/bin/pub get
/usr/lib/dart/bin/pub build


# Copy the compiled Web UI to the appropriate destination
sudo mkdir -p /usr/local/src/security_monkey/static/
sudo /bin/cp -R /usr/local/src/security_monkey/dart/build/web/* /usr/local/src/security_monkey/static/
sudo chgrp -R www-data /usr/local/src/security_monkey


# Generate self signed certificate for webui
CERT_PASSWD=`openssl rand -base64 16`
openssl genrsa -aes128 -passout pass:$CERT_PASSWD -out server.pass.key 2048
openssl rsa -passin pass:$CERT_PASSWD -in server.pass.key -out server.key

rm server.pass.key



openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=California/L=California/O=DB/OU=Security/CN=DB.net"

openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

sudo mv server.crt /etc/ssl/certs
sudo mv server.key /etc/ssl/private

sudo chown root.root /etc/ssl/private/server.key
sudo chmod 660 /etc/ssl/private/server.key

