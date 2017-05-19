CarrierWave.configure do |config|
  if ENV.has_key?('S3_BUCKET_NAME')
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['S3_REGION']
    }
    config.storage = :fog
    config.fog_attributes = { 'Cache-Control' => "max-age=#{365.days.to_i}" }
    config.fog_directory = ENV['S3_BUCKET_NAME']
    config.cache_dir = "#{Rails.root}/tmp/uploads"
    config.fog_public = true
  else
    config.storage = :file
    config.enable_processing = false
  end
end
