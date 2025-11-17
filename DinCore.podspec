#
# Be sure to run `pod lib lint DinSupport.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DinCore'
  s.version          = '0.0.6'
  s.summary          = 'DinCore'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "Base framework used in Dinsafe"

  s.homepage         = 'https://gitlab.sca.im/iOS/DinCore'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ios' => 'ios@dinsafe.com' }
  s.source           = { :git => 'https://gitlab.sca.im/iOS/DinCore.git', :tag => s.version.to_s }

  s.swift_version = "5.0"
  s.ios.deployment_target = '11.0'

  s.source_files = ['DinCore/DinCore/DinCore.h', 'DinCore/DinCore/Source/**/*']

  # for AlicloudHTTPDNS
  s.static_framework = true

  s.dependency 'AlicloudHTTPDNS', '3.2.1'
  s.dependency 'Moya', '15.0.0'
  s.dependency 'HandyJSON'
  s.dependency 'Snappy', '1.1.0'
  s.dependency 'RxSwift', '6.5.0'
  s.dependency 'RxCocoa', '6.5.0'
  s.dependency 'Qiniu', '>= 8.4.4'
  s.dependency 'Starscream', '3.1.1'
  s.dependency 'YYModel', '1.0.4'
  s.dependency 'CocoaAsyncSocket', '7.6.5'
  s.dependency 'Objective-LevelDB', '2.1.5'
  s.dependency 'DinSupport'

  s.subspec 'Shared' do |ss|
    ss.source_files = [
      'DinCore/DinCore/Source/DinCore.h',
      'DinCore/DinCore/Source/Shared/**/*',
      'DinCore/DinCore/Source/Common/**/*',
      'DinCore/DinCore/Source/Model/**/*',
      'DinCore/DinCore/Source/Definitions/**/*',
      'DinCore/DinCore/Source/DataBase/**/*',
      'DinCore/DinCore/Source/DinChannel/**/*',
      'DinCore/DinCore/Source/DinPeripheral/**/*',
      'DinCore/DinCore/Source/DinBLEPeripheralScanner/**/*',
      'DinCore/DinCore/Source/DinBLEPeripheralPool/**/*',
    ]
  end

  s.subspec 'DinPanel' do |ss|
    ss.dependency 'DinCore/Shared'
    ss.xcconfig = {
      "OTHER_SWIFT_FLAGS": "-D ENABLE_DINCORE_PANEL"
    }
    ss.source_files = [
      'DinCore/DinCore/Source/DinNovaPanel/**/*',
      'DinCore/DinCore/Source/DinPanelPeripheral/**/*',
    ]
  end

  s.subspec 'DinLiveStreaming' do |ss|
    ss.dependency 'DinCore/Shared'
    ss.xcconfig = {
      "OTHER_SWIFT_FLAGS": "-D ENABLE_DINCORE_LIVESTREAMING"
    }
    ss.source_files = [
      'DinCore/DinCore/Source/DinLiveStreaming/**/*',
      'DinCore/DinCore/Source/DinDoorbellPeripheral/**/*',
      'DinCore/DinCore/Source/DinVideoDoorbell/**/*',
      'DinCore/DinCore/Source/DinIPCPeripheral/**/*',
      'DinCore/DinCore/Source/DinCamera/**/*',
      'DinCore/DinCore/Source/DinIPCPeripheral/**/*',
      'DinCore/DinCore/Source/DinCameraV006/**/*',
      'DinCore/DinCore/Source/DinIPCPeripheral/**/*',
      'DinCore/DinCore/Source/DinCameraV015/**/*',
    ]
  end

  s.subspec 'DinStorageBattery' do |ss|
    ss.dependency 'DinCore/Shared'
    ss.xcconfig = {
      "OTHER_SWIFT_FLAGS": "-D ENABLE_DINCORE_STORAGE_BATTERY"
    }
    ss.source_files = [
      'DinCore/DinCore/Source/DinStorageBatteryPeripheral/**/*',
      'DinCore/DinCore/Source/DinStorageBattery/**/*',
    ]
  end

end
