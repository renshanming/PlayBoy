#include "common.mqh"

class MySignalNRTR
{
protected:
	int     handle;
	int     ATRPeriod;  // ATR ������, ����Ϊ��λ
	double  Koeff;     // ATR ֵ�ı��ϵ��   
	ENUM_TIMEFRAMES      period;        // ʱ��֡ 
	ENUM_APPLIED_PRICE   applied_price;  // �۸�����
	double NRTR[];

public:
	MySignalNRTR(void);
	~MySignalNRTR(void);
	void Applied(ENUM_APPLIED_PRICE value) { applied_price=value; }
	bool Init(void);
	void DeInit(void);
	TREND_SIGNAL GetSignal(void);
	bool GetNRTR(double &buffer[], int ind_handle, int amount);
	int CheckNewBar();

};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MySignalNRTR::MySignalNRTR(void) : handle(INVALID_HANDLE),
							   ATRPeriod(40),
							   Koeff(2.0),
							   period(PERIOD_CURRENT),
							   applied_price(PRICE_TYPICAL)
{
	ArraySetAsSeries(NRTR,true);
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
MySignalNRTR::~MySignalNRTR(void)
{
	DeInit();
}

//+------------------------------------------------------------------+
//| Initialize NRTR oscillators.                                     |
//+------------------------------------------------------------------+
bool MySignalNRTR::Init(void)
{
	//--- create NRTR indicator
	if(handle==INVALID_HANDLE)
		if((handle=iCustom(Symbol(),period,"Network\\NRTR",ATRPeriod,Koeff))==INVALID_HANDLE)
		{
			printf("Error creating NRTR indicator");
			return(false);
		}
	return true;
}

void MySignalNRTR::DeInit(void)
{
	//	ɾ��ָ����:
	if(handle!=INVALID_HANDLE)
	{
		IndicatorRelease(handle);
	}
}

TREND_SIGNAL MySignalNRTR::GetSignal(void)
{
	if(CheckNewBar()!=1)
	{
		return TREND_FLAT;
	}
	if(!GetNRTR(NRTR,handle,3))
	{
		return TREND_FLAT;
	}
	
	if(NRTR[1] > NRTR[2])
	{
		return TREND_UP;
	}
	else if(NRTR[1] < NRTR[2])
	{
		return TREND_DOWN;
	}
	return TREND_FLAT;
}

bool MySignalNRTR::GetNRTR(double &buffer[], int ind_handle, int amount)
{
	ResetLastError(); //--- ���ô������ 
	if(CopyBuffer(ind_handle,0,0,amount,buffer)<0) //--- ��0����ָ�껺������ֵ��䲿��Buffer ���� 
	{ 
		PrintFormat("Failed to copy data from the NRTR indicator, error code %d",GetLastError());//--- �������ʧ�ܣ���ʾ������� 
		return(false); //--- �˳����� - ����ʾ����Ϊ�ǲ������ָ�� 
	}
	
	return(true); 
}

int MySignalNRTR::CheckNewBar()
{
	MqlRates      current_rates[1];

	ResetLastError();
	if(CopyRates(Symbol(),Period(),0,1,current_rates)!=1)
	{
		Print("CopyRates ���ƴ���, ���� = ",GetLastError());
		return(0);
	}

	if(current_rates[0].tick_volume>1)
	{
		return(0);
	}

return(1);
}
//+------------------------------------------------------------------+
