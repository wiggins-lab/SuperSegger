/* fast_rotate_loose_double : replaces imrotate(image,angle,'crop') for
 * for double 3 dims image, UINT8 class.
 * Work ten times faster, tested on matlab 7, VC6.
 * Compile it using the mex tools -
 * mex fast_rotate.cpp.
 */

#include <mex.h>
#include <math.h>

const double PI = 3.14159265358979323846;

inline float Max( float x, float y );



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2) mexErrMsgTxt("Usage : fast_rotate(image,ang)");
    float angle = (float)mxGetScalar(prhs[1]);
    const int *dims = mxGetDimensions_700(prhs[0]);
    int width = dims[0];
    int height = dims[1];
    const int num_of_dims=mxGetNumberOfDimensions(prhs[0]);
    int dim	= 1; // Number of colors (default - gray scale)
    if(num_of_dims==3) dim=dims[2];
    
    unsigned char * source;
    double * dest;
    
    // Here need to insert the 0,90,180,360 special cases.
    
    const float rad = (float)((angle*PI)/180.0),
            ca=(float)cos(rad), sa=(float)sin(rad);
    
    const float
            ux  = (float)(abs(width*ca)),  uy  = (float)(abs(width*sa)),
            vx  = (float)(abs(height*sa)), vy  = (float)(abs(height*ca)),
            w2  = 0.5f*width,           h2  = 0.5f*height,
            dw2 = 0.5f*Max(ux+vx,abs(ux-vx)),         dh2 = 0.5f*Max(uy+vy,abs(uy-vy)); // dw2, dh2 are the dimentions for rotated image without cropping.
    
    // Changes by Paul Wiggins 8/10/2010
    // loose - double
    
    const int
            DW2 = ceil( dw2 ),	DH2 = ceil( dh2 ),
            WIDTH = 2*DW2+1, HEIGHT = 2*DH2+1,
            DIMS[2] = { WIDTH, HEIGHT };
            
            plhs[0] = mxCreateNumericArray_700(num_of_dims, DIMS, mxDOUBLE_CLASS, mxREAL);
            
            source=(unsigned char *)mxGetData(prhs[0]);
            dest=(double *)mxGetData(plhs[0]);
            
            
            int X,Y; // Locations in the source matrix
            double Xd, Yd, delX, delY;
            int x,y,color; // For counters
            int index_Color,index_Height;
            
            for(color=0;color<dim;color++)
            {
                index_Color=color*HEIGHT*WIDTH;
                for(y=0;y<HEIGHT;y++)
                {
                    index_Height=index_Color+y*WIDTH;
                    for(x=0;x<WIDTH;x++)
                    {
                        
                        Xd = (w2 + (x-DW2)*ca + (y-DH2)*sa); // Source X
                        X = floor(Xd);
                        delX = Xd-X;
                        
                        Yd = (h2 - (x-DW2)*sa + (y-DH2)*ca); // Source Y
                        Y = floor(Yd);
                        delY = Yd-Y;
                        
                        dest[index_Height+x] = (( X   <0 ||  Y   <0 ||  X   >=width ||  Y   >=height) ? 0.0:(((double)source[index_Color+ Y   *width+ X   ])*(1-delX)*(1-delY))) +
                                (((X+1)<0 ||  Y   <0 || (X+1)>=width ||  Y   >=height) ? 0.0:(((double)source[index_Color+ Y   *width+(X+1)])*(  delX)*(1-delY))) +
                                        (( X   <0 || (Y+1)<0 ||  X   >=width || (Y+1)>=height) ? 0.0:(((double)source[index_Color+(Y+1)*width+ X   ])*(1-delX)*(  delY))) +
                                                (((X+1)<0 || (Y+1)<0 || (X+1)>=width || (Y+1)>=height) ? 0.0:(((double)source[index_Color+(Y+1)*width+(X+1)])*(  delX)*(  delY)));
                                                
                    }
                }
            }
}

inline float Max( float x, float y )
{
    return ( x > y ) ? x : y;
}