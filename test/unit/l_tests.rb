# frozen_string_literal: true

require "assert"
require "libexec/l"

module LdotRB
  class UnitTests < Assert::Context
    desc "LdotRB"
    subject { unit_module }

    let(:unit_module) { LdotRB }

    should have_imeths :config, :apply, :bench, :run

    should "know its config singleton" do
      assert_that(subject.config).is_instance_of(subject::Config)
      assert_that(subject.config).is(subject.config)
    end
  end
end
