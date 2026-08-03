# frozen_string_literal: true

module Arrolio
  module Content
    autoload :Document, 'arrolio/content/document'
    autoload :Section, 'arrolio/content/section'
    autoload :Paragraph, 'arrolio/content/paragraph'
    autoload :InlineRun, 'arrolio/content/inline_run'
    autoload :Heading, 'arrolio/content/heading'
    autoload :Hyperlink, 'arrolio/content/hyperlink'
    autoload :Formula, 'arrolio/content/formula'
    autoload :Preformatted, 'arrolio/content/preformatted'
    autoload :PageBreak, 'arrolio/content/page_break'
    autoload :Footnote, 'arrolio/content/footnote'
    autoload :IndexEntry, 'arrolio/content/index_entry'
    autoload :FormField, 'arrolio/content/form_field'
    autoload :Table, 'arrolio/content/table'
    autoload :List, 'arrolio/content/list'
    autoload :Image, 'arrolio/content/image'
    autoload :Builder, 'arrolio/content/builder'
    autoload :Note, 'arrolio/content/note'
    autoload :Example, 'arrolio/content/example'
    autoload :TermEntry, 'arrolio/content/term_entry'
    autoload :FigureGroup, 'arrolio/content/figure_group'
    autoload :BibliographyItem, 'arrolio/content/bibliography_item'
  end
end
