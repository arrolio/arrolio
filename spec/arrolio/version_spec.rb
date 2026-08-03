# frozen_string_literal: true

RSpec.describe Arrolio do
  it 'exposes a VERSION string in x.y.z form' do
    expect(Arrolio::VERSION).to match(/\A\d+\.\d+/)
  end

  it 'exposes an Error base class' do
    expect(Arrolio::Error.ancestors).to include(StandardError)
  end
end
