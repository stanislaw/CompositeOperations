Pod::Spec.new do |s|
  s.name = 'CompositeOperations'
  s.version = '0.6.0-alpha.2'

  s.license = 'MIT'

  s.summary = 'Composite Operations for Objective-C.'
  s.description = 'Composite operations.'

  s.homepage = 'https://github.com/stanislaw/CompositeOperations'
  s.author = {
    'Stanislaw Pankevich' => 's.pankevich@gmail.com' 
  }

  s.source = { :git => 'https://github.com/stanislaw/CompositeOperations.git', :tag => s.version.to_s }
  s.source_files = 'CompositeOperations/**/*.{h,m}'
  s.private_header_files = 'CompositeOperations/Private/*.h'

  s.requires_arc = true

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
