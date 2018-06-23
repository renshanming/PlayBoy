//+------------------------------------------------------------------+
//|                                                    rs_FraSMA.mq5 |
//|                              Copyright © 2009, jppoton@yahoo.com | 
//|                                      migrated by cping.luo       |   
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, jppoton@yahoo.com"
#property link      "http://fractalfinance.blogspot.com/"
#property version   "1.02"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   1
#property indicator_width1  2
#property indicator_type1   DRAW_COLOR_LINE  //DRAW_LINE
#property indicator_color1  clrLimeGreen ,clrGray,clrRed
#property indicator_label1  "RS_FraSMA"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Applied_price_
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price
   PRICE_DEMARK_         //Demark Price
  };

//--- input parameters
input uint     e_period=64;
input uint     normal_speed=30;
input Applied_price_ IPC=PRICE_CLOSE_;
input int      Shift=0;
input int      PriceShift=0;
input int      PIP_Convertor=1;  //PIPS(10000 For Forx)

//--- indicator buffers
double IndBuffer[];
double ColorIndBuffer[];

double dPriceShift;   //price up shift
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,IndBuffer);
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,e_period);
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

   string short_name="RS_FraSMA";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(e_period)+")");
//---
   return(INIT_SUCCEEDED);
//--- Finish init
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//----
   int bar,limit;
//--- check for rates
   if(rates_total<(int)e_period) return(0);
//--- preliminary calculations
   if(prev_calculated==0)limit=(int)e_period+1;
   else limit=prev_calculated-1;

// Calculate init parament
   int  i,j,k,l,m,z,t;
   double  d[10],K[10],iter,K0;
   double  max,min,sum,mu,std,H1,H2,H,sumx,sumx2,sumy,sumy2,sumxy,alpha,speed;
   double  W[200][200],Wi[200],R[500],Rst[500],Rs[500];

//--- the main loop of calculations
   for(bar=limit;bar<rates_total && !IsStopped();bar++)
     {
      K0=MathFloor(e_period/4);
      iter=MathFloor(MathLog(K0)/MathLog(2));
      ArrayInitialize(W,0.0);
      ArrayInitialize(R,0.0);
      ArrayInitialize(Wi,0.0);
      ArrayInitialize(Rst,0.0);
      ArrayInitialize(Rs,0.0);
      sumx=0;
      sumy=0;
      sumxy=0;
      sumx2=0;
      sumy2=0;
      for(i=1; i<=iter; i++) // i is the subdivision index in Ki blocks, higher-level index
        {
         d[i]=MathPow(2,i+1);             // d[i]=size of each block in cut "i"  
         K[i]=MathFloor(e_period/d[i]);     // K[i]=nber of blocks in cut "i"
         t=0;
         l=1;
         while(t<=e_period-d[i])
           {
            mu=0;
            for(j=1; j<=d[i]; j++)
              {
               double PriceData=PriceSeries(IPC,rates_total-bar+t+j,open,low,high,close);
               mu+=PIP_Convertor*PriceData/d[i];
              }
            sum=0;
            for(j=1; j<=d[i]; j++)
              {
               double PriceData=PriceSeries(IPC,rates_total-bar+t+j,open,low,high,close);
               sum+=MathPow((PIP_Convertor*PriceData-mu),2);
              }
            std=0;
            std=MathSqrt(sum/d[i]);
            if(std<=0)std=0.1;
            for(k=1; k<=d[i]; k++)
              {
               for(z=1; z<=k; z++)
                 {
                  double PriceData=PriceSeries(IPC,rates_total-bar+t+z,open,low,high,close);
                  W[i,k+t]+=PIP_Convertor*PriceData-mu;
                 }
               Wi[k+t]=W[i,k+t];
              }
            max=_highest(d[i],t+1,Wi);
            min=_lowest(d[i],t+1,Wi);
            if(max<0)max=0;
            if(min>0)min=0;
            R[l]=max-min;
            Rst[l]=R[l]/std;
            t=t+int(d[i]);
            l=l+1;
           }  //********************************END OF while LOOP ON t AND l AS INDEXES    
         for(m=1; m<=K[i]; m++)
           {
            Rs[i]+=Rst[m]/K[i];
           }
         sumx+=MathLog(d[i])/MathLog(2);
         sumy+=MathLog(Rs[i])/MathLog(2);
         sumx2+=MathPow((MathLog(d[i])/MathLog(2)),2);
         sumy2+=MathPow((MathLog(Rs[i])/MathLog(2)),2);
         sumxy+=(MathLog(d[i])/MathLog(2))*(MathLog(Rs[i])/MathLog(2));
        }        //********************************END OF i LOOP
      H1=(iter*sumxy-sumx*sumy);
      H2=iter*sumx2-MathPow(sumx,2);
      if(H2<=0)H2=0.1;
      H=H1/H2;
      if(2*H<=0)H=0.001;
      alpha=1/(2*H);
      speed=MathRound(normal_speed*alpha);

      double res=0;
      for(int jj=bar;jj>bar-speed && jj>0;jj--)
        {
         double PriceData=PriceSeries(IPC,jj,open,low,high,close);
         res+=PriceData;
        }
      IndBuffer[bar]=res/speed;
     }
//----

//---- Line to Color,
   for(bar=limit; bar<rates_total-1 && !IsStopped(); bar++)
     {
      ColorIndBuffer[bar]=1;
      if(IndBuffer[bar+1]<IndBuffer[bar]) ColorIndBuffer[bar]=0;
      if(IndBuffer[bar+1]>IndBuffer[bar]) ColorIndBuffer[bar]=2;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+ 
double PriceSeries
(
 uint applied_price,// use which price
 uint   bar,        //Bars Position
 const double &Open[],
 const double &Low[],
 const double &High[],
 const double &Close[]
 )
//PriceSeries(applied_price, bar, open, low, high, close)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   switch(applied_price)
     {
      //---- ENUM_APPLIED_PRICE
      case  PRICE_CLOSE: return(Close[bar]);
      case  PRICE_OPEN: return(Open [bar]);
      case  PRICE_HIGH: return(High [bar]);
      case  PRICE_LOW: return(Low[bar]);
      case  PRICE_MEDIAN: return((High[bar]+Low[bar])/2.0);
      case  PRICE_TYPICAL: return((Close[bar]+High[bar]+Low[bar])/3.0);
      case  PRICE_WEIGHTED: return((2*Close[bar]+High[bar]+Low[bar])/4.0);

      //----                            
      case  8: return((Open[bar] + Close[bar])/2.0);
      case  9: return((Open[bar] + Close[bar] + High[bar] + Low[bar])/4.0);
      //----                                
      case 10:
        {
         if(Close[bar]>Open[bar])return(High[bar]);
         else
           {
            if(Close[bar]<Open[bar])
               return(Low[bar]);
            else return(Close[bar]);
           }
        }
      //----         
      case 11:
        {
         if(Close[bar]>Open[bar])return((High[bar]+Close[bar])/2.0);
         else
           {
            if(Close[bar]<Open[bar])
               return((Low[bar]+Close[bar])/2.0);
            else return(Close[bar]);
           }
         break;
        }
      //----         
      case 12:
        {
         double res=High[bar]+Low[bar]+Close[bar];
         if(Close[bar]<Open[bar]) res=(res+Low[bar])/2;
         if(Close[bar]>Open[bar]) res=(res+High[bar])/2;
         if(Close[bar]==Open[bar]) res=(res+Close[bar])/2;
         return(((res-Low[bar])+(res-High[bar]))/2);
        }
      //----
      default: return(Close[bar]);
     }
//----
//return(0);
  }
//+------------------------------------------------------------------+
//| FUNCTION : _highest                                              |
//| Search for the highest value in an array data                    |
//| In :                                                             |
//|    - n : find the highest on these n data                        |
//|    - pos : begin to search for from this index                   |
//|    - inputData : data array on which the searching for is done   |
//|                                                                  |
//| Return : the highest value                                       |                                                 |
//+------------------------------------------------------------------+
double _highest(double n,int pos,double &inputData[])
  {
   double length=pos+n;
   double highest=0.0;
//----
   for(int i=pos; i<length; i++)
     {
      if(inputData[i]>highest)highest=inputData[i];
     }
   return( highest );
  }
//+------------------------------------------------------------------+
//| FUNCTION : _lowest                                               |
//| Search for the lowest value in an array data                     |
//| In :                                                             |
//|    - n : find the hihest on these n data                         |
//|    - pos : begin to search for from this index                   |
//|    - inputData : data array on which the searching for is done   |
//|                                                                  |
//| Return : the highest value                                       |
//+------------------------------------------------------------------+
double _lowest(double n,int pos,double &inputData[])
  {
   double length=pos+n;
   double lowest=9999999999.0;
//----
   for(int i=pos; i<length; i++)
     {
      if(inputData[i]<lowest)lowest=inputData[i];
     }
   return( lowest );
  }

//+------------------------------------------------------------------+
