# -*- mode: ruby; coding: utf-8 -*-

# = strrand.rb: Generates a random string from a pattern
#
# Author:: Tama <repeatedly@gmail.com>
#
# StringRandom is derived from the String::Random written in Perl.
# See http://search.cpan.org/~steve/String-Random-0.22/
#
# == Example
#
#    string_random = StringRandom.new
#    string_random.rand_pattern('CCcc!ccn')  #=> ZIop$ab1
#
# refer to test_strrand.rb
#
# == Format
#
# === Regular expression syntax
#
# *_regex methods use this rule.
#
# The following regular expression elements are supported.
#
#  - \w  Alphanumeric + "_".
#  - \d  Digits.
#  - \W  Printable characters other than those in \w.
#  - \D  Printable characters other than those in \d.
#  - .   Printable characters.
#  - []  Character classes.
#  - {}  Repetition.
#  - *   Same as {0,}.
#  - ?   Same as {0,1}.
#  - +   Same as {1,}.
#
# === Patterns
#
# rand_pattern and rand_string methods use this rule.
#
# The following patterns are pre-defined.
#
#  - c  Any lowercase character [a-z]
#  - C  Any uppercase character [A-Z]
#  - n  Any digit [0-9]
#  - !  A punctuation character [~`!@$%^&*()-_+={}[]|\:;"'.<>?/#,]
#  - .  Any of the above
#  - s  A "salt" character [A-Za-z0-9./]
#  - b  Any binary data
#
# Pattern can modify and add as bellow.
#
#    string_random['C'] = ['n']
#    string_random['A'] = [('A'..'Z').to_a, ('A'..'Z').to_a]
#
# Pattern must be a flattened array(nested or other type raise exception).
#


class StringRandom
  Upper  = ('A'..'Z').to_a
  Lower  = ('a'..'z').to_a
  Digit  = ('0'..'9').to_a
  Punct  = [33..47, 58..64, 91..96, 123..126].map do |range|
    range.map { |val| val.chr }
  end.flatten
  Any    = Upper | Lower | Digit | Punct
  Salt   = Upper | Lower | Digit | ['.', '/']
  Binary = (0..255).map { |val| val.chr }

  # These are the regex-based patterns.
  Pattern = {
    # These are the regex-equivalents.
    '.'  => Any,
    '\d' => Digit,
    '\D' => Upper | Lower | Punct,
    '\w' => Upper | Lower | Digit | ['_'],
    '\W' => Punct.reject { |val| val == '_' },
    '\s' => [' ', "\t"],
    '\S' => Upper | Lower | Digit | Punct,

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
    'C' => Upper,
    'c' => Lower,
    'n' => Digit,
    '!' => Punct,
    '.' => Any,
    's' => Salt,
    'b' => Binary
  }

  #
  # Class method version of rand_regex.
  #
  def self.rand_regex(patterns)
    return StringRandom.new.rand_regex(patterns)
  end

  #
  # Same as StringRandom#rand_pattern if single argument.
  # Optionally, references to lists containing 
  # other patterns can be passed to the function.  
  # Those lists will be used for 0 through 9 in the pattern 
  # (The pattern of after 10 can't refer).
  #
  def self.rand_string(pattern, *pattern_list)
    string_random = StringRandom.new
    
    pattern_list.each_with_index do |new_pattern, i|
      string_random[i.to_s] = new_pattern
    end

    return string_random.rand_pattern(pattern)
  end

  #
  # _max_ is default length for creating random string
  #
  def initialize(max = 10)
    @max   = max
    @map   = OldPattern.clone
    @regch = {
      "\\" => method(:regch_slash),
      '.'  => method(:regch_dot),
      '['  => method(:regch_bracket),
      '*'  => method(:regch_asterisk),
      '+'  => method(:regch_plus),
      '?'  => method(:regch_question),
      '{'  => method(:regch_brace)
    }
  end

  #
  # Returns a random string that will match 
  # the regular expression passed in the list argument
  #
  def rand_regex(patterns)
    return _rand_regex(patterns) unless patterns.instance_of?(Array)

    result = []
    patterns.each do |pattern|
      result << _rand_regex(pattern)
    end
    result
  end

  #
  # This method returns a random string based on 
  # the concatenation of all the pattern strings in the list.
  #
  def rand_pattern(patterns)
    return _rand_pattern(patterns) unless patterns.instance_of?(Array)

    result = []
    patterns.each do |pattern|
      result << _rand_pattern(pattern)
    end
    result
  end

  #
  # Returns a random string pattern
  #
  def [](key)
    @map[key]
  end

  #
  # Adds a random string pattern
  #
  # _pattern_ must be flattend array
  #
  def []=(key, pattern)
    raise "pattern is Array only" unless pattern.instance_of?(Array)

    @map[key] = pattern
  end

  private

  def _rand_regex(pattern)
    string = []
    chars  = pattern.split(//)
    non_ch = /[\$\^\*\(\)\+\{\}\]\|\?]/  # not supported chars

    while ch = chars.shift
      if @regch.has_key?(ch)
        @regch[ch].call(ch, chars, string)
      else
        warn "'#{ch}' not implemented. treating literally." if ch =~ non_ch
        string << [ch]
      end
    end

    result = ''
    string.each do |ch|
      result << ch[rand(ch.size)]
    end
    result
  end

  def _rand_pattern(pattern)
    string = ''

    pattern.split(//).each do |ch|
      raise %Q(Unknown pattern character "#{ch}"!) unless @map.has_key?(ch)
      string << @map[ch][rand(@map[ch].size)]
    end

    string
  end

  #
  # The folloing methods are defined for regch.
  # These characters are treated specially in rand_regex.
  #
  def regch_slash(ch, chars, string)
    raise "regex not terminated" if chars.empty?

    tmp = chars.shift
    if tmp == 'x'
      # This is supposed to be a number in hex, so
      # there had better be at least 2 characters left.
      tmp = chars.shift + chars.shift
      string << tmp.hex.chr
    elsif tmp =~ /[0-7]/
      warn "octal parsing not implemented. treating literally."
      string << tmp
    elsif Pattern.has_key?(ch + tmp)
      string << Pattern[ch + tmp]
    else
      warn "'\\#{tmp}' being treated as literal '#{tmp}'"
      string << tmp
    end
  end

  def regch_dot(ch, chars, string)
    string << Pattern[ch]
  end

  def regch_bracket(ch, chars, string)
    tmp = []
    while ch = chars.shift and ch != ']'
      if ch == '-' and !chars.empty? and !tmp.empty?
        max = chars.shift
        min = tmp.last
        while min < max
          min  = min.succ
          tmp << min
        end
      else
        warn "${ch}' will be treated literally inside []" if ch =~ /\W/
        tmp << ch
      end
    end

    raise "unmatched []" if ch != ']'
    string << tmp
  end

  def regch_asterisk(ch, chars, string)
    chars = "{0,}".split("").concat(chars)
  end

  def regch_plus(ch, chars, string)
    chars = "{1,}".split("").concat(chars)
  end

  def regch_question(ch, chars, string)
    chars = "{0,1}".split("").concat(chars)
  end

  def regch_brace(ch, chars, string)
    # { isn't closed, so treat it literally.
    return string << ch unless chars.include?('}')

    tmp = ''
    while ch = chars.shift and ch != '}'
      raise "'#{ch}' inside {} not supported" unless ch =~ /[\d,]/
      tmp << ch
    end

    tmp = if tmp =~ /,/
      raise "malformed range {#{tmp}}" unless tmp =~ /^(\d*),(\d*)$/

      min = $1.length.nonzero? ? $1.to_i : 0
      max = $2.length.nonzero? ? $2.to_i : @max
      raise "bad range {#{tmp}}" if min > max

      min == max ? min : min + rand(max - min + 1)
    else
      tmp.to_i
    end

    if tmp.nonzero?
      last = string.last
      (tmp - 1).times do
        string << last
      end
    else
      string.pop
    end
  end
end
