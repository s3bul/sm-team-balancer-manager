# Instalacja dla administratorów serwerów #
Wrzuć z [paczki #1](https://bitbucket.org/sebek/sm-team-balancer-manager/get/master.zip) lub [paczki #2](https://github.com/s3bul/sm-team-balancer-manager/archive/master.zip) cały folder "sourcemod" do folderu "addons".

# Instalacja dla developerów (skrypterów) #
Do swojego folderu z pluginami sklonuj te repozytorium oraz [git@bitbucket.org:sebek/sm-my-includes.git](https://bitbucket.org/sebek/sm-my-includes) lub [git@github.com:s3bul/sm-my-includes.git](https://github.com/s3bul/sm-my-includes).

Przykładowa struktura folderów

	Pluginy SM/
		Team Balancer Manager/
			sourcemod/
				plugins/
					sm_tbm.smx
				scripting/
					include/
						*.inc
					sm_tbm.sp
				translations/
					tbm.phrases.txt
		include/
			*.inc
