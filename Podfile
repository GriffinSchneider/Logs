use_frameworks!
platform :ios, '11.0'

target 'tracker' do
  pod 'DRYUI'
  pod 'MoveViewUpForKeyboardKit'
  pod 'UIButton-ANDYHighlighted'
  pod 'Toast-Swift'
  pod 'SwiftyDropbox', :git => 'https://github.com/SofteqDG/SwiftyDropbox.git', :branch => 'feature/swift-4.2'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGesture'
  pod "Popover", :path => 'Popover'
end

target 'TrackerToday' do
  pod 'DRYUI'
  pod 'MoveViewUpForKeyboardKit'
  pod 'UIButton-ANDYHighlighted'
  pod 'Toast-Swift'
  pod 'SwiftyDropbox', :git => 'https://github.com/SofteqDG/SwiftyDropbox.git', :branch => 'feature/swift-4.2'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGesture'
  pod "Popover", :path => 'Popover'
end

post_install do |installer|
  # NOTE: If you are using a CocoaPods version prior to 0.38, replace `pods_project` with `project` on the below line
  installer.pods_project.targets.each do |target|
    if target.name.end_with? "Popover"
      target.build_configurations.each do |build_configuration|
        if build_configuration.build_settings['APPLICATION_EXTENSION_API_ONLY'] == 'YES'
          build_configuration.build_settings['OTHER_SWIFT_FLAGS'] = '-DPOPOVER_APP_EXTENSIONS'
        end
      end
    end
  end
end
