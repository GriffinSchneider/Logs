use_frameworks!
platform :ios, '10.0'

target 'tracker' do
  pod 'DRYUI'
  pod 'MoveViewUpForKeyboardKit'
  pod 'JSONModel'
  pod 'UIButton-ANDYHighlighted'
  pod 'Toast-Swift'
  pod 'SwiftyDropbox'
  pod 'RxSwift', '~> 3.0.0'
  pod 'RxCocoa', '~> 3.0.0'
  pod 'RxGesture'
  pod "Popover", :path => 'Popover'
  pod 'RxDataSources', '~> 1.0.0-beta.2'
  pod 'ObjectMapper'
end


target 'TrackerToday' do
  pod 'DRYUI'
  pod 'MoveViewUpForKeyboardKit'
  pod 'JSONModel'
  pod 'UIButton-ANDYHighlighted'
  pod 'Toast-Swift'
  pod 'SwiftyDropbox'
  pod 'RxSwift', '~> 3.0.0'
  pod 'RxCocoa', '~> 3.0.0'
  pod 'RxGesture'
  pod "Popover", :path => 'Popover'
  pod 'RxDataSources', '~> 1.0.0-beta.2'
  pod 'ObjectMapper'
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
