#include "common.mqh"

class MySignalTEMA
{
protected:
	int 			  m_handle_TEMA;           // variable for storing the handle of the iTEMA indicator
	int               ma_period;    // 平均周期
	int               ma_shift;  	// 移动
	ENUM_APPLIED_PRICE applied_price;       // the "price series" parameter of the oscillator
	double		indTEMA[];
	double 		lastLow;
	double 		newLow;
	double 		lastHigh;
	double		newHigh;
	
public:
	MySignalTEMA(void);
	~MySignalTEMA(void);
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetTEMA(double &TEMA_buffer[],// 变量指数动态平均值的指标缓冲区 
                 int v_shift,           // 线的移动  
                 int ind_handle,        // iTEMA指标的处理程序 
                 int amount             // 复制值的数量 
                 );

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalTEMA::MySignalTEMA(void) : m_handle_TEMA(INVALID_HANDLE),
                                 ma_period(14),
                                 ma_shift(0),
                                 applied_price(PRICE_CLOSE),
                                 lastLow(0.0),
                                 newLow(0.0),
                                 lastHigh(0.0),
                                 newHigh(0.0)
{
	ArraySetAsSeries(indTEMA,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalTEMA::~MySignalTEMA(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize TEMA oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalTEMA::Init(void)
{
	//--- create TEMA indicator
	if(m_handle_TEMA==INVALID_HANDLE)
		if((m_handle_TEMA=iTEMA(Symbol(),Period(),ma_period,ma_shift,applied_price))==INVALID_HANDLE)
		{
			printf("Error creating TEMA indicator");
			return(false);
		}
	
	return true;
}

void MySignalTEMA::DeInit(void)
{
	//	删除指标句柄:
	if(m_handle_TEMA!=INVALID_HANDLE)
	{
		IndicatorRelease(m_handle_TEMA);
	}
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
TREND_SIGNAL MySignalTEMA::GetSignal(void)
{
	static TREND_SIGNAL lastTrend = TREND_FLAT;
	if(!GetTEMA(indTEMA,ma_shift,m_handle_TEMA,4))
	{
		return TREND_FLAT;
	}
	double diff = MathAbs(indTEMA[1] - indTEMA[2]);
	if(indTEMA[1] > indTEMA[2] && indTEMA[2] < indTEMA[3] && diff > 0.0002)
	{
		if(indTEMA[1] < lastLow)
		{
			lastLow = indTEMA[1];
			return TREND_UP;
		}
	}
	
	if(indTEMA[1] < indTEMA[2] && indTEMA[2] > indTEMA[3] && diff > 0.0002)
	{
		if(indTEMA[1] > lastHigh)
		{
			lastHigh = indTEMA[1];
			return TREND_DOWN;
		}
	}
	if(indTEMA[1] > indTEMA[2] && indTEMA[2] > indTEMA[3])
	{
		lastTrend = TREND_UP;
		return lastTrend;
	}
	if(indTEMA[1] < indTEMA[2] && indTEMA[2] < indTEMA[3])
	{
		lastTrend = TREND_DOWN;
		return lastTrend;
	}

	return TREND_FLAT;
}

bool MySignalTEMA::GetTEMA(double &TEMA_buffer[],// 变量指数动态平均值的指标缓冲区 
                         int shift,           // 线的移动  
                         int ind_handle,        // iTEMA指标的处理程序 
                         int amount             // 复制值的数量 
                         ) 
{ 
	//--- 重置错误代码 
	ResetLastError(); 
	//--- 以0标引指标缓冲区的值填充部分iTEMABuffer 数组 
	if(CopyBuffer(ind_handle,0,-shift,amount,TEMA_buffer)<0) 
	{ 
		PrintFormat("Failed to copy data from the iTEMA indicator, error code %d",GetLastError());
		return(false); 
	} 
	//--- 一切顺利 
	return(true); 
}
