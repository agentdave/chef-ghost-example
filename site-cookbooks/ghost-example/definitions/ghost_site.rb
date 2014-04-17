define :ghost_site, :enable => true do
	# Grab the latest
	remote_file "/tmp/#{params[:name]}.zip" do
		source "https://ghost.org/zip/ghost-0.4.2.zip"
		not_if { File.exist?("/var/www/#{params[:name]}") }
		owner "www-data"
	end

	execute "unzip /tmp/#{params[:name]}.zip -d /var/www/#{params[:name]}" do
		creates "/var/www/#{params[:name]}"
		user "www-data"
	end

	# Install
	execute "su www-data -c 'npm install --production'" do
		cwd "/var/www/#{params[:name]}"
		creates "/var/www/#{params[:name]}/node_modules"
	end

	template "/var/www/#{params[:name]}/config.js" do
		source "ghost.config.js.erb"
		owner "www-data"
		group "www-data"
		variables(
			:host_ip => "127.0.0.1",
			:host_port => params[:port],
			:host_url => "http://#{params[:name]}"
		)
		notifies :restart, "service[pm2-#{params[:name]}]"
	end

	directory "/var/www/#{params[:name]}/log" do
		owner "www-data"
		group "www-data"
	end

	# Ghost configuration
	service_command_template = "cd /var/www/#{params[:name]} && su www-data -c 'NODE_ENV=production pm2 %s index.js --name #{params[:name]}'"
	service "pm2-#{params[:name]}" do
		supports :status => true, :restart => true, :reload => true
		start_command 		service_command_template % "start"
		restart_command 	service_command_template % "restart"
		stop_command 		service_command_template % "stop"
		reload_command 		service_command_template % "reload"
		status_command 		"pm2 status | grep #{params[:name]} | grep online"
		action :start
	end

	# Apache configuration
	template "/etc/apache2/sites-available/#{params[:name]}.conf" do
		source "ghost.apache.vhost.erb"
		owner "root"
		group "root"
		variables(
			:site_domain => params[:name],
			:site_home => "/var/www/#{params[:name]}",
			:host_port => params[:port],
			:host_url => "http://#{params[:name]}"
		)
		notifies :restart, "service[apache2]"
	end

	apache_site "#{params[:name]}.conf"
end