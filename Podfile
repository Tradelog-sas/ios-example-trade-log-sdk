# CocoaPods para el demo. El SDK se consume desde el paquete que descarga el CLI
# de Tradelog (`tradelog install --pods` → Tradelog/TradelogSupport), que trae el
# .podspec con los xcframeworks vendorizados.
platform :ios, '15.0'

project 'TradelogDemo.xcodeproj'

target 'TradelogDemo' do
  use_frameworks!

  pod 'TradelogSupport', :path => 'Tradelog/TradelogSupport'
end
