# frozen_string_literal: true

require 'rake/garden/metadata'

describe Garden::TreeDict do
  subject { Garden::TreeDict.new(data) }
  let(:data) { { 'a' => 2, 'nested' => { 'b' => 3 } } }

  it 'should be able to fetch data' do
    expect(subject['a']).to eq(2)
  end

  it 'should be able to set data' do
    subject['c'] = 4
    expect(subject['c']).to eq(4)
  end

  it 'should be able to create a namespace' do
    namespace = subject.namespace('nested')
    expect(namespace).to be_an(Garden::TreeDict)
    expect(namespace['b']).to eq(3)
  end

  it 'should be able to linked to no data' do
    expect(subject.namespace('new')).to be_an(Garden::TreeDict)
  end

  it 'should reused the same namespace' do
    expect(subject.namespace('new')).to eq(subject.namespace('new'))
  end

  it 'should be able to modify a namespace' do
    namespace = subject.namespace('nested')
    namespace['d'] = 9
    namespace.save
    expect(subject['nested']['d']).to eq(9)
  end
end
