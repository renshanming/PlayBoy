#include "common.mqh"

class MySignalZigZag
{
protected:
	int 	handle;
	int 	ma_period;			// 平均移动周期
	double	ZigzagHigh[];
	double	ZigzagLow[];
	double	Zigzag[];
	ENUM_TIMEFRAMES      period;        // 时间帧 
	ENUM_APPLIED_PRICE   applied_price;  // 价格类型
	TREND_SIGNAL trend;
	double lastZigzagHigh;
	double lastZigzagLow;

	int   Depth;
	int   Deviation;
	int   Backstep;
	int 	trend_cnt;
	int   lastSignal;

public:
	MySignalZigZag(void);
	~MySignalZigZag(void);
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetZigZag(double &high_buffer[], double &low_buffer[], double &base_buffer[], int ind_handle, int amount);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalZigZag::MySignalZigZag(void) : ma_period(14),
							   period(PERIOD_CURRENT),
							   applied_price(PRICE_TYPICAL),
							   trend(TREND_FLAT),
							   Depth(7),
							   Deviation(5),
							   Backstep(3),
							   lastZigzagHigh(0.0),
							   lastZigzagLow(0.0),
							   trend_cnt(1),
							   lastSignal(0)
{
	ArraySetAsSeries(ZigzagHigh,true);
	ArraySetAsSeries(ZigzagLow,true);
	ArraySetAsSeries(Zigzag,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalZigZag::~MySignalZigZag(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize ZigZag oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalZigZag::Init(void)
{
	//--- create ZigZag indicator
	if(handle==INVALID_HANDLE)
		if((handle=iCustom(Symbol(),period,"Examples\\ZigZag",Depth,Deviation,Backstep))==INVALID_HANDLE)
		{
			printf("Error creating ZigZag indicator");
			return(false);
		}
	return true;
}

void MySignalZigZag::DeInit(void)
{
	//	删除指标句柄:
	if(handle!=INVALID_HANDLE)
	{
		IndicatorRelease(handle);
	}
}

TREND_SIGNAL MySignalZigZag::GetSignal(void)
{
	int signal = 0;
	if(!GetZigZag(ZigzagHigh, ZigzagLow, Zigzag, handle, 3))
	{
		return TREND_FLAT;
	}

	if(Zigzag[1] > 0.0)
	{
		if(ZigzagHigh[1] == Zigzag[1])
		{
			signal = -1;
		}
		if(ZigzagLow[1] == Zigzag[1])
		{
			signal = 1;
		}
	}

	if(ZigzagLow[1] != lastZigzagLow)
	{
		PrintFormat("ZigzagLow change to %f", ZigzagLow[1]);
		lastZigzagLow = ZigzagLow[1];
		if(lastZigzagLow > 0.0)
		{
			if(lastSignal != signal)
			{
				lastSignal = signal;
				trend_cnt = 1;
			}
			else
			{
				trend_cnt = trend_cnt + 1;
			}
			return TREND_UP;
		}
	}

	if(ZigzagHigh[1] != lastZigzagHigh)
	{
		PrintFormat("ZigzagHigh change to %f", ZigzagHigh[1]);
		lastZigzagHigh = ZigzagHigh[1];
		if(lastZigzagHigh > 0.0)
		{
			if(lastSignal != signal)
			{
				lastSignal = signal;
				trend_cnt = 1;
			}
			else
			{
				trend_cnt = trend_cnt + 1;
			}
			return TREND_DOWN;
		}
	}

	return TREND_FLAT;
}

bool MySignalZigZag::GetZigZag(double &high_buffer[], double &low_buffer[], double &base_buffer[], int ind_handle, int amount)
{
	ResetLastError(); //--- 重置错误代码 

	if(CopyBuffer(ind_handle,0,0,amount,base_buffer)<0) //--- 以0标引指标缓冲区的值填充部分Buffer 数组 
	{ 
		PrintFormat("Failed to copy data from the IndBuff indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}

	if(CopyBuffer(ind_handle,1,0,amount,high_buffer)<0) //--- 以0标引指标缓冲区的值填充部分Buffer 数组 
	{ 
		PrintFormat("Failed to copy data from the IndBuff indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	
	if(CopyBuffer(ind_handle,2,0,amount,low_buffer)<0) //--- 以0标引指标缓冲区的值填充部分Buffer 数组 
	{ 
		PrintFormat("Failed to copy data from the IndBuff indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}

	return(true); 
}
//+------------------------------------------------------------------+
