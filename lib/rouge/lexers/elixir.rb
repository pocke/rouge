# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    # Direct port of pygments Lexer.
    # See: https://bitbucket.org/birkenfeld/pygments-main/src/7304e4759ae65343d89a51359ca538912519cc31/pygments/lexers/functional.py?at=default#cl-2362
    class Elixir < RegexLexer
      title "Elixir"
      desc "Elixir language (elixir-lang.org)"

      tag 'elixir'
      aliases 'elixir', 'exs'

      filenames '*.ex', '*.exs'

      mimetypes 'text/x-elixir', 'application/x-elixir'

      state :root do
        rule %r/\s+/m, Text
        rule %r/#.*$/, Comment::Single
        rule %r{\b(case|cond|end|bc|lc|if|unless|try|loop|receive|fn|defmodule|
             defp?|defprotocol|defimpl|defrecord|defmacrop?|defdelegate|
             defexception|defguardp?|defstruct|exit|raise|throw|after|rescue|catch|else)\b(?![?!])|
             (?<!\.)\b(do|\-\>)\b}x, Keyword
        rule %r/\b(import|require|use|recur|quote|unquote|super|refer)\b(?![?!])/, Keyword::Namespace
        rule %r/(?<!\.)\b(and|not|or|when|xor|in)\b/, Operator::Word
        rule %r{%=|\*=|\*\*=|\+=|\-=|\^=|\|\|=|
             <=>|<(?!<|=)|>(?!<|=|>)|<=|>=|===|==|=~|!=|!~|(?=[\s\t])\?|
             (?<=[\s\t])!+|&(&&?|(?!\d))|\|\||\^|\*|\+|\-|/|
             \||\+\+|\-\-|\*\*|\/\/|\<\-|\<\>|<<|>>|=|\.|~~~}x, Operator
        rule %r{(?<!:)(:)([a-zA-Z_]\w*([?!]|=(?![>=]))?|\<\>|===?|>=?|<=?|
             <=>|&&?|%\(\)|%\[\]|%\{\}|\+\+?|\-\-?|\|\|?|\!|//|[%&`/\|]|
             \*\*?|=?~|<\-)|([a-zA-Z_]\w*([?!])?)(:)(?!:)}, Str::Symbol
        rule %r/:"/, Str::Symbol, :interpoling_symbol
        rule %r/\b(nil|true|false)\b(?![?!])|\b[A-Z]\w*\b/, Name::Constant
        rule %r/\b(__(FILE|LINE|MODULE|MAIN|FUNCTION)__)\b(?![?!])/, Name::Builtin::Pseudo
        rule %r/[a-zA-Z_!][\w_]*[!\?]?/, Name
        rule %r{::|[%(){};,/\|:\\\[\]]}, Punctuation
        rule %r/@[a-zA-Z_]\w*|&\d/, Name::Variable
        rule %r{\b(0[xX][0-9A-Fa-f]+|\d(_?\d)*(\.(?![^\d\s])
             (_?\d)*)?([eE][-+]?\d(_?\d)*)?|0[bB][01]+)\b}x, Num

        mixin :strings
        mixin :sigil_strings
      end

      state :strings do
        rule %r/(%[A-Ba-z])?"""(?:.|\n)*?"""/, Str::Doc
        rule %r/'''(?:.|\n)*?'''/, Str::Doc
        rule %r/"/, Str::Doc, :dqs
        rule %r/'.*?'/, Str::Single
        rule %r{(?<!\w)\?(\\(x\d{1,2}|\h{1,2}(?!\h)\b|0[0-7]{0,2}(?![0-7])\b[^x0MC])|(\\[MC]-)+\w|[^\s\\])}, Str::Other

      end

      state :dqs do
        rule %r/"/, Str::Double, :pop!
        mixin :enddoublestr
      end

      state :interpoling do
        rule %r/#\{/, Str::Interpol, :interpoling_string
      end

      state :interpoling_string do
        rule %r/\}/, Str::Interpol, :pop!
        mixin :root
      end

      state :interpoling_symbol do
        rule %r/"/, Str::Symbol, :pop!
        mixin :interpoling
        rule %r/[^#"]+/, Str::Symbol
      end

      state :enddoublestr do
        mixin :interpoling
        rule %r/[^#"]+/, Str::Double
      end

      state :sigil_strings do
        # ~-sigiled strings
        # ~(abc), ~[abc], ~<abc>, ~|abc|, ~r/abc/, etc
        # Cribbed and adjusted from Ruby lexer
        delimiter_map = { '{' => '}', '[' => ']', '(' => ')', '<' => '>' }
        # Match a-z for custom sigils too
        sigil_opens = Regexp.union(delimiter_map.keys + %w(| / ' "))
        rule %r/~([A-Za-z])?(#{sigil_opens})/ do |m|
          open = Regexp.escape(m[2])
          close = Regexp.escape(delimiter_map[m[2]] || m[2])
          interp = /[SRCW]/ === m[1]
          toktype = Str::Other

          puts "    open: #{open.inspect}" if @debug
          puts "    close: #{close.inspect}" if @debug

          # regexes
          if 'Rr'.include? m[1]
            toktype = Str::Regex
            push :regex_flags
          end

          if 'Ww'.include? m[1]
            push :list_flags
          end

          token toktype

          push do
            rule %r/#{close}/, toktype, :pop!

            if interp
              mixin :interpoling
              rule %r/#/, toktype
            else
              rule %r/[\\#]/, toktype
            end

            rule %r/[^##{open}#{close}\\]+/m, toktype
          end
        end
      end

      state :regex_flags do
        rule %r/[fgimrsux]*/, Str::Regex, :pop!
      end

      state :list_flags do
        rule %r/[csa]?/, Str::Other, :pop!
      end
    end
  end
end
