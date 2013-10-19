Pod::Spec.new do |s|

  s.name         = "MRScalingImageCache"
  s.version      = "0.0.1"
  s.summary      = "A helpful image cache for iOS"
  s.homepage     = "https://github.com/mikerhodes/MRScalingImageCache"
  s.license      = { :type => 'BSD', :file => 'LICENSE' }
  s.author       = "Michael Rhodes"
  s.source       = { :git => "https://github.com/jbmorley/MRScalingImageCache.git", :commit => "75596f5db5cd680dc6c3281062c47834bb7d8fe7" }

  s.source_files = 'Classes/*.{h,m}'

  s.requires_arc = true

  s.platform = :ios, "6.0", :osx, "10.8"

  s.dependency 'AFNetworking', '~> 2.0'
  s.dependency 'UIImage-Categories'

end
