Gem::Specification.new do |s|
  s.name = 'projectsimulator'
  s.version = '0.3.3'
  s.summary = 'Project Simulator (in development) aims to make it easier to ' + 
      'observe triggers and actions from an XML based model.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/projectsimulator.rb']
  s.add_runtime_dependency('easydom', '~> 0.2', '>=0.2.1')
  s.add_runtime_dependency('app-routes', '~> 0.1', '>=0.1.19')
  s.signing_key = '../privatekeys/projectsimulator.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/projectsimulator'
end
