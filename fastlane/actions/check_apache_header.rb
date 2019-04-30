require 'git'
require 'active_support'
require 'active_support/core_ext'

module Fastlane
  module Actions
    class CheckApacheHeaderAction < Action
      def self.run(params)
        repo = Git.open(ENV['PWD'])
        repo.config('remote.origin.fetch', '+refs/heads/*:refs/remotes/origin/*')
        repo.fetch 'origin', {ref: 'refs/heads/master'}
        master_branch_commit = repo.branches['origin/master'].gcommit
        head_commit = repo.gcommit :HEAD
        diffs = repo.diff(head_commit, master_branch_commit)
        source_file_diffs = diffs.select do |diff|
          extname = File.extname diff.path
          params[:file_extens].include? extname
        end
        if source_file_diffs.size > 0
          file_header = File.read './Documents/common/Copyright.txt'
          error_file_diffs = source_file_diffs.reject do |diff|
            if diff.src.present?
              repo.gblob(diff.src).contents.start_with? file_header
            else
              true
            end
          end
          if error_file_diffs.size > 0
            error_file_names = error_file_diffs.map(&:path).join "\n"
            UI.user_error! "Those file don't have apache header:\n#{error_file_names}\n"
          end
        end

        UI.success "Apache header check success"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "check apache header"
      end

      def self.details
        "You can use this action to check source files contains apche header"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :file_extens,
                                       env_name: "FL_CHECK_APACHE_HEADER_FILE_EXTENS",
                                       description: "File extens which need to check",
                                       is_string: false,
                                       default_value: %w(.m .h .swift),
                                       optional: true
                                       )
        ]
      end

      def self.output
      end

      def self.return_value
        nil
      end

      def self.authors
        ["William Zang"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end