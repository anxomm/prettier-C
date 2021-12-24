# Prettier C

This is a prettier for C code. It has been developed only for a small subset
of the grammar, explained in the next sections.

For example, this piece of code to calculate if a number is prime:

```C
#include 
<stdio.h>

/* Program to calculate if a number given is prime */
 int main ( ){
  int n, i, flag = 0;

  printf("Enter a positive integer: ");
  scanf("%d", &n);
  for (i=2;i<=n/2;++i) {
    // condition for non-prime
    if (n% i == 0) 
{
      flag = 1;break;  }
}

  if (n == 1) {
    printf("1 is neither prime nor composite.");
  } 
  else{
    if (flag == 0) printf("%d is a prime number.", n);
    else printf("%d is not a prime number.", n);
  }
  return 0;
}
```

would be reformatted as:

```C
#include <stdio.h>

/* Program to calculate if a number given is prime */
int main()
{
    int n, i, flag = 0;

    printf("Enter a positive integer: ");
    scanf("%d", &n);

    for (i = 2; i <= n / 2; ++i)
    {
        // condition for non-prime
        if (n % i == 0)
        {
            flag = 1;
            break;
        }
    }

    if (n == 1)
    {
        printf("1 is neither prime nor composite.");
    }
    else 
    {
        if (flag == 0)
            printf("%d is a prime number.", n);
        else 
            printf("%d is not a prime number.", n);
    }

    return 0;
}
```

## Usage

To compile and run you can use the Makefile:

```Shell
make
make run  # Execute over the file specified as TEST, redirecting the input
make run2 # Execute reading the file specified as TEST
```

The output will be save in a file called _\_output.c_.

## Grammar considered

Not all the grammar has been considered for this project, just a little subset:

1. Types: char, int, long, float, double, pointers and arrays. Modifiers as
global, auto... or long long, unsigned int... are not allowed.

2. Preprocessing directives: #include, #ifdef/#ifndef...#endif, #define

3. Simple statements: expressions, declarations, asignations, break, continue
and return.

4. Complex statements: if, if-else, for, while, do-while and function definitions

5. Multiline or single line comments

## Content

- [prettier.l](prettier.l): lexical parser
- [prettier.y](prettier.y): syntactic parser
- tests: check the correct behaviour in specific situations
    - [test1.c](tests/test1.c): main function, declarations, expressions and comments
    - [test2.c](tests/test2.c): if, if-else, conditional expression
    - [test3.c](tests/test3.c): for, while, do-while, break and continue
    - [test4.c](tests/test4.c): preprocessing directives, function definitions and return statement
    - [test5.c](tests/test5.c): real code to calculate if a given number is prime
- test_errors: check the correct diagnosis of syntax errors
    - [test1.c](test_errors/test1.c): main not found
    - [test2.c](test_errors/test2.c): conditional and repetitive structures outside a function
    - [test3.c](test_errors/test3.c): expression expected
    - [test4.c](test_errors/test4.c): incorrect if/for/while/do-while header
    - [test5.c](test_errors/test5.c): ';' expected
    - [test6.c](test_errors/test6.c): unrecognized preprocessing directive
    - [test7.c](test_errors/test7.c): break or continue statement outside a loop
    - [test8.c](test_errors/test8.c): return outside a function
