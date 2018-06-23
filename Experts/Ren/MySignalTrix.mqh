#include "common.mqh"

class MySignalTrix
{
protected:
	int 	handle;
	int     InpPeriodEMA;               // EMA period
	//--- indicator buffers
	double	TRIX_Buffer[];
	int direction;
	int first;
	TREND_SIGNAL lastTrendSignal;
	int point_gain;
	double Trix[3];
	double lastTrix[3];

public:
	MySignalTrix(void);
	~MySignalTrix(void);
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetTrix(double &buffer[], int ind_handle, int amount);
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalTrix::MySignalTrix(void) : InpPeriodEMA(13),
								 handle(INVALID_HANDLE),
								 direction(0),
								 first(0),
								 lastTrendSignal(TREND_FLAT),
								 point_gain(1000000)
{
	Trix[0] = 0.0;
	Trix[1] = 0.0;
	Trix[2] = 0.0;
	lastTrix[0] = 0.0;
	lastTrix[1] = 0.0;
	lastTrix[2] = 0.0;
	ArraySetAsSeries(TRIX_Buffer,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalTrix::~MySignalTrix(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize Trix oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalTrix::Init(void)
{
	//--- create Trix indicator
	if(handle==INVALID_HANDLE)
		if((handle=iTriX(Symbol(),PERIOD_CURRENT,InpPeriodEMA,PRICE_CLOSE))==INVALID_HANDLE)
		{
			printf("Error creating Trix indicator");
			return(false);
		}
	return true;
}

void MySignalTrix::DeInit(void)
{
	//	删除指标句柄:
	if(handle!=INVALID_HANDLE)
	{
		IndicatorRelease(handle);
	}
}

TREND_SIGNAL MySignalTrix::GetSignal(void)
{
	int trix[3];
	if(!GetTrix(TRIX_Buffer,handle,4))
	{
		return TREND_FLAT;
	}

	trix[0] = (int)(TRIX_Buffer[1] * point_gain);
	trix[1] = (int)(TRIX_Buffer[2] * point_gain);
	trix[2] = (int)(TRIX_Buffer[3] * point_gain);

	if(lastTrix[0] == trix[0] || lastTrix[1] == trix[1] || lastTrix[2] == trix[2])
	{
		return TREND_FLAT;
	}
	lastTrix[0] = trix[0];
	lastTrix[1] = trix[1];
	lastTrix[2] = trix[2];
	if(trix[0] < trix[1] && trix[1] >= trix[2] && trix[0] > 0)
	//if(trix[0] < trix[1] && trix[1] >= trix[2])
	//if(TRIX_Buffer[0] < TRIX_Buffer[1])
	{
		return TREND_DOWN;
	}
	else if(trix[0] > trix[1] && trix[1] <= trix[2] && trix[0] < 0)
	//else if(trix[0] > trix[1] && trix[1] <= trix[2])
	//else if(TRIX_Buffer[0] > TRIX_Buffer[1])
	{
		return TREND_UP;
	}
	else
	{
		return TREND_FLAT;
	}
	return TREND_FLAT;
}

bool MySignalTrix::GetTrix(double &buffer[], int ind_handle, int amount)
{
	ResetLastError(); //--- 重置错误代码 
	if(CopyBuffer(ind_handle,0,0,amount,buffer)<0) //--- 以0标引指标缓冲区的值填充部分Buffer 数组 
	{ 
		PrintFormat("Failed to copy data from the Trix indicator, error code %d",GetLastError());//--- 如果复制失败，显示错误代码 
		return(false); //--- 退出零结果 - 它表示被认为是不计算的指标 
	}
	
	return(true); 
}
//+------------------------------------------------------------------+
