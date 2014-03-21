
double fabs(double);

double
fabs(d)
double	d;
{
	if(d < 0.0)
		return -d;
	return d;
}
