# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Glu < RegexLexer
      tag 'glu'
      aliases 'gil'
      filenames '*.glu', '*.gil'

      title "Glu"
      desc 'The Glu programming language (glu-lang.org)'

      id_head = /_|(?!\p{Mc})\p{Alpha}|[^\u0000-\uFFFF]/
      id_rest = /[\p{Alnum}_]|[^\u0000-\uFFFF]/
      id = /#{id_head}#{id_rest}*/

      keywords = Set.new %w(
        as
        break
        continue
        else
        for
        if
        import
        in
        or
        return
        while
      )

      declarations = Set.new %w(
        enum func struct operator let var typealias
      )

      constants = Set.new %w(
        true false
      )

      start do
        push :bol
        @re_delim = "" # multi-line regex delimiter
      end

      # beginning of line
      state :bol do
        rule %r/#(?![#"\/]).*/, Comment::Preproc

        mixin :inline_whitespace

        rule(//) { pop! }
      end

      state :inline_whitespace do
        rule %r/\s+/m, Text
        mixin :has_comments
      end

      state :whitespace do
        rule %r/\n+/m, Text, :bol
        rule %r(\/\/.*?$), Comment::Single, :bol
        mixin :inline_whitespace
      end

      state :has_comments do
        rule %r(/[*]), Comment::Multiline, :nested_comment
      end

      state :nested_comment do
        mixin :has_comments
        rule %r([*]/), Comment::Multiline, :pop!
        rule %r([^*/]+)m, Comment::Multiline
        rule %r/./, Comment::Multiline
      end

      state :root do
        mixin :whitespace
        
        rule %r/\$(([1-9]\d*)?\d)/, Name::Variable
        rule %r/\$#{id}/, Name

        rule %r/(\.)(#{id})/ do |m|
          groups Operator, Name::Variable
        end

        rule %r/(#{id})\s*(::)/ do |m|
          groups Name::Namespace, Punctuation
        end

        rule %r/(#{id})\s*(:)/ do |m|
          groups Name::Variable, Punctuation
        end

        rule %r/(::|<=>)/, Operator
        rule %r{[()\[\]{}:;,?\\]}, Punctuation
        rule %r([-/=+*%<>!&|^.~]+), Operator
        rule %r/"/, Str, :dq
        rule %r/'(\\.|.)'/, Str::Char
        rule %r/(\d+(?:_\d+)*\*|(?:\d+(?:_\d+)*)*\.\d+(?:_\d)*)(e[+-]?\d+(?:_\d)*)?/i, Num::Float
        rule %r/\d+e[+-]?[0-9]+/i, Num::Float
        rule %r/0o?[0-7]+(?:_[0-7]+)*/, Num::Oct
        rule %r/0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*((\.[0-9A-F]+(?:_[0-9A-F]+)*)?p[+-]?\d+)?/, Num::Hex
        rule %r/0b[01]+(?:_[01]+)*/, Num::Bin
        rule %r{[\d]+(?:_\d+)*}, Num::Integer

        rule %r/@#{id}/, Keyword::Declaration
        rule %r/##{id}/, Keyword

        rule %r/(?!\b(if|while|for)\b)\b#{id}(?=(\?|!)?\s*[(])/ do |m|
          if m[0] =~ /^[[:upper:]][[:upper:]]+$/
            token Name::Constant
          elsif m[0] =~ /^[[:upper:]]/
            token Name::Class
          else
            token Name::Function
          end
        end

        rule id do |m|
          if keywords.include? m[0]
            token Keyword
          elsif declarations.include? m[0]
            token Keyword::Declaration
          elsif constants.include? m[0]
            token Keyword::Constant
          elsif m[0] =~ /^[[:upper:]][[:upper:]]+$/
            token Name::Constant
          elsif m[0] =~ /^[[:upper:]]/
            token Name::Class
          else
            token Name
          end
        end

        rule %r/(`)(#{id})(`)/ do
          groups Punctuation, Name::Variable, Punctuation
        end
      end

      state :dq do
        rule %r/\\[\\0tnr'"]/, Str::Escape
        rule %r/\\[(]/, Str::Escape, :interp
        rule %r/\\u\{\h{1,8}\}/, Str::Escape
        rule %r/[^\\"]+/, Str
        rule %r/"""/, Str, :pop!
        rule %r/"/, Str, :pop!
      end

      state :interp do
        rule %r/[(]/, Punctuation, :interp_inner
        rule %r/[)]/, Str::Escape, :pop!
        mixin :root
      end

      state :interp_inner do
        rule %r/[(]/, Punctuation, :push
        rule %r/[)]/, Punctuation, :pop!
        mixin :root
      end
    end
  end
end
