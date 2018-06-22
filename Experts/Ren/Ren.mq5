//+------------------------------------------------------------------+
//|                                                          Ren.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include "MyExpertMACD.mqh"
#include "MyExpertVIDYA.mqh"
#include "MyExpertTEMA.mqh"
#include "MyExpertEMA.mqh"
#include "MyExpertMA.mqh"
#include "MyExpert.mqh"

input ulong  MagicNumber	  = 1863473;
input double InpLots          = 0.1; // Lots
//input int    InpTakeProfit    = 60;  // Take Profit (in pips)
input int    InpTakeProfit    = 0.0;  // Take Profit (in pips)
//input int    InpTrailingStop  = 160;  // Trailing Stop Level (in pips)
input int    InpTrailingStop  = 0.0;  // Trailing Stop Level (in pips)

//MyExpertMACD expert;
//MyExpert expert;
//MyExpertTEMA expert;
//MyExpertVIDYA expert;
//MyExpertEMA expert;
MyExpertMA expert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
	if(!expert.Init(MagicNumber, InpLots, InpTakeProfit, InpTrailingStop))
	{
		return INIT_FAILED;
	}
	return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
	
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
	expert.OnTick();
}
//+------------------------------------------------------------------+
