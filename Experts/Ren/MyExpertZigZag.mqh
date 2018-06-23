
#include "MySignalZigZag.mqh"
#include "MyTrade.mqh"

class MyExpertZigZag
{
	MyTrade		trade;
	MySignalZigZag trendSignal;
public:
	MyExpertZigZag(void);
   	~MyExpertZigZag(void);
   	bool Init(ulong magic_number, double lots, double take_profit, double stop_loss);
   	bool Processing(void);
   	void OnTick(void);
};

MyExpertZigZag::MyExpertZigZag(void)
{
	
}

MyExpertZigZag::~MyExpertZigZag(void)
{
	trendSignal.DeInit();
}
bool MyExpertZigZag::Init(ulong magic_number, double lots, double take_profit, double stop_loss)
{
	if(!trade.Init(magic_number, lots, take_profit, stop_loss))
		return false;
		
	if(!trendSignal.Init())
		return(false);
	//--- succeed
	return(true);
}
//+------------------------------------------------------------------+
//| Checking for input parameters                                    |
//+------------------------------------------------------------------+



bool MyExpertZigZag::Processing(void)
{
	static TREND_SIGNAL lastTrend = TREND_FLAT;
	if(!trade.IsTradeTime())
	{
		return false;
	}
	//--- refresh rates
	if(!trade.RefreshRates())
		return(false);
		
	TREND_SIGNAL trend = trendSignal.GetSignal();
	//--- refresh indicators
	if(trend == TREND_FLAT)
		return(false);

	if(trend != lastTrend)
	{
		if(lastTrend != TREND_UP && trend == TREND_UP)
		{
			trade.OrderClose(MY_ORDER_BUY);
			trade.OrderOpen(MY_ORDER_BUY);
		}
		if(lastTrend != TREND_DOWN && trend == TREND_DOWN)
		{
			trade.OrderClose(MY_ORDER_SELL);
			trade.OrderOpen(MY_ORDER_SELL);
		}
		lastTrend = trend;
	}
	
	//--- exit without position processing
	return(false);
}


void MyExpertZigZag::OnTick(void)
{
	Processing();
}