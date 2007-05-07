static inline void
taql_pack_uint64 (void * mem, size_t bit_offset, t_taql_uint64 v)
{
  *(t_taql_uint64 *)mem = v;
}


static inline void
taql_pack_uint8 (void * mem, size_t bit_offset, t_taql_uint32 v)
{
 *(unsigned char *)mem = (unsigned char)v;
}


static inline void
taql_pack_int4 (void * mem, size_t bit_offset, t_taql_int32 v)
{
  *(unsigned char *)mem &= ~(((1 << 4) - 1) << bit_offset);
  *(unsigned char *)mem |= ((v & ((1 << 4) - 1)) << bit_offset);
}


static inline void
taql_pack_dfloat (void * mem, size_t bit_offset, t_taql_dfloat v)
{
  *(t_taql_dfloat *)mem = v;
}


static inline void
taql_pack_sfloat (void * mem, size_t bit_offset, t_taql_sfloat v)
{
  *(t_taql_sfloat *)mem = v;
}


static inline void
taql_pack_int32 (void * mem, size_t bit_offset, t_taql_int32 v)
{
  *(t_taql_int32 *)mem = v;
}


static inline void
taql_pack_int8 (void * mem, size_t bit_offset, t_taql_int32 v)
{
 *(char *)mem = (char)v;
}


static inline void
taql_pack_uint32 (void * mem, size_t bit_offset, t_taql_uint32 v)
{
  *(t_taql_uint32 *)mem = v;
}


static inline void
taql_pack_uint4 (void * mem, size_t bit_offset, t_taql_uint32 v)
{
  *(unsigned char *)mem &= ~(((1 << 4) - 1) << bit_offset);
  *(unsigned char *)mem |= ((v & ((1 << 4) - 1)) << bit_offset);
}


static inline void
taql_pack_sym (void * mem, size_t bit_offset, t_taql_sym v)
{
  *(t_taql_sym *)mem = v;
}


static inline void
taql_pack_int64 (void * mem, size_t bit_offset, t_taql_int64 v)
{
  *(t_taql_int64 *)mem = v;
}


static inline t_taql_uint64
taql_unpack_uint64 (void * mem, size_t bit_offset)
{
  return *(t_taql_uint64 *)mem;
}


static inline t_taql_uint32
taql_unpack_uint8 (void * mem, size_t bit_offset)
{
 return (t_taql_uint32)*(unsigned char *)mem;
}


static inline t_taql_int32
taql_unpack_int4 (void * mem, size_t bit_offset)
{
  return (t_taql_int32)((*(unsigned char *)mem >> bit_offset) & ((1 << 4) - 1));
}


static inline t_taql_dfloat
taql_unpack_dfloat (void * mem, size_t bit_offset)
{
  return *(t_taql_dfloat *)mem;
}


static inline t_taql_sfloat
taql_unpack_sfloat (void * mem, size_t bit_offset)
{
  return *(t_taql_sfloat *)mem;
}


static inline t_taql_int32
taql_unpack_int32 (void * mem, size_t bit_offset)
{
  return *(t_taql_int32 *)mem;
}


static inline t_taql_int32
taql_unpack_int8 (void * mem, size_t bit_offset)
{
 return (t_taql_int32)*(char *)mem;
}


static inline t_taql_uint32
taql_unpack_uint32 (void * mem, size_t bit_offset)
{
  return *(t_taql_uint32 *)mem;
}


static inline t_taql_uint32
taql_unpack_uint4 (void * mem, size_t bit_offset)
{
  return (t_taql_uint32)((*(unsigned char *)mem >> bit_offset) & ((1 << 4) - 1));
}


static inline t_taql_sym
taql_unpack_sym (void * mem, size_t bit_offset)
{
  return *(t_taql_sym *)mem;
}


static inline t_taql_int64
taql_unpack_int64 (void * mem, size_t bit_offset)
{
  return *(t_taql_int64 *)mem;
}


static inline int
taql__bitsof (const char * file, size_t line, enum taql_type_tag t)
{
  switch (t)
    {
      default: taql__fatal (file, line, "type_error"); return 0;
      case taql_t_uint64: return 64;
      case taql_t_uint8: return 8;
      case taql_t_int4: return 4;
      case taql_t_dfloat: return 64;
      case taql_t_sfloat: return 32;
      case taql_t_int32: return 32;
      case taql_t_int8: return 8;
      case taql_t_uint32: return 32;
      case taql_t_uint4: return 4;
      case taql_t_sym: return 64;
      case taql_t_int64: return 64;
    }
}


static inline int
taql__eq (const char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  if (taql_typeof (a) != taql_typeof (b)) return 0;
  switch (taql_typeof(a))
    {
      default: taql__fatal (file, line, "type_error"); return 0;
      case taql_t_uint64: return taql__unbox_uint64 (file, line, a) == taql__unbox_uint64 (file, line, b);
      case taql_t_uint8: return taql__unbox_uint8 (file, line, a) == taql__unbox_uint8 (file, line, b);
      case taql_t_int4: return taql__unbox_int4 (file, line, a) == taql__unbox_int4 (file, line, b);
      case taql_t_dfloat: return taql__unbox_dfloat (file, line, a) == taql__unbox_dfloat (file, line, b);
      case taql_t_sfloat: return taql__unbox_sfloat (file, line, a) == taql__unbox_sfloat (file, line, b);
      case taql_t_int32: return taql__unbox_int32 (file, line, a) == taql__unbox_int32 (file, line, b);
      case taql_t_int8: return taql__unbox_int8 (file, line, a) == taql__unbox_int8 (file, line, b);
      case taql_t_uint32: return taql__unbox_uint32 (file, line, a) == taql__unbox_uint32 (file, line, b);
      case taql_t_uint4: return taql__unbox_uint4 (file, line, a) == taql__unbox_uint4 (file, line, b);
      case taql_t_sym:
        {
          t_taql_sym av = taql__unbox_sym (file, line, a);
          t_taql_sym bv = taql__unbox_sym (file, line, b);
          return !memcmp ((void *)&av, (void *)&bv, sizeof (av));
        }
      case taql_t_int64: return taql__unbox_int64 (file, line, a) == taql__unbox_int64 (file, line, b);
    }
}


static inline t_taql_boxed
taql_box_uint64 (t_taql_uint64 v)
{
  t_taql_boxed b;
  b._type = taql_t_uint64;
  b._value._uint64 = ((t_taql_uint64)-1 >> (8 * sizeof (t_taql_uint64) - 64)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_uint8 (t_taql_uint32 v)
{
  t_taql_boxed b;
  b._type = taql_t_uint8;
  b._value._uint32 = ((t_taql_uint32)-1 >> (8 * sizeof (t_taql_uint32) - 8)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_int4 (t_taql_int32 v)
{
  t_taql_boxed b;
  b._type = taql_t_int4;
  b._value._int32 = ((t_taql_int32)-1 >> (8 * sizeof (t_taql_int32) - 4)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_dfloat (t_taql_dfloat v)
{
  t_taql_boxed b;
  b._type = taql_t_dfloat;
  b._value._dfloat = v;
  return b;
}


static inline t_taql_boxed
taql_box_sfloat (t_taql_sfloat v)
{
  t_taql_boxed b;
  b._type = taql_t_sfloat;
  b._value._sfloat = v;
  return b;
}


static inline t_taql_boxed
taql_box_int32 (t_taql_int32 v)
{
  t_taql_boxed b;
  b._type = taql_t_int32;
  b._value._int32 = ((t_taql_int32)-1 >> (8 * sizeof (t_taql_int32) - 32)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_int8 (t_taql_int32 v)
{
  t_taql_boxed b;
  b._type = taql_t_int8;
  b._value._int32 = ((t_taql_int32)-1 >> (8 * sizeof (t_taql_int32) - 8)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_uint32 (t_taql_uint32 v)
{
  t_taql_boxed b;
  b._type = taql_t_uint32;
  b._value._uint32 = ((t_taql_uint32)-1 >> (8 * sizeof (t_taql_uint32) - 32)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_uint4 (t_taql_uint32 v)
{
  t_taql_boxed b;
  b._type = taql_t_uint4;
  b._value._uint32 = ((t_taql_uint32)-1 >> (8 * sizeof (t_taql_uint32) - 4)) & v;
  return b;
}


static inline t_taql_boxed
taql_box_sym (t_taql_sym v)
{
  t_taql_boxed b;
  b._type = taql_t_sym;
  b._value._sym = v;
  return b;
}


static inline t_taql_boxed
taql_box_int64 (t_taql_int64 v)
{
  t_taql_boxed b;
  b._type = taql_t_int64;
  b._value._int64 = ((t_taql_int64)-1 >> (8 * sizeof (t_taql_int64) - 64)) & v;
  return b;
}


static inline t_taql_uint64
taql__unbox_uint64 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_uint64)
    taql__fatal (file, line, "type error");
  return b._value._uint64;
}


static inline t_taql_uint32
taql__unbox_uint8 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_uint8)
    taql__fatal (file, line, "type error");
  return b._value._uint32;
}


static inline t_taql_int32
taql__unbox_int4 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_int4)
    taql__fatal (file, line, "type error");
  return b._value._int32;
}


static inline t_taql_dfloat
taql__unbox_dfloat (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_dfloat)
    taql__fatal (file, line, "type error");
  return b._value._dfloat;
}


static inline t_taql_sfloat
taql__unbox_sfloat (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_sfloat)
    taql__fatal (file, line, "type error");
  return b._value._sfloat;
}


static inline t_taql_int32
taql__unbox_int32 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_int32)
    taql__fatal (file, line, "type error");
  return b._value._int32;
}


static inline t_taql_int32
taql__unbox_int8 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_int8)
    taql__fatal (file, line, "type error");
  return b._value._int32;
}


static inline t_taql_uint32
taql__unbox_uint32 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_uint32)
    taql__fatal (file, line, "type error");
  return b._value._uint32;
}


static inline t_taql_uint32
taql__unbox_uint4 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_uint4)
    taql__fatal (file, line, "type error");
  return b._value._uint32;
}


static inline t_taql_sym
taql__unbox_sym (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_sym)
    taql__fatal (file, line, "type error");
  return b._value._sym;
}


static inline t_taql_int64
taql__unbox_int64 (const char * file, size_t line, t_taql_boxed b)
{
  if (b._type != taql_t_int64)
    taql__fatal (file, line, "type error");
  return b._value._int64;
}


static inline enum taql_type_tag
taql_typeof (t_taql_boxed v)
{
  return v._type;
}


static inline void
taql__pack_boxed (const char * file, size_t line, void * mem, size_t bit_offset, enum taql_type_tag type, t_taql_boxed v)
{
  switch (type)
    {
      default: taql__fatal (file, line, "type error (packing)"); return;
      case taql_t_uint64:
        taql_pack_uint64 (mem, bit_offset, taql__unbox_uint64 (file, line, v));
        return;
      case taql_t_uint8:
        taql_pack_uint8 (mem, bit_offset, taql__unbox_uint8 (file, line, v));
        return;
      case taql_t_int4:
        taql_pack_int4 (mem, bit_offset, taql__unbox_int4 (file, line, v));
        return;
      case taql_t_dfloat:
        taql_pack_dfloat (mem, bit_offset, taql__unbox_dfloat (file, line, v));
        return;
      case taql_t_sfloat:
        taql_pack_sfloat (mem, bit_offset, taql__unbox_sfloat (file, line, v));
        return;
      case taql_t_int32:
        taql_pack_int32 (mem, bit_offset, taql__unbox_int32 (file, line, v));
        return;
      case taql_t_int8:
        taql_pack_int8 (mem, bit_offset, taql__unbox_int8 (file, line, v));
        return;
      case taql_t_uint32:
        taql_pack_uint32 (mem, bit_offset, taql__unbox_uint32 (file, line, v));
        return;
      case taql_t_uint4:
        taql_pack_uint4 (mem, bit_offset, taql__unbox_uint4 (file, line, v));
        return;
      case taql_t_sym:
        taql_pack_sym (mem, bit_offset, taql__unbox_sym (file, line, v));
        return;
      case taql_t_int64:
        taql_pack_int64 (mem, bit_offset, taql__unbox_int64 (file, line, v));
        return;
    }
}


static inline t_taql_boxed
taql__unpack_boxed (const char * file, size_t line, void * mem, size_t bit_offset, enum taql_type_tag type)
{
  switch (type)
    {
      default: taql__fatal (file, line, "type error (packing)"); return taql_box_uint32 (0);      case taql_t_uint64:
        return taql_box_uint64 (taql_unpack_uint64 (mem, bit_offset));
      case taql_t_uint8:
        return taql_box_uint8 (taql_unpack_uint8 (mem, bit_offset));
      case taql_t_int4:
        return taql_box_int4 (taql_unpack_int4 (mem, bit_offset));
      case taql_t_dfloat:
        return taql_box_dfloat (taql_unpack_dfloat (mem, bit_offset));
      case taql_t_sfloat:
        return taql_box_sfloat (taql_unpack_sfloat (mem, bit_offset));
      case taql_t_int32:
        return taql_box_int32 (taql_unpack_int32 (mem, bit_offset));
      case taql_t_int8:
        return taql_box_int8 (taql_unpack_int8 (mem, bit_offset));
      case taql_t_uint32:
        return taql_box_uint32 (taql_unpack_uint32 (mem, bit_offset));
      case taql_t_uint4:
        return taql_box_uint4 (taql_unpack_uint4 (mem, bit_offset));
      case taql_t_sym:
        return taql_box_sym (taql_unpack_sym (mem, bit_offset));
      case taql_t_int64:
        return taql_box_int64 (taql_unpack_int64 (mem, bit_offset));
    }
}


static inline t_taql_boxed
taql__cast_to_uint64 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        return b;
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint64;
          answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (t_taql_uint64)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_uint8 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        return b;
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint8;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (t_taql_uint32)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_int4 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        return b;
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int4;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (t_taql_int32)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_dfloat (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        return b;
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_dfloat;
          answer._value._dfloat = (t_taql_dfloat)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_sfloat (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        return b;
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_sfloat;
          answer._value._sfloat = (t_taql_sfloat)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_int32 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        return b;
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int32;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (t_taql_int32)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_int8 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        return b;
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int8;
          answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (t_taql_int32)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_uint32 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        return b;
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint32;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (t_taql_uint32)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_uint4 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        return b;
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_uint4;
          answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (t_taql_uint32)b._value._int64;
          return answer;
        }
    };
}


static inline t_taql_boxed
taql__cast_to_sym (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        goto type_error;
      case taql_t_uint8:
        goto type_error;
      case taql_t_int4:
        goto type_error;
      case taql_t_dfloat:
        goto type_error;
      case taql_t_sfloat:
        goto type_error;
      case taql_t_int32:
        goto type_error;
      case taql_t_int8:
        goto type_error;
      case taql_t_uint32:
        goto type_error;
      case taql_t_uint4:
        goto type_error;
      case taql_t_sym:
        return b;
      case taql_t_int64:
        goto type_error;
    };
}


static inline t_taql_boxed
taql__cast_to_int64 (const char * file, size_t line, t_taql_boxed b)
{
  switch (b._type)
    {
      default: type_error: taql__fatal (file, line, "type_error"); return b;
      case taql_t_uint64:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._uint64;
          return answer;
        }
      case taql_t_uint8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._uint32;
          return answer;
        }
      case taql_t_int4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._int32;
          return answer;
        }
      case taql_t_dfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._dfloat;
          return answer;
        }
      case taql_t_sfloat:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._sfloat;
          return answer;
        }
      case taql_t_int32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._int32;
          return answer;
        }
      case taql_t_int8:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._int32;
          return answer;
        }
      case taql_t_uint32:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._uint32;
          return answer;
        }
      case taql_t_uint4:
        {
          t_taql_boxed answer;
          answer._type = taql_t_int64;
          answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (t_taql_int64)b._value._uint32;
          return answer;
        }
      case taql_t_sym:
        goto type_error;
      case taql_t_int64:
        return b;
    };
}


static inline t_taql_uint64
taql__asa_uint64 (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_uint64 (file, line, b);
  return b._value._uint64;
}


static inline t_taql_sfloat
taql__asa_sfloat (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_sfloat (file, line, b);
  return b._value._sfloat;
}


static inline t_taql_dfloat
taql__asa_dfloat (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_dfloat (file, line, b);
  return b._value._dfloat;
}


static inline t_taql_int32
taql__asa_int32 (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_int32 (file, line, b);
  return b._value._int32;
}


static inline t_taql_uint32
taql__asa_uint32 (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_uint32 (file, line, b);
  return b._value._uint32;
}


static inline t_taql_int64
taql__asa_int64 (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_int64 (file, line, b);
  return b._value._int64;
}


static inline t_taql_sym
taql__asa_sym (const char * file, size_t line, t_taql_boxed b)
{
  b = taql__cast_to_sym (file, line, b);
  return b._value._sym;
}


static inline void
taql__binop_cast (const char * file, size_t line, t_taql_boxed * a, t_taql_boxed * b)
{
  t_taql_boxed * changing;
  t_taql_boxed * to;
  if (a->_type == b->_type)
    return;
  if (a->_type < b->_type)
    { changing = a; to = b; }
  else
    { changing = b; to = a; }
  switch (to->_type)
    {
      default: taql__fatal (file, line, "type_error"); return;
      case taql_t_uint64: *changing = taql__cast_to_uint64 (file, line, *changing); return;
      case taql_t_uint8: *changing = taql__cast_to_uint8 (file, line, *changing); return;
      case taql_t_int4: *changing = taql__cast_to_int4 (file, line, *changing); return;
      case taql_t_dfloat: *changing = taql__cast_to_dfloat (file, line, *changing); return;
      case taql_t_sfloat: *changing = taql__cast_to_sfloat (file, line, *changing); return;
      case taql_t_int32: *changing = taql__cast_to_int32 (file, line, *changing); return;
      case taql_t_int8: *changing = taql__cast_to_int8 (file, line, *changing); return;
      case taql_t_uint32: *changing = taql__cast_to_uint32 (file, line, *changing); return;
      case taql_t_uint4: *changing = taql__cast_to_uint4 (file, line, *changing); return;
      case taql_t_sym: *changing = taql__cast_to_sym (file, line, *changing); return;
      case taql_t_int64: *changing = taql__cast_to_int64 (file, line, *changing); return;
    }
}


static inline t_taql_boxed
taql__bor (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 | b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 | b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 | b._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 | b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 | b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 | b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 | b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 | b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__bxor (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 ^ b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 ^ b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 ^ b._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 ^ b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 ^ b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 ^ b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 ^ b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 ^ b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__mod (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 % b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 % b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 % b._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 % b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 % b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 % b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 % b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 % b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__mul (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 * b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 * b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 * b._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = a._value._dfloat * b._value._dfloat;
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = a._value._sfloat * b._value._sfloat;
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 * b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 * b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 * b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 * b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 * b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__div (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 / b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 / b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 / b._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = a._value._dfloat / b._value._dfloat;
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = a._value._sfloat / b._value._sfloat;
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 / b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 / b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 / b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 / b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 / b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__add (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 + b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 + b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 + b._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = a._value._dfloat + b._value._dfloat;
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = a._value._sfloat + b._value._sfloat;
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 + b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 + b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 + b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 + b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 + b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__band (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 & b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 & b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 & b._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 & b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 & b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 & b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 & b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 & b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__sub (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 - b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 - b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 - b._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = a._value._dfloat - b._value._dfloat;
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = a._value._sfloat - b._value._sfloat;
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 - b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 - b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 - b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 - b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 - b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__lor (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 || b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 || b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 || b._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 || b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 || b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 || b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 || b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 || b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__land (char * file, size_t line, t_taql_boxed a, t_taql_boxed b)
{
  t_taql_boxed answer;
  taql__binop_cast (file, line, &a, &b);
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & (a._value._uint64 && b._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & (a._value._uint32 && b._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & (a._value._int32 && b._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & (a._value._int32 && b._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & (a._value._int32 && b._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & (a._value._uint32 && b._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & (a._value._uint32 && b._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & (a._value._int64 && b._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__neg (char * file, size_t line, t_taql_boxed a)
{
  t_taql_boxed answer;
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & taql__neg_op (a._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & taql__neg_op (a._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & taql__neg_op (a._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = taql__neg_op (a._value._dfloat);
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = taql__neg_op (a._value._sfloat);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & taql__neg_op (a._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & taql__neg_op (a._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & taql__neg_op (a._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & taql__neg_op (a._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & taql__neg_op (a._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__lnot (char * file, size_t line, t_taql_boxed a)
{
  t_taql_boxed answer;
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & taql__lnot_op (a._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & taql__lnot_op (a._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & taql__lnot_op (a._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = taql__lnot_op (a._value._dfloat);
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = taql__lnot_op (a._value._sfloat);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & taql__lnot_op (a._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & taql__lnot_op (a._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & taql__lnot_op (a._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & taql__lnot_op (a._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & taql__lnot_op (a._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__bnot (char * file, size_t line, t_taql_boxed a)
{
  t_taql_boxed answer;
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & taql__bnot_op (a._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & taql__bnot_op (a._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & taql__bnot_op (a._value._int32);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & taql__bnot_op (a._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & taql__bnot_op (a._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & taql__bnot_op (a._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & taql__bnot_op (a._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & taql__bnot_op (a._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__inc (char * file, size_t line, t_taql_boxed a)
{
  t_taql_boxed answer;
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & taql__inc_op (a._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & taql__inc_op (a._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & taql__inc_op (a._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = taql__inc_op (a._value._dfloat);
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = taql__inc_op (a._value._sfloat);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & taql__inc_op (a._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & taql__inc_op (a._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & taql__inc_op (a._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & taql__inc_op (a._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & taql__inc_op (a._value._int64);
      return answer;
  }
}


static inline t_taql_boxed
taql__dec (char * file, size_t line, t_taql_boxed a)
{
  t_taql_boxed answer;
  answer._type = a._type;
  switch (a._type)
  {
    default: taql__fatal (file, line, "type_error"); return a;
    case taql_t_uint64:
      answer._value._uint64 = ((t_taql_uint64)-1ULL >> (8 * sizeof (t_taql_uint64) - 64)) & taql__dec_op (a._value._uint64);
      return answer;
    case taql_t_uint8:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 8)) & taql__dec_op (a._value._uint32);
      return answer;
    case taql_t_int4:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 4)) & taql__dec_op (a._value._int32);
      return answer;
    case taql_t_dfloat:
      answer._value._dfloat = taql__dec_op (a._value._dfloat);
      return answer;
    case taql_t_sfloat:
      answer._value._sfloat = taql__dec_op (a._value._sfloat);
      return answer;
    case taql_t_int32:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 32)) & taql__dec_op (a._value._int32);
      return answer;
    case taql_t_int8:
      answer._value._int32 = ((t_taql_int32)-1ULL >> (8 * sizeof (t_taql_int32) - 8)) & taql__dec_op (a._value._int32);
      return answer;
    case taql_t_uint32:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 32)) & taql__dec_op (a._value._uint32);
      return answer;
    case taql_t_uint4:
      answer._value._uint32 = ((t_taql_uint32)-1ULL >> (8 * sizeof (t_taql_uint32) - 4)) & taql__dec_op (a._value._uint32);
      return answer;
    case taql_t_int64:
      answer._value._int64 = ((t_taql_int64)-1ULL >> (8 * sizeof (t_taql_int64) - 64)) & taql__dec_op (a._value._int64);
      return answer;
  }
}




/* arch-tag: Thomas Lord Fri Oct 27 17:03:05 2006 (libtaql/g-inlines.c)
 */


