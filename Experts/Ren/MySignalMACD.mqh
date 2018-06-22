#include "common.mqh"

class MySignalMACD
{
protected:
	int 				m_handle_macd;           // variable for storing the handle of the iMACD indicator
	int 				m_handle_ema;           // variable for storing the handle of the iMA indicator
	//--- adjusted parameters
	int               periodFast;    // the "period of fast EMA" parameter of the oscillator
	int               periodSlow;    // the "period of slow EMA" parameter of the oscillator
	int               periodSignal;  // the "period of averaging of difference" parameter of the oscillator
	ENUM_APPLIED_PRICE applied;       // the "price series" parameter of the oscillator
	int 			InpMATrendPeriod;
	double		indMACD[];
	double		indMACDSignal[];
	double 		macd[3];

public:
	                  MySignalMACD(void);
	                 ~MySignalMACD(void);
	//--- methods of setting adjustable parameters
	void              PeriodFast(int value)             { periodFast=value; }
	void              PeriodSlow(int value)             { periodSlow=value;  }
	void              PeriodSignal(int value)           { periodSignal=value; }
	void              Applied(ENUM_APPLIED_PRICE value) { applied=value; }
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetMACD(double &buffer[], int amount);

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalMACD::MySignalMACD(void) : m_handle_macd(INVALID_HANDLE),
								 m_handle_ema(INVALID_HANDLE),
								 periodFast(12),
                                 periodSlow(26),
                                 periodSignal(9),
                                 applied(PRICE_CLOSE),
                                 InpMATrendPeriod(26)
{
	macd[0] = 0.0;
	macd[1] = 0.0;
	macd[2] = 0.0;
	ArraySetAsSeries(indMACD,true);
	ArraySetAsSeries(indMACDSignal,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalMACD::~MySignalMACD(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize MACD oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalMACD::Init(void)
{
	//--- create MACD indicator
	if(m_handle_macd==INVALID_HANDLE)
		if((m_handle_macd=iMACD(Symbol(),Period(),periodFast,periodSlow,periodSignal,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating MACD indicator");
			return(false);
		}
	//--- create EMA indicator and add it to collection
	if(m_handle_ema==INVALID_HANDLE)
		if((m_handle_ema=iMA(Symbol(),Period(),InpMATrendPeriod,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating EMA indicator");
			return(false);
		}
	return true;
}

void MySignalMACD::DeInit(void)
{
	//	删除指标句柄:
	if(m_handle_macd!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_macd);
	}
	
	if(m_handle_ema!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_ema);
	}
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
TREND_SIGNAL MySignalMACD::GetSignal(void)
{
	if(!GetMACD(indMACD, 4))
	{
		return TREND_FLAT;
	}
	macd[0] = indMACD[1];
	macd[1] = indMACD[2];
	macd[2] = indMACD[3];
	
	if(macd[0] < macd[1] && macd[1] > macd[2] && macd[0]>0.0003)
	{
		return TREND_HARD_DOWN;
	}
	
	if(macd[0] < macd[1] && macd[1] < macd[2] && macd[0]>0)
	{
		return TREND_DOWN;
	}
	
	if(macd[0] < macd[1] && macd[1] < macd[2] && macd[0]<0)
	{
		return TREND_SOFT_DOWN;
	}
	
	if(macd[0] > macd[1] && macd[1] < macd[2] && macd[0]<-0.0003)
	{
		return TREND_HARD_UP;
	}
	
	if(macd[0] > macd[1] && macd[1] > macd[2] && macd[0]<0)
	{
		return TREND_UP;
	}
	
	if(macd[0] > macd[1] && macd[1] > macd[2] && macd[0]>0)
	{
		return TREND_SOFT_UP;
	}
	
	return TREND_FLAT;
}

bool MySignalMACD::GetMACD(double &buffer[], int amount)
{
	ResetLastError(); //--- 重置错误代码 
	if(CopyBuffer(m_handle_macd,0,0,amount, buffer)<0) 
	{ 
		PrintFormat("Failed to copy data from the MACD indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	
	return(true);
}
//+------------------------------------------------------------------+
