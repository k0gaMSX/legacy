/*
	MSX-C Library Math-Pack Module Header (math.h)
	signed long(SLONG)  and  MSX double(XDOUBLE)
	
	Copyright  by ASCII Corporation  1987
*/

/*
	Definition of  SLONG and XDOUBLE
*/
#ifndef NOUSESL
typedef	struct	{
	char	byte[4];
	} SLONG;
#endif
#ifndef NOUSEXD
typedef	struct	{
	char	byte[8];
	} XDOUBLE;
#endif

/*
	Function Declarations
*/
#ifndef NOUSESL
extern	SLONG	*atosl();
extern	SLONG	*slcpy();
#endif

#ifndef NOUSEXD
extern	STATUS	atoxd();
extern	XDOUBLE	*xdcpy();
#endif

#ifndef NOUSESL
extern	SLONG	*sladd(), *slsub(), *slmul(), *sldiv(), *slmod();
extern	SLONG	*slneg(), *slabs(), *uldiv(), *ulmod();
extern	SLONG	*slnot(), *sland(), *slor(), *slxor();
extern	SLONG	*slsla(), *slsll(), *slsra(), *slsrl();
extern	SLONG	*slrlc(), *slrl(), *slrrc(), *slrr();
#endif

#ifndef NOUSEXD
extern	STATUS	xdadd(), xdsub(), xdmul(), xddiv(), xdpow();
extern	STATUS	xdneg(), xdfabs();
extern	STATUS	xdfix(), xdfloor(), xdceil();
extern	STATUS	xdsqrt();
extern	STATUS	xdsin(), xdcos(), xdtan(), xdatn();
extern	STATUS	xdlog(), xdexp();
extern	STATUS	xdrnd(), xdnrm();
#endif

#ifndef NOUSESL
extern	int	slsgn(), slcmp();
extern	char	*sltoa();
extern	SLONG	*itosl(), *uitosl();
#endif

#ifndef NOUSEXD
extern	int	xdsgn(), xdcmp();
extern	char	*xdtoa();
extern	STATUS	itoxd(), xdtoi();
#endif

#ifndef NOUSESL
#ifndef NOUSEXD
extern	STATUS	sltoxd(), ultoxd(), xdtosl();
#endif
#endif
/*
	External Variables
*/
#ifndef NOUSESL
extern	SLONG	slbuf;
extern	BOOL	slcy;
#endif

/*
	Substitute printf(), scanf()
*/

#ifndef NOUSESL
#ifndef NOUSEXD
/*  use sl, xd  */
#define	printf	mprf
#define	fprintf	mfprf
#define	sprintf	msprf
#define	scanf	mscf
#define	fscanf	mfscf
#define	sscanf	msscf

#else
/*  use sl  */
#define	printf	mprfl
#define	fprintf	mfprfl
#define	sprintf	msprfl
#define	scanf	mscfl
#define	fscanf	mfscfl
#define	sscanf	msscfl

#endif
#else
#ifndef NOUSEXD
/*  use xd  */
#define	printf	mprfd
#define	fprintf	mfprfd
#define	sprintf	msprfd
#define	scanf	mscfd
#define	fscanf	mfscfd
#define	sscanf	msscfd

#else
/*  use nomal type  */
#endif
#endif
/*
	Extended printf(), scanf()
*/
extern	STATUS	printf(.), fprintf(.);
extern	VOID	sprintf(.);
extern	int	scanf(.), fscanf(.), sscanf(.);

/*
	end of math.h
*/

                                                                                    