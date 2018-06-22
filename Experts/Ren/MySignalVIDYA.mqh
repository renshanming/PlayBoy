#include "common.mqh"

class MySignalVIDYA
{
protected:
	int 				m_handle_vidya;           // variable for storing the handle of the ividya indicator
	//--- adjusted parameters
	int               cmo_period;    // the "period of fast EMA" parameter of the oscillator
	int               ema_period;    // the "period of slow EMA" parameter of the oscillator
	int               ma_shift;  // the "period of averaging of difference" parameter of the oscillator
	ENUM_APPLIED_PRICE applied_price;       // the "price series" parameter of the oscillator
	int 			InpMATrendPeriod;
	double		indVIDyA[];
	double		indVIDyASignal[];
	
public:
	MySignalVIDYA(void);
	~MySignalVIDYA(void);
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	TREND_SIGNAL GetSignal1(void);
	bool GetVIDYA(double &vidya_buffer[],// 变量指数动态平均值的指标缓冲区 
                 int v_shift,           // 线的移动  
                 int ind_handle,        // iVIDyA指标的处理程序 
                 int amount             // 复制值的数量 
                 );
	double GetHigh();
	double GetLow();
	double GetOpen();
	double GetClose();

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalVIDYA::MySignalVIDYA(void) : m_handle_vidya(INVALID_HANDLE),
								 cmo_period(12),
                                 ema_period(26),
                                 ma_shift(9),
                                 applied_price(PRICE_CLOSE),
                                 InpMATrendPeriod(26)
{
	ArraySetAsSeries(indVIDyA,true);
	ArraySetAsSeries(indVIDyASignal,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalVIDYA::~MySignalVIDYA(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize vidya oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalVIDYA::Init(void)
{
	//--- create vidya indicator
	if(m_handle_vidya==INVALID_HANDLE)
		if((m_handle_vidya=iVIDyA(Symbol(),Period(),cmo_period,ema_period,ma_shift,applied_price))==INVALID_HANDLE)
		{
			printf("Error creating VIDyA indicator");
			return(false);
		}
	
	return true;
}

void MySignalVIDYA::DeInit(void)
{
	//	删除指标句柄:
	if(m_handle_vidya!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_vidya);
	}
}

TREND_SIGNAL MySignalVIDYA::GetSignal1(void)
{
	static int upCnt = 0;
	static int downCnt = 0;
	static int flatCnt = 0;
	static TREND_SIGNAL lastTrend = TREND_FLAT;
	TREND_SIGNAL trend = TREND_FLAT;
	double high = GetHigh();
	double low = GetLow();
	double open = GetOpen();
	double close = GetClose();
	double vidya = 0.0;
	static double lastVidya = 0.0;
	if(!GetVIDYA(indVIDyA,ma_shift,m_handle_vidya,cmo_period))
	{
		return TREND_FLAT;
	}
	vidya = indVIDyA[cmo_period-2];
	if(lastVidya == vidya)
	{
		return TREND_FLAT;
	}
	lastVidya = vidya;
	if(close > open)
	{
		if(vidya > close) // trend down
		{
			downCnt++;
		}
		else if(vidya >= open) // trend flat
		{
			flatCnt++;
			upCnt = 0;
		}
		else // trend up
		{
			upCnt++;
		}
	}
	if(close < open)
	{
		if(vidya < close) // trend up
		{
			upCnt++;
		}
		else if(vidya <= open) // trend flat
		{
			flatCnt++;
			downCnt = 0;
		}
		else // trend down
		{
			downCnt++;
		}
	}
	
	if(lastTrend != TREND_DOWN)
	{
		if(upCnt >= 5 && downCnt == 1 && flatCnt == 1)
		{
			lastTrend = TREND_DOWN;
			upCnt = 0;
			flatCnt = 0;
			return lastTrend;
		}	
	}
	if(lastTrend != TREND_UP)
	{
		if(downCnt >= 5 && upCnt == 1 && flatCnt == 1)
		{
			lastTrend = TREND_UP;
			downCnt = 0;
			flatCnt = 0;
			return lastTrend;
		}	
	}
	
	return lastTrend;
}

TREND_SIGNAL MySignalVIDYA::GetSignal(void)
{
	static TREND_SIGNAL lastTrend = TREND_FLAT;
	TREND_SIGNAL trend = TREND_FLAT;
	double high = GetHigh();
	double low = GetLow();
	double open = GetOpen();
	double close = GetClose();
	double vidya = 0.0;
	static double lastVidya = 0.0;
	if(!GetVIDYA(indVIDyA,ma_shift,m_handle_vidya,cmo_period))
	{
		return TREND_FLAT;
	}
	vidya = indVIDyA[cmo_period-2];
	if(lastVidya == vidya)
	{
		return TREND_FLAT;
	}
	lastVidya = vidya;
	if(close > open)
	{
		if(vidya > close) // trend down
		{
			trend = TREND_DOWN;
		}
		else if(vidya >= open) // trend flat
		{
			trend = TREND_FLAT;
		}
		else // trend up
		{
			trend = TREND_UP;
		}
	}
	if(close < open)
	{
		if(vidya < close) // trend up
		{
			trend = TREND_UP;
		}
		else if(vidya <= open) // trend flat
		{
			trend = TREND_FLAT;
		}
		else // trend down
		{
			trend = TREND_DOWN;
		}
	}
	
	if(lastTrend != TREND_DOWN)
	{
		if(trend == TREND_DOWN)
		{
			lastTrend = TREND_DOWN;
			return lastTrend;
		}	
	}
	if(lastTrend != TREND_UP)
	{
		if(trend == TREND_UP)
		{
			lastTrend = TREND_UP;
			return lastTrend;
		}	
	}
	
	return trend;
}

bool MySignalVIDYA::GetVIDYA(double &vidya_buffer[],// 变量指数动态平均值的指标缓冲区 
                         int v_shift,           // 线的移动  
                         int ind_handle,        // iVIDyA指标的处理程序 
                         int amount             // 复制值的数量 
                         ) 
{ 
	//--- 重置错误代码 
	ResetLastError(); 
	//--- 以0标引指标缓冲区的值填充部分iVIDyABuffer 数组 
	if(CopyBuffer(ind_handle,0,-v_shift,amount,vidya_buffer)<0) 
	{ 
		PrintFormat("Failed to copy data from the iVIDyA indicator, error code %d",GetLastError());
		return(false); 
	} 
	//--- 一切顺利 
	return(true); 
}

double MySignalVIDYA::GetHigh()
{
	return iHigh(Symbol(), Period(), 1);
}

double MySignalVIDYA::GetLow()
{
	return iLow(Symbol(), Period(), 1);
}

double MySignalVIDYA::GetOpen()
{
	return iOpen(Symbol(), Period(), 1);
}

double MySignalVIDYA::GetClose()
{
	return iClose(Symbol(), Period(), 1);
}

//+------------------------------------------------------------------+
