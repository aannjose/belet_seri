# belet_seri
#
# Installs and configures NGINX and MySQL for a simple web service
#
# Copyright 2017 Puppet Inc
#
# @example
#   include belet_seri
class belet_seri (
  String  $folder,
  String  $file_name,
  String  $port,
  String  $url,
  String  $system_user,
  String  $system_group,
  String  $database_name,
  String  $database_user,
  String  $database_pass,
  Array[String] $paths,
) {
  # create user and group for the sintra service
  group { $belet_seri::system_group:
    ensure => present,
  }

  user { $belet_seri::system_user:
    ensure  => present,
    gid     => $belet_seri::system_group,
    require => Group[$belet_seri::system_group],
  }

  # install the sintra gem for our web service
  package { 'sinatra':
    ensure   => installed,
    provider => 'gem',
  }

  # random packages needed for mysql
  package { 'ruby-all-dev':
    ensure => installed,
  }

  package { 'libmysqlclient-dev':
    ensure   => installed,
  }

  package { 'mysql2':
    ensure   => installed,
    provider => 'gem',
    require  => [Package['libmysqlclient-dev'], Class['::mysql::server'], Package['ruby-all-dev']],
  }

  # create the folders and files where the code will live
  file { $belet_seri::folder:
    ensure => directory,
  }

  # file that has the code we care about
  file { "${belet_seri::folder}/${belet_seri::file_name}":
    ensure  => file,
    owner   => $belet_seri::system_user,
    group   => $belet_seri::system_group,
    mode    => '0755',
    content => epp('belet_seri/web_service.rb.epp', {
      'port'          => $belet_seri::port,
      'url'           => $belet_seri::url,
      'database_host' => 'localhost',
      'database_user' => $belet_seri::database_user,
      'database_pass' => $belet_seri::database_pass,
      'database_name' => $belet_seri::database_name}),
    require => [File[$belet_seri::folder], Package['sinatra'], Package['mysql2']],
    notify  => Service['belet_seri'],
  }

  # this creates the db tables for us
  file { "${belet_seri::folder}/table_setup.sql":
    ensure  => file,
    owner   => $belet_seri::system_user,
    group   => $belet_seri::system_group,
    require => File[$belet_seri::folder],
    notify  => Mysql::Db[$belet_seri::database_name],
    source  => 'puppet:///modules/belet_seri/table_setup.sql',
  }

  # installs mysql and configures it
  class { '::mysql::server':
    root_password           => 'strongpassword1',
    remove_default_accounts => true,
    override_options        => { 'mysqld' => { 'max_connections' => '1024' } }
  }

  # creates our database
  mysql::db { $belet_seri::database_name:
    user     => $belet_seri::database_user,
    password => $belet_seri::database_pass,
    host     => 'localhost',
    dbname   => $belet_seri::database_name,
    grant    => ['SELECT', 'UPDATE', 'INSERT', 'DELETE'],
    sql      => "${belet_seri::folder}/table_setup.sql",
    require  => [File["${belet_seri::folder}/table_setup.sql"], Class['::mysql::server']],
  }

  $epp_file = 'debian.epp'
  $daemon_path = '/etc/init.d'

  # we create a service file so the OS knows what to do
  file { "${daemon_path}/belet_seri":
    content => epp("belet_seri/${epp_file}", {
      'app_path'     => $belet_seri::folder,
      'file_name'    => $belet_seri::file_name,
      'system_group' => $belet_seri::system_group,
      'system_user'  => $belet_seri::system_user }),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['belet_seri'],
    require => File["${belet_seri::folder}/${belet_seri::file_name}"],
  }

  # this ensures the service is running
  service { 'belet_seri':
    ensure     => running,
    name       => 'belet_seri',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File["${daemon_path}/belet_seri"],
    require    => [Class['::mysql::server'], Package['mysql2']],
  }

  # this creates a reverse proxy to sinatra. it's bad practice to expose sinatra directly
  class { 'nginx': }

  nginx::resource::server { "${facts['fqdn']}":
    listen_port => 80,
    proxy       => "http://${belet_seri::url}:${belet_seri::port}",
  }
}
