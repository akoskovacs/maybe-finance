module Finachy
  class << self
    def version
      date_version
    end

    def commit_sha
      if Rails.env.production?
        ENV["BUILD_COMMIT_SHA"]
      else
        `git rev-parse HEAD`.chomp
      end
    end

    private
      def date_version
        "2026.01.10-01"
      end
  end
end
