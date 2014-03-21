#ifndef __STDARG_H
#define __STDARG_H

#ifndef __VARARGS_H
#ifdef HI_TECH_C		/* HTC-MSDOS STDARG.H */

typedef void *va_list[1];
#define _STACK_ALIGN	2
#define va_start(ap, parmn)	*ap = (char *)&parmn + ((sizeof(parmn)+_STACK_ALIGN-1)&~(_STACK_ALIGN-1))
#define va_arg(ap, type)	(*(*(type **)ap)++)
#define va_end(ap)

#else				/* STDARG.H (TC2.0) */

typedef void *va_list;
#define va_start(ap, p) 	(ap = (char *) (&(p)+1))
#define va_arg(ap, type)	((type *) (((char *)ap) += sizeof(type)))[-1]
#define va_end(ap)

#endif
#endif

#endif /* __STDARG_H */

