##### Install packages #####
package "build-essential"
package "zip"
package "nodejs"
package "apache2"


##### Define the apache2 service #####
service "apache2"


##### Get rid of default apache sites #####
[ "000-default.conf", "default-ssl.conf" ].each do | default_conf |
	apache_site "#{default_conf}" do
		enable false
	end
	file "/etc/apache2/sites-available/#{default_conf}" do
		action :delete
	end
end


##### Enable necessary modules #####
apache_module "proxy"
apache_module "proxy_http"


##### NodeJS setup #####
link "/usr/bin/node" do
	to "/usr/bin/nodejs"
end

execute "curl https://www.npmjs.org/install.sh | sudo sh" do
	creates "/usr/lib/node_modules/npm"
end

execute "npm install -g pm2" do
	creates "/usr/lib/node_modules/pm2"
end

execute "pm2 startup ubuntu" do
	creates "/etc/init.d/pm2-init.sh"
end

directory "/var/www" do
	owner "www-data"
	group "www-data"
end

##### Ghost setup #####
node[:ghost][:sites].each do | site_name, config |
	ghost_site site_name do
		port config[:port]
	end
end