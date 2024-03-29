# beacker GKE
Beaker library to use the Google Kubernetes Engine hypervisor

# How to use this wizardry

This gem that allows you to use hosts with [GKE](gke.md) hypervisor with [beaker](https://github.com/puppetlabs/beaker). 

Beaker will automatically load the appropriate hypervisors for any given hosts file, so as long as your project dependencies are satisfied there's nothing else to do. No need to `require` this library in your tests.

## With Beaker 4.x

As of Beaker 4.0, all hypervisor and DSL extension libraries have been removed and are no longer dependencies. In order to use a specific hypervisor or DSL extension library in your project, you will need to include them alongside Beaker in your Gemfile or project.gemspec. E.g.

~~~ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-gke'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-gke'
~~~

# Spec tests

Spec test live under the `spec` folder. There are the default rake task and therefore can run with a simple command:
```bash
bundle exec rake test:spec
```

# Contributing

Pull requests are welcome!
