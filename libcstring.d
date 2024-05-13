module libcstring;

extern(C) nothrow @nogc {
  @trusted void *malloc(size_t size);
  @trusted void *realloc(return void *ptr, size_t size);
  @trusted void free(void *ptr);
  @trusted double log2(double x);
}
@trusted T typed_malloc(T)(const size_t size) @nogc nothrow {
  T ptr = cast(T)malloc(size);
  assert(ptr !is null);
  return ptr;
}
@trusted T typed_realloc(T)(T ptr, const size_t size) @nogc nothrow {
  T my_ptr = cast(T)realloc(cast(void *)ptr, size);
  assert(my_ptr !is null);
  return my_ptr;
}

@trusted void casted_free(T)(T ptr) @nogc nothrow {
  assert(cast(void *)ptr !is null);
  free(cast(void *)ptr);
}

// TODO:
// - more performance
// - (probably) add pure
// - add safer versions of string functions

extern(C) static size_t floor_base2(const size_t i) nothrow @safe @nogc {
  return 1LU << (cast(size_t)log2(cast(double)i) + 1);
}

public alias c_char = char;
public alias c_string = const(c_char *);
public alias mut_c_string = c_char *;
extern(C) struct OSString {
// strncpy could fail with buffer overrun
// strlen could fail with buffer overrun
// strncpy could fail with buffer overrun -- most problematic
import core.stdc.string : strlen, strncat, strncpy;
  private:
    enum MALLOC_THRESHOLD = mut_c_string.sizeof + size_t.sizeof + size_t.sizeof;
    bool large_string_allocation = void;
  union OSStr_ {
    char[MALLOC_THRESHOLD] small_string = void;
    struct {
      mut_c_string big_string = void;
      size_t len = void;
      size_t capacity = void;
    }
  }
  static assert(MALLOC_THRESHOLD == 24);
  OSStr_ OSStr = void;
  public @nogc nothrow:
    // small string optimization
    this(int N)(char[N] str) @trusted
    in (N <= 23) {
      large_string_allocation = false;
      strncpy(OSStr.small_string.ptr, str.ptr, N);
      OSStr.small_string[23] = N; // set length
    }

    this(c_string str) @trusted {
      OSStr.len = strlen(str);
      OSStr.capacity = floor_base2(OSStr.len);
      large_string_allocation = true;
      OSStr.big_string = typed_malloc!mut_c_string(OSStr.capacity);
      strncpy(OSStr.big_string, str, OSStr.len + 1);
    }
    pragma(inline) c_string c_str() pure const @trusted {
      // cast from array to pointer is what causes this to not be @safe
      return large_string_allocation ? OSStr.big_string : OSStr.small_string.ptr;
    }
    pragma(inline) size_t length() pure const @safe {
      return large_string_allocation ? OSStr.len : cast(size_t)OSStr.small_string[23];
    }
    // deemed trusted and not safe for...various reasons
    // cannot be pure because the malloc, realloc, and free are not pure
    typeof(this) cat(c_string str) @trusted {
      assert(large_string_allocation ? this.length() < 0xFFFFFFFFFFFF : true);
      if (large_string_allocation) {
        if (strlen(str) + this.length() >= OSStr.capacity) {
          OSStr.big_string = typed_realloc!mut_c_string(OSStr.big_string, strlen(str) + this.length() + 1);
        }
        OSStr.len += strlen(str) + 1;
        OSStr.capacity = floor_base2(OSStr.len);
        OSStr.big_string = strncat(OSStr.big_string, str, strlen(str) + 1);
      } else {
        // copy into temp string
        immutable size_t small_size = this.length() + 1;
        c_char[MALLOC_THRESHOLD] small_str_temp;
        strncpy(small_str_temp.ptr, OSStr.small_string.ptr, small_size);

        // new length
        OSStr.len = small_size + strlen(str);
        OSStr.capacity = floor_base2(OSStr.len);

        OSStr.big_string = typed_malloc!mut_c_string(OSStr.capacity);

        // copy string over
        strncpy(OSStr.big_string, small_str_temp.ptr, small_size);
        OSStr.big_string = strncat(OSStr.big_string, str, strlen(str));
        large_string_allocation = true;
      }
      return OSString(this.c_str());
    }
    typeof(this) cat(OSString str) @safe {
      return this.cat(str.c_str());
    }

    ~this() @trusted {
      // freeing union memory causes this to be unsafe
      if (large_string_allocation) {
        casted_free(OSStr.big_string);
      }
    }
  pragma(inline) int opCmp(ref OSString s) const @trusted {
    import core.stdc.string : strncmp;
    return strncmp(this.c_str(), s.c_str(), s.length);
  }
  pragma(inline) int opCmp(c_string s) pure const @trusted {
    import core.stdc.string : strncmp;
    return strncmp(this.c_str(), s, strlen(s));
  }
  pragma(inline) bool opEquals(ref OSString s) const @trusted {
    return this.opCmp(s) == 0;
  }
  pragma(inline) bool opEquals(c_string s) pure const @trusted {
    return this.opCmp(s) == 0;
  }
  size_t toHash() @trusted nothrow @nogc const {
    return this.length * cast(size_t)this.c_str();
  }

}

version (D_BetterC) {} else {

  // string equality with c_string
  @safe @nogc nothrow unittest {
    OSString s = OSString("foo");
    assert(s == "foo");
  }

  // string equality with other OSString
  @safe @nogc nothrow unittest {
    OSString s1 = OSString("foo");
    OSString s2 = OSString("foo");
    assert(s1 == s2);
    assert(!(s1 > s2));
    assert(s1 >= s2);
    assert(!(s1 < s2));
    assert(s1 <= s2);

    s1 = s1.cat("1");
    s2 = s2.cat("2");
    assert(s1 < s2);
    assert(s1 <= s2);
    assert(!(s1 >= s2));
    assert(!(s1 > s2));
    assert(s1 != s2);
  }

  //string concatenation
  @safe @nogc nothrow unittest {
    OSString s = OSString("this ");
        s = s.cat("uses @nogc!\n")
            .cat("Amazing!");
    assert(s == "this uses @nogc!\nAmazing!");
    OSString a1 = OSString("foo");
    OSString a2 = OSString("bar");
    a1 = a1.cat(a2);
    assert(a1 == "foobar");
  }
}
