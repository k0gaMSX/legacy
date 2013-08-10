/*
 *	Modem7 protocol drivers for TELED package. See TELED.C.
 *
 *	Added:	"CRC" mode, Abort via Control-X
 *		Stefan Badstuebner	4 Mar 83
 */


#include <bdscio.h>
#include <hardware.h>
#include "teledit.h"

shocrt(sec,try,tot)
int sec,try,tot;
{
	if(sflg)
		printf("Sending #%d (Try=%d Errs=%d)  \r", sec, try, tot);
	else
		printf("Awaiting #%d (Try=%d, Errs=%d)  \r", sec, try, tot);

	if(try && tot) putchar('\n');
}

receive(seconds)
int seconds;
{
   char data;
    int lpc,seccnt;
    for (lpc = 0; lpc < CPUCLK; lpc++)
    {
	seccnt = seconds * SPS;
	do
	{  if (kbhit())

		if ((data = getch()) == CTRL_X)
		{
			send (CTRL_X);
			longjmp(jump_buf, 1);		/* Abort on ^X */
		}

	} while (!MOD_RDA && seccnt--);

        if(seccnt >= 0)
        {
		data = MOD_RDATA;   
                return(data);
        }
    }
    return(TIMEOUT);
}

purgeline()
{
   while (MOD_RDA)
      MOD_RDATA;	/* purge the receive register	*/
}


rcv_file(file)
char *file;
{ int j, firstchar, sectcurr, sectcomp, errors;
  int errorflag;
  int rcvd_char;
  int good_record;

  sflg = FALSE;
  fd = creat(file);

  if(fd == -1)
  {	printf("Teledit: cannot create %s\n", file);
	exit(1);
  }

  printf("\nReady to receive %s\n", file);
  sectnum = 0;
  errors = 0;
  toterr = 0;
  bufctr = 0;
  purgeline();

  /*
   *	Since the Modem protocol implies that
   *	the Sender starts the Xfer process;
   *	The following code was added. <sb>
   */

  if (crc_flag)
	send (CRC);
  else
	send (NAK);

  shocrt(0,0,0);
  do
      { errorflag = FALSE;
        do
            firstchar = receive (10);
        while(firstchar != SOH && firstchar != EOT && firstchar != TIMEOUT);

        if(firstchar == TIMEOUT)
            errorflag = TRUE;
        if(firstchar == SOH)
            { sectcurr = receive (1);
              sectcomp = receive (1);
              if((sectcurr + sectcomp) == 255)
                  { if(sectcurr == ((sectnum + 1) & 0xFF))
                        { checksum = 0;
			  crc_value = 0;
                          for(j = bufctr;j < (bufctr + SECSIZ);j++)
                              { buffer[j] = receive (1);
                                checksum = (checksum + buffer[j]) & 0xff;
				calc_crc ( &crc_value, buffer[j]);
                              }
			  rcvd_char = receive (1);
			  calc_crc ( &crc_value, rcvd_char );
			  if (crc_flag)
			  {
				rcvd_char = receive (1);
				calc_crc (&crc_value, rcvd_char);
			  }

			  if (crc_flag)
				good_record = (crc_value == 0);
			  else
				good_record = (checksum == rcvd_char);

                          if(good_record)
                              { errors = 0;
                                sectnum = sectcurr;
                                bufctr = bufctr + SECSIZ;
                                if(bufctr == TBFSIZ)
                                    { bufctr = 0;
				      write(fd, buffer, NSECTS);
                                    }
                                shocrt(sectnum,errors,toterr);
				send(ACK);
                              }
                          else
                              errorflag = TRUE;
                        }
                    else
                        if(sectcurr == sectnum)
                            { do;
                              while(receive (1) != TIMEOUT) 
					;
			      send(ACK);
                            }
                        else
                            errorflag = TRUE;
                  }
              else
                  errorflag = TRUE;
            }
        if(errorflag == TRUE)
            { errors++;
              if(sectnum)
                  toterr++;
              while(receive (1) != TIMEOUT);
              shocrt(sectnum,errors,toterr);
	      if (crc_flag)
		send(CRC);
	      else
		send(NAK);
            }
      }
  while(firstchar != EOT && errors != ERRORMAX);

  if((firstchar == EOT) && (errors < ERRORMAX))
      { send(ACK);
	bufctr = (bufctr + SECSIZ - 1) / SECSIZ; 
	write(fd, buffer, bufctr);
        close(fd);
	printf("\nDone -- returning to menu:\n");
      }
  else
	printf("\n\7Aborting\n\n");
}

sendfile(file)
char *file;
{ char *npnt;
  int rqst;
  int j, sectors, attempts;

  sflg = TRUE;
  fd = open(file,0);

  if(fd == -1)
      { printf("\nTeledit: %s not found\n", file);
	return;
      }
  else
	printf("\nFile is %d records long.\n",cfsize(fd));

  purgeline();
  attempts=0;
  toterr = 0;
  crc_flag = FALSE;

  printf("\nAwaiting Initial Request...");

  do
	rqst = receive (6);
  while(rqst != NAK && rqst != CRC && ++attempts < 10);

  if (attempts == 10)
     {
	printf("\nNo Response, Aborting...\n");
	return;
     }

  if (rqst == CRC)
     {
	printf("\nCRC Transfer Requested");
	crc_flag  = TRUE;
     }

  putchar('\n');

  attempts = 0;
  sectnum  = 1;

  while((sectors = read(fd, buffer, NSECTS)) && (attempts != RETRYMAX))
      { if(sectors == -1)
            { printf("\nFile read error.\n");
              break;
            }
        else
            { bufctr = 0;
              do
                  { attempts = 0;
                    do
                      { shocrt(sectnum,attempts,toterr);
			send(SOH);
			send(sectnum);
			send(-sectnum-1);
                        checksum = 0;
			crc_value = 0;
                        for(j = bufctr;j < (bufctr + SECSIZ);j++)
			    {	send(buffer[j]);
                             	checksum = (checksum + buffer[j]) & 0xff;
				calc_crc ( &crc_value, buffer[j]);
                            }
			if (crc_flag)
			{
			   calc_crc ( &crc_value, 0 );
			   calc_crc ( &crc_value, 0 );
			   send (crc_value >> 8);
			   send (crc_value);
			}
			else	
			   send(checksum);

                        purgeline();
                        attempts++;
                        toterr++;
                      }
                    while((receive (10) != ACK) && (attempts != RETRYMAX));
                    bufctr = bufctr + SECSIZ;
                    sectnum++;
                    sectors--;
                    toterr--;
                  }
              while((sectors != 0) && (attempts != RETRYMAX));
            }
      }
        if(attempts == RETRYMAX)
            printf("\nNo ACK on sector, aborting\n");
        else
            { attempts = 0;
              do
		  { send(EOT);
                    purgeline();
                    attempts++;
                  }
              while((receive (10) != ACK) && (attempts != RETRYMAX));
              if(attempts == RETRYMAX)
                  printf("\nNo ACK on EOT, aborting\n");
            } 
  close(fd);
  printf("\nDone -- Returning to menu:\n");
}

/*
 * Calculate the CCITT CRC polynomial X^16 + X^12 + X^5 + 1
 *
 *	Adapted by Stefan Badstuebner from the assembly language
 *	version of CRCSUBS ver. 1.20 by Paul Hansknecht JUN '81
 */

calc_crc ( crc, a_byte )
 unsigned *crc;
 int	a_byte;
 {
	int carry, i, mask;

	mask = 0x80;

	for (i=0; i<8; i++)
	{
	    carry = *crc & 0x8000;	/* Preserve MSB state */

	    *crc <<= 1;

	    *crc |= (a_byte & mask ?  1 : 0);

	    if (carry)	 *crc ^= 0x1021;

	    mask >>= 1;
	}
 }
