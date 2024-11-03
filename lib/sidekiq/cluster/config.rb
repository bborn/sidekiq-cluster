require "etc"
require "dry-configurable"
require_relative "version"

module Sidekiq
  module Cluster
    class Config
      MEMORY_STRATEGIES = %i[total individual]
      ARGV_SEPARATOR = "--".freeze

      extend ::Dry::Configurable

      setting :spawn_block, constructor: ->(worker) {
                                           require "sidekiq"
                                           require "sidekiq/cli"

                                           process_argv = worker.config.worker_argv.dup
                                           process_argv << "--tag" << "sidekiq.#{worker.config.name}.#{worker.index + 1}"

                                           cli = Sidekiq::CLI.instance
                                           cli.parse %w[bundle exec sidekiq] + process_argv
                                           cli.run
                                         }

      setting :name, default: "default"
      setting :process_count, default: Etc.nprocessors - 1
      setting :max_memory_percent, default: MAX_RAM_PCT
      setting :memory_strategy, default: :total # also supported :individual
      setting :logfile
      setting :work_dir, default: Dir.pwd
      setting :cluster_argv, default: []
      setting :worker_argv, default: []
      setting :debug, default: false
      setting :quiet, default: false
      setting :help, default: false

      def self.split_argv(argv)
        configure do |c|
          if argv.index(ARGV_SEPARATOR)
            c.worker_argv = argv[(argv.index(ARGV_SEPARATOR) + 1)..-1] || []
            c.cluster_argv = argv[0..(argv.index(ARGV_SEPARATOR) - 1)] || []
          else
            c.worker_argv = []
            c.cluster_argv = argv
          end
        end
      end
    end
  end
end
