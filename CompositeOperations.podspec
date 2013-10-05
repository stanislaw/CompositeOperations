Pod::Spec.new do |s|
  s.name = 'SACompositeOperations'
  s.version = '0.4.7'
  s.license = 'MIT'
  s.summary = '(Sync-Async) Composite Operations for Objective-C.'
  s.homepage = 'https://github.com/stanislaw/SACompositeOperations'
  s.author = { 
    'Stanislaw Pankevich' => 's.pankevich@gmail.com' 
  }
  s.source = { :git => 'https://github.com/stanislaw/SACompositeOperations.git', :tag => s.version.to_s }
  s.description = 'Composite operations.'
  s.source_files = 'SACompositeOperations/*.{h,m}'
  s.platform = :ios
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
