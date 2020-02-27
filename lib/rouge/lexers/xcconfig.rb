# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
    module Lexers
      class XcodeBuildSettings < RegexLexer
        title "xcconfig"
        desc %q(Xcode Build Settings File)
        tag 'xcconfig'
        filenames '*.xcconfig'

        start { push :root }

        state :inline_whitespace do
            rule %r/[ \t\r]+/, Text
            rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
          end

          state :whitespace do
            rule %r/\n+/m, Text, :root
            rule %r(//(\\.|.)*?$), Comment::Single, :root
            mixin :inline_whitespace
          end

        state :root do
          rule %r/#/, Comment::Preproc, :macro
          rule %r/\$\(/, Str::Interpol, :parentheses
          rule %r/=/, Operator

          rule %r/\"/, Str::Double, :double_quotes
          rule %r/'/, Str::Single, :single_quotes

          rule %r/\$?\[/, Operator, :brackets

          mixin :whitespace
        end

        state :double_quotes do
            # NB: "abc$" is literally the string abc$.
            rule %r/(?:\$#?)?"/, Str::Double, :pop!
            rule %r/[^"`\\$]+/, Str::Double
          end

          state :single_quotes do
            rule %r/\\./, Str::Escape
            rule %r/[^\\']+/, Str::Single
            rule %r/'/, Str::Single, :pop!
            rule %r/[^']+/, Str::Single
          end

        state :macro do
            rule %r/\n/, Comment::Preproc, :pop!
            rule %r([^/\n\\]+), Comment::Preproc
            rule %r/\\./m, Comment::Preproc
            mixin :inline_whitespace
            rule %r(/), Comment::Preproc
          end

          state :parentheses do
            rule %r/\)/, Str::Interpol, :pop!
            rule %r/\:/, Punctuation
            mixin :root
          end

          state :brackets do
            rule %r/\[/, Operator, :push
            rule %r/(.+)(\s*)(=)(\s*)(.+)/ do
              groups Keyword, Text, Operator, Text, Name
            end
            rule %r/\]/, Operator, :pop!
            mixin :root
          end

      end
    end
  end
