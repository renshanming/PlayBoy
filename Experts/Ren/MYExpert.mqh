

#include "MyTrade.mqh"
#include "MySignalMACD.mqh"
#include "MySignalVIDYA.mqh"

class MyExpert
{
	MyTrade		trade;
	MySignalMACD trendSignalMACD;
	MySignalVIDYA trendSignalVIDYA;
public:
	MyExpert(void);
   	~MyExpert(void);
   	bool Init(ulong magic_number, double lots, double take_profit, double stop_loss);
   	bool Processing(void);
   	void OnTick(void);
};

MyExpert::MyExpert(void)
{
	
}

MyExpert::~MyExpert(void)
{
	trendSignalMACD.DeInit();
	trendSignalVIDYA.DeInit();
}
bool MyExpert::Init(ulong magic_number, double lots, double take_profit, double stop_loss)
{
	if(!trade.Init(magic_number, lots, take_profit, stop_loss))
		return false;
		
	if(!trendSignalMACD.Init())
		return(false);
	if(!trendSignalVIDYA.Init())
		return(false);
	//--- succeed
	return(true);
}
//+------------------------------------------------------------------+
//| Checking for input parameters                                    |
//+------------------------------------------------------------------+



bool MyExpert::Processing(void)
{
	static TREND_SIGNAL lastTrend = TREND_FLAT;
	if(!trade.IsTradeTime())
	{
		return false;
	}
	//--- refresh rates
	if(!trade.RefreshRates())
		return(false);
	TREND_SIGNAL trend = TREND_FLAT;
	TREND_SIGNAL trendMACD = trendSignalMACD.GetSignal();
	TREND_SIGNAL trendVIDYA = trendSignalVIDYA.GetSignal();
	//--- refresh indicators
	if(trend == TREND_FLAT)
		return(false);
	if(trendMACD == TREND_HARD_UP && trendVIDYA == TREND_UP)
	{
		trend = TREND_UP;
	}
	
	if(trendMACD == TREND_HARD_DOWN && trendVIDYA == TREND_DOWN)
	{
		trend = TREND_DOWN;
	}
	if(trend != lastTrend)
	{
		if(lastTrend != TREND_UP && trend == TREND_UP)
		{
			trade.OrderOpen(MY_ORDER_BUY);
			trade.OrderClose(MY_ORDER_BUY);
		}
		if(lastTrend != TREND_DOWN && trend == TREND_DOWN)
		{
			trade.OrderOpen(MY_ORDER_SELL);
			trade.OrderClose(MY_ORDER_SELL);
		}
		lastTrend = trend;
	}
	
	//--- exit without position processing
	return(false);
}


void MyExpert::OnTick(void)
{
	Processing();
}