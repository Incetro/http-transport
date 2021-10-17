Pod::Spec.new do |s|
  s.name         = "incetro-http-transport"
  s.module_name  = "HTTPTransport"
  s.version      = "5.2.5"
  s.summary      = "HTTP transport library"
  s.description  = "Based on Alamofire. Implements synchronous transport"
  s.homepage     = "https://github.com/Incetro/http-transport.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "incetro" => "incetro@ya.ru", "Jeorge Taflanidi" => "et@redmadrobot.com", "Gasol" => "1ezya007@gmail.com" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/Incetro/http-transport.git", :tag => s.version, :branch => "main" }
  s.source_files = "HTTPTransport/HTTPTransport/Classes/**/*"
  s.requires_arc = true
  s.dependency "Alamofire", '~> 5'
end
