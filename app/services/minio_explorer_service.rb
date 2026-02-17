# app/services/minio_explorer_service.rb
class MinioExplorerService
  def initialize(bucket_name, prefix = "")
    @bucket = bucket_name
    @prefix = prefix
    @s3 = Aws::S3::Client.new(
      endpoint: 'http://your-minio-url:9000',
      access_key_id: 'minio-admin',
      secret_access_key: 'minio-password',
      force_path_style: true, # Required for MinIO
      region: 'us-east-1'
    )
  end

  def list_contents
    response = @s3.list_objects_v2(bucket: @bucket, prefix: @prefix, delimiter: '/')

    # Folders are 'common_prefixes', Files are 'contents'
    {
      folders: response.common_prefixes.map(&:prefix),
      files: response.contents.reject { |c| c.key == @prefix }
    }
  end
end