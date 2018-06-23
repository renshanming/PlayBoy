#include "common.mqh"

class MySignalFraSMA
{
protected:
	int 	handle;
	int 	ma_period;			// 平均移动周期
	double	FraSMA[];
	ENUM_TIMEFRAMES      period;        // 时间帧 
	ENUM_APPLIED_PRICE   applied_price;  // 价格类型
	uint     e_period;
	uint     normal_speed;
	int      Shift;
	int      PriceShift;
	int      PIP_Convertor;

public:
	MySignalFraSMA(void);
	~MySignalFraSMA(void);
	void Applied(ENUM_APPLIED_PRICE value) { applied_price=value; }
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetFraSMA(double &buffer[], int ind_handle, int amount);

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalFraSMA::MySignalFraSMA(void) : handle(INVALID_HANDLE),
							   ma_period(14),
							   period(PERIOD_CURRENT),
							   applied_price(PRICE_CLOSE),
							   e_period(64),
							   normal_speed(30),
							   Shift(0),
							   PriceShift(0),
							   PIP_Convertor(1)
{
	ArraySetAsSeries(FraSMA,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalFraSMA::~MySignalFraSMA(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize FraSMA oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalFraSMA::Init(void)
{
	//--- create FraSMA indicator
	if(handle==INVALID_HANDLE)
		if((handle=iCustom(Symbol(),period,"Network\\RS_FraSMA",e_period,normal_speed, applied_price, Shift,PriceShift,PIP_Convertor))==INVALID_HANDLE)
		{
			printf("Error creating FraSMA indicator");
			return(false);
		}
	return true;
}

void MySignalFraSMA::DeInit(void)
{
	//	删除指标句柄:
	if(handle!=INVALID_HANDLE)
	{
		IndicatorRelease(handle);
	}
}

TREND_SIGNAL MySignalFraSMA::GetSignal(void)
{
	if(!GetFraSMA(FraSMA,handle,4))
	{
		return TREND_FLAT;
	}
	
	if(FraSMA[1] > FraSMA[2])
	{
		return TREND_UP;
	}
	else if(FraSMA[1] < FraSMA[2])
	{
		return TREND_DOWN;
	}
	return TREND_FLAT;
}

bool MySignalFraSMA::GetFraSMA(double &buffer[], int ind_handle, int amount)
{
	ResetLastError(); //--- 重置错误代码 
	if(CopyBuffer(ind_handle,0,0,amount,buffer)<0) //--- 以0标引指标缓冲区的值填充部分Buffer 数组 
	{ 
		PrintFormat("Failed to copy data from the FraSMA indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	
	return(true); 
}
//+------------------------------------------------------------------+
