require_recipe "apache2"

# Required to compile passenger
package "apache2-prefork-dev"

gem_package "passenger" do
  version node[:passenger_version]
end

execute "passenger_module" do
  command 'echo -en "\n\n\n\n" | passenger-install-apache2-module'
  creates node[:passenger][:module_path]
end

template node[:passenger][:apache_load_path] do
  source "passenger.load.erb"
  owner "root"
  group "root"
  mode 0755
end

template node[:passenger][:apache_conf_path] do
  source "passenger.conf.erb"
  owner "root"
  group "root"
  mode 0755
end

apache_module "passenger"
include_recipe "apache2::mod_deflate"
include_recipe "apache2::mod_rewrite"

apache_site "default" do
  disable true
end

if node[:applications]
  node[:applications].each do |app, config|
    template "/etc/apache2/sites-available/#{app}_#{config[:env]}" do
      owner 'root'
      group 'root'
      mode 0644
      source "application.vhost.erb"
      variables({
        :docroot  => "/u/apps/#{app}/current/public",
        :server_name  => config[:server_name],
        :max_pool_size    => config[:max_pool_size]
      })
    end
    apache_site "#{app}_#{config[:env]}" do
      enable config[:enable]
    end
  end
end