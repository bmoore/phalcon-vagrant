Phalcon Vagrant
===============

This is a simple vagrant which scafolds out the start of a phalcon project.

`git clone http://github.com/bmoore/phalcon-vagrant phalcon-test && cd phalcon-test && vagrant up`

After vagrant provisions, you will be able to view your site on http://192.168.37.33/

This vagrant uses private_networking to avoid port forwarding. If you need to change this to public_networking, you will need to forward the http port 80 to some open port, possibly 8080, and visit http://localhost:8080/

To use phalcon-devtools, refer to https://github.com/phalcon/phalcon-devtools and remember, if you're using public_networking, you may need to have a condition in your config to use the appropriate mysql port when running php cli.
