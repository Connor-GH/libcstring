module test;
import libcstring;


version(D_BetterC) {
    void myStr(int argc, char **argv) {
      import core.stdc.stdio : printf;
      for (int i = 0; i < argc; i++) {
        char *arg = argv[i];
        OSString s = OSString(arg);
        s = s.cat("HI");
        printf("%s\n", s.c_str());
    }
  }
  extern(C) void main(int argc, char **argv) {
    import core.stdc.stdio : printf;
    import core.stdc.time;
    printf("%lu\n", OSString.sizeof);

      clock_t time = clock();
      foreach (x; 0..1000) {
        cast(void)myStr(argc, argv);
      }
      printf("Mine: %f\n", cast(double)(clock() - time)/CLOCKS_PER_SEC);
  }

} else {
  void theirStr(string[] args) {
    import std.stdio : writeln;
    foreach (arg; args) {
      string s = arg;
      s = s ~ "HI";
      writeln(s);
    }
  }
  int call_main(string[] args) {
    import core.stdc.time;
    import std.stdio : writeln;
    writeln(string.sizeof);
    clock_t time = clock();
    foreach (x; 0..1000) {
      cast(void)theirStr(args);
    }
    writeln("Theirs: ", cast(double)(clock() - time)/CLOCKS_PER_SEC);
    return 0;
  }
  extern(D) int main(string[] args) {
    return call_main(args);
  }
}
