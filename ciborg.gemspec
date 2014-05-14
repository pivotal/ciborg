# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ciborg/version"

Gem::Specification.new do |s|
  s.name        = "ciborg"
  s.version     = Ciborg::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Kocher", "Lee Edwards", "Brian Cunnie", "Doc Ritezel"]
  s.email       = ["ciborg@pivotallabs.com"]
  s.homepage    = "https://github.com/pivotal/ciborg"
  s.summary     = %q{CI in the Cloud: Jenkins + EC2 = Ciborg}
  s.description = %q{Rails generators that make it easy to spin up a CI instance in the cloud. Formerly known as 'Lobot'.}
  s.license     = "MIT"

  s.rubyforge_project = "ciborg"

  s.files         = `git ls-files`.split("\n") + `cd chef/travis-cookbooks && git ls-files`.split("\n").map { |f| "chef/travis-cookbooks/#{f}" }
  s.executables   = `git ls-files -- bin`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "fog", "~> 1.6"
  s.add_dependency "ci_reporter", "~> 1.7"
  s.add_dependency "thor"
  s.add_dependency "hashie", "~> 2.0.2"
  s.add_dependency "haddock"
  s.add_dependency "net-ssh"
  s.add_dependency "httpclient"
  s.add_dependency "godot"

  s.add_development_dependency "rspec"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "test-kitchen", "~> 1.0.0.alpha.5"

  s.add_development_dependency "terminal-notifier-guard"
  s.add_development_dependency "rb-fsevent"
end
