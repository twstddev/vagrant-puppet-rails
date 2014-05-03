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
