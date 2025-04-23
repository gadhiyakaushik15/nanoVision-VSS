# Uncomment the next line to define a global platform for your project
 platform :ios, '15.0'

target 'nanoVision' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for nanoVision
  pod 'Alamofire'
  pod 'SVProgressHUD'
  pod 'IQKeyboardManagerSwift'
  pod 'KeychainSwift'
  pod 'SSZipArchive'
  pod 'TTTAttributedLabel'
  pod 'BiometricAuthentication'
  pod 'MKToolTip'
  pod 'SideMenu'
  pod 'CocoaMQTT'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
end
