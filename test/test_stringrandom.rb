#
# test/test_strrand.rb
#

$KCODE      = 'u' if RUBY_VERSION < '1.9.0'
$LOAD_PATH << '../'

require 'lib/stringrandom'
require 'test/unit'

class TestStringRandom < Test::Unit::TestCase
  def setup
    @string_random = StringRandom.new
  end

  # StringRandom itself
  def test_initialize
    assert_not_nil(@string_random)
    assert_instance_of(StringRandom, @string_random)
  end

  # StringRandom methods
  def test_method_respond
    # instance methods
    assert_respond_to(@string_random, :[])
    assert_respond_to(@string_random, :[]=)
    assert_respond_to(@string_random, :random_regex)
    assert_respond_to(@string_random, :random_pattern)

    # singleton methods
    assert_respond_to(StringRandom, :random_regex)
    assert_respond_to(StringRandom, :random_string)
  end

  # StringRandom#random_regex
  def test_random_regex
    patterns = ['\d\d\d',
                '\w\w\w',
                '[ABC][abc]',
                '[012][345]',
                '...',
                '[a-z][0-9]',
                '[aw-zX][123]',
                '[a-z]{5}',
                '0{80}',
                '[a-f][nprt]\d{3}',
                '\t\n\r\f\a\e',
                '\S\S\S',
                '\s\s\s',
                '\w{5,10}',
                '\w?',
                '\w+',
                '\w*',
                '']

    patterns.each do |pattern|
      result = @string_random.random_regex(pattern)
      assert_match(/#{pattern}/, result, "#{result} is invalid: pattern #{pattern}")
    end

    result = @string_random.random_regex(patterns)
    assert_equal(patterns.size, result.size)
  end

  # StringRandom#random_regex
  def test_random_regex_invalid
    patterns = ['[a-z]{a}',
                '0{,,}',
                '9{1,z}']

    patterns.each do |pattern|
      assert_raise(RuntimeError, "Non expected: #{pattern}") { @string_random.random_regex(pattern) }
    end
  end

  # StringRandom#random_pattern
  def test_random_pattern
    assert_equal(0, @string_random.random_pattern('').length)

    patterns = {
      'x' => ['a'],
      'y' => ['b'],
      'z' => ['c']
    }

    patterns.each_pair do |key, pattern|
      @string_random[key] = pattern
    end
    assert_equal('abc', @string_random.random_pattern('xyz'))

    target = patterns.keys
    result = @string_random.random_pattern(target)
    assert_equal(target.size, result.size)
    target.each_with_index do |pattern, i|
      assert_equal(@string_random[pattern][0], result[i])
    end
  end

  # StringRandom#random_pattern
  def test_random_pattern_builtin
    ['C', 'c', 'n', '!', '.', 's', 'b'].each do |val|
      assert_not_nil(@string_random[val])
    end

    range = ('A'..'Z').to_a
    range.each_with_index do |val, i|
      assert_equal(val, @string_random['C'][i])
    end

    # modify built-in pattern
    @string_random['C'] = ['n']
    assert_equal('n', @string_random.random_pattern('C'))

    # undefined behavior
    count    = 0
    patterns = {
      'X' => ('A'..'Z'),
      'Y' => [['foo,', 'bar'], [['baz']]],
      'Z' => [true, false],
      ''  => 'hogehoge' # no raise
    }
    patterns.each_pair do |key, pattern|
      begin
        @string_random[key] = pattern
        @string_random.random_pattern(key)
      rescue Exception
        count += 1
      end
    end
    assert_equal(patterns.keys.size - 1, count)

    # No pollute other object
    @other = StringRandom.new
    assert_not_equal('n', @other.random_pattern('C'))
  end

  # StringRandom#random_pattern
  def test_random_pattern_invalid
    ['A', 'CZ1s', 'Hoge', '\n'].each do |pattern|
      assert_raise(RuntimeError) { @string_random.random_pattern(pattern) }
    end
  end

  # StringRandom.random_regex
  def test_singleton_random_regex
    patterns = ['\d\d\d',
                '\w\w\w',
                '[ABC][abc]',
                '[012][345]',
                '...',
                '[a-z][0-9]',
                '[aw-zX][123]',
                '[a-z]{5}',
                '0{80}',
                '[a-f][nprt]\d{3}',
                '\t\n\r\f\a\e',
                '\S\S\S',
                '\s\s\s',
                '\w{5,10}',
                '\w?',
                '\w+',
                '\w*',
                '']

    patterns.each do |pattern|
      result = StringRandom.random_regex(pattern)
      assert_match(/#{pattern}/, result, "#{result} is invalid: pattern #{pattern}")
    end
  end

  # StringRandom.random_string
  def test_singleton_random_string
    assert_match(/\d/, StringRandom.random_string('n'))
    assert_raise(RuntimeError) { StringRandom.random_string('0') }

    # with optional lists
    assert_equal('abc', StringRandom.random_string('012', ['a'], ['b'], ['c']))
    assert_match(/[abc][def]/, StringRandom.random_string('01', ['a', 'b', 'c'], ['d', 'e', 'f']))
  end
end
