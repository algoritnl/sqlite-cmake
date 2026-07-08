#include "sqlite3.h"
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    printf("SQLite version: %s\n", sqlite3_libversion());
    return EXIT_SUCCESS;
}
