/* UZIX TCP/IP Stack
 * (c) 2000 A&L Software
 * Adriano C. R. da Cunha <adrcunha@dcc.unicamp.br>
 */

/* Protocol numbers */
#define ICMP_PROTOCOL 1
#define TCP_PROTOCOL 6
#define UDP_PROTOCOL 17

/* TCP/IP open modes */
#define TCP_ACTIVE_OPEN     255
#define TCP_PASSIVE_OPEN    0

/* data size */
#define DOMSIZE         128

/* protocols */
#define IPV4_TCP     0x01
#define IPV4_UDP     0x02
#define IPV4_ICMP    0x03

/* UDP modes */
#define UDPMODE_ASC     1
#define UDPMODE_CKSUM   2

/* error codes */
#define ECONTIMEOUT 0x80
#define ECONREFUSED 0x81
#define ENOPERM     0x82
#define ENOPORT     0x83
#define ENOROUTE    0x84
#define ENOSOCK     0x85
#define ENOTIMP     0x86
#define EPROT       0x87
#define EPORTINUSE  0x88

/* TCP socket status
   bits: 76543210
         ^^  ^^^^ state
         |+-------listen state
         +--------write enable
*/

#define TCP_CLOSED       0x00
#define TCP_LISTEN       0x01
#define TCP_SYN_SENT     0x42
#define TCP_SYN_RECEIVED 0x43
#define TCP_ESTABLISHED  0xc4
#define TCP_FIN_WAIT1    0x45
#define TCP_FIN_WAIT2    0x46
#define TCP_CLOSE_WAIT   0x87
#define TCP_CLOSING      0x08
#define TCP_LAST_ACK     0x09
#define TCP_TIMEWAIT     0x0a

/* UDP socket status */
#define UDP_LISTEN       0x91
#define UDP_ESTABLISHED  0x94

/* some structures used */
typedef struct s_ip_struct {    /* TCP/UDP connection info data */
	uchar remote_ip[4];
	uint remote_port;
	uint local_port;
} ip_struct_t;

typedef struct s_icmpdata {     /* ICMP packet data */
	uchar type;
	uchar icmpcode;
        unsigned long unused;   /* Used for various things */
        uchar data[28];         /* Make up to 64 bytes */
	uint len;
	uchar sourceIP[4];
	uchar ttl;
} icmpdata_t;

typedef struct {                /* TCP/IP stack info */
	uchar IP[4];
        uchar dns1ip[4];
        uchar dns2ip[4];
        char datalink[5];
        char domainname[DOMSIZE];
	int used_sockets;
	int avail_sockets;
	int used_buffers;
	int avail_buffers;
        int IP_chksum_errors;
} tcpinfo_t;

typedef struct {                /* socket info */
	int localport;
	int remoteport;
	uchar remote_ip[4];
	char socketstatus;      /* bit 7: listen, bits 3-0: closed...timewait */
	char sockettype;        /* IPV4_UDP or IPV4_TCP */
        char sockerr;           /* error code (if any) */
	int pid;
} sockinfo_t;

/* user calls: TCP/IP */
int ipconnect(char mode, ip_struct_t *ipstruct);
int ipclose(uchar socknum);
int iplisten(int aport, uchar protocol);
int ipunlisten(int aport);
int ipaccept(ip_struct_t *ipstruct, int aport, uchar block);
int ping(uchar *IP, unsigned long *unused, uint len);
int setsocktimeout(uchar socknum, uint timeout);
icmpdata_t *ipgetpingreply(void);
int ipwrite(uchar socknum, uchar *bytes, int len);
int ipread(uchar socknum, uchar *bytes, int len);
int ipgetc(uchar socknum);
int ipputc(uchar socknum, uchar byte);
tcpinfo_t *gettcpinfo(void);
sockinfo_t *getsockinfo(uchar socknum);

/* user calls: DNS */
int local_lookup(char *ip_name, uchar *ipaddr);
int resolve(char *name, uchar *ipaddr);
int reverse_lookup(char *name, char *ipaddr);
