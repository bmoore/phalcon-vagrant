# Puppet Stages
stage {
    'users':       before => Stage['updates'];
    'updates':     before => Stage['packages'];
    'packages':    before => Stage['composer'];
    'composer':    before => Stage['configure'];
    'configure':   before => Stage['phalcon'];
    'phalcon':     before => Stage['services'];
    'services':    before => Stage['main'];
}

class users {
    group { "www-data":
        ensure => "present",
     }
}

class updates {
    exec {
        "aptitude-repository":
            command => "/usr/bin/sudo apt-add-repository ppa:phalcon/stable",
            timeout => 0;
        "aptitude-update":
            command => "/usr/bin/sudo aptitude update -y -q",
            require => Exec['aptitude-repository'],
            timeout => 0;
    }
}

class packages {
    package {[
            "git",
            "apache2",
            "mariadb-server",
            "php5",
            "php5-mysql",
            "php5-phalcon",
            ]:
        ensure => "present",
    }
}

class composer {
    exec {
        "get-composer":
            command => '/usr/bin/sudo curl -sS https://getcomposer.org/installer | php',
            unless => '/usr/bin/which composer';

        "set-composer":
            command => '/usr/bin/sudo mv composer.phar /usr/local/bin/composer',
            unless => '/usr/bin/which composer',
            require => Exec['get-composer'];

        "composer-dir":
            command => '/bin/mkdir -p ~/.composer',
            unless => '/bin/ls ~/.composer';

        "github-api-conf":
            command => '/usr/bin/sudo cp /var/www/manifests/composer.json ~/.composer/config.json',
            onlyif => '/bin/ls /var/www/manifests/composer.json',
            unless => '/bin/ls ~/.composer/config.json',
            require => Exec['composer-dir'];
    }
}

class configure {
    exec {
        "clear-apache-conf":
            command => '/usr/bin/sudo rm /etc/apache2/sites-enabled/000-default.conf',
            onlyif => '/bin/ls /etc/apache2/sites-enabled/000-default.conf';

        "link-apache-conf":
            command => '/usr/bin/sudo cp /vagrant/manifests/vagrant.conf /etc/apache2/sites-enabled/vagrant.conf',
            unless => '/bin/ls /etc/apache2/sites-enabled/vagrant.conf';

        "apache-rewrite":
            command => '/usr/bin/sudo a2enmod rewrite';

        "mysql-bind-address":
            command => '/usr/bin/sudo cp /vagrant/manifests/bind.cnf /etc/mysql/conf.d/bind.cnf',
            unless => '/bin/ls /etc/mysql/conf.d/bind.cnf';

        "mysql-privilege":
            command => '/usr/bin/mysql -uroot -h 127.0.0.1 -e \'GRANT ALL PRIVILEGES ON *.* TO "vagrant"@"%" IDENTIFIED BY "vagrant"; FLUSH PRIVILEGES;\'';

        "mysql-create-database":
            command => '/usr/bin/mysql -uvagrant -pvagrant -h 127.0.0.1 -e \'CREATE DATABASE vagrant;\'',
            unless => '/usr/bin/mysql -uroot -h 127.0.0.1 vagrant';
    }
}

class phalcon {
    exec {
        "phalcon-tool-install":
            command => '/usr/bin/sudo composer install',
            cwd => '/vagrant',
            timeout => 0,
            unless => '/bin/ls /vagrant/vendor';

        "phalcon-create":
            command => '/usr/bin/sudo /vagrant/vendor/bin/phalcon.php project phalcon',
            cwd => '/vagrant',
            timeout => 0,
            unless => '/bin/ls /vagrant/phalcon',
            require => Exec['phalcon-tool-install'];

        "phalcon-config":
            command => '/usr/bin/sudo cp /vagrant/manifests/config.php /vagrant/phalcon/app/config',
            require => Exec['phalcon-create'];

        "phalcon-migration":
            command => '/usr/bin/sudo /vagrant/vendor/bin/phalcon.php migration run',
            cwd => '/vagrant/phalcon',
            require => Exec['phalcon-config'];
    }
}

class services {
    exec {
        "apache-restart":
            command => '/usr/bin/sudo service apache2 restart';

        "mysql-restart":
            command => '/usr/bin/sudo service mysql restart';
    }
}

class {
    users:       stage => "users";
    updates:     stage => "updates";
    packages:    stage => "packages";
    composer:    stage => "composer";
    configure:   stage => "configure";
    phalcon:     stage => "phalcon";
    services:    stage => "services";
}
