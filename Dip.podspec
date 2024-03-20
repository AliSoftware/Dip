Pod::Spec.new do |s|
  s.name             = "Dip"
  s.version          = "7.1.2"
  s.summary          = "Dependency Injection for Swift made easy."

  s.description      = <<-DESC
                        Dip is a Swift Dependency Injection Container.
                        It provides reusable functionality for managing dependencies of your types 
                        and will help you to wire up different parts of your app.
                        DESC

  s.homepage         = "https://github.com/AliSoftware/Dip"
  s.license          = 'MIT'
  s.authors          = { "Olivier Halligon" => "olivier@halligon.net", "Ilya Puchka" => "ilyapuchka@gmail.com" }
  s.source           = { :git => "https://github.com/AliSoftware/Dip.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/aligatr'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.visionos.deployment_target = '1.1'

  s.requires_arc = true

  s.source_files = 'Sources/**/*.swift'

  s.swift_version = "5.0", "5.1"
end
