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

  context "with globs" do
    subject { Garden::FileAwareString.new(nil, '/home/sub/test.txt', glob) }

    describe "with double glob" do
      let(:glob) { "/home/**/*.txt" }
      it { is_expected.to have_attributes('glob?' => true) }
    end

    describe "with single glob" do
      let(:glob) { "/home/abc/*.txt" }
      it { is_expected.to have_attributes('glob?' => true) }
    end
    describe "without glob" do
      let(:glob) { "/home/abc/a.txt" }
      it { is_expected.to have_attributes('glob?' => false) }
    end
  end

  describe "with_file" do
    let(:file) { "/home/abc/b.txt" }
    let(:folder) { "/home/" }
    subject { Garden::FileAwareString }

    it 'should set the folder and the filepath' do
      filestring = nil
      subject.with_file file, folder do
        filestring = subject.create('')
        expect(filestring).to have_attributes(
                                'file' => file,
                                'directory_root' => folder
                              )
      end

      expect(filestring).to have_attributes(
                              'file' => file,
                              'directory_root' => folder
                            )
    end

    it 'should preserve the folder even if the file change' do
      filestring = nil
      subject.with_folder folder do
        subject.with_file file do
          expect(subject.create('')).to have_attributes(
                                          'file' => file,
                                          'directory_root' => folder
                                        )
        end
      end
    end

    it 'should override the file if the file changed' do
      filestring = nil
      subject.with_file 'wrong_file', folder do
        subject.with_file file do
          expect(subject.create('')).to have_attributes(
                                          'file' => file,
                                          'directory_root' => folder
                                        )
        end
      end
    end

    it 'should restore the file after the file changed' do
      filestring = nil
      subject.with_file file, folder do
        subject.with_file 'wrong_file' do
        end

        expect(subject.create('')).to have_attributes(
                                        'file' => file,
                                        'directory_root' => folder
                                      )
      end
    end
  end
end
