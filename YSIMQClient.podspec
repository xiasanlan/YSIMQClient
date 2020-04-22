Pod::Spec.new do |s|
  s.name     = 'YSIMQClient'
  s.version  = '1.0.0'
  s.license  = { :type => 'MIT', :file => "LICENSE"}
  s.summary  = 'iOS平台即时通讯'
  s.homepage = 'https://github.com/xiasanlan/YSIMQClient'
  s.authors  = { 'xiasanlan' => '931283787@qq.com' }
  s.source   = {
    :git => 'https://github.com/xiasanlan/YSIMQClient.git',
    :tag => s.version
  }
  s.source_files = 'YSIMQClient/*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.dependency 'Protobuf', '~> 3.11.4'
end
