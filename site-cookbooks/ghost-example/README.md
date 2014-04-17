ghost-example Cookbook
======================
This contains several examples of using chef-solo to install a ghost blog (see: https://ghost.org). It starts with a simple single site example, where resources are used fairly directly. It then moves onto some cleanup, by moving the setup for a single ghost site into a definition and using that to create another ghost site on the same server. Finally, it switches to using external attributes to define the different ghost sites, allowing you to create new sites without having to edit the cookbook.

Apache2 is used as a front-end web server. PM2 is used to manage the nodejs processes. The recipe sets both of these up as well.

Note that the ghost blog that this example sets up does not use SSL for the admin section and login page. Because of this, you should not use it to run a ghost blog that you actually want to use, as it will be pretty easy for anyone sniffing network traffic to get your username password. SSL is not that hard to add to it and may be added in a future version, but right now, this cookbook is being used mainly to demonstrate Chef and I didn't want to complicate it needlessly (Demo's tomorrow... Sheesh! Talk about last minute!).

Requirements
------------

This cookbook assumes you are running Ubuntu 13.10 or later

Attributes
----------
TODO: List your cookbook attributes here.

Usage
-----

pre-requisites:

1. USERNAME has to have sudo access and be able to ssh into the machine
2. SERVER_ADDRESS is accessible from a public ip address
3. To access site-one.com, site-two.com, and site-three.com, you'll need to edit your /etc/hosts. Alternatively, you could use domains you control.

Steps:

```
cd /PATH/TO/REPO_DIRECTORY
knife solo init .
knife solo prepare USERNAME@SERVER_ADDRESS -r "recipe[ghost-example::rev1]"
knife solo cook USERNAME@SERVER_ADDRESS
```

To move on to the other examples, edit the node data that will now be (after the knife solo prepare step) at: /PATH/TO/REPO_DIRECTORY/nodes/SERVER_ADDRESS.json

The re-run:

```
knife solo cook USERNAME@SERVER_ADDRESS
```

#### ghost-example::rev1

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[ghost-example::rev1]"
  ]
}
```

#### ghost-example::rev2

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[ghost-example::rev2]"
  ]
}
```

#### ghost-example::rev3

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[ghost-example::rev3]"
  ],
  "ghost": {
  	"sites": {
  		"site-one.com": { "port": 2368 },
   		"site-two.com": { "port": 2369 },
    	"site-three.com": { "port": 2370 }
  	}
  }
}
```


Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: David Ackerman
