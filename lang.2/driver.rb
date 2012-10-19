require 'open3'
require 'tempfile'

class FunType
  attr_reader :retType, :argTypes
  def initialize retType, argTypes
    @retType = retType
    @argTypes = argTypes
  end

  def to_s
    "#{retType} (#{argTypes.map(&:to_s).join','})"
  end
end

IntTypes = %q[i1 i8 i16 i32]
IntBinOps = %q[add sub mul udiv sdiv urem srem shl lshr ashr and or xor]

class ModuleCompiler
  attr_reader :primOps, :funTypes

  def initialize
    @declares = []
    @definitions = []

    @global_string_index = 0
    @global_strings = {}

    @funTypes = {}
    add_declare 'printf', FunType.new('i32', ['i8*', '...'])
    add_declare 'strlen', FunType.new('i32', ['i8*'])
    add_declare 'strcat', FunType.new('i8*', ['i8*', 'i8*'])
  end

  def compile_function tldef
    raise ArgumentError, "expected [:define ...], got #{tldef.inspect}" unless tldef[0] == :define
    raise ArgumentError, "expected [:define [:sym args] body], got #{tldef.inspect}" unless tldef[1][0].class == Symbol
    funName = tldef[1][0]
    funArgs = tldef[1][1]
    funType = FunType.new tldef[1][2], funArgs.map { |n,t| t }
    addFunType funName, funType
    body = tldef[2..-1]
    FunctionCompiler.new(self, funName, funType, funArgs).compile body
  end

  def llvm_ir
    @declares.join("\n") + "\n" + @definitions.join("\n")
  end

  def add_declare funName, funType
    addFunType funName, funType
    @declares << "declare #{funType.retType} @#{funName}(#{funType.argTypes.join ','})"
  end

  def add_definition deftext
    @definitions << deftext
  end

  def addFunType funName, funType
    funName = funName.to_s
    raise NameError, "function '#{funName}' already exists" if @funTypes.has_key? funName
    @funTypes[funName] = funType
  end

  def getFunType funName
    if not @funTypes.has_key? funName
      raise NameError, "function '#{funName}' not defined"
    end
    return @funTypes[funName]
  end

  def global_string str
    return @global_strings[str] if @global_strings[str]

    n = "@.str.#{@global_string_index}"
    @global_string_index += 1
    string_as_chars = str.split ''
    emit_chars = string_as_chars.map { |c|
      if c[0]>=32
        c
      else
        "\\%02X" % c[0]
      end
    }.join ''
    add_definition "#{n} = private unnamed_addr constant [#{str.length+1} x i8] c\"#{emit_chars}\\00\", align 1"
    result = ["i8*", "getelementptr inbounds ([#{str.length+1} x i8]* #{n}, i32 0, i32 0)"]
    @global_strings[str] = result
    return result
  end

  class FunctionCompiler
    def initialize moduleCompiler, name, type, args
      @moduleCompiler = moduleCompiler
      @name = name
      @argTypes = {}
      @args = args
      @args.each { |n,t| @argTypes[n.to_s] = t }
      @type = type
      @body = []
      @call_index = 0
    end

    def compileFunctionApplication expr
        funName = expr[0].to_s
        funType = @moduleCompiler.getFunType funName
        args = expr[1..-1].map { |e| compile_expr e }
        n = "%.call.#{@call_index}"
        @call_index += 1
        @body << "#{n} = call #{funType.to_s}* @#{funName}(#{args.map{|a| a.join ' '}.join ','})"
        return [funType.retType, n]
    end

    def compilePrimOpApplication expr
        funName = expr[0].to_s
        info = funName.split ':'
        bad = Proc.new { raise NameError, "function '#{funName}' not defined" }
        bad.call if info.length < 2
        bad.call unless IntTypes.include? info[0]
        bad.call unless IntBinOps.include? info[1]

        type = info[0]

        args = expr[1..-1].map { |e| compile_expr e }

        n = "%.call.#{@call_index}"
        @call_index += 1

        @body << "#{n} = #{info[1]} #{info[0]} #{args.map{|a| a[1]}.join ','}"

        return [type, n]
    end

    def compile_expr expr
      if expr.class == Fixnum
        return ["i32", expr]
      elsif expr.class == Symbol
        return [@argTypes[expr.to_s], '%'+expr.to_s]
      elsif expr.class == String
        return @moduleCompiler.global_string expr
      elsif expr.class == Array
        funName = expr[0].to_s
        if @moduleCompiler.funTypes[funName]
          return compileFunctionApplication expr
        else
          return compilePrimOpApplication expr
        end
      end

      raise ArgumentError, "unhandled expr: #{expr.inspect}"
    end

    def compile body
      result = nil
      body.each { | expr| result = compile_expr expr }
      @body << "ret #{result.join ' '}"
      funtext = "define #{@type.retType.to_s} @#{@name}(#{@args.map{|n,t| "#{t} %#{n}"}.join ','}) nounwind uwtable ssp {\n"
      funtext += @body.map {|line| "  #{line}"}.join "\n"
      funtext += "\n}"
      @moduleCompiler.add_definition funtext
    end
  end
end

def test_compile_expr result, body
  mc = ModuleCompiler.new
  test_compile result, [[:define, [:main, [], 'i32'], body]]
end

def test_compile result, program
  mc = ModuleCompiler.new
  program.each { |tldef|
    raise ArgumentError, "can't handle toplevel #{tldef.inspect}" unless tldef[0] == :define
    mc.compile_function tldef
  }

  llvm = mc.llvm_ir

  separator = '='*80
  puts separator
  puts llvm
  puts separator
  $stdout.flush
  $stderr.flush

  childin = IO::pipe
  childout = IO::pipe
  pid = fork {
    childin[1].close
    $stdin.reopen childin[0]
    childin[0].close

    childout[0].close
    $stdout.reopen childout[1]
    childout[1].close

    exec 'lli' #+ ' -stats'
  }

  childin[0].close
  childin[1].puts llvm
  childin[1].close

  childout[1].close
  output = childout[0].read()

  Process.waitpid pid

  got_result = [$?.exitstatus, output]
  p got_result
  if got_result != result
    raise ArgumentError, "expected #{result.inspect}, got #{got_result.inspect}"
  end
end

