//+------------------------------------------------------------------+
//|                                  Multi Moving Average Expert.mq5 |
//|                                                  Aleksey Zinovik |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Aleksey Zinovik"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//|enum                                                                  
//+------------------------------------------------------------------+
enum TypeOfMA //Type of MA
  {
   AMA,//Adaptive Moving Average
   DEMA,// Double Exponential Moving Average
   FraMA,//Fractal Adaptive Moving Average 
   MA,//Moving Average 
   TEMA,//Triple Exponential Moving Average
   VIDYA,//Variable Index Dynamic Average
   NRMA//Nick Rypock Moving Average
  }; 
enum Smooth_Method //averaging method for NRMA
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  };
enum Applied_price_ //Prices series for NRMA
  {
   PRICE_CLOSE_ = 1,     //close
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
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input string             Expert_Title="Multi Moving Average Expert"; // Document name
input TypeOfMA           Type_MA                =AMA;                           // Type of Moving Average

input double             StopLevel              =50.0;                          // Stop Loss level (in points)
input double             TakeLevel              =80.0;                          // Take Profit level (in points)
input int                AMA_PeriodMA           =14;                             // Adaptive Moving Average Period of averaging
input int                AMA_PeriodFast         =2;                             // Adaptive Moving Average Period of fast EMA
input int                AMA_PeriodSlow         =30;                            // Adaptive Moving Average Period of slow EMA
input int                AMA_Shift              =0;                             // Adaptive Moving Average Time shift
input ENUM_APPLIED_PRICE AMA_Applied            =PRICE_CLOSE;                   // Adaptive Moving Average Prices series

input int                DEMA_PeriodMA          =28;                            // Double Exponential Moving Average Period of averaging
input int                DEMA_Shift             =0;                             // Double Exponential Moving Average Time shift
input ENUM_APPLIED_PRICE DEMA_Applied           =PRICE_CLOSE;                   // Double Exponential Moving Average Prices series

input int                FraMA_PeriodMA         =16;                            // Fractal Adaptive Moving Average Period of averaging
input int                FraMA_Shift            =0;                             // Fractal Adaptive Moving Average Time shift
input ENUM_APPLIED_PRICE FraMA_Applied          =PRICE_CLOSE;                   // Fractal Adaptive Moving Average Prices series

input int                MA_PeriodMA            =15;                            // Moving Average Period of averaging
input int                MA_Shift               =0;                             // Moving Average Time shift
input ENUM_MA_METHOD     MA_Method              =MODE_SMA;                      // Moving Average Method of averaging
input ENUM_APPLIED_PRICE MA_Applied             =PRICE_CLOSE;                   // Moving Average Prices series

input int                TEMA_PeriodMA          =44;                            // Triple Exponential Moving Average Period of averaging
input int                TEMA_Shift             =0;                             // Triple Exponential Moving Average Time shift
input ENUM_APPLIED_PRICE TEMA_Applied           =PRICE_CLOSE;                   // Triple Exponential Moving Average Prices series

input int                VIDYA_InpPeriodCMO     =11;                             // Variable Index Dynamic Average Period CMO
input int                VIDYA_InpPeriodEMA     =27;                            // Variable Index Dynamic Average Period EMA
input int                VIDYA_InpShift         =0;                             // Variable Index Dynamic Average Indicator's shift
input ENUM_APPLIED_PRICE VIDYA_Applied          =PRICE_CLOSE;                   // Variable Index Dynamic Average Prices series

input Smooth_Method      NRMA_Method            =MODE_SMA_;                     //NRMA Method of averaging
input int                XLength                =3;                             //NRMA Depth of smoothing                 
input int                XPhase                 =15;                            //NRMA Parameter of smoothing
input Applied_price_     IPC                    =PRICE_CLOSE_;                  //NRMA Prices series
input double             Kf                     =1;                             //NRMA coefficient of the sliding filter (NRTR)
input double             Fast                   =12;                            //NRMA Factor of smoothing 
input double             Sharp                  =2;                             //NRMA Degree of dynamism of the oscillator
input int                Shift                  =0;                             //NRMA Horizontal shift in bars
input int                PriceShift             =0;                             //NRMA vertical shift in points


input double             Lots                   =0.1;                           // Fixed volume
input double             GFactor                =0.0001;                        // Growth factor

CTrade ExtTrade;

double TP,SL;//StopLoos and TakeProfit
bool   ExtHedging=false;//for Hedging Mode
bool SellCross=false;//first signal of sell
bool BuyCross=false;//first signal of buy
datetime Old_Time;//for new bar
datetime New_Time[1];//for new bar

// Handles
int AMA_Handle;// Handle of Adaptive Moving Average
int DEMA_Handle;// Handle of Double Exponential Moving Average
int FraMA_Handle;//Handle of Fractal Adaptive Moving Average 
int MA_Handle;//Handle of Moving Average 
int TEMA_Handle;//Handle of Triple Exponential Moving Average
int VIDYA_Handle;//Handle of Variable Index Dynamic Average
int NRMA_Handle;//Handle of NRMA

#define MA_MAGIC 1234501
//+------------------------------------------------------------------+
//| Position select depending on netting or hedging                  |
//+------------------------------------------------------------------+
bool SelectPosition()
  {
   bool res=false;
//--- check position in Hedging mode
   if(ExtHedging)
     {
      uint total=PositionsTotal();
      for(uint i=0; i<total; i++)
        {
         string position_symbol=PositionGetSymbol(i);
         if(_Symbol==position_symbol && MA_MAGIC==PositionGetInteger(POSITION_MAGIC))
           {
            res=true;
            break;
           }
        }
     }
//--- check position in Netting mode
   else
     {
      if(!PositionSelect(_Symbol))
         return(false);
      else
         return(PositionGetInteger(POSITION_MAGIC)==MA_MAGIC); //---check Magic number
     }
//--- result for Hedging mode
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for open position conditions                               |
//+------------------------------------------------------------------+
void CheckForOpen(void)
  {
   MqlRates rt[2];
   double   ma[2];
   ma[0]=0;
   ma[1]=0;
   ENUM_ORDER_TYPE signal=WRONG_VALUE;
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2)
     {
      Alert("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   switch(Type_MA)
     {
      case AMA:
        {
         if(CopyBuffer(AMA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from iAMA failed, no data");
            return;
           }
         break;
        }
      case DEMA:
        {
         if(CopyBuffer(DEMA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from iDEMA failed, no data");
            return;
           }
         break;
        }
      case FraMA:
        {
         if(CopyBuffer(FraMA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from iFraMA failed, no data");
            return;
           }
         break;
        }
      case MA:
        {
         if(CopyBuffer(MA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from iMA failed, no data");
            return;
           }
         break;
        }
      case TEMA:
        {
         if(CopyBuffer(TEMA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from iTEMA failed, no data");
            return;
           }
         break;
        }
      case VIDYA:
        {
         if(CopyBuffer(VIDYA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from iVIDYA failed, no data");
            return;
           }
         break;
        }
      case NRMA:
        {
         if(CopyBuffer(NRMA_Handle,0,0,2,ma)!=2)
           {
            Alert("CopyBuffer from NRMA failed, no data");
            return;
           }
         break;
        }
     }

   if(rt[0].open>ma[0] && rt[0].close<ma[0])
     {
      if(BuyCross)
         BuyCross=false;
      SellCross=true;
     }
   else
   if(rt[0].open<ma[0] && rt[0].close>ma[0])
     {
      if(SellCross)
         SellCross=false;
      BuyCross=true;
     }
   if(SellCross && ma[0]>ma[1] && ma[0]-ma[1]>GFactor)
     {
      signal=ORDER_TYPE_SELL;    // sell conditions
      SellCross=false;
     }
   else
   if(BuyCross && ma[1]>ma[0] && ma[1]-ma[0]>GFactor)
     {
      signal=ORDER_TYPE_BUY;  // buy conditions
      BuyCross=false;
     }

   if(signal!=WRONG_VALUE)
     {
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol,_Period)>100)
        {
         if(signal==ORDER_TYPE_BUY)
            if(!ExtTrade.PositionOpen(_Symbol,signal,Lots,SymbolInfoDouble(_Symbol,SYMBOL_ASK),
               SymbolInfoDouble(_Symbol,SYMBOL_ASK)-NormalizeDouble(SL*_Point,_Digits),
               SymbolInfoDouble(_Symbol,SYMBOL_ASK)+NormalizeDouble(TP*_Point,_Digits)))
              {
               Alert("Can not open buy position by symbol ",_Symbol);
               return;
              }
         if(signal==ORDER_TYPE_SELL)
            if(!ExtTrade.PositionOpen(_Symbol,signal,Lots,SymbolInfoDouble(_Symbol,SYMBOL_BID),
               SymbolInfoDouble(_Symbol,SYMBOL_BID)+NormalizeDouble(SL*_Point,_Digits),
               SymbolInfoDouble(_Symbol,SYMBOL_BID)-NormalizeDouble(TP*_Point,_Digits)))
              {
               Alert("Can not open sell position by symbol  ",_Symbol);
               return;
              }
        }
     }
  }
//+------------------------------------------------------------------+
//| Check for close position conditions                              |
//+------------------------------------------------------------------+
void CheckForClose(void)
  {
   MqlRates rt[2];
   double   ma[1];
   ma[0]=0;
   if(CopyRates(_Symbol,_Period,0,2,rt)!=2)
     {
      Alert("CopyRates of ",_Symbol," failed, no history");
      return;
     }
   switch(Type_MA)
     {
      case AMA:
        {
         if(CopyBuffer(AMA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from iAMA failed, no data");
            return;
           }
         break;
        }
      case DEMA:
        {
         if(CopyBuffer(DEMA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from iDEMA failed, no data");
            return;
           }
         break;
        }
      case FraMA:
        {
         if(CopyBuffer(FraMA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from iFraMA failed, no data");
            return;
           }
         break;
        }
      case MA:
        {
         if(CopyBuffer(MA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from iMA failed, no data");
            return;
           }
         break;
        }
      case TEMA:
        {
         if(CopyBuffer(TEMA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from iTEMA failed, no data");
            return;
           }
         break;
        }
      case VIDYA:
        {
         if(CopyBuffer(VIDYA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from iVIDYA failed, no data");
            return;
           }
         break;
        }
      case NRMA:
        {
         if(CopyBuffer(NRMA_Handle,0,0,1,ma)!=1)
           {
            Alert("CopyBuffer from NRMA failed, no data");
            return;
           }
         break;
        }
     }
   bool signal=false;
   long type=PositionGetInteger(POSITION_TYPE);

   if(type==(long)POSITION_TYPE_BUY && rt[0].open>ma[0] && rt[0].close<ma[0])
      signal=true;
   if(type==(long)POSITION_TYPE_SELL && rt[0].open<ma[0] && rt[0].close>ma[0])
      signal=true;
   if(signal)
     {
      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol,_Period)>100)
         ExtTrade.PositionClose(_Symbol,3);
     }
  }
int OnInit(void)
  {
   TP=TakeLevel;
   SL=StopLevel;
   if(_Digits==5 || _Digits==3)
     {
      TP = TP*10;
      SL = SL*10;
     }
//--- prepare trade class to control positions if hedging mode is active
   ExtHedging=((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   ExtTrade.SetExpertMagicNumber(MA_MAGIC);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(Symbol());
//initializing indicators and adding them to the chart
   switch(Type_MA)
     {
      case AMA:
        {
         AMA_Handle=iAMA(_Symbol,_Period,AMA_PeriodMA,AMA_PeriodFast,AMA_PeriodSlow,AMA_Shift,AMA_Applied);
         if(AMA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating AMA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,AMA_Handle))
           {
            Alert("Unable to add AMA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
      case DEMA:
        {
         DEMA_Handle=iDEMA(_Symbol,_Period,DEMA_PeriodMA,DEMA_Shift,DEMA_Applied);
         if(DEMA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating DEMA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,DEMA_Handle))
           {
            Alert("Unable to add DEMA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
      case FraMA:
        {
         FraMA_Handle=iFrAMA(_Symbol,_Period,FraMA_PeriodMA,FraMA_Shift,FraMA_Applied);
         if(DEMA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating FrAMA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,FraMA_Handle))
           {
            Alert("Unable to add FraMA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
      case MA:
        {
         MA_Handle=iMA(_Symbol,_Period,MA_PeriodMA,MA_Shift,MA_Method,MA_Applied);
         if(DEMA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating MA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,MA_Handle))
           {
            Alert("Unable to add MA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
      case TEMA:
        {
         TEMA_Handle=iTEMA(_Symbol,_Period,TEMA_PeriodMA,TEMA_Shift,TEMA_Applied);
         if(TEMA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating TEMA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,TEMA_Handle))
           {
            Alert("Unable to add TEMA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
      case VIDYA:
        {
         VIDYA_Handle=iVIDyA(_Symbol,_Period,VIDYA_InpPeriodCMO,VIDYA_InpPeriodEMA,VIDYA_InpShift,VIDYA_Applied);
         if(VIDYA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating VIDyA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,VIDYA_Handle))
           {
            Alert("Unable to add VIDyA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
      case NRMA:
        {
         NRMA_Handle=iCustom(_Symbol,_Period,"Examples\\nrma",NRMA_Method,XLength,XPhase,IPC,Kf,Fast,Sharp,Shift,PriceShift);
         if(NRMA_Handle==INVALID_HANDLE)
           {
            Alert("Error creating NRMA indicator");
            return(INIT_FAILED);
           }
         else
         if(!ChartIndicatorAdd(0,0,NRMA_Handle))
           {
            Alert("Unable to add NRMA indicator on the chart, the error number =",GetLastError());
            ResetLastError();
           }
         break;
        }
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   bool NewBar=false;
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0)
     {
      if(Old_Time!=New_Time[0])
        {
         NewBar=true;
         Old_Time=New_Time[0];
        }
      else
         return;
     }
   else
     {
      Alert("Error copying time, error number = ",GetLastError());
      ResetLastError();
      return;
     }
   if(NewBar)
     {
      NewBar=false;
      if(SelectPosition())
         CheckForClose();
      else
         CheckForOpen();
     }
  }
