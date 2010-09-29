/*********************************************************************
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*                   Version 2, December 2004                         *
*                                                                    *
*  Copyleft meh.                                                     *
*                                                                    *
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION   *
*                                                                    *
*  0. You just DO WHAT THE FUCK YOU WANT TO.                         *
**********************************************************************
* gcc -o call call.c \                                               *
* `nspr-config --libs` `nspr-config --cflags` \                      *
* `pkg-config --libs libffi` `pkg-config --cflags libffi`            *
*********************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>


#include <signal.h>
#include <prlink.h>
#include <ffi.h>

void
you_did_it_wrong (int fail)
{
    fprintf(stderr, "You did it wrong.\n");

    exit(23);
}

void*
call (void* function, char* type, char** arguments, int length)
{
    int i;
    int n;

    char* tmp;

    ffi_cif    cif;
    void*      result;
    ffi_type*  resultType;
    ffi_status status;
    
    ffi_type** types  = malloc(sizeof(ffi_type*) * length);
    void**     values = malloc(sizeof(void*) * length);

    for (i = 0; i < length; i++) {
        tmp = strchr(arguments[i], ':');
        
        if (tmp == NULL) {
            values[i] = NULL;
            continue;
        }
        
        n = tmp - arguments[i];

        if (strncmp(arguments[i], "string", n) == 0) {
            types[i]  = &ffi_type_pointer;
            values[i] = malloc(sizeof(char*));

            *((char**) values[i]) = strdup(arguments[i] + n + 1);
        }
        else if (strncmp(arguments[i], "char", n) == 0) {
            types[i]  = &ffi_type_uchar;
            values[i] = malloc(sizeof(char));

            *((char*) values[i]) = (char) *(arguments[i] + n + 1);
        }
        else if (strncmp(arguments[i], "short", n) == 0) {
            types[i]  = &ffi_type_ushort;
            values[i] = malloc(sizeof(short));

            *((short*) values[i]) = (short) atoi(arguments[i] + n + 1);
        }
        else if (strncmp(arguments[i], "int", n) == 0) {
            types[i]  = &ffi_type_uint;
            values[i] = malloc(sizeof(int));

            *((int*) values[i]) = (int) atoi(arguments[i] + n + 1);
        }
        else if (strncmp(arguments[i], "long", n) == 0) {
            types[i]  = &ffi_type_ulong;
            values[i] = malloc(sizeof(long));

            *((long*) values[i]) = (long) atol(arguments[i] + n + 1);
        }
        else if (strncmp(arguments[i], "float", n) == 0) {
            types[i]  = &ffi_type_float;
            values[i] = malloc(sizeof(float));

            *((float*) values[i]) = (float) atof(arguments[i] + n + 1);
        }
        else if (strncmp(arguments[i], "double", n) == 0) {
            types[i]  = &ffi_type_double;
            values[i] = malloc(sizeof(double));

            *((double*) values[i]) = (double) atof(arguments[i] + n + 1);
        }
    }

    if (strcmp(type, "string") == 0) {
        resultType = &ffi_type_pointer;
        result     = malloc(sizeof(char**));
    }
    else if (strcmp(type, "char") == 0) {
        resultType = &ffi_type_uchar;
        result     = malloc(sizeof(char*));
    }
    else if (strcmp(type, "short") == 0) {
        resultType = &ffi_type_ushort;
        result     = malloc(sizeof(short*));
    }
    else if (strcmp(type, "int") == 0) {
        resultType = &ffi_type_uint;
        result     = malloc(sizeof(int*));
    }
    else if (strcmp(type, "long") == 0) {
        resultType = &ffi_type_ulong;
        result     = malloc(sizeof(long*));
    }
    else if (strcmp(type, "float") == 0) {
        resultType = &ffi_type_float;
        result     = malloc(sizeof(float*));
    }
    else if (strcmp(type, "double") == 0) {
        resultType = &ffi_type_double;
        result     = malloc(sizeof(double*));
    }
    else {
        resultType = &ffi_type_void;
    }

    if ((status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, length, resultType, types)) != FFI_OK) {
        return 0;
    }

    ffi_call(&cif, FFI_FN(function), result, values);

    for (i = 0; i < length; i++) {
        if (values[i] == NULL) {
            continue;
        }

        if (types[i] == &ffi_type_pointer) {
            free(*((char**) values[i]));
            free((char*) values[i]);
        }
        else if (types[i] == &ffi_type_uchar) {
            free((char*) values[i]);
        }
        else if (types[i] == &ffi_type_ushort) {
            free((short*) values[i]);
        }
        else if (types[i] == &ffi_type_uint) {
            free((int*) values[i]);
        }
        else if (types[i] == &ffi_type_ulong) {
            free((long*) values[i]);
        }
        else if (types[i] == &ffi_type_float) {
            free((float*) values[i]);
        }
        else if (types[i] == &ffi_type_double) {
            free((double*) values[i]);
        }
    }

    free(types);
    free(values);

    return result;
}

int
main (int argc, char** argv)
{
    PRLibrary* library = NULL;
    void*      function;
    void*      result;

    if (argc < 3) {
        fprintf(stderr, "Usage: %s <library> <function> <return type> [Type1:Value1] [Type2:Value2] [TypeN:ValueN]\n", argv[0]);
        return 1;
    }

    signal(SIGSEGV, you_did_it_wrong);

    if (strcmp(argv[1], "-") == 0) {
        function = PR_FindSymbolAndLibrary(argv[2], &library);
    }
    else {
        if ((library = PR_LoadLibrary(argv[1])) == NULL) {
            fprintf(stderr, "Couldn't open `%s`.\n", argv[1]);
            return 2;
        }

        function = PR_FindSymbol(library, argv[2]);
    }

    if (function == NULL) {
        fprintf(stderr, "Function `%s` not found in `%s`.\n", argv[2], argv[1]);
        return 3;
    }

    result = call(function, argv[3], &argv[4], argc - 4);

    if (strcmp(argv[3], "string") == 0) {
        printf("%s\n", *((char**) result)); 
    }
    else if (strcmp(argv[3], "char") == 0) {
        printf("%c\n", *((char*) result));
    }
    else if (strcmp(argv[3], "short") == 0) {
        printf("%d\n", *((int*) result));
    }
    else if (strcmp(argv[3], "int") == 0) {
        printf("%d\n", *((short*) result));
    }
    else if (strcmp(argv[3], "long") == 0) {
        printf("%ld\n", *((long*) result));
    }
    else if (strcmp(argv[3], "float") == 0) {
        printf("%f\n", *((float*) result));
    }
    else if (strcmp(argv[3], "double") == 0) {
        printf("%lf\n", *((double*) result));
    }

    PR_UnloadLibrary(library);

    return 0;
}
