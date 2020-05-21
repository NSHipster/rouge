# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
    module Lexers
      class NTriples < HTML
        title "N-Triples"
        desc ""
        tag 'ntriples'
        filenames '*.nt'
        mimetypes 'application/n-triples'
      end
    end
end
