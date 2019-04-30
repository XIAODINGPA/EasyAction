Pod::Spec.new do |s|
  s.name             = 'EasyAction'
  s.version          = '0.2.0'
  s.summary          = 'EasyReact'

  s.description      = <<-DESC
EasyAction is an extension for EasyReact which use action to describe the data transfer between nodes.
                       DESC

  s.homepage         = 'https://github.com/Meituan-Dianping/EasyAction'
  s.license          = { :type => 'Apache License 2.0', :file => 'LICENSE' }
  s.author           = { 'William Zang' => 'chengwei.zang.1985@gmail.com', '姜沂' => 'nero_jy@qq.com', 'Qin Hong' => 'qinhong@face2d.com'}
  s.source           = { :git => 'https://github.com/Meituan-Dianping/EasyAction.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.module_map = 'EasyAction/EasyAction.modulemap'

  s.source_files = 'EasyAction/Classes/**/*'
  s.private_header_files = ['EasyAction/Classes/Private/**/*.h']

  s.dependency 'EasyReact', '~> 2.2.0'
end
