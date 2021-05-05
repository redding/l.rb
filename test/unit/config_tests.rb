# frozen_string_literal: true

require "assert"
require "libexec/l"

class LdotRB::Config
  class UnitTests < Assert::Context
    desc "LdotRB::Config"
    subject{ unit_class }

    let(:unit_class) { LdotRB::Config }

    should have_imeths :settings

    should "know its config file path" do
      assert_that(subject::CONFIG_FILE_PATH).equals("./.l.yml")
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ config }

    let(:config) { unit_class.new }

    should have_readers :stdout, :version
    should have_readers :source_file_paths, :ignored_file_paths, :linter_hashes
    should have_imeths  :changed_only, :changed_ref
    should have_imeths :dry_run, :list, :autocorrect, :debug
    should have_imeths  :apply
    should have_imeths :debug_msg, :debug_puts, :puts, :print
    should have_imeths :bench, :bench_start_msg, :bench_finish_msg

    should "know its stdout" do
      assert_that(subject.stdout).is($stdout)

      io = StringIO.new(+"")
      assert_that(unit_class.new(io).stdout).is_the_same_as(io)
    end

    should "default its configured attrs" do
      assert_that(subject.source_file_paths).equals(["./"])
      assert_that(subject.ignored_file_paths).equals([])
      assert_that(subject.linter_hashes).equals([])
    end

    should "default its settings attrs" do
      assert_that(subject.changed_only).is_false
      assert_that(subject.changed_ref).is_empty
      assert_that(subject.dry_run).is_false
      assert_that(subject.list).is_false
      assert_that(subject.autocorrect).is_false
      assert_that(subject.debug).is_false
    end

    should "allow applying custom settings attrs" do
      settings = {
        :changed_only => true,
        :changed_ref  => Factory.string,
        :dry_run      => true,
        :list         => true,
        :autocorrect  => true,
        :debug        => true
      }
      subject.apply(settings)

      assert_that(subject.changed_only).equals(settings[:changed_only])
      assert_that(subject.changed_ref).equals(settings[:changed_ref])
      assert_that(subject.dry_run).equals(settings[:dry_run])
      assert_that(subject.list).equals(settings[:list])
      assert_that(subject.autocorrect).equals(settings[:autocorrect])
      assert_that(subject.debug).equals(settings[:debug])
    end

    should "know how to build debug messages" do
      msg = Factory.string
      assert_that(subject.debug_msg(msg)).equals("[DEBUG] #{msg}")
    end

    should "know how to build bench start messages" do
      msg = Factory.string
      assert_that(subject.bench_start_msg(msg))
        .equals(subject.debug_msg("#{msg}...".ljust(30)))

      msg = Factory.string(35)
      assert_that(subject.bench_start_msg(msg)).equals(
        subject.debug_msg("#{msg}...".ljust(30)))
    end

    should "know how to build bench finish messages" do
      time_in_ms = Factory.float
      assert_that(subject.bench_finish_msg(time_in_ms)).equals(
        " (#{time_in_ms} ms)")
    end
  end

  class BenchTests < InitTests
    desc "`bench`"
    setup do
      @start_msg   = Factory.string
      @proc        = proc{}
      @lint_output = +""
    end

    let(:config) { unit_class.new(StringIO.new(@lint_output)) }

    should "not output any stdout info if not in debug mode" do
      Assert.stub(subject, :debug){ false }
      subject.bench(@start_msg, &@proc)

      assert_that(@lint_output).is_empty
    end

    should "output any stdout info if in debug mode" do
      Assert.stub(subject, :debug){ true }
      time_in_ms = subject.bench(@start_msg, &@proc)

      assert_that(@lint_output).equals(
        "#{subject.bench_start_msg(@start_msg)}"\
        "#{subject.bench_finish_msg(time_in_ms)}\n"
      )
    end
  end
end
