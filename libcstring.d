module libcstring;

static pragma(inline) size_t floor_base2(size_t i) pure nothrow @nogc {
  import std.math.exponential : log2;
  return 1LU << (cast(size_t)log2(cast(float)i) + 1);
}

public alias c_char = char;
public alias c_string = const(c_char *);
public alias mut_c_string = c_char *;
final struct OSString {
import core.stdc.stdlib : malloc, free, realloc;
import core.stdc.stdio : stderr, fprintf, printf;
import core.stdc.string : strlen, strncat, strncpy;
  private:
  align(8):
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
  OSStr_ OSStr;
  public @nogc nothrow:
    // small string optimization
    this(int N)(char[N] str)
    in (N <= 23) {
      large_string_allocation = false;
      strncpy(cast(mut_c_string)OSStr.small_string, cast(c_string)str, N);
      OSStr.small_string[23] = N; // set length
    }

    this(c_string str) {
      OSStr.len = strlen(str);
      OSStr.capacity = floor_base2(OSStr.len);
      large_string_allocation = true;
      OSStr.big_string = cast(mut_c_string)malloc(OSStr.capacity);
      strncpy(OSStr.big_string, str, OSStr.len + 1);
    }
    c_string c_str() const {
      return large_string_allocation ? OSStr.big_string : cast(c_string)OSStr.small_string;
    }
    size_t length() const {
      return large_string_allocation ? OSStr.len : cast(size_t)OSStr.small_string[23];
    }
    // TODO cover the case where OSStr.small_string > MALLOC_THRESHOLD
    pragma(inline) typeof(this) cat(c_string str) {
      assert(large_string_allocation ? this.length() < 0xFFFFFFFFFFFF : true);
      if (large_string_allocation) {
        if (strlen(str) + this.length() >= OSStr.capacity) {
          OSStr.big_string = cast(mut_c_string)realloc(cast(void *)OSStr.big_string, strlen(str) + this.length() + 1);
          assert(OSStr.big_string is null);
        }
        OSStr.len += strlen(str) + 1;
        OSStr.capacity = floor_base2(OSStr.len);
        OSStr.big_string = strncat(OSStr.big_string, str, strlen(str) + 1);
      } else {
        // copy into temp string
        size_t small_size = this.length() + 1;
        c_char[MALLOC_THRESHOLD] small_str_temp;
        strncpy(cast(mut_c_string)small_str_temp, cast(c_string)OSStr.small_string, small_size);

        // new length
        OSStr.len = small_size + strlen(str);
        OSStr.capacity = floor_base2(OSStr.len);

        OSStr.big_string = cast(mut_c_string)malloc(OSStr.capacity);

        strncpy(OSStr.big_string, cast(c_string)small_str_temp, small_size);
        OSStr.big_string = strncat(OSStr.big_string, str, strlen(str));
        large_string_allocation = true;
      }
      return OSString(this.c_str());
    }

    ~this() {
      if (large_string_allocation) {
        free(cast(void *)OSStr.big_string);
      }
    }
  int opCmp(const OSString s) const {
    import core.stdc.string : strncmp;
    return strncmp(this.c_str(), s.c_str(), s.length);
  }
  int opCmp(const c_string s) const {
    import core.stdc.string : strncmp;
    return strncmp(this.c_str(), s, strlen(s));
  }
  bool opEquals(const OSString s) const {
    import core.stdc.string : strncmp;
    return strncmp(this.c_str(), s.c_str(), s.length) == 0;
  }
  bool opEquals(const c_string s) const {
    import core.stdc.string : strncmp;
    return strncmp(this.c_str(), s, strlen(s)) == 0;
  }

}



unittest {
  OSString s = OSString("this ");
      s = s.cat("uses @nogc!\n")
           .cat("Amazing!");
  assert(s == "this uses @nogc!\nAmazing!");
}

// 8.8% in ctor
// 11.04% in cat
// 0.15% in c_str()
// 0.07% in length()
// 9.44% in floor_base2()
int main(string[] args) {
  import core.stdc.stdio : printf, fprintf, stderr;
  import std.string : toStringz;
  import std.datetime.stopwatch;
  import std.stdio : writeln;
  printf("%lu\n", OSString.sizeof);
  printf("%lu\n", string.sizeof);
  void myStr() {
   foreach (arg; args) {
     OSString s = OSString(arg.toStringz);
     s = s.cat("HI");
     fprintf(stderr, "%s\n", s.c_str());
   }
  }
  void theirStr() {
   foreach (arg; args) {
     string s = arg;
     s = s ~ "HI";
     fprintf(stderr, "%s\n", s.toStringz);
   }
  }
  auto r = benchmark!(myStr, theirStr)(100);
  writeln("mine", r[0]);
  writeln("theirs", r[1]);

  return 0;
}
