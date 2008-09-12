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

  def test_initialize
    assert_not_nil(@string_random)
    assert_instance_of(StringRandom, @string_random)
  end

  def test_method_respond
    assert_respond_to(@string_random, :[])
    assert_respond_to(@string_random, :[]=)
    assert_respond_to(@string_random, :rand_regex)
    assert_respond_to(@string_random, :rand_pattern)
  end

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
      assert_match(/#{pattern}/, result)
    end

    result = @string_random.rand_regex(patterns)
    assert_equal(result.size, patterns.size)
  end

  def test_rand_pattern

  end
end
