Pod::Spec.new do |s|
    s.name             = 'Shakuro.InfinityScrollView'
    s.version          = '1.0.0'
    s.summary          = 'Shakuro Infinity Scroll View'
    s.homepage         = 'https://github.com/shakurocom/InfinityScrollView'
    s.license          = { :type => "MIT", :file => "LICENSE.md" }
    s.authors          = {'apopov1988' => 'apopov@shakuro.com', 'wwwpix' => 'spopov@shakuro.com', 'slaschuk' => 'slaschuk@shakuro.com'}
    s.source           = { :git => 'https://github.com/shakurocom/InfinityScrollView.git', :tag => s.version }
    s.source_files     = 'Source/*', 'Source/**/*'
    s.swift_version    = ['5.1', '5.2', '5.3', '5.4']
    s.ios.deployment_target = '10.0'

    s.dependency 'Shakuro.CommonTypes', '1.1.1'

end
