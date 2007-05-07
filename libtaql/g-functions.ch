const char *
taql__type_tag_name (const char * file, size_t line, enum taql_type_tag t)
{
  switch (t)
    {
      default: taql__fatal (file, line, "no such type?!?"); return 0;
      case taql_t_uint64: return "uint64";
      case taql_t_uint8: return "uint8";
      case taql_t_int4: return "int4";
      case taql_t_dfloat: return "dfloat";
      case taql_t_sfloat: return "sfloat";
      case taql_t_int32: return "int32";
      case taql_t_int8: return "int8";
      case taql_t_uint32: return "uint32";
      case taql_t_uint4: return "uint4";
      case taql_t_sym: return "sym";
      case taql_t_int64: return "int64";
    }
}


int
taql__lex_typename (enum taql_type_tag * type, const char * s)
{
  if (!strcmp (s, "uint64")) return (*type = taql_t_uint64);
  else if (!strcmp (s, "uint8")) return (*type = taql_t_uint8);
  else if (!strcmp (s, "int4")) return (*type = taql_t_int4);
  else if (!strcmp (s, "dfloat")) return (*type = taql_t_dfloat);
  else if (!strcmp (s, "sfloat")) return (*type = taql_t_sfloat);
  else if (!strcmp (s, "int32")) return (*type = taql_t_int32);
  else if (!strcmp (s, "int8")) return (*type = taql_t_int8);
  else if (!strcmp (s, "uint32")) return (*type = taql_t_uint32);
  else if (!strcmp (s, "uint4")) return (*type = taql_t_uint4);
  else if (!strcmp (s, "sym")) return (*type = taql_t_sym);
  else if (!strcmp (s, "int64")) return (*type = taql_t_int64);
  else return taql_t_nil;
}


t_taql_boxed
taql__cast_to (const char * file, size_t line, t_taql_boxed b, enum taql_type_tag type)
{
  switch (type)
    {
      default: taql__fatal (file, line, "type error"); return b;
      case taql_t_uint64: return taql__cast_to_uint64 (file, line, b);
      case taql_t_uint8: return taql__cast_to_uint8 (file, line, b);
      case taql_t_int4: return taql__cast_to_int4 (file, line, b);
      case taql_t_dfloat: return taql__cast_to_dfloat (file, line, b);
      case taql_t_sfloat: return taql__cast_to_sfloat (file, line, b);
      case taql_t_int32: return taql__cast_to_int32 (file, line, b);
      case taql_t_int8: return taql__cast_to_int8 (file, line, b);
      case taql_t_uint32: return taql__cast_to_uint32 (file, line, b);
      case taql_t_uint4: return taql__cast_to_uint4 (file, line, b);
      case taql_t_sym: return taql__cast_to_sym (file, line, b);
      case taql_t_int64: return taql__cast_to_int64 (file, line, b);
    }
}


void
taql__fmt (const char * file, size_t line, char * buf, size_t bufsize, t_taql_boxed b)
{
  switch (taql_typeof (b))
    {
      default: taql__fatal (file, line, "type_error"); return;
      case taql_t_uint64:
        snprintf (buf, bufsize, "%llu", (long long int)taql__unbox_uint64 (file, line, b));
        return;
      case taql_t_uint8:
        snprintf (buf, bufsize, "%u", ( int)taql__unbox_uint8 (file, line, b));
        return;
      case taql_t_int4:
        snprintf (buf, bufsize, "%d", ( int)taql__unbox_int4 (file, line, b));
        return;
      case taql_t_dfloat:
        snprintf (buf, bufsize, "%f", taql__unbox_dfloat (file, line, b));
        return;
      case taql_t_sfloat:
        snprintf (buf, bufsize, "%f", taql__unbox_sfloat (file, line, b));
        return;
      case taql_t_int32:
        snprintf (buf, bufsize, "%d", ( int)taql__unbox_int32 (file, line, b));
        return;
      case taql_t_int8:
        snprintf (buf, bufsize, "%d", ( int)taql__unbox_int8 (file, line, b));
        return;
      case taql_t_uint32:
        snprintf (buf, bufsize, "%u", ( int)taql__unbox_uint32 (file, line, b));
        return;
      case taql_t_uint4:
        snprintf (buf, bufsize, "%u", ( int)taql__unbox_uint4 (file, line, b));
        return;
      case taql_t_sym: taql__fmt_sym (file, line, buf, bufsize, b._value._sym); return;
      case taql_t_int64:
        snprintf (buf, bufsize, "%lld", (long long int)taql__unbox_int64 (file, line, b));
        return;
    }
}




/* arch-tag: Thomas Lord Fri Oct 27 17:03:05 2006 (libtaql/g-functions.c)
 */


