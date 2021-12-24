  main (int argc, 
  char argv[]) {

    /* Declaration and assignation */
    int var1 = -1;    long var2 = +4329;
    float var3 = .5f; double var4 = 3423.4e-10;
    char var5 = '\n'; char *var6 = "test1";
    int var7[2][2] = { {0,0}, {1,1} };

    var1<<= !var2+ (var1 %f()) *43 - 'a';

    /* Expressions */
    ~!(var1++ <= --var2 <<2  && (var2 |= 2,-var2|4+4-!6)) == 1 >= 1, --var2;
    f(); g(1+1); h(var2,var4++,(g(1)));

    // Empty
    ;

  }