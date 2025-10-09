Pod::Spec.new do |spec|
  spec.name          = "YourGPTSDK"
  spec.version       = "1.0.0"
  spec.summary       = "YourGPT Chatbot SDK for iOS"
  spec.description   = "A Swift SDK for integrating YourGPT chatbot widget as a full-screen view in iOS applications."
  
  spec.homepage      = "https://yourgpt.ai"
  spec.license       = { :type => "MIT", :file => "LICENSE" }
  spec.author        = { "YourGPT" => "support@yourgpt.ai" }
  
  spec.platform      = :ios, "12.0"
  spec.source        = { :git => "https://github.com/YourGPT/yourgpt-widget-sdk-ios.git", :tag => "#{spec.version}" }
  
  spec.source_files  = "Sources/**/*.{swift,h,m}"
  spec.frameworks    = "UIKit", "WebKit"
  spec.swift_version = "5.0"
end