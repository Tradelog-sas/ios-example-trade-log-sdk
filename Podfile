# CocoaPods para el demo. Elige la fuente del SDK según TRADELOG_PODS_LOCAL:
#   make pods-local  → local Debug (fuente + xcframeworks Debug, para simulador)
#   make pods        → distribución (git/tag; mecanismo por definir)
platform :ios, '15.0'

project 'TradelogDemo.xcodeproj'

target 'TradelogDemo' do
  use_frameworks!

  if ENV['TRADELOG_PODS_LOCAL'] == '1'
    # LOCAL (Debug/simulador): pod de desarrollo con fuente + frameworks Debug.
    pod 'TradelogSupport', :path => '../tradelog-support-sdk/ios_sdk'
  else
    # DISTRIBUCIÓN (por definir el canal real para CocoaPods).
    pod 'TradelogSupport',
        :git => 'https://github.com/Tradelog-sas/tradelog-support-sdk.git',
        :tag => '2026.508.83'
  end
end
