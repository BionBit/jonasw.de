---
title: Continously Integrated Blog
category: meta, CI
---

During the last redesign oft my blog I decided to use the future today and have my blog built as static HTML files generated by [Jekyll][1]. Guides that can be found in the Internet usually assume you want to host on Github Pages, but since I already pay for hosting on a classical, non-cloudy provider, this wasn't an option.

[Drone.io][2] offers flexible deployment options, including the possibility to execute arbitrary commands on a remote server via SSH after transferring the compiled sources via rsync.

This guide assumes that your Jekyll-powered site is already existing and stored in a git repo on Github. BitBucket works as well.

## Setting up Drone.io

Drone.io offers free CI for open source projects, i.e. the repository is publicly hosted on Github, BitBucket or Google Code.

Create an account by connecting an existing Github user, the free plan will do.

After sign up, you can add a new project using the toolbar, selecting Github and then the correct repository.
I chose the Ruby environment, after all, Jekyll is Ruby based.

## Configuring the build

Let's give the CI the commands it needs to execute to build our site.

Please go to 'Settings', then to 'Build & Test'.

Unfortunately, Drone.io does not yet have Jekyll preinstalled, but we have `gem`. Make sure that the Ruby version selectable at the very top is set to at least 2.0.0, as the steps below will not work otherwise.

Firstly, we install Jekyll with

    gem install --no-rdoc Jekyll

As I am also using `jekyll-assets`, I also have

    gem install --no-rdoc jekyll-assets

To make sure that the environment finds Jekyll after the installation, we need to ask `rbenv` to rehash:

    rbenv rehash

Finally, we want to build the site, which in my case is simply

    jekyll build

Now is a good time to see if the build actually works. You can do this by saving and then clicking on 'Build now'. While everything compiles for you, we can set up the deployment of the generated files.

## Deploying

Head over to 'Deployments' and add a new SSH deployment.
Fill in the user and server names for the deployment script.
The remote path is used as target for the `rsync` triggered by Drone.io.



 
[1]: http://www.jekyllrb.com/
[2]: https://drone.io/
