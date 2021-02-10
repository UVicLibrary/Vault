module Hyrax
  class VersioningService
    class << self
      # Make a version and record the version committer
      # @param [ActiveFedora::File] content
      # @param [User, String] user
      def create(content, user = nil)
        content.create_version
        record_committer(content, user) if user
      end

      # @param [ActiveFedora::File] file
      def latest_version_of(file)
        file.versions.last
      end

      def versioned_file_id(file)
        versions = file.versions.all
        if versions.count > 1 # Check if a file set has multiple versions
          # The latest is always the "last" version, even if a past version was restored
          ActiveFedora::Base.uri_to_id(file.versions.last.uri)
        else
          file.id
        end
      end

      # Record the version committer of the last version
      # @param [ActiveFedora::File] content
      # @param [User, String] user_key
      def record_committer(content, user_key)
        user_key = user_key.user_key if user_key.respond_to?(:user_key)
        version = latest_version_of(content)
        return if version.nil?
        VersionCommitter.create(version_id: version.uri, committer_login: user_key)
      end
    end
  end
end
