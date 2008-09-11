# -*- mode: ruby; encoding: utf-8 -*-

# = strrand.rb: Generates a random string from a pattern
#
# Author:: Tama <repeatedly@gmail.com>
#
# StringRandom is derived from the String::Random written in Perl.
# See http://search.cpan.org/~steve/String-Random-0.22/

class StringRandom
  UPPER  = ('A'..'Z').to_a
  LOWER  = ('a'..'z').to_a
  DIGIT  = (0..9).to_a
  PUNCT  = [33..47, 58..64, 91..96, 123..126].map do |range|
    range.map { |val| val.chr }
  end.flatten
  ANY    = UPPER + LOWER + DIGIT + PUNCT
  SALT   = UPPER + LOWER + DIGIT + ['.', '/']
  BINARY = (0..255).map { |val| val.chr }

  # These are the regex-based patterns.
  PATTERN = {
    # These are the regex-equivalents.
    '.'  => ANY,
    '\d' => DIGIT,
    '\D' => UPPER + LOWER + PUNCT,
    '\w' => UPPER + LOWER + DIGIT + ['_'],
    '\W' => PUNCT.reject { |val| val == '_' },
    '\s' => [' ', '\t'],
    '\S' => UPPER + LOWER + DIGIT + PUNCT,

    # These are translated to their double quoted equivalents.
    '\t' => ["\t"],
    '\n' => ["\n"],
    '\r' => ["\r"],
    '\f' => ["\f"],
    '\a' => ["\a"],
    '\e' => ["\e"]
  }
  # What's important is how they relate to the pattern characters.
  # These are the old patterns for rand_pattern.
  OldPattern = {
    'C' => UPPER,
    'c' => LOWER,
    'n' => DIGIT,
    '!' => PUNCT,
    '.' => ANY,
    's' => SALT,
    'b' => BINARY
  }
  # These characters are treated specially in randregex.
  Regch = {
    "\\" => lambda { |ch, chars, string|
      unless chars.empty?
        tmp = chars.shift
        if tmp = 'x'
          # This is supposed to be a number in hex, so
          # there had better be at least 2 characters left.
          tmp = chars.shift + chars.shift
          string << tmp.hex.chr
        elsif tmp =~ /[0-7]/
          warn "octal parsing not implemented.  treating literally."
          string << tmp
        elsif Pattern["\\#{tmp}"]
          ch     << tmp
          string << ch
        else
          warn "'\\#{tmp}' being treated as literal '#{tmp}'"
          string << tmp
        end
      else
        raise "regex not terminated"
      end
    },
    '.'  => lambda { |ch, chars, string|
      string << Pattern[ch]
    },
    '['  => lambda { |ch, chars, string|
    },
    '*'  => lambda { |ch, chars, string|
      chars.unshift("{0,}".split(""))
    },
    '+'  => lambda { |ch, chars, string|
      chars.unshift("{1,}".split(""))
    },
    '?'  => lambda { |ch, chars, string|
      chars.unshift("{0,1}".split(""))
    },
    '{'  => lambda { |ch, chars, string|
    }
  }

  def initialize(max = 10)
    @max = max
  end

  def rand_regex

  end

  def rand_pattern

  end
end
