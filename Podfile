# Uncomment the next line to define a global platform for your project
 platform :ios, '12.1'
 swift_version = "4.0"
# ignore all warnings from all pods
inhibit_all_warnings!

target 'Deluge Remote' do
  # Pods for Deluge Remote
  use_frameworks!
  pod 'Alamofire'
  pod 'PromiseKit', "~> 4.5.2"
  pod 'Valet', "<= 3.2.3" 
  pod 'Eureka',"~> 4.3.0"
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
