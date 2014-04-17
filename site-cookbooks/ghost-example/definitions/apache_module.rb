# This definition was taken from the main Chef community apache2 cookbook that you
# can find here: http://community.opscode.com/cookbooks/apache2
# It was modified purely to simplify cookbook and module dependencies in order to
# make a cleaner example for someone looking to play with chef-solo and set up a
# working example (in this case, a ghost blog) from it. This will only work for
# Ubuntu-style systems. If you want to set up your blog on another system, you
# should probably look at grabbing the original apache cookbook. Also check out the
# README.md for an important note regarding SSL.

#
# Cookbook Name:: apache2
# Definition:: apache_module
#
# Copyright 2008-2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

define :apache_module, :enable => true, :conf => false do
  # include_recipe 'apache2::default'

  params[:filename]    = params[:filename] || "mod_#{params[:name]}.so"
  params[:module_path] = params[:module_path] || "/usr/lib/apache2/modules/#{params[:filename]}"
  params[:identifier]  = params[:identifier] || "#{params[:name]}_module"

  apache_conf params[:name] if params[:conf]

  if platform_family?('rhel', 'fedora', 'arch', 'suse', 'freebsd')
    file "/etc/apache2/mods-available/#{params[:name]}.load" do
      content "LoadModule #{params[:identifier]} #{params[:module_path]}\n"
      mode    '0644'
    end
  end

  if params[:enable]
    execute "a2enmod #{params[:name]}" do
      command "/usr/sbin/a2enmod #{params[:name]}"
      notifies :restart, 'service[apache2]'
      not_if do
        ::File.symlink?("/etc/apache2/mods-enabled/#{params[:name]}.load") &&
        (::File.exists?("/etc/apache2/mods-available/#{params[:name]}.conf") ? ::File.symlink?("/etc/apache2/mods-enabled/#{params[:name]}.conf") : true)
      end
    end
  else
    execute "a2dismod #{params[:name]}" do
      command "/usr/sbin/a2dismod #{params[:name]}"
      notifies :restart, 'service[apache2]'
      only_if { ::File.symlink?("/etc/apache2/mods-enabled/#{params[:name]}.load") }
    end
  end
end
