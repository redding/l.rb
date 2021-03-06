# frozen_string_literal: true

require "assert"
require "libexec/l"

class LdotRB::Linter
  class UnitTests < Assert::Context
    desc "LdotRB::Linter"
    subject{ unit_class }

    let(:unit_class) { LdotRB::Linter }
  end

  class InitTests < UnitTests
    desc "when init"
    subject {
      unit_class.new(
        name: name1,
        cmd: cmd1,
        autocorrect_cmd: autocorrect_cmd1,
        extensions: [extension1],
      )
    }

    let(:name1) { Factory.string }
    let(:cmd1) { Factory.string }
    let(:autocorrect_cmd1) { Factory.string }
    let(:extension1) { ".rb" }
    let(:applicable_source_files) { ["app/file1.rb", "app/file2.rb"] }
    let(:not_applicable_source_file) { "app/file2.js" }
    let(:cli_option_name1) { Factory.string }
    let(:cli_abbrev1) { Factory.string(1) }

    should have_readers :name, :cmd, :autocorrect_cmd, :extensions
    should have_readers :cli_option_name, :cli_abbrev
    should have_imeths :specifically_enabled=, :specifically_enabled?, :enabled?
    should have_imeths :cmd_str, :autocorrect_cmd_str

    should "know its attributes" do
      assert_that(subject.name).equals(name1)
      assert_that(subject.cmd).equals(cmd1)
      assert_that(subject.autocorrect_cmd).equals(autocorrect_cmd1)
      assert_that(subject.extensions).equals([extension1])
      assert_that(subject.cli_option_name).equals(name1)
      assert_that(subject.cli_abbrev).equals(name1[0])

      linter =
        unit_class.new(
          name: name1,
          cmd: cmd1,
          autocorrect_cmd: autocorrect_cmd1,
          extensions: [extension1],
          cli_option_name: cli_option_name1,
          cli_abbrev: cli_abbrev1,
        )
      assert_that(linter.cli_option_name).equals(cli_option_name1)
      assert_that(linter.cli_abbrev).equals(cli_abbrev1)
    end

    should "not complain if unknown kargs are given" do
      assert_that{
        unit_class.new(
          name: name1,
          cmd: cmd1,
          extensions: [extension1],
          other: "value",
        )
      }.does_not_raise
    end

    should "know if it is enabled and specifically enabled" do
      assert_that(subject.specifically_enabled?).is_false
      assert_that(subject.enabled?).is_true

      subject.specifically_enabled = nil
      assert_that(subject.specifically_enabled?).is_false
      assert_that(subject.enabled?).is_true

      subject.specifically_enabled = true
      assert_that(subject.specifically_enabled?).is_true
      assert_that(subject.enabled?).is_true

      subject.specifically_enabled = false
      assert_that(subject.specifically_enabled?).is_false
      assert_that(subject.enabled?).is_false
    end

    should "know its cmd str" do
      assert_that(subject.cmd_str(nil)).equals("#{cmd1} .")
      assert_that(subject.cmd_str(applicable_source_files)).equals(
        "#{cmd1} #{applicable_source_files.join(" ")}"
      )
      assert_that(subject.cmd_str([not_applicable_source_file])).is_nil
    end

    should "know its autocorrect cmd str" do
      assert_that(subject.autocorrect_cmd_str(nil))
        .equals("#{autocorrect_cmd1} .")
      assert_that(subject.autocorrect_cmd_str(applicable_source_files)).equals(
        "#{autocorrect_cmd1} #{applicable_source_files.join(" ")}"
      )
      assert_that(subject.autocorrect_cmd_str([not_applicable_source_file]))
        .is_nil

      Assert.stub(subject, :autocorrect_cmd){ nil }
      assert_that(subject.autocorrect_cmd_str(nil)).is_nil
      assert_that(subject.autocorrect_cmd_str(applicable_source_files)).is_nil
      assert_that(subject.autocorrect_cmd_str([not_applicable_source_file]))
        .is_nil
    end
  end
end
