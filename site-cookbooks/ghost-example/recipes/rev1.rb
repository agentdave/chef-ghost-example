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

# Grab the latest
remote_file "/tmp/site-one.com.zip" do
	source "https://ghost.org/zip/ghost-0.4.2.zip"
	not_if { File.exist?("/var/www/site-one.com") }
	owner "www-data"
end

execute "unzip /tmp/site-one.com.zip -d /var/www/site-one.com" do
	creates "/var/www/site-one.com"
	user "www-data"
end

# Install
execute "su www-data -c 'npm install --production'" do
	cwd "/var/www/site-one.com"
	creates "/var/www/site-one.com/node_modules"
end

# Ghost configuration
template "/var/www/site-one.com/config.js" do
	source "ghost.config.js.erb"
	owner "www-data"
	group "www-data"
	variables(
		:host_ip => "127.0.0.1",
		:host_port => 2368,
		:host_url => "http://site-one.com"
	)
	notifies :restart, "service[pm2-site-one.com]"
end

directory "/var/www/site-one.com/log" do
	owner "www-data"
	group "www-data"
end

service "pm2-site-one.com" do
	supports :status => true, :restart => true, :reload => true
	start_command "cd /var/www/site-one.com && su www-data -c 'NODE_ENV=production pm2 start index.js --name site-one.com'"
	restart_command "cd /var/www/site-one.com && su www-data -c 'NODE_ENV=production pm2 restart index.js --name site-one.com'"
	stop_command "cd /var/www/site-one.com && su www-data -c 'NODE_ENV=production pm2 stop index.js --name site-one.com'"
	reload_command "cd /var/www/site-one.com && su www-data -c 'NODE_ENV=production pm2 reload index.js --name site-one.com'"
	status_command "pm2 status | grep site-one.com | grep online"
	action :start
end

# Apache configuration
template "/etc/apache2/sites-available/site-one.com.conf" do
	source "ghost.apache.vhost.erb"
	owner "root"
	group "root"
	variables(
		:site_domain => "site-one.com",
		:site_home => "/var/www/site-one.com",
		:host_port => 2368,
		:host_url => "http://site-one.com"
	)
	notifies :restart, "service[apache2]"
end

apache_site "site-one.com.conf"
