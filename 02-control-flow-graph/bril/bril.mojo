"""Typed Bril IR, parsed straight from Bril JSON with EmberJSON.

    from emberjson import from_json
    from bril import BrilProgram

    var prog = from_json[BrilProgram](raw)
    print(prog)  # the parsed structs, field by field

Nothing here hands an EmberJSON `Value` back to the caller. `Value` is used
only inside `BrilType.deserialize` and `Code.deserialize`, for the two wire
fields whose JSON shape varies: `type` (string or `{"ptr": ...}`) and
`value` (number, boolean or one-character string).
"""

from std.utils import Variant
from emberjson import Value, from_json
from emberserde import (
    Deserializable,
    Deserializer,
    DeserializationError,
    DerErrorKind,
    deserialize,
)


def _invalid(msg: Some[Writable]) -> DeserializationError:
    return DeserializationError(String(msg), DerErrorKind.InvalidValue)


def _or_empty[T: Copyable & Deinitable](var xs: Optional[List[T]]) -> List[T]:
    if xs:
        return xs.take()
    return List[T]()


# --------------------------------------------------------------------------
# Struct-form printing
#
# `print(x)` on any Bril struct shows its fields, nested and indented like
# Rust's `{:#?}`. Each type implements `write_debug(w, level)`, where
# `level` is the indentation depth of the line the value starts on.
# --------------------------------------------------------------------------


trait DebugWritable:
    def write_debug(self, mut w: Some[Writer], level: Int):
        ...


def _pad(mut w: Some[Writer], level: Int):
    for _ in range(level):
        w.write("  ")


def _quote(mut w: Some[Writer], s: String):
    w.write('"')
    for cp in s.codepoints():
        var n = cp.to_u32()
        if n == 34:
            w.write('\\"')
        elif n == 92:
            w.write("\\\\")
        elif n == 10:
            w.write("\\n")
        elif n == 9:
            w.write("\\t")
        else:
            w.write(cp)
    w.write('"')


def _open(mut w: Some[Writer], name: StaticString):
    w.write(name, " {\n")


def _key(mut w: Some[Writer], level: Int, name: StaticString):
    _pad(w, level + 1)
    w.write(name, ": ")


def _next(mut w: Some[Writer]):
    w.write(",\n")


def _close(mut w: Some[Writer], level: Int):
    _pad(w, level)
    w.write("}")


def _strs(mut w: Some[Writer], xs: List[String]):
    w.write("[")
    for i in range(len(xs)):
        if i:
            w.write(", ")
        _quote(w, xs[i])
    w.write("]")


def _opt_str(mut w: Some[Writer], o: Optional[String]):
    if o:
        w.write("Some(")
        _quote(w, o.value())
        w.write(")")
    else:
        w.write("None")


def _opt[
    T: DebugWritable & Copyable
](mut w: Some[Writer], o: Optional[T], level: Int):
    if o:
        w.write("Some(")
        o.value().write_debug(w, level)
        w.write(")")
    else:
        w.write("None")


def _list[
    T: DebugWritable & Copyable
](mut w: Some[Writer], xs: List[T], level: Int):
    if not xs:
        w.write("[]")
        return
    w.write("[\n")
    for x in xs:
        _pad(w, level + 1)
        x.write_debug(w, level + 1)
        _next(w)
    _pad(w, level)
    w.write("]")


# --------------------------------------------------------------------------
# Source positions
# --------------------------------------------------------------------------


@fieldwise_init
struct Position(Copyable, DebugWritable, Defaultable, Movable, Writable):
    var row: Int
    var col: Int

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        w.write("Position { row: ", self.row, ", col: ", self.col, " }")

    def __init__(out self):
        self.row = 0
        self.col = 0


# --------------------------------------------------------------------------
# Types
# --------------------------------------------------------------------------


struct BrilType(
    Copyable, DebugWritable, Defaultable, Deserializable, Equatable, Writable
):
    """A Bril type. `ptr<ptr<int>>` is `base="int", wrappers=["ptr", "ptr"]`.

    Bril's only parameterized types take exactly one parameter, so a chain of
    wrapper names around a primitive covers the whole type grammar without a
    recursive struct.
    """

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        w.write("BrilType { base: ")
        _quote(w, self.base)
        w.write(", wrappers: ")
        _strs(w, self.wrappers)
        w.write(" }")

    var base: String
    var wrappers: List[String]  # outermost first

    def __init__(out self):
        self.base = "void"
        self.wrappers = []

    def __init__(out self, var base: String):
        self.base = base^
        self.wrappers = []

    def __init__(out self, var base: String, var wrappers: List[String]):
        self.base = base^
        self.wrappers = wrappers^

    @staticmethod
    def ptr(inner: BrilType) -> BrilType:
        var w: List[String] = ["ptr"]
        w.extend(inner.wrappers.copy())
        return BrilType(inner.base, w^)

    def is_ptr(self) -> Bool:
        return len(self.wrappers) > 0 and self.wrappers[0] == "ptr"

    def is_primitive(self) -> Bool:
        return len(self.wrappers) == 0

    def is_primitive(self, name: StringSlice) -> Bool:
        return len(self.wrappers) == 0 and self.base == name

    def pointee(self) raises -> BrilType:
        """The type one level in: `ptr<int>` -> `int`."""
        if len(self.wrappers) == 0:
            raise Error(t"{self} is not a parameterized type")
        var w = List[String](capacity=len(self.wrappers) - 1)
        for i in range(1, len(self.wrappers)):
            w.append(self.wrappers[i])
        return BrilType(self.base, w^)

    def __eq__(self, other: Self) -> Bool:
        return self.base == other.base and self.wrappers == other.wrappers

    @staticmethod
    def _from_value(v: Value) raises DeserializationError -> BrilType:
        if v.is_string():
            return BrilType(v.string())
        if v.is_object():
            ref obj = v.object()
            if len(obj) != 1:
                raise _invalid(
                    "parameterized type must have exactly one key, e.g."
                    ' {"ptr": "int"}'
                )
            for item in obj.items():
                var ty = BrilType._from_value(item.value)
                ty.wrappers.insert(0, String(item.key))
                return ty^
        raise _invalid(t"expected a type (string or object), got {v}")

    @staticmethod
    def deserialize(
        mut d: Some[Deserializer],
    ) raises DeserializationError -> Self:
        return Self._from_value(deserialize[Value](d))


# --------------------------------------------------------------------------
# Literals
# --------------------------------------------------------------------------


def _char_escape(cp: Codepoint) -> Optional[StaticString]:
    var n = cp.to_u32()
    if n == 0:
        return StaticString("\\0")
    if n == 7:
        return StaticString("\\a")
    if n == 8:
        return StaticString("\\b")
    if n == 9:
        return StaticString("\\t")
    if n == 10:
        return StaticString("\\n")
    if n == 11:
        return StaticString("\\v")
    if n == 12:
        return StaticString("\\f")
    if n == 13:
        return StaticString("\\r")
    return None


struct Literal(Copyable, DebugWritable, Movable, Writable):
    """The value of a `const`: an int, bool, float or char.

    The kind follows the instruction's declared type, so `{"type": "float",
    "value": 1}` is the float `1.0`, not the int `1`. `nullptr` arrives as
    the int `0`, which is how `bril2json` encodes it.
    """

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        if self.is_int():
            w.write("Literal.Int(", self.int(), ")")
        elif self.is_bool():
            w.write("Literal.Bool(", "true" if self.bool() else "false", ")")
        elif self.is_float():
            w.write("Literal.Float(", self.float(), ")")
        else:
            var esc = _char_escape(self.char())
            w.write("Literal.Char('")
            if esc:
                w.write(esc.value())
            else:
                w.write(self.char())
            w.write("')")

    comptime Storage = Variant[Int64, Bool, Float64, Codepoint]
    var _v: Self.Storage

    @implicit
    def __init__(out self, v: Int64):
        self._v = v

    @implicit
    def __init__(out self, v: Bool):
        self._v = v

    @implicit
    def __init__(out self, v: Float64):
        self._v = v

    @implicit
    def __init__(out self, v: Codepoint):
        self._v = v

    def is_int(self) -> Bool:
        return self._v.isa[Int64]()

    def is_bool(self) -> Bool:
        return self._v.isa[Bool]()

    def is_float(self) -> Bool:
        return self._v.isa[Float64]()

    def is_char(self) -> Bool:
        return self._v.isa[Codepoint]()

    def int(self) -> Int64:
        return self._v[Int64]

    def bool(self) -> Bool:
        return self._v[Bool]

    def float(self) -> Float64:
        return self._v[Float64]

    def char(self) -> Codepoint:
        return self._v[Codepoint]

    @staticmethod
    def _from_value(
        v: Value, ty: Optional[BrilType]
    ) raises DeserializationError -> Literal:
        var want = String()
        if ty and ty.value().is_primitive():
            want = ty.value().base

        if want == "float":
            if v.is_float():
                return v.float()
            if v.is_int():
                return Float64(v.int())
            if v.is_uint():
                return Float64(v.uint())
            raise _invalid(t"float const needs a number, got {v}")
        if want == "int":
            if v.is_int():
                return v.int()
            if v.is_uint() and v.uint() <= UInt64(Int64.MAX):
                return Int64(v.uint())
            raise _invalid(t"int const needs a 64-bit integer, got {v}")
        if want == "bool" and not v.is_bool():
            raise _invalid(t"bool const needs true or false, got {v}")
        if want == "char" and not v.is_string():
            raise _invalid(t"char const needs a string, got {v}")

        # `any`, pointers and unknown extension types: go by the JSON kind.
        if v.is_bool():
            return v.bool()
        if v.is_int():
            return v.int()
        if v.is_uint() and v.uint() <= UInt64(Int64.MAX):
            return Int64(v.uint())
        if v.is_float():
            return v.float()
        if v.is_string():
            ref s = v.string()
            if s.count_codepoints() != 1:
                raise _invalid(t"char const must be one character, got {v}")
            for cp in s.codepoints():
                return cp
        raise _invalid(t"unsupported const value {v}")


# --------------------------------------------------------------------------
# Instructions and labels
# --------------------------------------------------------------------------


@fieldwise_init
struct Label(Copyable, DebugWritable, Movable, Writable):
    var _name: String
    var pos: Optional[Position]
    var pos_end: Optional[Position]
    var src: Optional[String]

    def name(self) -> String:
      return self._name

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        _open(w, "Label")
        _key(w, level, "name")
        _quote(w, self._name)
        _next(w)
        _key(w, level, "pos")
        _opt(w, self.pos, level + 1)
        _next(w)
        _key(w, level, "pos_end")
        _opt(w, self.pos_end, level + 1)
        _next(w)
        _key(w, level, "src")
        _opt_str(w, self.src)
        _next(w)
        _close(w, level)

    def __init__(out self, var name: String):
        self._name = name^
        self.pos = None
        self.pos_end = None
        self.src = None


@fieldwise_init
struct Instruction(Copyable, DebugWritable, Movable, Writable):
    """A Bril instruction. Absent `args`/`funcs`/`labels` are empty lists."""

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        _open(w, "Instruction")
        _key(w, level, "op")
        _quote(w, self.op)
        _next(w)
        _key(w, level, "dest")
        _opt_str(w, self.dest)
        _next(w)
        _key(w, level, "type")
        _opt(w, self.type, level + 1)
        _next(w)
        _key(w, level, "args")
        _strs(w, self.args)
        _next(w)
        _key(w, level, "funcs")
        _strs(w, self.funcs)
        _next(w)
        _key(w, level, "labels")
        _strs(w, self.labels)
        _next(w)
        _key(w, level, "value")
        _opt(w, self.value, level + 1)
        _next(w)
        _key(w, level, "pos")
        _opt(w, self.pos, level + 1)
        _next(w)
        _key(w, level, "pos_end")
        _opt(w, self.pos_end, level + 1)
        _next(w)
        _key(w, level, "src")
        _opt_str(w, self.src)
        _next(w)
        _close(w, level)

    var op: String
    var dest: Optional[String]
    var type: Optional[BrilType]
    var args: List[String]
    var funcs: List[String]
    var labels: List[String]
    var value: Optional[Literal]
    var pos: Optional[Position]
    var pos_end: Optional[Position]
    var src: Optional[String]

    def is_const(self) -> Bool:
        return self.op == "const"

    def is_value_op(self) -> Bool:
        """Produces a value (has a `dest`) and is not a `const`."""
        return Bool(self.dest) and not self.is_const()

    def is_effect_op(self) -> Bool:
        return not self.dest


# Wire shape of one entry in a function's `instrs`: the union of a Label and
# an Instruction, with every key optional. `Code.deserialize` reads this via
# reflection and then decides which one it is.
struct _WireCode(Defaultable, Movable):
    var label: Optional[String]
    var op: Optional[String]
    var dest: Optional[String]
    var type: Optional[BrilType]

    var args: Optional[List[String]]

    var funcs: Optional[List[String]]

    var labels: Optional[List[String]]

    var value: Optional[Value]
    var pos: Optional[Position]
    var pos_end: Optional[Position]
    var src: Optional[String]

    def __init__(out self):
        self.label = None
        self.op = None
        self.dest = None
        self.type = None
        self.args = None
        self.funcs = None
        self.labels = None
        self.value = None
        self.pos = None
        self.pos_end = None
        self.src = None

    def into_code(deinit self) raises DeserializationError -> Code:
        if self.label and self.op:
            raise _invalid(
                t"entry has both a label ({self.label.value()}) and an op"
                t" ({self.op.value()})"
            )
        if self.label:
            return Label(self.label.take(), self.pos^, self.pos_end^, self.src^)
        if not self.op:
            raise _invalid("entry has neither a 'label' nor an 'op' key")

        var op = self.op.take()
        var lit = Optional[Literal]()
        if self.value:
            lit = Literal._from_value(self.value.value(), self.type)
        elif op == "const":
            raise _invalid("const instruction is missing 'value'")
        if op == "const" and not self.dest:
            raise _invalid("const instruction is missing 'dest'")

        return Instruction(
            op^,
            self.dest^,
            self.type^,
            _or_empty(self.args^),
            _or_empty(self.funcs^),
            _or_empty(self.labels^),
            lit^,
            self.pos^,
            self.pos_end^,
            self.src^,
        )


struct Code(Copyable, DebugWritable, Deserializable, Movable, Writable):
    """One entry of `Function.instrs`: a `Label` or an `Instruction`."""

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        if self.is_label():
            self.label().write_debug(w, level)
        else:
            self.instr().write_debug(w, level)

    var _v: Variant[Label, Instruction]

    @implicit
    def __init__(out self, var l: Label):
        self._v = l^

    @implicit
    def __init__(out self, var i: Instruction):
        self._v = i^

    def is_label(self) -> Bool:
        return self._v.isa[Label]()

    def is_instr(self) -> Bool:
        return self._v.isa[Instruction]()

    def label(ref self) -> ref[self._v] Label:
        debug_assert(self.is_label(), "Code.label() on an instruction")
        return self._v.unsafe_get[Label]()

    def instr(ref self) -> ref[self._v] Instruction:
        debug_assert(self.is_instr(), "Code.instr() on a label")
        return self._v.unsafe_get[Instruction]()

    @staticmethod
    def deserialize(
        mut d: Some[Deserializer],
    ) raises DeserializationError -> Self:
        return deserialize[_WireCode](d).into_code()


# --------------------------------------------------------------------------
# Functions and programs
# --------------------------------------------------------------------------


@fieldwise_init
struct Argument(Copyable, DebugWritable, Defaultable, Movable, Writable):
    var name: String
    var type: BrilType

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        w.write("Argument { name: ")
        _quote(w, self.name)
        w.write(", type: ")
        self.type.write_debug(w, level)
        w.write(" }")

    def __init__(out self):
        self.name = ""
        self.type = BrilType()


@fieldwise_init
struct Function(
    Copyable, DebugWritable, Defaultable, Deserializable, Movable, Writable
):
    var name: String
    var args: List[Argument]  # empty when the JSON omits `args`
    var type: Optional[BrilType]  # None means no return value
    var instrs: List[Code]
    var pos: Optional[Position]
    var pos_end: Optional[Position]
    var src: Optional[String]

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        _open(w, "Function")
        _key(w, level, "name")
        _quote(w, self.name)
        _next(w)
        _key(w, level, "args")
        _list(w, self.args, level + 1)
        _next(w)
        _key(w, level, "type")
        _opt(w, self.type, level + 1)
        _next(w)
        _key(w, level, "instrs")
        _list(w, self.instrs, level + 1)
        _next(w)
        _key(w, level, "pos")
        _opt(w, self.pos, level + 1)
        _next(w)
        _key(w, level, "pos_end")
        _opt(w, self.pos_end, level + 1)
        _next(w)
        _key(w, level, "src")
        _opt_str(w, self.src)
        _next(w)
        _close(w, level)

    def __init__(out self):
        self.name = ""
        self.args = []
        self.type = None
        self.instrs = []
        self.pos = None
        self.pos_end = None
        self.src = None

    @staticmethod
    def deserialize(
        mut d: Some[Deserializer],
    ) raises DeserializationError -> Self:
        return deserialize[_WireFunction](d).into_function()


struct _WireFunction(Defaultable, Movable):
    var name: String
    var args: Optional[List[Argument]]
    var type: Optional[BrilType]
    var instrs: List[Code]
    var pos: Optional[Position]
    var pos_end: Optional[Position]
    var src: Optional[String]

    def __init__(out self):
        self.name = ""
        self.args = None
        self.type = None
        self.instrs = []
        self.pos = None
        self.pos_end = None
        self.src = None

    def into_function(deinit self) -> Function:
        return Function(
            self.name^,
            _or_empty(self.args^),
            self.type^,
            self.instrs^,
            self.pos^,
            self.pos_end^,
            self.src^,
        )


@fieldwise_init
struct ImportedFunction(
    Copyable, DebugWritable, Defaultable, Movable, Writable
):
    var name: String
    var alias: Optional[String]

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        w.write("ImportedFunction { name: ")
        _quote(w, self.name)
        w.write(", alias: ")
        _opt_str(w, self.alias)
        w.write(" }")

    def __init__(out self):
        self.name = ""
        self.alias = None

    def local_name(self) -> String:
        return self.alias.value() if self.alias else self.name


@fieldwise_init
struct Import(Copyable, DebugWritable, Defaultable, Movable, Writable):
    var path: String
    var functions: List[ImportedFunction]

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        _open(w, "Import")
        _key(w, level, "path")
        _quote(w, self.path)
        _next(w)
        _key(w, level, "functions")
        _list(w, self.functions, level + 1)
        _next(w)
        _close(w, level)

    def __init__(out self):
        self.path = ""
        self.functions = []


@fieldwise_init
struct StructMember(Copyable, DebugWritable, Defaultable, Movable, Writable):
    var name: String
    var type: BrilType

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        w.write("StructMember { name: ")
        _quote(w, self.name)
        w.write(", type: ")
        self.type.write_debug(w, level)
        w.write(" }")

    def __init__(out self):
        self.name = ""
        self.type = BrilType()


@fieldwise_init
struct StructDef(Copyable, DebugWritable, Defaultable, Movable, Writable):
    """`struct` declarations, which `bril2json` emits under `"structs"`."""

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        _open(w, "StructDef")
        _key(w, level, "name")
        _quote(w, self.name)
        _next(w)
        _key(w, level, "mbrs")
        _list(w, self.mbrs, level + 1)
        _next(w)
        _close(w, level)

    var name: String
    var mbrs: List[StructMember]

    def __init__(out self):
        self.name = ""
        self.mbrs = []


@fieldwise_init
struct BrilProgram(
    Copyable, DebugWritable, Defaultable, Deserializable, Movable, Writable
):
    var functions: List[Function]
    var imports: List[Import]  # empty when the JSON omits `imports`
    var structs: List[StructDef]  # empty when the JSON omits `structs`

    def write_to(self, mut w: Some[Writer]):
        self.write_debug(w, 0)

    def write_debug(self, mut w: Some[Writer], level: Int):
        _open(w, "BrilProgram")
        _key(w, level, "functions")
        _list(w, self.functions, level + 1)
        _next(w)
        _key(w, level, "imports")
        _list(w, self.imports, level + 1)
        _next(w)
        _key(w, level, "structs")
        _list(w, self.structs, level + 1)
        _next(w)
        _close(w, level)

    def __init__(out self):
        self.functions = []
        self.imports = []
        self.structs = []

    @staticmethod
    def deserialize(
        mut d: Some[Deserializer],
    ) raises DeserializationError -> Self:
        return deserialize[_WireProgram](d).into_program()

    def find_function(ref self, name: StringSlice) -> Optional[Int]:
        for i in range(len(self.functions)):
            if self.functions[i].name == name:
                return i
        return None


struct _WireProgram(Defaultable, Movable):
    var functions: List[Function]
    var imports: Optional[List[Import]]
    var structs: Optional[List[StructDef]]

    def __init__(out self):
        self.functions = []
        self.imports = None
        self.structs = None

    def into_program(deinit self) -> BrilProgram:
        return BrilProgram(
            self.functions^, _or_empty(self.imports^), _or_empty(self.structs^)
        )


def parse_bril(raw: StringSlice) raises -> BrilProgram:
    """Parse Bril JSON text into a `BrilProgram`."""
    return from_json[BrilProgram](String(raw))
