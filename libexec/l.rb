#!/usr/bin/env ruby

# frozen_string_literal: true

require "benchmark"
require "set"
require "yaml"

module LdotRB
  VERSION = "0.1.4"

  class Config
    CONFIG_FILE_PATH = "./.l.yml"

    def self.settings(*items)
      items.each do |item|
        define_method(item) do |*args|
          if !(value = args.size > 1 ? args : args.first).nil?
            instance_variable_set("@#{item}", value)
          end
          instance_variable_get("@#{item}")
        end
      end
    end

    def self.file_path_source_files(file_path)
      pwd = Dir.pwd
      path = File.expand_path(file_path, pwd)

      (Dir.glob("#{path}*") + Dir.glob("#{path}*/**/*"))
        .map{ |p| p.gsub("#{pwd}/", "") }
    end

    def self.root_source_files
      pwd = Dir.pwd

      Dir.glob("#{pwd}/*")
        .select{ |p| File.file?(p) }
        .map{ |p| p.gsub("#{pwd}/", "") }
    end

    attr_reader :stdout, :version
    attr_reader :source_file_paths, :ignored_file_paths, :linter_hashes

    settings :changed_only, :changed_ref
    settings :dry_run, :list, :autocorrect, :debug

    def initialize(stdout = nil)
      @stdout = stdout || $stdout
      @version = VERSION

      @source_file_paths = ["./"]
      @ignored_file_paths = []
      @linter_hashes = []

      # cli option settings
      @changed_only = false
      @changed_ref  = ""
      @dry_run      = false
      @list         = false
      @autocorrect  = false
      @debug        = false
    end

    def source_whitelist
      @source_whitelist ||=
        source_file_paths
          .reduce(Set.new(self.class.root_source_files)) { |acc, path|
            acc + self.class.file_path_source_files(path)
          }
          .sort
    end

    def source_blacklist
      @source_blacklist ||=
        ignored_file_paths
          .reduce(Set.new) { |acc, path|
            acc + self.class.file_path_source_files(path)
          }
          .sort
    end

    def linters
      @linters ||=
        @linter_hashes.map{ |linter_hash|
          Linter.new(**linter_hash.transform_keys(&:to_sym))
        }
    end

    def apply(settings)
      settings.keys.each do |name|
        if !settings[name].nil? && self.respond_to?(name.to_s)
          self.send(name.to_s, settings[name])
        elsif (linter = linters.detect { |l| l.cli_option_name == name })
          linter.specifically_enabled = settings[name]
        end
      end
    end

    def load
      config = YAML.load(File.read(CONFIG_FILE_PATH))
      @source_file_paths  = config["source_file_paths"] || @source_file_paths
      @ignored_file_paths = config["ignored_file_paths"] || @ignored_file_paths
      @linter_hashes      = config["linters"] || @linter_hashes
    end

    def debug_msg(msg)
      "[DEBUG] #{msg}"
    end

    def debug_puts(msg)
      self.puts debug_msg(msg)
    end

    def puts(msg)
      self.stdout.puts msg
    end

    def print(msg)
      self.stdout.print msg
    end

    def bench(start_msg, &block)
      if !self.debug
        block.call; return
      end
      self.print bench_start_msg(start_msg)
      RoundedMillisecondTime.new(Benchmark.measure(&block).real).tap do |time_in_ms|
        self.puts bench_finish_msg(time_in_ms)
      end
    end

    def bench_start_msg(msg)
      self.debug_msg("#{msg}...".ljust(30))
    end

    def bench_finish_msg(time_in_ms)
      " (#{time_in_ms} ms)"
    end

    private

    def source_root_files
      @source_whitelist ||=
        source_files
          .reduce(Set.new) { |acc, path|
            acc + self.class.file_path_source_files(path)
          }
          .sort
    end
  end

  class Linter
    ARGUMENT_SEPARATOR = " "

    attr_reader :name, :cmd, :autocorrect_cmd
    attr_reader :extensions, :cli_option_name, :cli_abbrev

    def initialize(
          name:,
          cmd:,
          extensions:,
          autocorrect_cmd: nil,
          cli_option_name: nil,
          cli_abbrev: nil,
          **)
      @name = name
      @cmd = cmd
      @autocorrect_cmd = autocorrect_cmd
      @extensions = extensions
      @cli_option_name = cli_option_name || name.downcase.gsub(/\W+/, "_")
      @cli_abbrev = cli_abbrev || name[0].downcase

      @specifically_enabled = nil
      @enabled = true
    end

    # This is set by CLI flags:
    # * `true`: enabled by flag, e.g. `--rubocop`
    # * `false`: disabled by flag, e.g. `--no-rubocop`
    # * `nil`: default when no is flag specified
    def specifically_enabled=(value)
      @enabled = false if value == false
      @specifically_enabled = value
    end

    def specifically_enabled?
      !!@specifically_enabled
    end

    def enabled?
      !!@enabled
    end

    def cmd_str(specified_source_files)
      return "#{cmd} ." if specified_source_files.nil?

      applicable_source_files =
        specified_source_files.select { |source_file|
          @extensions.include?(File.extname(source_file))
        }
      return if applicable_source_files.none?

      "#{cmd} #{applicable_source_files.join(ARGUMENT_SEPARATOR)}"
    end

    def autocorrect_cmd_str(specified_source_files)
      return if autocorrect_cmd.nil?
      return "#{autocorrect_cmd} ." if specified_source_files.nil?

      applicable_source_files =
        specified_source_files.select { |source_file|
          @extensions.include?(File.extname(source_file))
        }
      return if applicable_source_files.none?

      "#{autocorrect_cmd} #{applicable_source_files.join(ARGUMENT_SEPARATOR)}"
    end

    def ==(other_linter)
      return super unless other_linter.kind_of?(self.class)

      name == other_linter.name &&
      cmd == other_linter.cmd &&
      extensions == other_linter.extensions &&
      cli_option_name == other_linter.cli_option_name &&
      cli_abbrev == other_linter.cli_abbrev
    end
  end

  class Runner
    DEFAULT_FILE_PATH = "."

    attr_reader :file_paths, :config

    def initialize(file_paths, config:)
      @file_paths = file_paths
      @config = config
    end

    def execute?
      any_linters? && !dry_run? && !list?
    end

    def any_linters?
      config.linters.any?
    end

    def dry_run?
      !!config.dry_run
    end

    def list?
      !!config.list
    end

    def autocorrect?
      !!config.autocorrect
    end

    def debug?
      !!config.debug
    end

    def changed_only?
      !!config.changed_only
    end

    def any_specifically_enabled_linters?
      specifically_enabled_linters.any?
    end

    def linters
      config.linters
    end

    def specifically_enabled_linters
      @specifically_enabled_linters ||=
        config.linters.select(&:specifically_enabled?)
    end

    def enabled_linters
      @enabled_linters ||= config.linters.select(&:enabled?)
    end

    def specified_source_files
      @specified_source_files ||=
        if file_paths.any? || changed_only?
          (found_source_files & config.source_whitelist) - config.source_blacklist
        else
          nil
        end
    end

    def cmds
      @cmds ||=
        linters.reduce({}) { |acc, linter|
          acc[linter.cli_option_name] = linter.cmd_str(specified_source_files)
          acc
        }
    end

    def autocorrect_cmds
      @autocorrect_cmds ||=
        linters.reduce({}) { |acc, linter|
          acc[linter.cli_option_name] =
            linter.autocorrect_cmd_str(specified_source_files)
          acc
        }
    end

    def run
      output_source_files = specified_source_files.to_a
      if debug?
        debug_puts "#{output_source_files.size} specified source files:"
        output_source_files.each do |source_file|
          debug_puts "  #{source_file}"
        end
      end

      if list?
        puts output_source_files.join("\n")
      else
        linters_to_run =
          if any_specifically_enabled_linters?
            specifically_enabled_linters
          else
            enabled_linters
          end
        cmd_str_method = autocorrect? ? :autocorrect_cmd_str : :cmd_str

        linters_to_run.each_with_index do |linter, index|
          puts "\n\n" if index > 0
          puts "Running #{linter.name}"

          cmd = linter.public_send(cmd_str_method, specified_source_files)
          next unless cmd

          debug_puts "  #{cmd}" if debug?
          puts cmd if dry_run?
          system(cmd) if execute?
        end
      end
    end

    private

    def found_source_files
      source_file_paths = file_paths.empty? ? [DEFAULT_FILE_PATH] : file_paths
      files = nil

      if changed_only?
        result = nil
        LdotRB.bench("Lookup changed source files") do
          result = changed_source_files(source_file_paths)
        end
        files = result.files
        if debug?
          debug_puts "  `#{result.cmd}`"
        end
      else
        LdotRB.bench("Lookup source files") do
          files = globbed_source_files(source_file_paths)
        end
      end

      files
    end

    def changed_source_files(source_file_paths)
      result = GitChangedFiles.new(config, source_file_paths)
      ChangedResult.new(result.cmd, globbed_source_files(result.files))
    end

    def globbed_source_files(source_file_paths)
      source_file_paths
        .reduce(Set.new) { |acc, source_file_path|
          acc + Config.file_path_source_files(source_file_path)
        }
        .sort
    end

    def puts(*args)
      config.puts(*args)
    end

    def debug_puts(*args)
      config.debug_puts(*args)
    end
  end

  ChangedResult = Struct.new(:cmd, :files)

  module GitChangedFiles
    def self.cmd(config, file_paths)
      [
        "git diff --no-ext-diff --relative --name-only #{config.changed_ref}", # changed files
        "git ls-files --others --exclude-standard"                             # added files
      ]
        .map{ |c| "#{c} -- #{file_paths.join(" ")}" }
        .join(" && ")
    end

    def self.new(config, file_paths)
      cmd = self.cmd(config, file_paths)
      ChangedResult.new(cmd, `#{cmd}`.split("\n"))
    end
  end

  module RoundedMillisecondTime
    ROUND_PRECISION = 3
    ROUND_MODIFIER = 10 ** ROUND_PRECISION
    def self.new(time_in_seconds)
      (time_in_seconds * 1000 * ROUND_MODIFIER).to_i / ROUND_MODIFIER.to_f
    end
  end

  class CLIRB  # Version 1.2.0, https://github.com/redding/cli.rb
    Error    = Class.new(RuntimeError);
    HelpExit = Class.new(RuntimeError); VersionExit = Class.new(RuntimeError)
    attr_reader :argv, :args, :opts, :data

    def initialize(&block)
      @options = []; instance_eval(&block) if block
      require "optparse"
      @data, @args, @opts = [], [], {}; @parser = OptionParser.new do |p|
        p.banner = ""; @options.each do |o|
          @opts[o.name] = o.value; p.on(*o.parser_args){ |v| @opts[o.name] = v }
        end
        p.on_tail("--version", ""){ |v| raise VersionExit, v.to_s }
        p.on_tail("--help",    ""){ |v| raise HelpExit,    v.to_s }
      end
    end

    def option(*args, **kargs); @options << Option.new(*args, **kargs); end
    def parse!(argv)
      @args = (argv || []).dup.tap do |args_list|
        begin; @parser.parse!(args_list)
        rescue OptionParser::ParseError => err; raise Error, err.message; end
      end; @data = @args + [@opts]
    end
    def to_s; @parser.to_s; end
    def inspect
      "#<#{self.class}:#{"0x0%x" % (object_id << 1)} @data=#{@data.inspect}>"
    end

    class Option
      attr_reader :name, :opt_name, :desc, :abbrev, :value, :klass, :parser_args

      def initialize(name, desc = nil, abbrev: nil, value: nil)
        @name, @desc = name, desc || ""
        @opt_name, @abbrev = parse_name_values(name, abbrev)
        @value, @klass = gvalinfo(value)
        @parser_args = if [TrueClass, FalseClass, NilClass].include?(@klass)
          ["-#{@abbrev}", "--[no-]#{@opt_name}", @desc]
        else
          ["-#{@abbrev}", "--#{@opt_name} VALUE", @klass, @desc]
        end
      end

      private

      def parse_name_values(name, custom_abbrev)
        [ (processed_name = name.to_s.strip.downcase).gsub("_", "-"),
          custom_abbrev || processed_name.gsub(/[^a-z]/, "").chars.first || "a"
        ]
      end
      def gvalinfo(v); v.kind_of?(Class) ? [nil,v] : [v,v.class]; end
    end
  end

  # LdotRB

  def self.clirb
    linters = config.linters
    @clirb ||= CLIRB.new do
      linters.each do |linter|
        option(
          linter.cli_option_name,
          "specifically run or don't run #{linter.name}",
          abbrev: linter.cli_abbrev,
        )
      end
      option(
        "changed_only",
        "only run source files with changes",
        abbrev: "c",
      )
      option(
        "changed_ref",
        "reference for changes, use with `-c` opt",
        abbrev: "r",
        value: "",
      )
      option(
        "autocorrect",
        "autocorrect any correctable violations",
        abbrev: "a",
      )
      option(
        "dry_run",
        "output each linter command to $stdout without executing",
      )
      option(
        "list",
        "list source files on $stdout",
        abbrev: "l",
      )
      # show specified source files, cli err backtraces, etc
      option("debug",
        "run in debug mode",
        abbrev: "d",
      )
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.apply(argv)
    config.load

    clirb.parse!(argv)
    config.apply(clirb.opts)
  end

  def self.bench(*args, &block)
    config.bench(*args, &block)
  end

  def self.run
    begin
      bench("ARGV parse and configure"){ apply(ARGV) }
      Runner.new(self.clirb.args, config: self.config).run
    rescue CLIRB::HelpExit
      config.puts help_msg
    rescue CLIRB::VersionExit
      config.puts config.version
    rescue CLIRB::Error => exception
      config.puts "#{exception.message}\n\n"
      config.puts config.debug ? exception.backtrace.join("\n") : help_msg
      exit(1)
    rescue StandardError => exception
      config.puts "#{exception.class}: #{exception.message}"
      config.puts exception.backtrace.join("\n")
      exit(1)
    end
    exit(0)
  end

  def self.help_msg
    "Usage: l [options] [FILES]\n\n"\
    "Options:"\
    "#{clirb}"
  end
end

unless ::Hash.method_defined?(:transform_keys)
  class ::Hash
    def transform_keys(&block)
      reduce({}) do |acc, (key, value)|
        acc[block.call(key)] = value
        acc
      end
    end
  end
end

unless ENV["LDOTRB_DISABLE_RUN"]
  LdotRB.run
end
