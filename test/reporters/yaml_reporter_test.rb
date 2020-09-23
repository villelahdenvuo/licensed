# frozen_string_literal: true
require "test_helper"

describe Licensed::Reporters::JsonReporter do
  let(:shell) { TestShell.new }
  let(:reporter) { Licensed::Reporters::YamlReporter.new(shell) }
  let(:app) { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd }) }
  let(:source) { TestSource.new(app) }
  let(:dependency) { source.dependencies.first }
  let(:command) { TestCommand.new(config: nil) }

  describe "#report_run" do
    it "runs a block" do
      success = false
      reporter.report_run(command) do
        success = true
      end
      assert success
    end

    it "returns the result of the block" do
      assert_equal 1, reporter.report_run(command) { 1 }
    end

    it "provides a report hash to the block" do
      reporter.report_run(command) { |report| refute_nil report }
    end

    it "prints any data set as YAML" do
      reporter.report_run(command) { |report| report["key"] = "test" }

      expected_object = {
        "key" => "test"
      }
      assert_includes shell.messages,
                      {
                         message: expected_object.to_yaml,
                         newline: true,
                         style: :info
                      }
    end

    it "sanitizes data to print using primitive types" do
      reporter.report_run(command) do |report|
        report[:key] = :value
        report[:path] = Pathname.pwd
        report[:hash] = {
          array: [1, :symbol, true, false],
          hash: {
            key: :value
          }
        }
        report[:array] = [
          { key: :value },
          [1, :symbol, true, false],
          :symbol
        ]
      end

      expected_object = {
        "key" => "value",
        "path" => Pathname.pwd.to_s,
        "hash" => {
          "array" => [1, "symbol", true, false],
          "hash" => {
            "key" => "value"
          }
        },
        "array" => [
          { "key" => "value" },
          [1, "symbol", true, false],
          "symbol"
        ]
      }

      assert_includes shell.messages,
                      {
                         message: expected_object.to_yaml,
                         newline: true,
                         style: :info
                      }
    end
  end

  describe "#report_app" do
    it "runs a block" do
      success = false
      reporter.report_run(command) do
        reporter.report_app(app) { success = true }
      end
      assert success
    end

    it "returns the result of the block" do
      reporter.report_run(command) do
        assert_equal 1, reporter.report_app(app) { 1 }
      end
    end

    it "provides a report hash to the block" do
      reporter.report_run(command) do
        reporter.report_app(app) { |report| refute_nil report }
      end
    end

    it "prints any data set as YAML" do
      reporter.report_run(command) do
        reporter.report_app(app) { |report| report["key"] = "test" }
      end

      expected_object = {
        "apps" => [
          {
            "name" => app["name"],
            "key" => "test"
          }
        ]
      }
      assert_includes shell.messages,
                      {
                         message: expected_object.to_yaml,
                         newline: true,
                         style: :info
                      }
    end
  end

  describe "#report_source" do
    it "runs a block" do
      success = false
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) { success = true }
        end
      end

      assert success
    end

    it "returns the result of the block" do
      reporter.report_run(command) do
        reporter.report_app(app) do
          assert_equal 1, reporter.report_source(source) { 1 }
        end
      end
    end

    it "provides a report hash to the block" do
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) { |report| refute_nil report }
        end
      end
    end

    it "prints any data set as YAML" do
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) { |report| report["key"] = "test" }
        end
      end

      expected_object = {
        "apps" => [
          {
            "name" => app["name"],
            "sources" => [
              {
                "name" => "#{app["name"]}.#{source.class.type}",
                "key" => "test"
              }
            ]
          }
        ]
      }
      assert_includes shell.messages,
                      {
                         message: expected_object.to_yaml,
                         newline: true,
                         style: :info
                      }
    end
  end

  describe "#report_dependency" do
    it "runs a block" do
      success = false
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) do
            reporter.report_dependency(dependency) { success = true }
          end
        end
      end

      assert success
    end

    it "returns the result of the block" do
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) do
            assert_equal 1, reporter.report_dependency(dependency) { 1 }
          end
        end
      end
    end

    it "provides a report hash to the block" do
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) do
            reporter.report_dependency(dependency) { |report| refute_nil report }
          end
        end
      end
    end

    it "prints any data set as YAML" do
      reporter.report_run(command) do
        reporter.report_app(app) do
          reporter.report_source(source) do
            reporter.report_dependency(dependency) { |report| report["key"] = "test" }
          end
        end
      end

      expected_object = {
        "apps" => [
          {
            "name" => app["name"],
            "sources" => [
              {
                "name" => "#{app["name"]}.#{source.class.type}",
                "dependencies" => [
                  {
                    "name" => "#{app["name"]}.#{source.class.type}.#{dependency.name}",
                    "key" => "test"
                  }
                ]
              }
            ]
          }
        ]
      }
      assert_includes shell.messages,
                      {
                         message: expected_object.to_yaml,
                         newline: true,
                         style: :info
                      }
    end
  end
end
