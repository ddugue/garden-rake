require 'rake/garden/fileawarestring'

RSpec.describe Garden::FileAwareString, "#format" do
  subject { Garden::FileAwareString.new(nil, '/home/test.txt', selector).to_s }
  describe "with %f (filename)" do
    let(:selector) { '%f' }
    it { is_expected.to eql('test.txt') }
  end

  describe "with %F (filename without directory)" do
    let(:selector) { '%f' }
    it { is_expected.to eql('test.txt') }
  end

  describe "with %b (filename without extension)" do
    let(:selector) { '%b' }
    it { is_expected.to eql('test') }
  end

  describe "with %B (filename without directory and extension)" do
    let(:selector) { '%B' }
    it { is_expected.to eql('test') }
  end

  describe "with %d (directory)" do
    let(:selector) { '%d' }
    it { is_expected.to eql('/home/') }
  end

  describe "with %D (full directory)" do
    let(:selector) { '%D' }
    it { is_expected.to eql('/home') }
  end

  describe "with %p (fullfilename)" do
    let(:selector) { '%p' }
    it { is_expected.to eql('/home/test.txt') }
  end

  context 'with root' do
    subject { Garden::FileAwareString.new("/home/", '/home/sub/test.txt', selector).to_s }

    describe "with %f" do
      let(:selector) { '%f' }
      it { is_expected.to eql('sub/test.txt') }
    end

    describe "with %F (filename without directory)" do
      let(:selector) { '%F' }
      it { is_expected.to eql('test.txt') }
    end

    describe "with %b (filename without extension)" do
      let(:selector) { '%b' }
      it { is_expected.to eql('sub/test') }
    end

    describe "with %b (filename without directory and extension)" do
      let(:selector) { '%B' }
      it { is_expected.to eql('test') }
    end

    describe "with %d (directory)" do
      let(:selector) { '%d' }
      it { is_expected.to eql('sub/') }
    end

    describe "with %D (full directory)" do
      let(:selector) { '%D' }
      it { is_expected.to eql('/home/sub') }
    end

    describe "with %p (fullfilename)" do
      let(:selector) { '%p' }
      it { is_expected.to eql('/home/sub/test.txt') }
    end
  end
end

#   it "should replace %x with the extension of the file" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%x").to_s)\
#       .to eq(".txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%x").to_s)\
#       .to eq(".txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test", "%x").to_s)\
#       .to eq("")
#   end

# end

# RSpec.describe FileAwareString, "#creation" do
#   it "should pass the folder root and the file from the class" do
#     FileAwareString.file = "a.txt"
#     FileAwareString.folder_root = "root"
#     f = FileAwareString.create("%f")
#     expect(f.file).to eq("a.txt")
#     expect(f.folder_root).to eq("root")
#   end

#   it "should not override previously passed value" do
#     FileAwareString.file = "a.txt"
#     FileAwareString.folder_root = "root"
#     f = FileAwareString.create("%f")
#     FileAwareString.file = "b.txt"
#     FileAwareString.folder_root = "root2"
#     expect(f.file).to eq("a.txt")
#     expect(f.folder_root).to eq("root")
#   end
# end
