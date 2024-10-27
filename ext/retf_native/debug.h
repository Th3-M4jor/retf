#ifndef RETF_DEBUG_H
#define RETF_DEBUG_H

#include <stdio.h>
#include <stdlib.h>

#ifndef NDEBUG
#define RETF_DEBUG_PRINT(...) fprintf(stderr, __VA_ARGS__)
#else
#define RETF_DEBUG_PRINT(...) ((void)0)
#endif

#endif  // RETF_DEBUG_H
