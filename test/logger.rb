# coding: utf-8
# frozen_string_literal: true

require 'rake/garden/logger'
describe Garden::Logger do

  describe ".truncate" do
    context "with long sentence" do
      let(:sentence) { subject.class.truncate("this is a longer sentence", 10, "....") }

      it "should set the right length" do
        expect(sentence.length).to eq(10)
      end
      it "should end with the suffix" do
        expect(sentence).to end_with '....'
      end
    end

    context "with short sentence" do
      let(:sentence) { subject.class.truncate("this", 10, "....") }

      it "should not alter length" do
        expect(sentence.length).to eq(4)
      end
      it "should not end with suffix" do
        expect(sentence).not_to end_with '....'
      end
    end
  end

  describe ".align" do
    before(:example) do
      allow(subject.class).to receive(:terminal_width).and_return(25)
    end

    context "without colored strings" do
      let (:aligned) { subject.class.align("PREFIX", "MIDDLE", "SUFFIX") }

      it "should align to size of the terminal" do
        expect(aligned.length).to eq(25)
      end
      it "should be aligned to the right" do
        expect(aligned).to eq("PREFIXMIDDLE       SUFFIX")
      end
    end

    context "with colored strings" do
      let (:aligned) { subject.class.align("PREFIX".blue, "MIDDLE".red, "SUFFIX") }

      it "should be aligned to the right" do
        expect(aligned).to eq("PREFIX".blue + "MIDDLE".red + "       SUFFIX")
      end
    end
  end

  describe ".hierarchy" do
    let (:result) { "   [2] " }

    it "should work with int" do
      expect(subject.class.hierarchy 2).to eq(result)
    end
    it "should work with str" do
      expect(subject.class.hierarchy "2").to eq(result)
    end

    context "with sub" do
      let (:result) { "    └[2.2] " }

      it "should work with float" do
        expect(subject.class.hierarchy 2.2).to eq(result)
      end
      it "should work with str" do
        expect(subject.class.hierarchy "2.2").to eq(result)
      end
    end
  end
end
