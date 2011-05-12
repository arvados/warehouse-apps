
BEGIN {
  init_type_database();

  typesfile = "g-types.h";
  inlines = "g-inlines.ch";
  functions = "g-functions.ch";
  prototypes = "g-prototypes.h";

  generate_pack_functions(prototypes, inlines, functions);
  generate_unpack_functions(prototypes, inlines, functions);

  generate_unboxed_union(typesfile);
  generate_type_tag_enum(typesfile);
  generate_boxed_struct(typesfile);

  generate_type_tag_nameof(prototypes, inlines, functions);
  generate_typelexer(prototypes, inlines, functions);
  generate_bitsof_fn(prototypes, inlines, functions);
  generate_eq_fn(prototypes, inlines, functions);

  generate_box_functions(prototypes, inlines, functions);
  generate_unbox_functions(prototypes, inlines, functions);

  generate_typeof_fn(prototypes, inlines, functions);
  generate_pack_boxed_function(prototypes, inlines, functions);
  generate_unpack_boxed_function(prototypes, inlines, functions);

  generate_cast_to_fixed_type_ops(prototypes, inlines, functions);
  generate_cast_to_dynamic_type_op(prototypes, inlines, functions);
  generate_asa_functions(prototypes, inlines, functions);

  generate_binop_cast_fn(prototypes, inlines, functions);
  generate_math_binops(prototypes, inlines, functions);
  generate_math_monops(prototypes, inlines, functions);

  generate_fmt(prototypes, inlines, functions);

  generate_arch_tag(typesfile, "arch-tag: Thomas Lord Fri Oct 27 17:00:44 2006 (libtaql/g-types.awk)");
  generate_arch_tag(inlines, "arch-tag: Thomas Lord Fri Oct 27 17:03:05 2006 (libtaql/g-inlines.c)");
  generate_arch_tag(functions, "arch-tag: Thomas Lord Fri Oct 27 17:03:05 2006 (libtaql/g-functions.c)");
  generate_arch_tag(prototypes, "arch-tag: Thomas Lord Fri Oct 27 17:03:05 2006 (libtaql/g-prototypes.h)");
}


function init_type_database ()
{
  taqltypes["int4"] = 4;
  {
    repstub["int4"] = "int32";
    bitsize["int4"] = 4;
    exact["int4"] = 1;
    signed["int4"] = 1;
  }


  taqltypes["uint4"] = 5;
  {
    repstub["uint4"] = "uint32";
    bitsize["uint4"] = 4;
    exact["uint4"] = 1;
    unsigned["uint4"] = 1;
  }


  taqltypes["int8"] = 6;
  {
    repstub["int8"] = "int32";
    bitsize["int8"] = 8;
    exact["int8"] = 1;
    signed["int8"] = 1;
  }

  taqltypes["uint8"] = 7;
  {
    repstub["uint8"] = "uint32";
    bitsize["uint8"] = 8;
    exact["uint8"] = 1;
    unsigned["uint8"] = 1;
  }

  taqltypes["int32"] = 10;
  {
    repstub["int32"] = "int32";
    bitsize["int32"] = 32;
    exact["int32"] = 1;
    signed["int32"] = 1;
  }

  taqltypes["uint32"] = 11;
  {
    repstub["uint32"] = "uint32";
    bitsize["uint32"] = 32;
    exact["uint32"] = 1;
    unsigned["uint32"] = 1;
  }

  taqltypes["int64"] = 12;
  {
    repstub["int64"] = "int64";
    bitsize["int64"] = 64;
    exact["int64"] = 1;
    signed["int64"] = 1;
  }

  taqltypes["uint64"] = 13;
  {
    repstub["uint64"] = "uint64";
    bitsize["uint64"] = 64;
    exact["uint64"] = 1;
    unsigned["uint64"] = 1;
  }

  taqltypes["sfloat"] = 14;
  {
    repstub["sfloat"] = "sfloat";
    bitsize["sfloat"] = 32;
    inexact["sfloat"] = 1;
    signed["sfloat"] = 1;
  }

  taqltypes["dfloat"] = 15;
  {
    repstub["dfloat"] = "dfloat";
    bitsize["dfloat"] = 64;
    inexact["dfloat"] = 1;
    signed["dfloat"] = 1;
  }

 taqltypes["sym"] = 16;
  {
    repstub["sym"] = "sym";
    bitsize["sym"] = 64;
  }

  for (x in taqltypes)
    union_types[repstub[x]] = 1;

  for (x in exact)
   numeric[x] = 1;
  for (x in inexact)
   numeric[x] = 1;

  mathbinops["add"] = "+";
  mathbinops["sub"] = "-";
  mathbinops["mul"] = "*";
  mathbinops["div"] = "/";

  exactbinops["land"] = "&&";
  exactbinops["lor"] = "||";
  exactbinops["band"] = "&";
  exactbinops["bor"] = "|";
  exactbinops["bxor"] = "^";
  exactbinops["mod"] = "%";

  for (op in exactbinops)
    mathbinops[op] = exactbinops[op];

  mathmonops["neg"] = 1;
  mathmonops["inc"] = 1;
  mathmonops["dec"] = 1;
  mathmonops["lnot"] = 1;
  exactmonops["bnot"] = 1;

  for (op in exactmonops)
    mathmonops[op] = 1;
}


function generate_pack_functions(protos, inls, fns, type, rtype, name, formals)
{
  for (type in taqltypes)
    {
      rtype = "void";
      name = "taql_pack_" type;
      formals = "(void * mem, size_t bit_offset, t_taql_" repstub[type] " v)";
      start_inline_function(protos, inls, fns, rtype, name, formals);

      printf "{\n" > inls;
      if (bitsize[type] < 8)
        {
          mask = "((1 << " bitsize[type] ") - 1)";
          printf "  *(unsigned char *)mem &= ~(" mask " << bit_offset);\n" > inls;
          printf "  *(unsigned char *)mem |= ((v & " mask ") << bit_offset);\n" > inls;
        }
      else if (exact[type] && (bitsize[type] == 8))
        {
          if (unsigned[type])
            printf " *(unsigned char *)mem = (unsigned char)v;\n" > inls;
          else
            printf " *(char *)mem = (char)v;\n" > inls;
        }
      else
        {
          printf "  *(t_taql_" repstub[type] " *)mem = v;\n" > inls;
        }
      printf "}\n" > inls;
      printf "\n" > inls;
      printf "\n" > inls;
    }
}


function generate_unpack_functions(protos, inls, fns, type, rtype, name, formals)
{
  for (type in taqltypes)
    {
      rtype = "t_taql_" repstub[type];
      name = "taql_unpack_" type;
      formals = "(void * mem, size_t bit_offset)";
      start_inline_function(protos, inls, fns, rtype, name, formals);

      printf "{\n" > inls;
      if (bitsize[type] < 8)
        {
         mask = "((1 << " bitsize[type] ") - 1)";
         printf "  return (t_taql_" repstub[type] ")((*(unsigned char *)mem >> bit_offset) & " mask ");\n" > inls;
        }
      else if (exact[type] && (bitsize[type] == 8))
        {
          if (unsigned[type])
            printf " return (t_taql_" repstub[type] ")*(unsigned char *)mem;\n" > inls
          else
            printf " return (t_taql_" repstub[type] ")*(char *)mem;\n" > inls
        }
      else
        {
          printf "  return *(t_taql_" repstub[type] " *)mem;\n" > inls;
        }
      printf "}\n" > inls;
      printf "\n" > inls;
      printf "\n" > inls;
    }
}


function generate_unboxed_union (file, x)
{
  printf "union taql__unboxed\n" > file;
  printf "{\n" > file;
  for (x in union_types)
    printf "  t_taql_%s _%s;\n", x, x > file;
  printf "};\n" > file;
  printf "typedef union taql__unboxed t_taql_unboxed;\n" > file;
  printf "\n" > file;
  printf "\n" > file;
}


function generate_type_tag_enum (file, x)
{
  printf "enum taql_type_tag\n" > file;
  printf "{\n" > file;
  printf "  taql_t_nil = 0,\n" > file;
  for (x in taqltypes)
    printf "  taql_t_%s = %d,\n", x, taqltypes[x] > file;
  printf "};\n" > file;
  printf "\n" > file;
  printf "\n" > file;
}


function generate_boxed_struct (file, x)
{
  printf "struct taql__boxed\n" > file;
  printf "{\n" > file;
  printf "  enum taql_type_tag _type;\n" > file;
  printf "  t_taql_unboxed _value;\n" > file;
  printf "};\n" > file;
  printf "typedef struct taql__boxed t_taql_boxed;\n" > file
  printf "\n" > file;
  printf "\n" > file;
}


function generate_type_tag_nameof (protos, inls, fns, x)
{
  start_extern_function(protos, inls, fns,
                        "const char *",       
                        "taql__type_tag_name",
                        "(const char * file, size_t line, enum taql_type_tag t)");
  printf "{\n" > fns;
  printf "  switch (t)\n" > fns;
  printf "    {\n" > fns;
  printf "      default: taql__fatal (file, line, \"no such type?!?\"); return 0;\n" > fns;
  for (x in taqltypes)
    {
      printf "      case taql_t_%s: return \"%s\";\n", x, x > fns;
    }
  printf "    }\n" > fns;
  printf "}\n" > fns;
  printf "\n" > fns;
  printf "\n" > fns;
}


function generate_typelexer (protos, inls, fns, type)
{
  start_extern_function(protos, inls, fns,
                        "int",
                        "taql__lex_typename",
                        "(enum taql_type_tag * type, const char * s)");

  printf "{\n" > fns;
  printf "  " > fns;
  for (type in taqltypes)
    {
      printf "if (!strcmp (s, \"%s\")) return (*type = taql_t_%s);\n", type, type > fns;
      printf "  else " > fns;
    }
  printf "return taql_t_nil;\n" > fns;
  printf "}\n" > fns;
  printf "\n" > fns;
  printf "\n" > fns;
}


function start_extern_function(protos, inls, fns, rtype, name, formals)
{
  printf "extern %s %s %s;\n", rtype, name, formals > protos;
  printf "%s\n%s %s\n", rtype, name, formals > fns;
}

function start_inline_function(protos, inls, fns, rtype, name, formals)
{
  printf "static %s %s %s;\n", rtype, name, formals > protos;
  printf "static inline %s\n%s %s\n", rtype, name, formals > inls;
}


function generate_bitsof_fn (protos, inls, fns, type, rtype, name, formals)
{
  rtype = "int";
  name = "taql__bitsof";
  formals = "(const char * file, size_t line, enum taql_type_tag t)";


  start_inline_function(protos, inls, fns, rtype, name, formals);

  printf "{\n" > inls
  printf "  switch (t)\n" > inls
  printf "    {\n" > inls;
  printf "      default: taql__fatal (file, line, \"type_error\"); return 0;\n" > inls;
  for (type in taqltypes)
    {
      printf "      case taql_t_%s: return %d;\n", type, bitsize[type] > inls;
    }
  printf "    }\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}


function generate_eq_fn (protos, inls, fns, type, rtype, name, formals)
{
  rtype = "int";
  name = "taql__eq";
  formals = "(const char * file, size_t line, t_taql_boxed a, t_taql_boxed b)";

  start_inline_function(protos, inls, fns, rtype, name, formals);

  printf "{\n" > inls
  printf "  if (taql_typeof (a) != taql_typeof (b)) return 0;\n" > inls;
  printf "  switch (taql_typeof(a))\n" > inls
  printf "    {\n" > inls;
  printf "      default: taql__fatal (file, line, \"type_error\"); return 0;\n" > inls;
  for (type in taqltypes)
    {
      if (numeric[type])
        {
          printf "      case taql_t_%s: return taql__unbox_%s (file, line, a) == taql__unbox_%s (file, line, b);\n", type, type, type > inls;
        }
      else
        {
          printf "      case taql_t_%s:\n", type > inls;
          printf "        {\n" > inls;
          printf "          t_taql_%s av = taql__unbox_%s (file, line, a);\n", type, type > inls;
          printf "          t_taql_%s bv = taql__unbox_%s (file, line, b);\n", type, type > inls;
          printf "          return !memcmp ((void *)&av, (void *)&bv, sizeof (av));\n" > inls;
          printf "        }\n" > inls;
        }
    }
  printf "    }\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}


function generate_box_functions (protos, inls, fns, x, rtype, name, formals)
{
  rtype = "t_taql_boxed";
  for (x in taqltypes)
    {
      name = "taql_box_" x;
      formals = "(t_taql_" repstub[x] " v)";

      start_inline_function(protos, inls, fns, rtype, name, formals);

      printf "{\n" > inls;
      printf "  t_taql_boxed b;\n" > inls;
      printf "  b._type = taql_t_%s;\n", x > inls;
      if (exact [x])
        printf "  b._value._%s = ((t_taql_%s)-1 >> (8 * sizeof (t_taql_%s) - %d)) & v;\n", repstub[x], repstub[x], repstub[x], bitsize[x] > inls;
      else
        printf "  b._value._%s = v;\n", repstub[x] > inls;
      printf "  return b;\n" > inls;
      printf "}\n" > inls;
      printf "\n" > inls;
      printf "\n" > inls;
    }
}


function generate_unbox_functions (protos, inls, fns, x, rtype, name, formals)
{
  for (x in taqltypes)
    {
      rtype = "t_taql_" repstub[x];
      name = "taql__unbox_" x;
      formals = "(const char * file, size_t line, t_taql_boxed b)";

      start_inline_function(protos, inls, fns, rtype, name, formals);

      printf "{\n" > inls;
      printf "  if (b._type != taql_t_%s)\n", x > inls;
      printf "    taql__fatal (file, line, \"type error\");\n" > inls;
      printf "  return b._value._%s;\n", repstub[x] > inls;
      printf "}\n" > inls;
      printf "\n" > inls;
      printf "\n" > inls;
    }
}


function generate_typeof_fn (protos, inls, fns)
{
  start_inline_function(protos, inls, fns,
                        "enum taql_type_tag",
                        "taql_typeof",
                        "(t_taql_boxed v)");

  printf "{\n" > inls;
  printf "  return v._type;\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}


function generate_pack_boxed_function (protos, inls, fns, type)
{
  start_inline_function(protos, inls, fns,
                        "void",
                        "taql__pack_boxed",
                        "(const char * file, size_t line, void * mem, size_t bit_offset, enum taql_type_tag type, t_taql_boxed v)");



  printf "{\n" > inls;
  printf "  switch (type)\n" > inls;
  printf "    {\n" > inls;
  printf "      default: taql__fatal (file, line, \"type error (packing)\"); return;\n" > inls;
  for (type in taqltypes)
    {
      printf "      case taql_t_%s:\n", type > inls
      printf "        taql_pack_%s (mem, bit_offset, taql__unbox_%s (file, line, v));\n", type, type > inls
      printf "        return;\n" > inls;
    }  
  printf "    }\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}


function generate_unpack_boxed_function (protos, inls, fns, type)
{
  start_inline_function(protos, inls, fns,
                        "t_taql_boxed",
                        "taql__unpack_boxed",
                        "(const char * file, size_t line, void * mem, size_t bit_offset, enum taql_type_tag type)");


  printf "{\n" > inls;
  printf "  switch (type)\n" > inls;
  printf "    {\n" > inls;
  printf "      default: taql__fatal (file, line, \"type error (packing)\"); return taql_box_uint32 (0);" > inls;
  for (type in taqltypes)
    {
      printf "      case taql_t_%s:\n", type > inls
      printf "        return taql_box_%s (taql_unpack_%s (mem, bit_offset));\n", type, type > inls;
    }  
  printf "    }\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}



function generate_cast_to_fixed_type_ops (protos, inls, fns, x, rtype, name, formals)
{
  rtype = "t_taql_boxed";
  formals = "(const char * file, size_t line, t_taql_boxed b)";

  for (x in taqltypes)
    {
      name = "taql__cast_to_" x;

      start_inline_function(protos, inls, fns, rtype, name, formals);

      printf "{\n" > inls;
      printf "  switch (b._type)\n" > inls;
      printf "    {\n" > inls;
      printf "      default: type_error: taql__fatal (file, line, \"type_error\"); return b;\n" > inls;
      for (y in taqltypes)
        {
          printf "      case taql_t_%s:\n", y > inls;
          generate_cast_case(inls, "b", y, x);
        }
      printf "    };\n" > inls;
      printf "}\n" > inls;
      printf "\n" > inls;
      printf "\n" > inls;
    }
}


function generate_cast_case (inls, var, from, to)
{
  if (from == to)
    printf "        return b;\n" > inls;
  else if (!numeric[to] || !numeric[from])
    printf "        goto type_error;\n" > inls;
  else
    {
      printf "        {\n" > inls;
      printf "          t_taql_boxed answer;\n" > inls;
      printf "          answer._type = taql_t_%s;\n", to > inls;
      if (!exact[to])
        printf "          answer._value._%s = (t_taql_%s)%s._value._%s;\n", repstub[to], repstub[to], var, repstub[from] > inls;
      else
        printf "          answer._value._%s = ((t_taql_%s)-1ULL >> (8 * sizeof (t_taql_%s) - %s)) & (t_taql_%s)%s._value._%s;\n", repstub[to], repstub[to], repstub[to], bitsize[to], repstub[to], var, repstub[from] > inls;
      printf "          return answer;\n" > inls;
      printf "        }\n" > inls;
    }  
}


function generate_cast_to_dynamic_type_op (protos, inls, fns, x, rtype, name, formals)
{
  rtype = "t_taql_boxed";
  name = "taql__cast_to";
  formals = "(const char * file, size_t line, t_taql_boxed b, enum taql_type_tag type)";

  start_extern_function(protos, inls, fns, rtype, name, formals);

  printf "{\n" > fns;
  printf "  switch (type)\n" > fns;
  printf "    {\n" > fns;
  printf "      default: taql__fatal (file, line, \"type error\"); return b;\n" > fns;

  for (x in taqltypes)
    {
      printf "      case taql_t_%s: return taql__cast_to_%s (file, line, b);\n", x, x > fns;
    }

  printf "    }\n" > fns;
  printf "}\n" > fns;
  printf "\n" > fns;
  printf "\n" > fns;
}


function generate_asa_functions (protos, inls, fns, x, rtype, name, formals)
{
  formals = "(const char * file, size_t line, t_taql_boxed b)";

  for (x in union_types)
    {
      rtype = "t_taql_" x;
      name = "taql__asa_" x;
      
      start_inline_function(protos, inls, fns, rtype, name, formals);

      printf "{\n" > inls;
      printf "  b = taql__cast_to_%s (file, line, b);\n", x > inls;
      printf "  return b._value._%s;\n", x > inls;
      printf "}\n" > inls;
      printf "\n" > inls;
      printf "\n" > inls;
    }
}


function generate_binop_cast_fn (protos, inls, fns, x)
{
  start_inline_function(protos, inls, fns,
                        "void",
                        "taql__binop_cast",
                        "(const char * file, size_t line, t_taql_boxed * a, t_taql_boxed * b)");

  printf "{\n" > inls;
  printf "  t_taql_boxed * changing;\n" > inls;
  printf "  t_taql_boxed * to;\n" > inls;
  printf "  if (a->_type == b->_type)\n" > inls;
  printf "    return;\n" > inls;
  printf "  if (a->_type < b->_type)\n" > inls;
  printf "    { changing = a; to = b; }\n" > inls;
  printf "  else\n" > inls;
  printf "    { changing = b; to = a; }\n" > inls;
  printf "  switch (to->_type)\n" > inls;
  printf "    {\n" > inls;
  printf "      default: taql__fatal (file, line, \"type_error\"); return;\n" > inls;
  for (x in taqltypes)
    {
      printf "      case taql_t_%s: *changing = taql__cast_to_%s (file, line, *changing); return;\n", x, x > inls;
    }
  printf "    }\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}

function generate_math_binops (protos, inls, fns, operator)
{
  for (operator in mathbinops)
    generate_math_binop(protos, inls, fns, operator);
}

function generate_math_binop(protos, inls, fns, operator, type, rtype, name, formals)
{
  rtype = "t_taql_boxed";
  name = "taql__" operator;
  formals = "(char * file, size_t line, t_taql_boxed a, t_taql_boxed b)";

  start_inline_function(protos, inls, fns, rtype, name, formals);
  
  printf "{\n" > inls;
  printf "  t_taql_boxed answer;\n" > inls;
  printf "  taql__binop_cast (file, line, &a, &b);\n" > inls;
  printf "  answer._type = a._type;\n" > inls;
  printf "  switch (a._type)\n" > inls;
  printf "  {\n" > inls;
  printf "    default: taql__fatal (file, line, \"type_error\"); return a;\n" > inls;
  for (type in taqltypes)
    {
      if (numeric[type] && (!exactbinops[operator] || exact[type]))
        {
          generate_math_binop_case(protos, inls, fns, operator, type);
        }
    }
  printf "  }\n" > inls;
  printf "}\n" > inls;
  printf "\n" > inls;
  printf "\n" > inls;
}

function generate_math_binop_case(protos, inls, fns, operator, type)
{
  printf "    case taql_t_%s:\n", type > inls;
  if (inexact[type])
    printf "      answer._value._%s = a._value._%s %s b._value._%s;\n", repstub[type], repstub[type], mathbinops[operator], repstub[type] > inls;
  else
    printf "      answer._value._%s = ((t_taql_%s)-1ULL >> (8 * sizeof (t_taql_%s) - %s)) & (a._value._%s %s b._value._%s);\n", repstub[type], repstub[type], repstub[type], bitsize[type], repstub[type], mathbinops[operator], repstub[type] > inls;
  printf "      return answer;\n" > inls;
}

function generate_math_monops (protos, inls, fns, operator)
{
  for (operator in mathmonops)
    generate_math_monop(protos, inls, fns, operator);
}


function generate_math_monop(protos, inls, fns, operator, type, rtype, name, formals)
{
  rtype = "t_taql_boxed";
  name =  "taql__" operator;
  formals = "(char * file, size_t line, t_taql_boxed a)";

  start_inline_function(protos, inls, fns, rtype, name, formals);

  printf "{\n" > inls
  printf "  t_taql_boxed answer;\n" > inls
  printf "  answer._type = a._type;\n" > inls
  printf "  switch (a._type)\n" > inls
  printf "  {\n" > inls
  printf "    default: taql__fatal (file, line, \"type_error\"); return a;\n" > inls
  for (type in taqltypes)
    {
      if (numeric[type] && (!exactmonops[operator] || exact[type]))
        {
          generate_math_monop_case(protos, inls, fns, operator, type);
        }
    }
  printf "  }\n" > inls
  printf "}\n" > inls
  printf "\n" > inls
  printf "\n" > inls
}


function generate_math_monop_case (protos, inls, fns, operator, type)
{
  printf "    case taql_t_%s:\n", type > inls
  if (inexact[type])
    printf "      answer._value._%s = taql__%s_op (a._value._%s);\n", repstub[type], operator, repstub[type] > inls
  else
    printf "      answer._value._%s = ((t_taql_%s)-1ULL >> (8 * sizeof (t_taql_%s) - %s)) & taql__%s_op (a._value._%s);\n", repstub[type], repstub[type], repstub[type], bitsize[type], operator, repstub[type] > inls
  printf "      return answer;\n" > inls
}


function generate_fmt (protos, inls, fns, type)
{
  for (type in taqltypes)
    {
      if (!numeric[type])
        printf "extern void taql__fmt_%s (const char * file, size_t line, char * buf, size_t bufsize, t_taql_%s v);\n", type, repstub[type] > protos;
    }

  start_extern_function(protos, inls, fns,
                        "void",
                        "taql__fmt",
                        "(const char * file, size_t line, char * buf, size_t bufsize, t_taql_boxed b)");

  printf "{\n" > fns;
  printf "  switch (taql_typeof (b))\n" > fns;
  printf "    {\n" > fns;
  printf "      default: taql__fatal (file, line, \"type_error\"); return;\n" > fns;
  for (type in taqltypes)
    {
      if (numeric[type])
        generate_numeric_fmt_case(protos, inls, fns, type);
      else
        printf "      case taql_t_%s: taql__fmt_%s (file, line, buf, bufsize, b._value._%s); return;\n", type, type, repstub[type] > fns;
    }
  printf "    }\n" > fns;
  printf "}\n" > fns;
  printf "\n" > fns;
  printf "\n" > fns;
}


function generate_numeric_fmt_case (protos, inls, fns, type, modifier, typechar, castmodifier, casttype)
{
  printf "      case taql_t_%s:\n", type > fns;
  if (exact[type])
    {
      if (bitsize[type] <= 32)
        {
          modifier = "";
          castmodifier = "";
        }
      else
        {
          modifier = "ll";
          castmodifier = "long long";
        }
      typechar = (signed[type] ? "d" : "u");
      casttype = "int";
      printf "        snprintf (buf, bufsize, \"%%%s%s\", (%s %s)taql__unbox_%s (file, line, b));\n", modifier, typechar, castmodifier, casttype, type > fns;
      printf "        return;\n" > fns;
    }
  else
    {
      printf "        snprintf (buf, bufsize, \"%%f\", taql__unbox_%s (file, line, b));\n", type > fns;
      printf "        return;\n" > fns;
    }
}


function generate_arch_tag (file, str)
{
  printf "\n" > file;
  printf "\n" > file;
  printf "/* %s\n */\n\n\n", str > file;
}

# arch-tag: Thomas Lord Thu Oct 26 12:48:55 2006 (libtable/generate.awk)

