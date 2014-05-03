# Variables
$home = "/home/vagrant"
$execute_as_vagrant = "sudo -u vagrant -H bash -l -c"
# user "postgresql" or "mongodb"
$database = "postgresql"

# Set default binary paths 
Exec {
	path => [ "/usr/bin", "/usr/local/bin" ]
}


# Prepare system before main stage
stage { "init": }

class update_apt {
	exec { "apt-get -y update": }
}

class{ "update_apt" :
	stage => init,
}

Stage[ "init" ] -> Stage[ "main" ]


# Main packages
package { "vim":
	ensure => "present",
}

package { "git":
	ensure => "present",
}

package { "curl":
	ensure => "present",
}

package { "nodejs":
	ensure => "present",
}

package { [ "sqlite3", "libsqlite3-dev" ]:
	ensure => "present",
}

# Install database
case $database {
	"postgresql" : {
		class { "postgresql::server":
			postgres_password => "postgres"
		}
		postgresql::server::db { "app":
			user => "root",
			password => postgresql_password( "root", "root" ),
			require => Class[ "postgresql::server" ],
		}
	}

	"mongodb" : {
		class { "::mongodb::server":
			auth => true,
		}
		mongodb::db { "app":
			user => "root",
			password => "root",
		}
	}
}

# Rails installation
# This installation follows instruction from https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-ubuntu-12-04-lts-precise-pangolin-with-rvm

exec { "install_rvm":
	command => "${execute_as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'"
}

exec { "source_rvm_profile":
	command => "${execute_as_vagrant} 'source ${home}/.rvm/scripts/rvm'"
}

exec { "install_dependencies":
	command => "${execute_as_vagrant} 'rvm requirements'"
}

exec { "install_ruby":
	command => "${execute_as_vagrant} 'rvm install ruby && rvm use ruby --default'"
}

exec { "install_rubygems":
	command  => "${execute_as_vagrant} 'rvm rubygems current'"
}

exec { "disable_documentation":
	command => "${execute_as_vagrant} 'echo \"gem: --no-ri --no-rdoc\" > ${home}/.gemrc'"
}

exec { "install_rails":
	command => "${execute_as_vagrant} 'gem install rails'"
}

Package[ "curl" ] ->
	Exec[ "install_rvm" ] ->
	Exec[ "source_rvm_profile" ] ->
	Exec[ "install_dependencies" ] ->
	Exec[ "install_ruby" ] ->
	Exec[ "install_rubygems" ] ->
	Exec[ "disable_documentation" ] ->
	Exec[ "install_rails" ]
