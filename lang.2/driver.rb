require 'open3'
require 'tempfile'
require 'sexpr'
require 'pp'

class Type
  def isPrimType? ; false end
  def isIntType? ; false end
  def isAlwaysPointedTo? ; false end # structs, function types
end

class FunType < Type
  attr_reader :retType, :argTypes
  def initialize retType, argTypes
    @retType = retType
    @argTypes = argTypes
  end
  def isAlwaysPointedTo? ; true end
  def to_s ; "#{retType} (#{argTypes.map(&:to_s).join','})" end
end

class PrimType < Type
  attr_reader :llvm
  def initialize llvm
    @llvm = llvm
  end
  def to_s ; @llvm end
  def isPrimType? ; end
  def isIntType? ; @llvm[0...1] == 'i' end
end

class PointerType < Type
  attr_reader :pointeeType
  def initialize pointeeType
    @pointeeType = pointeeType
  end
  def to_s ; "#{@pointeeType}*" end
end

class StructType
  attr_reader :fields, :name
  def initialize name, fields
    @name = name.to_s
    @fields = fields
  end
  def getLlvmFullTypeStr
    "{ #{@fields.map{|f|f[1].to_s}.join', '} }"
  end
  def to_s
    "%struct.#{@name}"
  end
  def isAlwaysPointedTo? ; true end
  def getFieldIndex fieldName
    @fields.each_with_index {|f,i| return i if f[0].to_s == fieldName.to_s }
    raise ArgumentError, "no field named '#{fieldName}'"
  end
end

PrimTypes = {}
%w[i1 i8 i16 i32 void ...].each {|llvm|
  PrimTypes[llvm] = PrimType.new llvm
}

IntBinOps = %q[add sub mul udiv sdiv urem srem shl lshr ashr and or xor]
IntCmpOps = %q[eq ne ugt uge ult ule sgt sge slt sle]

class ModuleCompiler
  attr_reader :primOps, :funTypes

  def initialize
    @declares = []
    @definitions = []
    @structdefs = []

    @global_string_index = 0
    @global_strings = {}

    @funTypes = {}
    @structTypes = {}
    add_declare 'printf', FunType.new('i32', ['i8*', '...'])
    add_declare 'strlen', FunType.new('i32', ['i8*'])
    add_declare 'strcat', FunType.new('i8*', ['i8*', 'i8*'])
  end

  def compile_function tldef
    raise ArgumentError, "expected [:define ...], got #{tldef.inspect}" unless tldef[0] == :define
    raise ArgumentError, "expected [:define [:sym args retType] body], got #{tldef.inspect}" unless tldef[1][0].class == Symbol
    funName = tldef[1][0]
    funArgs = tldef[1][1]
    retType = getType tldef[1][2]
    funType = FunType.new retType, funArgs.map { |n,t| t }
    addFunType funName, funType
    body = tldef[2..-1]
    FunctionCompiler.new(self, funName, funType, funArgs).compile body
  end

  def compile_defstruct tldef
    raise ArgumentError, "expected [:defstruct ...], got #{tldef.inspect}" unless tldef[0] == :defstruct
    structName = tldef[1]
    fieldDefs = tldef[2..-1]
    fieldNames = {}
    fields = fieldDefs.map { |fieldDef|
      fieldName = fieldDef[0]
      raise ArgumentError, "duplicate name: #{fieldName}" if fieldNames[fieldName]
      fieldNames[fieldName] = 1
      fieldType = getType fieldDef[1]
      [fieldName, fieldType]
    }
    structType = StructType.new structName, fields
    @structTypes[structName.to_s] = structType
    add_structdef "%struct.#{structName} = type #{structType.getLlvmFullTypeStr}"
  end

  def compile_module tldefs
    tldefs.each { |tldef|
      if tldef[0] == :define
        compile_function tldef
      elsif tldef[0] == :defstruct
        compile_defstruct tldef
      else
        raise ArgumentError, "can't handle toplevel #{tldef.inspect}"
      end
    }
  end

  def llvm_ir
    (@structdefs + @declares + @definitions).join "\n"
  end

  def add_declare funName, funType
    addFunType funName, funType
    @declares << "declare #{funType.retType} @#{funName}(#{funType.argTypes.join ','})"
  end

  def add_definition deftext
    @definitions << deftext
  end

  def add_structdef deftext
    @structdefs << deftext
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

  def getType typeName
    if PrimTypes.include? typeName.to_s
      return PrimTypes[typeName.to_s]
    end
    if @structTypes.include? typeName.to_s
      return @structTypes[typeName.to_s]
    end
    if typeName.to_s.end_with? '*'
      return PointerType.new getType(typeName.to_s[0...-1])
    end
    raise ArgumentError, "can't find type '#{typeName}'"
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
    result = ['i8*', "getelementptr inbounds ([#{str.length+1} x i8]* #{n}, i32 0, i32 0)"]
    @global_strings[str] = result
    return result
  end

  class FunctionCompiler
    def initialize moduleCompiler, name, type, args
      @moduleCompiler = moduleCompiler
      @name = name
      @argTypes = {}
      @args = args
      @args.each { |n,t| @argTypes[n.to_s] = t.to_s }
      @type = type
      @body = []
      @nameIdx = Hash.new 0
      @localVarTypes = {}
    end

    def bodyLine line
      @body << '  '+line
    end
    def labelLine line
      @body << line
    end

    def localName base
      base = base[1..-1] while base[0...1] == '%'
      n = "%#{base}.#{@nameIdx[base]}"
      @nameIdx[base] += 1
      return n
    end

    def compileFunctionApplication expr
      funName = expr[0].to_s
      funType = @moduleCompiler.getFunType funName
      args = expr[1..-1].map { |e| compile_expr e }
      n = localName "call"
      bodyLine "#{n} = call #{funType.to_s}* @#{funName}(#{args.map{|a| a.join ' '}.join ','})"
      return [funType.retType, n]
    end

    def badfunc funName
      raise NameError, "function '#{funName}' not defined"
    end

    def compileIfApplication expr
      funName = expr[0].to_s
      badfunc(funName) unless funName == 'if'

      if expr.length != 4
        raise ArgumentError, "if expression requires 3 args"
      end

      test = compile_expr expr[1]
      label_then = localName 'if.then'
      label_else = localName 'if.else'
      label_end = localName 'if.end'

      bodyLine "br i1 #{test[1]}, label #{label_then}, label #{label_else}"

      labelLine label_then[1..-1] + ':'
      result_then = compile_expr expr[2]
      bodyLine "br label #{label_end}"

      labelLine label_else[1..-1] + ':'
      result_else = compile_expr expr[3]
      bodyLine "br label #{label_end}"

      labelLine label_end[1..-1] + ':'
      n = localName 'if.result'
      type = result_then[0]
      if type != result_else[0]
        raise ArgumentError, "if expression requires both branches to have the same type #{type.inspect} != #{result_else[0].inspect}"
      end
      bodyLine "#{n} = phi #{type} [ #{result_then[1]},#{label_then} ], [ #{result_else[1]},#{label_else}]"

      return [type, n]
    end

    def compilePrimOpApplication expr
      funName = expr[0].to_s
      info = funName.split ':'
      badfunc(funName) if info.length < 2
      badfunc(funName) unless @moduleCompiler.getType(info[0].to_s).isIntType?
      badfunc(funName) unless IntBinOps.include? info[1] or IntCmpOps.include? info[1]

      if IntBinOps.include? info[1]
        type = info[0]
        opname = info[1]
      else
        type = 'i1'
        opname = "icmp #{info[1]}"
      end

      args = expr[1..-1].map { |e| compile_expr e }

      n = localName info[1]

      bodyLine "#{n} = #{opname} #{info[0]} #{args.map{|a| a[1]}.join ','}"

      return [type, n]
    end

    def compileLocalVariableAllocation expr
      funName = expr[0].to_s
      badfunc(funName) unless funName == 'var'

      if expr.length != 3
        raise ArgumentError, "var statement requires 2 args"
      end

      if expr[1].class != Symbol
        raise ArgumentError, "var statement requires symbol as first arg, got: "+expr[1]
      end

      varName = expr[1]
      varType = @moduleCompiler.getType expr[2]
      @localVarTypes[varName.to_s] = PointerType.new varType
      # TODO: align
      bodyLine "%#{expr[1]} = alloca #{varType}"
    end

    def compileLocalVarLookup expr
      raise ArgumentError, "expected Symbol, got #{expr}" unless expr.is_a? Symbol
      raise ArgumentError, "not a local variable: #{expr}" unless @localVarTypes[expr.to_s]
      [@localVarTypes[expr.to_s], "%#{expr.to_s}"]
    end

    def compileSetBang expr
      if expr.length != 3
        raise ArgumentError, "set! statement requires 2 args"
      end

      address = compile_expr expr[1]

      value = compile_expr expr[2]
      # TODO: align
      bodyLine "store #{value[0]} #{value[1]}, #{address[0]} #{address[1].to_s}"
    end

    def compileGet expr
      if expr.length != 2
        raise ArgumentError, "get statement requires 1 arg"
      end
      subExpr = compile_expr expr[1]
      n = localName expr.to_s
      bodyLine "#{n} = load #{subExpr[0]} #{subExpr[1].to_s}"
      return [subExpr[0].pointeeType, n]
    end

    def compileStructFieldPtr expr
      if expr.length != 3
        raise ArgumentError, "struct-field statement requires 2 args"
      end

      structExpr = compile_expr expr[1]
      fieldName = expr[2]

      raise ArgumentError, "expected pointer-to-StructType, got: #{structExpr}" unless (structExpr[0].is_a?(PointerType) and structExpr[0].pointeeType.is_a?(StructType))
      raise ArgumentError, "expected Symbol, got: #{fieldName}" unless fieldName.is_a? Symbol

      structPtrType = structExpr[0]
      structType = structPtrType.pointeeType
      fieldIndex = structType.getFieldIndex fieldName

      n = localName fieldName.to_s+'.ptr'
      bodyLine "#{n} = getelementptr inbounds #{structExpr[0]} #{structExpr[1]}, i32 0, i32 #{fieldIndex}"
      [PointerType.new(structType.fields[fieldIndex][1]), n]
    end

    def compileStructSetBang expr
      structExpr = compile_expr expr[1]
      fieldPtr = compileStructFieldPtr structExpr, expr[2]
      value = compile_expr expr[3]

      bodyLine "store #{value[0]} #{value[1]}, #{fieldPtr[0]} #{fieldPtr[1].to_s}"
    end

    def compileStructGet expr
      structExpr = compile_expr expr[1]
      fieldPtr = compileStructFieldPtr structExpr, expr[2]

      n = localName expr[2].to_s
      bodyLine "#{n} = load #{fieldPtr[0]} #{fieldPtr[1].to_s}"
      return [fieldPtr[0].pointeeType, n]
    end

    def compileSpecialForm expr
      if expr.length == 0
        raise ArgumentError, "unhandled expr: #{expr.inspect}"
      end

      if expr[0].to_s == 'if'
        return compileIfApplication expr
      elsif expr[0].to_s == 'var'
        return compileLocalVariableAllocation expr
      elsif expr[0].to_s == 'set!'
        return compileSetBang expr
      elsif expr[0].to_s == 'get'
        return compileGet expr
      elsif expr[0].to_s == 'struct-field'
        return compileStructFieldPtr expr
      else
        return compilePrimOpApplication expr
      end

    end

    def compile_expr expr
      if expr.class == Fixnum
        return ['i32', expr]
      elsif expr.class == Symbol
        if @argTypes[expr.to_s]
          return [@argTypes[expr.to_s], '%'+expr.to_s]
        elsif @localVarTypes[expr.to_s]
          return compileLocalVarLookup expr
        else
          raise NameError, "can't resolve symbol: #{expr.to_s}"
        end
      elsif expr.class == String
        return @moduleCompiler.global_string expr
      elsif expr.class == Array
        funName = expr[0].to_s
        if @moduleCompiler.funTypes[funName]
          return compileFunctionApplication expr
        else
          return compileSpecialForm expr
        end
      end

      raise ArgumentError, "unhandled expr: #{expr.inspect}"
    end

    def compile body
      result = nil
      body.each { | expr| result = compile_expr expr }
      bodyLine "ret #{result.join ' '}"
      funtext = "define #{@type.retType.to_s} @#{@name}(#{@args.map{|n,t| "#{t} %#{n}"}.join ','}) nounwind uwtable ssp {\n"
      funtext += @body.join "\n"
      funtext += "\n}"
      @moduleCompiler.add_definition funtext
    end
  end
end

def test_compile_expr result, body
  if body.instance_of? String
    body = Sexpr.read1 body
  end
  mc = ModuleCompiler.new
  test_compile result, [[:define, [:main, [], 'i32'], body]]
end

def test_compile result, program
  if program.instance_of? String
    program = Sexpr.read program
  end
  mc = ModuleCompiler.new
  mc.compile_module program

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
  else
    puts 'OK'
  end
end

