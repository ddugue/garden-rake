require 'rake/garden/fileawarestring'

RSpec.describe Garden::FileAwareString, "#format" do
  subject { Garden::FileAwareString.new(nil, '/home/test.txt', selector).to_s }
  describe "with %f" do
    let(:selector) { '%f' }
    it { is_expected.to eql('test.txt') }
  end

  context 'with root' do

  end
end



#   it "should replace %f with filename + root" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%f").to_s)\
#       .to eq("test.txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%f").to_s)\
#       .to eq("sub/test.txt")
#   end

#   it "should replace %F with only the filename" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%F").to_s)\
#       .to eq("test.txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%F").to_s)\
#       .to eq("test.txt")
#   end

#   it "should replace %b with the filename without extension" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%b").to_s)\
#       .to eq("test")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%b").to_s)\
#       .to eq("sub/test")
#   end

#   it "should replace %B with only the filename without extension" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%B").to_s)\
#       .to eq("test")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%B").to_s)\
#       .to eq("test")
#   end

#   it "should replace %x with the extension of the file" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%x").to_s)\
#       .to eq(".txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%x").to_s)\
#       .to eq(".txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test", "%x").to_s)\
#       .to eq("")
#   end

#   it "should replace %d with the directory of the file" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%d").to_s)\
#       .to eq("/home/")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%d").to_s)\
#       .to eq("sub/")
#   end

#   it "should replace %D with the full directory of the file" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%D").to_s)\
#       .to eq("/home")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%D").to_s)\
#       .to eq("/home/sub")
#   end

#   it "should replace %p with the full filename" do
#     expect(FileAwareString.new(nil, "/home/test.txt", "%p").to_s)\
#       .to eq("/home/test.txt")
#     expect(FileAwareString.new("/home/", "/home/sub/test.txt", "%p").to_s)\
#       .to eq("/home/sub/test.txt")
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
