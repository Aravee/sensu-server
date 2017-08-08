#!/bin/bash


# --- Colors & Tabbing --- #
RED="\e[31m"
GREEN="\e[32m"
TAB="\t\t\t\t\t\t"
NL="\n\n"
DEC="####### ---"
RDEC="--- #######"

# --- Finding the Operating System & Version --- #

OS=$(uname -a | awk '{print $4}' | cut -c5-10)
OS_VERSION=$(. /etc/os-release && echo $VERSION )
CODENAME=$(. /etc/os-release && echo $VERSION | awk '{print tolower($3)}' | cut -b 2-7)


if [[ $OS == "Ubuntu" ]];
then
			### ---- Sensu Server Installation Begins ---- ###
	echo -e "$RED $TAB $DEC System is running on Debian Based Operating System...! $NL"
	echo -e "$GREEN $TAB  $DEC Installing Sensu for - $OS $RDEC $NL"
	echo -e "$RED $TAB $DEC Version of $OS - $OS_VERSION $RDEC $NL"
	sleep 2
	echo -e "$GREEN $TAB $DEC Installing GPG Key For Sensu Server $RDEC $NL"
	sudo wget -q https://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -
	echo -e "$GREEN $TAB GPG Key for Sensu Server Installed Successfully On the Server $NL"
	sleep 2

	echo -e "$GREEN $TAB Adding the Sensu Server Repo - /etc/apt/sources.list.d/sensu.list $NL"
	echo "deb https://sensu.global.ssl.fastly.net/apt $CODENAME main" | sudo tee /etc/apt/sources.list.d/sensu.list
	echo -e "$RED $TAB Sensu Server Repo Added to /etc/apt/sources.list.d/sensu.list $NL"
	sleep 2
	sudo apt-get update
	sudo apt-get install sensu -y
	sudo systemctl enable sensu-server && sudo systemctl start sensu-server && sudo systemctl status sensu-server
	sudo systemctl enable sensu-client && sudo systemctl start sensu-client && sudo systemctl status sensu-client 
	sudo systemctl enable sensu-api && sudo systemctl start sensu-api && sudo systemctl status sensu-api
	sleep 2

	echo -e "$NL $RED $TAB $DEC Sensu Server Automated Configurations $RDEC $NL"

	sudo touch /etc/sensu/conf.d/transport.json && sudo touch /etc/sensu/conf.d/api.json

	echo '{
  			"transport": {
    		"name": "rabbitmq",
    		"reconnect_on_error": true
  			}
		}' > /etc/sensu/conf.d/transport.json

	echo '{
  			"api": {
    		"host": "localhost",
    		"bind": "0.0.0.0",
    		"port": 4567
 			 }
		}' > /etc/sensu/conf.d/api.json

	echo -e "$GREEN $TAB Configurations Has Been Added Successfully, Restarting the Sensu services...! $NL"

	sudo systemctl restart sensu-server && sudo systemctl restart sensu-client && sudo systemctl restart sensu-api

	if [[ $? -eq 0 ]]
        then
        	echo -e "$GREEN $TAB Sensu successfully installed & Enabled On Boot Time...! $NL"
        else
        	echo -e "$RED $TAB Sensu Installation Has Failed Please Retry...! $NL"
    fi

					### ---- Sensu Server Installation Ends ---- ###

					### ---- Redis Server Installation Begins ---- ###
	echo -e "$GREEN $TAB $DEC Installing Redis for - $OS $RDEC $NL"
	sleep 2
	sudo apt-get update
	sudo apt-get install redis-server -y
	sleep 2
	
	sudo systemctl enable redis-server && sudo systemctl start redis-server  && sudo systemctl status redis-server
	echo -e "$NL $GREEN $TAB Verify Redis is working $NL"
	sudo redis-cli ping

	echo -e "$RED $TAB $DEC Redis-server Automated Configurations $RDEC $NL"
	sudo touch /etc/sensu/conf.d/redis.json

	echo '{
  			"redis": {
    		"host": "127.0.0.1",
    		"port": 6379
  			}
		}' > /etc/sensu/conf.d/redis.json

	sudo systemctl restart redis-server

	if [[ $? -eq 0 ]]
        then
        	echo -e "$GREEN $TAB Redis-server successfully installed & Enabled On Boot Time...! $NL"
        else
        	echo -e "$RED $TAB Redis-server Installation Has Failed Please Retry...! $NL"
    fi
	
					### ---- Redis Server Installation Ends ---- ###


					### ---- RabittMQ Server Installation Begins ---- ###

						
						### ---- Erlang Installation for - RabbitMQ - Part 1 ---- ###

	echo -e "$GREEN $TAB $DEC Downloading Erlang for - $OS $RDEC $NL"
	sudo wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
	sleep 2

	echo -e "$GREEN $TAB $DEC Installing Redis for - $OS $RDEC $NL"
	sudo dpkg -i erlang-solutions_1.0_all.deb
	sudo apt-get update
	sudo apt-get install socat erlang-nox -y
	if [[ $? -eq 0 ]]
        then
        	echo -e "$GREEN $TAB Erlang Runtime successfully installed...! $NL"
        else
        	echo -e "$RED $TAB Erlang Runtime Installation Has Failed Please Retry...! $NL"
    fi
	

						### ---- Erlang Installation for - RabbitMQ - Part 2 ---- ###

	echo -e "$GREEN $TAB $DEC Downloading RabbitMQ for - $OS $RDEC $NL"
	sudo wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.9/rabbitmq-server_3.6.9-1_all.deb
	sleep 2

	echo -e "$GREEN $TAB $DEC Installing RabbitMQ for - $OS $RDEC $NL"
	sudo dpkg -i rabbitmq-server_3.6.9-1_all.deb

	sudo systemctl enable rabbitmq-server && sudo systemctl start rabbitmq-server && sudo systemctl status rabbitmq-server

						### ---- RabbitMQ V-Host Configuration ---- ###

	sudo rabbitmqctl add_vhost /sensu
	sudo rabbitmqctl add_user sensu secret
	sudo rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

	sudo touch /etc/sensu/conf.d/rabbitmq.json

	echo '{
  			"rabbitmq": {
    		"host": "127.0.0.1",
    		"port": 5672,
    		"vhost": "/sensu",
    		"user": "sensu",
    		"password": "secret"
  			}
		}' > /etc/sensu/conf.d/rabbitmq.json

	sudo systemctl restart rabbitmq-server 

	if [[ $? -eq 0 ]]
        then
        	echo -e "$GREEN $TAB RabbitMQ-server successfully installed & Enabled On Boot Time...! $NL"
        else
        	echo -e "$RED $TAB RabbitMQ-server Installation Has Failed Please Retry...! $NL"
    fi
	

						### ---- RabittMQ Server Installation Ends ---- ###


						### ---- Uchiwa Dashboard - Installation Begins ---- ###

	echo -e "$GREEN $TAB $DEC Downloading Uchiwa Dashboard for - $OS $RDEC $NL"
	wget http://dl.bintray.com/palourde/uchiwa/uchiwa_0.14.2-1_amd64.deb
	sleep 2

	echo -e "$GREEN $TAB $DEC Installing Uchiwa Dashboard for - $OS $RDEC $NL"
	dpkg -i uchiwa_0.14.2-1_amd64.deb

	sudo apt-get update
	sudo apt-get install uchiwa -y

	sudo systemctl enable uchiwa && sudo systemctl start uchiwa

	sudo touch /etc/sensu/uchiwa.json

	echo '{
      	"sensu": [
            {
          "name": "sensu",
          "host": "localhost",
          "user": "admin",
          "pass": "admin",
          "port": 4567,
          "timeout": 10
            }
          ],
        "uchiwa": {
            "host": "0.0.0.0",
            "port": 3000,
            "user": "admin",
            "user": "admin",
            "refresh": 10
          }
		}' > /etc/sensu/uchiwa.json

	sudo systemctl restart uchiwa

										#### --- Changing the Default Logo --- ####

	# /opt/uchiwa/src/public/bower_components/uchiwa-web/img/uchiwa.png - Replace this image with you own logo.


	if [[ $? -eq 0 ]]
        then
        	echo -e "$GREEN $TAB Uchiwa Dashboard successfully installed & Enabled On Boot Time...! $NL"
        else
        	echo -e "$RED $TAB Uchiwa Dashboard Installation Has Failed Please Retry...! $NL"
    fi

    							### ---- Uchiwa Dashboard - Installation Ends ---- ###
else
	echo -e "not running on linux"
fi
