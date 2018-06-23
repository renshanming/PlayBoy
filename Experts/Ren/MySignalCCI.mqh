#include "common.mqh"

class MySignalCCI
{
protected:
	int 	handle;
	int 	ma_period;			// 平均移动周期
	double	CCI[];
	ENUM_TIMEFRAMES      period;        // 时间帧 
	ENUM_APPLIED_PRICE   applied_price;  // 价格类型

public:
	                  MySignalCCI(void);
	                 ~MySignalCCI(void);
	void              Applied(ENUM_APPLIED_PRICE value) { applied_price=value; }
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetCCI(double &buffer[], int ind_handle, int amount);

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalCCI::MySignalCCI(void) : handle(INVALID_HANDLE),
							   ma_period(14),
							   period(PERIOD_CURRENT),
							   applied_price(PRICE_TYPICAL)
{
	ArraySetAsSeries(CCI,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalCCI::~MySignalCCI(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize CCI oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalCCI::Init(void)
{
	//--- create CCI indicator
	if(handle==INVALID_HANDLE)
		if((handle=iCCI(Symbol(),period,ma_period,applied_price))==INVALID_HANDLE)
		{
			printf("Error creating CCI indicator");
			return(false);
		}

	return true;
}

void MySignalCCI::DeInit(void)
{
	//	删除指标句柄:
	if(handle!=INVALID_HANDLE)
	{
		IndicatorRelease(handle);
	}
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
TREND_SIGNAL MySignalCCI::GetSignal(void)
{
	if(!GetCCI(CCI,handle,4))
	{
		return TREND_FLAT;
	}

	//if(CCI[1]<CCI[2] && CCI[2]>CCI[3] && CCI[1] > 150)
	if(CCI[1] > 100)
	{
		return TREND_DOWN;
	}
	//if(CCI[1]>CCI[2] && CCI[2]<CCI[3] && CCI[1] < -150)
	if(CCI[1] < -100)
	{
		return TREND_UP;
	}
	return TREND_FLAT;
}

bool MySignalCCI::GetCCI(double &buffer[], int ind_handle, int amount)
{
	ResetLastError(); //--- 重置错误代码 
	if(CopyBuffer(ind_handle,0,0,amount,buffer)<0) //--- 以0标引指标缓冲区的值填充部分Buffer 数组 
	{ 
		PrintFormat("Failed to copy data from the CCI indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	
	return(true);
}
//+------------------------------------------------------------------+
