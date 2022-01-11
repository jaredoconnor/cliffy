require_relative 'lib/cliffy/version'

Gem::Specification.new do |specification|
  specification.name = 'cliffy'
  specification.version = Cliffy::VERSION
  specification.required_ruby_version = '>= 3.0.0'

  specification.summary = 'Command Line Interface Framework For You'
  specification.description = 'Cliffy is a command line interface framework for you.'
  specification.homepage = 'https://github.com/jaredoconnor/cliffy'
  specification.license = 'MIT'

  specification.authors = ["Jared O'Connor"]
  specification.email = ['jaredoconnor@hotmail.com']

  specification.metadata['homepage_uri'] = specification.homepage
  specification.metadata['source_code_uri'] = specification.homepage

  specification.files = `git ls-files lib -z`.split "\x0"
end
