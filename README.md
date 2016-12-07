
sfm_dashboard
> HTTP Server on Ruby Sinatra
===

Check out http://shopify.github.com/dashing for more information.

### Getting Started

To set up dashing on Raspberry Pi use this tutorial (http://kubecloud.io/guide-installing-dashing-dashboard-on-raspberry-pi/)

To set up dashing on Linux 16.04 use this tutorial (http://labrat.it/2014/01/11/dashing-dashboard/)

### Clone Repository

```
$ git clone https://github.com/georgiev2592/sfm_dashboard.git
$ cd sfm_dashboard
```

### Start Server

```
$ bundle install
$ sudo dashing start [-p 80] [-d] [-e development] [-e production]
```

> Flags:

	p: specify port
	d: run in the background as a service
	e: specify environment [development/production]