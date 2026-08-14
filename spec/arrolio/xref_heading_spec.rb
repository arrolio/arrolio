# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::GenericAdapter do
  let(:rules) do
    {
      'selectors' => { 'heading' => 'fmt-title' },
      'metadata' => { 'root' => 'bibdata', 'fields' => {} },
      'element_mapping' => { 'clause' => { 'content_type' => 'section' } },
      'sections' => { 'container' => 'sections' }
    }
  end
  let(:adapter) { described_class.new(rules: rules) }

  it 'does not include xref autonums in heading number' do # rubocop:disable RSpec/ExampleLength
    xml = <<~XML
      <root>
        <sections>
          <clause>
            <fmt-title depth="4">
              <span class="fmt-caption-label">
                <semx element="autonum">5</semx>
                <span class="fmt-autonum-delim">.</span>
                <semx element="autonum">7</semx>
                <span class="fmt-autonum-delim">.</span>
                <semx element="autonum">1</semx>
                <span class="fmt-autonum-delim">.</span>
                <semx element="autonum">5</semx>
              </span>
              <span class="fmt-caption-delim"><tab/></span>
              <semx element="title">Application in
                <semx element="xref">
                  <fmt-xref target="X">
                    <span class="citesec">
                      <semx element="autonum">5</semx>
                      <span class="fmt-autonum-delim">.</span>
                      <semx element="autonum">7</semx>
                      <span class="fmt-autonum-delim">.</span>
                      <semx element="autonum">1</semx>
                      <span class="fmt-autonum-delim">.</span>
                      <semx element="autonum">1</semx>
                    </span>
                  </fmt-xref>
                </semx>
              </semx>
            </fmt-title>
            <p>body</p>
          </clause>
        </sections>
        <bibdata/>
      </root>
    XML

    doc = adapter.convert(xml)
    section = doc.sections.first
    expect(section.number).to eq('5.7.1.5')
    expect(section.number).not_to include('5.7.1.55.7.1.1')
  end
end
