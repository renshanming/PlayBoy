#include "common.mqh"

class MySignalEMA
{
protected:
	int 				m_handle_ema_fast;           // variable for storing the handle of the iMA indicator
	int 				m_handle_ema_slow;           // variable for storing the handle of the iMA indicator
	int 				m_handle_ema_long;           // variable for storing the handle of the iMA indicator
	//--- adjusted parameters
	int               periodFast;    // the "period of fast EMA" parameter of the oscillator
	int               periodSlow;    // the "period of slow EMA" parameter of the oscillator
	int               periodLong;  // the "period of averaging of difference" parameter of the oscillator
	ENUM_APPLIED_PRICE applied;       // the "price series" parameter of the oscillator
	double		ema_fast[];
	double		ema_slow[];
	double 		ema_long[];

public:
	                  MySignalEMA(void);
	                 ~MySignalEMA(void);
	void              Applied(ENUM_APPLIED_PRICE value) { applied=value; }
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetEMA(double &ema_fast_buffer[], double &ema_slow_buffer[], double &ema_long_buffer[],int amount);

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalEMA::MySignalEMA(void) : m_handle_ema_fast(INVALID_HANDLE),
								 m_handle_ema_slow(INVALID_HANDLE),
								 m_handle_ema_long(INVALID_HANDLE),
								 periodFast(12),
                                 periodSlow(26),
                                 periodLong(200),
                                 applied(PRICE_CLOSE)
{
	ArraySetAsSeries(ema_fast,true);
	ArraySetAsSeries(ema_slow,true);
	ArraySetAsSeries(ema_long,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalEMA::~MySignalEMA(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize EMA oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalEMA::Init(void)
{
	//--- create EMA indicator
	if(m_handle_ema_fast==INVALID_HANDLE)
		if((m_handle_ema_fast=iMA(Symbol(),Period(),periodFast,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating EMA indicator");
			return(false);
		}
	if(m_handle_ema_slow==INVALID_HANDLE)
		if((m_handle_ema_slow=iMA(Symbol(),Period(),periodSlow,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating EMA indicator");
			return(false);
		}
	if(m_handle_ema_long==INVALID_HANDLE)
		if((m_handle_ema_long=iMA(Symbol(),Period(),periodLong,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating EMA indicator");
			return(false);
		}
	return true;
}

void MySignalEMA::DeInit(void)
{
	//	删除指标句柄:
	if(m_handle_ema_fast!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_ema_fast);
	}
	
	if(m_handle_ema_slow!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_ema_slow);
	}
	
	if(m_handle_ema_long!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_ema_long);
	}
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
TREND_SIGNAL MySignalEMA::GetSignal(void)
{
	if(!GetEMA(ema_fast, ema_slow, ema_long, 3))
	{
		return TREND_FLAT;
	}
	
	// 死叉
	if(ema_fast[1] < ema_slow[1] && ema_fast[2] > ema_slow[2])
	{
		return TREND_DOWN;
	}
	
	// 金叉
	if(ema_fast[1] > ema_slow[1] && ema_fast[2] < ema_slow[2])
	{
		return TREND_UP;
	}
	return TREND_FLAT;
}

bool MySignalEMA::GetEMA(double &ema_fast_buffer[], double &ema_slow_buffer[], double &ema_long_buffer[],int amount)
{
	ResetLastError(); //--- 重置错误代码 
	if(CopyBuffer(m_handle_ema_fast,0,0,amount, ema_fast_buffer)<0) 
	{ 
		PrintFormat("Failed to copy data from the EMA indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	if(CopyBuffer(m_handle_ema_slow,0,0,amount, ema_slow_buffer)<0) 
	{ 
		PrintFormat("Failed to copy data from the EMA indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	if(CopyBuffer(m_handle_ema_long,0,0,amount, ema_long_buffer)<0) 
	{ 
		PrintFormat("Failed to copy data from the EMA indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	return(true);
}
//+------------------------------------------------------------------+
