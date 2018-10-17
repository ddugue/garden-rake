# frozen_string_literal: true
require 'rake'
require 'rake/garden/chore'
require 'rake/garden/file_chore'
require 'rake/garden/options'
require 'rake/garden/metadata'

describe Garden::Chore do
  fs = ["/tmp/choretest/sub/*.txt", "/tmp/choretest/b.txt"]
  let!(:data) { { 'name' => 'fake' } }

  subject { Garden::Chore.define_task(options, arg) }

  let(:options) { Garden::Option.new }
  let(:arg) { { :name_long => fs } }

  context 'simple chore creation' do
    before(:each) do

      $metadata = Garden::TreeDict.new data
      %x( rm -fr /tmp/choretest )
      %x( mkdir /tmp/choretest )
      %x( mkdir /tmp/choretest/sub )
      %x( touch /tmp/choretest/sub/a.txt )
      %x( touch /tmp/choretest/b.txt )
    end


    it "should have right input_files" do
      expect(subject.input_files.to_a).to eq(["/tmp/choretest/sub/a.txt", "/tmp/choretest/b.txt"])
    end
    it { is_expected.to have_attributes('title' => 'Name long'.bold) }
    it { is_expected.to have_attributes('needed?' => true) }
  end

  describe "needed? when not needed" do
    let(:arg) { { :newname_long => fs } }
    it "should not be needed if execution time is more recent" do
      subject.instance_variable_set(:@last_executed, Time.now + 1000)
      expect(subject.needed?).to be(false)
    end
  end

end

describe Garden::FileChore do
  let!(:data) { { 'name' => 'fake' } }
  before(:each) do

    $metadata = Garden::TreeDict.new data
    %x( rm -fr /tmp/choretest )
    %x( mkdir /tmp/choretest )
    %x( mkdir /tmp/choretest/sub )
    %x( touch /tmp/choretest/sub/a.txt )
  end

  subject { Garden::FileChore.new "/tmp/choretest/sub/*.txt", Rake.application }
  it "should have the right output_files" do
    expect(subject.output_files.to_a).to eq(["/tmp/choretest/sub/a.txt"])
    subject.each do |f|
      expect(f).to eq("/tmp/choretest/sub/a.txt")
    end
  end
end
