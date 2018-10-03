# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bole/version'

Gem::Specification.new do |spec|
  spec.name          = 'bole'
  spec.version       = Bole::VERSION
  spec.authors       = ['Tim Gourley']
  spec.email         = ['tgourley@gmail.com']

  spec.summary       = 'Simple Ruby File Logger'
  spec.description   = 'Log messages to a file or stdout with a timestamp'
  spec.homepage      = 'https://github.com/bratta/bole'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Required dependencies
  spec.add_dependency 'konfigyu', '~> 0.1.0'

  # Development Dependencies
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'byebug', '~> 10.0.2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.8.0'
  spec.add_development_dependency 'rubocop', '~> 0.59.2'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.29.1'
end
