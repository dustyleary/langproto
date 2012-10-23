
module Sexpr
  def self.read1 str
    v, rest = self.read_piece str
    if rest != ''
      raise ArgumentError, "unexpected trailing characters '#{rest}'"
    end
    v
  end

  def self.read str
    result = []
    while true
      v, str = self.read_piece str
      result << v
      str = self.eat_whitespace str
      if str == ''
        return result
      end
    end
  end

  def self.eat_whitespace str
    return str.strip
  end

  EscapeChars = {
    'n' => "\n",
    't' => "\t",
    "\n" => "\n",
    'r' => "\r",
    '0' => "\0",
    '\\' => "\\"
  }

  def self.read_piece str
    str = self.eat_whitespace str
    m = /^(-?\d+)(.*)/m.match str
    if m
      v, rest = m[1].to_i, m[2]
      return v, rest if rest == ''
      return v, rest if /^[\s\(\)]/m.match rest
    end
    if str[0..0] == '"'
      result = ""
      while true
        c = str[1..1]
        if str == ""
          raise ArgumentError, "unterminated string literal"
        elsif c == '"'
          return result, str[2..-1]
        elsif c == '\\'
          if str[2..-1] == ""
            raise ArgumentError, "unterminated string literal"
          else
            c2 = str[2..2]
            raise ArgumentError, "bad escape: '\\#{c2}'" unless EscapeChars[c2]
            result += EscapeChars[c2]
            str = str[2..-1]
          end
        else
          result += c
          str = str[1..-1]
        end
      end
    end
    if str[0..0] == '('
      str = str[1..-1]
      children = []
      while true
        str = self.eat_whitespace str
        if str[0..0] == ')'
          return children, str[1..-1]
        end
        if str == ''
          raise ArgumentError, "end of input with unterminated list"
        end
        child, str = self.read_piece str
        children << child
      end
    end
    m = /^([^\s\(\)]+)(.*)/m.match str
    if m
      v, rest = m[1].to_sym, m[2]
      return v, rest
    end
    raise ArgumentError, "can't parse: '#{str}'"
  end

end

