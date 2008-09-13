#
# test/test_strrand.rb
#

$KCODE      = 'u'
$LOAD_PATH << '../'

require 'lib/strrand'
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
    assert_respond_to(@string_random, :rand_regex)
    assert_respond_to(@string_random, :rand_pattern)

    # class methods
    assert_respond_to(StringRandom,   :rand_regex)
    assert_respond_to(StringRandom,   :rand_string)
  end

  # StringRandom#rand_regex
  def test_rand_regex
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
      result = @string_random.rand_regex(pattern)
      assert_match(/#{pattern}/, result, "#{result} is invalid: pattern #{pattern}")
    end

    result = @string_random.rand_regex(patterns)
    assert_equal(patterns.size, result.size)
  end

  # StringRandom#rand_regex
  def test_rand_regex_invalid
    patterns = ['[a-z]{a}',
                '0{,,}',
                '9{1,z}']

    patterns.each do |pattern|
      assert_raise(RuntimeError, "Non expected: #{pattern}") { @string_random.rand_regex(pattern) }
    end
  end

  # StringRandom#rand_pattern
  def test_rand_pattern
    assert_equal(0, @string_random.rand_pattern('').length)

    patterns = {
      'x' => ['a'],
      'y' => ['b'],
      'z' => ['c']
    }

    patterns.each_pair do |key, pattern|
      @string_random[key] = pattern
    end
    assert_equal('abc', @string_random.rand_pattern('xyz'))

    target = patterns.keys
    result = @string_random.rand_pattern(target)
    assert_equal(target.size, result.size)
    target.each_with_index do |pattern, i|
      assert_equal(@string_random[pattern][0], result[i])
    end
  end

  # StringRandom#rand_pattern
  def test_rand_pattern_builtin
    ['C', 'c', 'n', '!', '.', 's', 'b'].each do |val|
      assert_not_nil(@string_random[val])
    end

    range = ('A'..'Z').to_a
    range.each_with_index do |val, i|
      assert_equal(val, @string_random['C'][i])
    end

    # modify built-in pattern
    @string_random['C'] = ['n']
    assert_equal('n', @string_random.rand_pattern('C'))

    # No pollute other object
    @other = StringRandom.new
    assert_not_equal('n', @other.rand_pattern('C'))
  end

  # StringRandom#rand_pattern
  def test_rand_pattern_invalid
    ['A', 'CZ1s', 'Hoge', '\n'].each do |pattern|
      assert_raise(RuntimeError) { @string_random.rand_pattern(pattern) }
    end
  end

  # StringRandom.rand_regex
  def test_static_rand_regex
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
      result = StringRandom.rand_regex(pattern)
      assert_match(/#{pattern}/, result, "#{result} is invalid: pattern #{pattern}")
    end
  end

  # StringRandom.rand_string
  def test_static_rand_string
    assert_match(/\d/, StringRandom.rand_string('n'))
    assert_raise(RuntimeError) { StringRandom.rand_string('0') }

    # with optional lists
    assert_equal('abc', StringRandom.rand_string('012', ['a'], ['b'], ['c']))
    assert_match(/[abc][def][abc][def]/, StringRandom.rand_string('0101', ['a', 'b', 'c'], ['d', 'e', 'f']))
  end
end
