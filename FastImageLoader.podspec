Pod::Spec.new do |s|
  s.name         = "FastImageLoader"
  s.version      = "1.0.0"
  s.summary      = "Swift library to speed up UIImage loading"

  s.description  = <<-DESC
                      Swift library to speed up subsequent UIImage loading in the cost of disk space.
                      It caches image data on disk after first load in raw format, to be able to read it back very quickly.
                      User may expect 10x to 50x increase compared to UIImage(named:) loading.
                   DESC

  s.homepage     = "https://github.com/Pash237/FastImageLoader"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Pavel Alexeev" => "pasha.alexeev@gmail.com" }
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/Pash237/FastImageLoader.git", :tag => "#{s.version}" }

  s.source_files = "Source/*.swift"
end
