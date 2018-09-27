require 'rake/garden/async'

class AsyncTester
  include Garden::AsyncLifecycle
  attr_accessor :force_skip
  def process(); end
  def should_skip
    @force_skip
  end
end

describe AsyncTester do
  context "when idle" do
    it { is_expected.to have_attributes("running?" => false) }
    it { is_expected.to have_attributes("completed?" => false) }
    it { is_expected.to have_attributes("skipped?" => false) }
    it { is_expected.to have_attributes("time" => nil) }
  end

  context "when running" do
    before :each do
      subject.start(0)
    end
    it { is_expected.to have_attributes("running?" => true) }
    it { is_expected.to have_attributes("completed?" => false) }
    it { is_expected.to have_attributes("skipped?" => false) }
    it { is_expected.to have_attributes("time" => nil) }
  end

  context "when complete" do
    before :each do
      subject.start(0)
      subject.update_status
    end

    it { is_expected.to have_attributes("running?" => false) }
    it { is_expected.to have_attributes("completed?" => true) }
    it { is_expected.to have_attributes("skipped?" => false) }
    it { is_expected.to have_attributes("time" => a_truthy_value) }
  end

  context "when skipping" do
    before :each do
      subject.force_skip = true
      subject.start(0)
    end

    it { is_expected.to have_attributes("running?" => false) }
    it { is_expected.to have_attributes("completed?" => true) }
    it { is_expected.to have_attributes("skipped?" => true) }
    it { is_expected.to have_attributes("time" => a_truthy_value) }
  end
  context "when having an error" do

  end
end
