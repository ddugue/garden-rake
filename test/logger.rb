require 'rake/garden/logger'
RSpec.describe Garden::Logger, "#truncate"do
  it "should always unalter the string when shorter" do
    expect(Garden::Logger.truncate("this", 10).length).to eq(4)
  end

  it "should be the exact length set when longer" do
    expect(Garden::Logger.truncate("this is a longer sentence", 10).length).to eq(10)
  end

  it "should end with characters when longer than max length" do
    expect(Garden::Logger.truncate("this is a longer sentence", 10, "....").end_with? '....').to be(true)
  end
end

RSpec.describe Garden::Logger, "#align"do
  it "should override terminal size" do
    allow(Garden::Logger).to receive(:terminal_width).and_return(85)
    expect(Garden::Logger.terminal_width).to eq(85)
  end
  it "should align the suffix to the end of the line" do
    allow(Garden::Logger).to receive(:terminal_width).and_return(25)

    aligned = Garden::Logger.align("PREFIX", "MIDDLE", "SUFFIX")
    expect(aligned.length).to eq(25)
    expect(aligned).to eq("PREFIXMIDDLE       SUFFIX")
  end
  it "should align the suffix to the end of the line with colored strings" do
    allow(Garden::Logger).to receive(:terminal_width).and_return(25)
    expect(Garden::Logger.align("PREFIX".blue, "MIDDLE".red, "SUFFIX")).to eq("PREFIX".blue + "MIDDLE".red + "       SUFFIX")
  end
end
