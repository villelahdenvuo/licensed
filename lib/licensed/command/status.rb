# frozen_string_literal: true
require "yaml"

module Licensed
  module Command
    class Status
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def allowed_or_reviewed?(app, dependency)
        app.allowed?(dependency) || app.reviewed?(dependency)
      end

      def run
        @results = @config.apps.flat_map do |app|
          Dir.chdir app.source_path do
            dependencies = app.sources.flat_map(&:dependencies)
            @config.ui.info "Checking licenses for #{app['name']}: #{dependencies.size} dependencies"

            results = dependencies.map do |dependency|
              name = dependency.name
              filename = app.cache_path.join(dependency.record["type"], "#{name}.txt")

              warnings = []

              # verify cached license data for dependency
              if File.exist?(filename)
                cached_record = DependencyRecord.read(filename)

                if cached_record["version"] != dependency.version
                  warnings << "cached license data out of date"
                end
                warnings << "missing license text" if cached_record.licenses.empty?
                unless allowed_or_reviewed?(app, cached_record)
                  warnings << "license needs reviewed: #{cached_record["license"]}."
                end
              else
                warnings << "cached license data missing"
              end

              if warnings.size > 0
                @config.ui.error("F", false)
                [filename, warnings]
              else
                @config.ui.confirm(".", false)
                nil
              end
            end.compact

            unless results.empty?
              @config.ui.warn "\n\nWarnings:"

              results.each do |filename, warnings|
                @config.ui.info "\n#{filename}:"
                warnings.each do |warning|
                  @config.ui.error "  - #{warning}"
                end
              end
            end

            puts "\n#{dependencies.size} dependencies checked, #{results.size} warnings found."
            results
          end
        end
      end

      def success?
        @results.empty?
      end
    end
  end
end
