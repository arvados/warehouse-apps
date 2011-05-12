union taql__unboxed
{
  t_taql_uint64 _uint64;
  t_taql_sfloat _sfloat;
  t_taql_dfloat _dfloat;
  t_taql_int32 _int32;
  t_taql_uint32 _uint32;
  t_taql_int64 _int64;
  t_taql_sym _sym;
};
typedef union taql__unboxed t_taql_unboxed;


enum taql_type_tag
{
  taql_t_nil = 0,
  taql_t_uint64 = 13,
  taql_t_uint8 = 7,
  taql_t_int4 = 4,
  taql_t_dfloat = 15,
  taql_t_sfloat = 14,
  taql_t_int32 = 10,
  taql_t_int8 = 6,
  taql_t_uint32 = 11,
  taql_t_uint4 = 5,
  taql_t_sym = 16,
  taql_t_int64 = 12,
};


struct taql__boxed
{
  enum taql_type_tag _type;
  t_taql_unboxed _value;
};
typedef struct taql__boxed t_taql_boxed;




/* arch-tag: Thomas Lord Fri Oct 27 17:00:44 2006 (libtaql/g-types.awk)
 */


