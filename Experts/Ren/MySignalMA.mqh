#include "common.mqh"

class MySignalMA
{
protected:
	int 				m_handle_MA_fast;           // variable for storing the handle of the iMA indicator
	int 				m_handle_MA_slow;           // variable for storing the handle of the iMA indicator
	//--- adjusted parameters
	int               periodFast;    // the "period of fast MA" parameter of the oscillator
	int               periodSlow;    // the "period of slow MA" parameter of the oscillator
	int 				MovingShift;
	ENUM_APPLIED_PRICE applied;       // the "price series" parameter of the oscillator
	double		MA_fast[];
	double		MA_slow[];
	CSymbolInfo    m_symbol;                     // symbol info object

public:
	                  MySignalMA(void);
	                 ~MySignalMA(void);
	void              Applied(ENUM_APPLIED_PRICE value) { applied=value; }
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	double iMAGet(int handle_iMA,const int index);

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalMA::MySignalMA(void) : m_handle_MA_fast(INVALID_HANDLE),
								 m_handle_MA_slow(INVALID_HANDLE),
								 periodFast(14),
                                 periodSlow(79),
                                 MovingShift(4),
                                 applied(PRICE_CLOSE)
{
	ArraySetAsSeries(MA_fast,true);
	ArraySetAsSeries(MA_slow,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalMA::~MySignalMA(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize MA oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalMA::Init(void)
{
	//--- create MA indicator
	if(m_handle_MA_fast==INVALID_HANDLE)
		if((m_handle_MA_fast=iMA(Symbol(),PERIOD_M1,periodFast,MovingShift,MODE_SMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating MA indicator");
			return(false);
		}
	if(m_handle_MA_slow==INVALID_HANDLE)
		if((m_handle_MA_slow=iMA(Symbol(),PERIOD_M1,periodSlow,MovingShift,MODE_SMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating MA indicator");
			return(false);
		}

	return true;
}

void MySignalMA::DeInit(void)
{
	//	É¾³ýÖ¸±ê¾ä±ú:
	if(m_handle_MA_fast!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_MA_fast);
	}
	
	if(m_handle_MA_slow!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_MA_slow);
	}
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
TREND_SIGNAL MySignalMA::GetSignal(void)
{
	double FastMa=iMAGet(m_handle_MA_fast,0);
	double FastMa2 = iMAGet(m_handle_MA_fast, 2);
	double FastMa5 = iMAGet(m_handle_MA_fast, 5);
	double SlowMa = iMAGet(m_handle_MA_slow,0);
	double SlowMa2 = iMAGet(m_handle_MA_slow, 2);
	double SlowMa5 = iMAGet(m_handle_MA_slow, 5);
	double open = iOpen(Symbol(), Period(), 1);
	double close = iClose(Symbol(), Period(), 1);
	
	//---- sell conditions
	if((SlowMa-FastMa)>=m_symbol.Point() && (FastMa2-SlowMa2)>=m_symbol.Point() && 
		(FastMa5-SlowMa5)>=m_symbol.Point() && close<open)
	{
		return TREND_DOWN;
	}
	//---- buy conditions
	if((FastMa-SlowMa)>=m_symbol.Point() && (SlowMa2-FastMa2)>=m_symbol.Point() && 
		(SlowMa5-FastMa5)>=m_symbol.Point() && close>open)
	{
		return TREND_UP;
	}

	return TREND_FLAT;
}

//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double MySignalMA::iMAGet(int handle_iMA,const int index)
{
	double MA[1];
	//--- reset error code 
	ResetLastError();
	//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
	if(CopyBuffer(handle_iMA,0,index,1,MA)<0)
	{
		//--- if the copying fails, tell the error code 
		PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
		//--- quit with zero result - it means that the indicator is considered as not calculated 
		return(0.0);
	}
	return(MA[0]);
}
//+------------------------------------------------------------------+
