# Uncomment the next line to define a global platform for your project
 platform :ios, '13.0'
 swift_version = "5.0"
# ignore all warnings from all pods
inhibit_all_warnings!

target 'Deluge Remote' do
  # Pods for Deluge Remote
  use_frameworks!
  pod 'Alamofire'
  pod "PromiseKit"
  pod 'Valet'
  pod 'Eureka'
  pod 'MBProgressHUD'
  pod 'Houston'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['PromiseKit'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end
