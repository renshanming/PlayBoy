#include "common.mqh"

class MySignalCCI
{
protected:
	int 	handle;
	int 	ma_period;			// ƽ���ƶ�����
	double	CCI[];
	ENUM_TIMEFRAMES      period;        // ʱ��֡ 
	ENUM_APPLIED_PRICE   applied_price;  // �۸�����

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
	//	ɾ��ָ����:
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
	ResetLastError(); //--- ���ô������ 
	if(CopyBuffer(ind_handle,0,0,amount,buffer)<0) //--- ��0����ָ�껺������ֵ��䲿��Buffer ���� 
	{ 
		PrintFormat("Failed to copy data from the CCI indicator, error code %d",GetLastError());//--- �������ʧ�ܣ���ʾ������� 
		return(false); //--- �˳����� - ����ʾ����Ϊ�ǲ������ָ�� 
	}
	
	return(true);
}
//+------------------------------------------------------------------+
