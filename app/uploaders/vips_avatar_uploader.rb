class VipsAvatarUploader < Hyrax::AvatarUploader
  include CarrierWave::Vips

  version :medium do
    process resize_to_limit: [300, 300]
  end

  version :thumb do
    process resize_to_limit: [100, 100]
  end

end