#include "common.mqh"

class MySignalFraSMA
{
protected:
	int 	handle;
	int 	ma_period;			// ƽ���ƶ�����
	double	FraSMA[];
	ENUM_TIMEFRAMES      period;        // ʱ��֡ 
	ENUM_APPLIED_PRICE   applied_price;  // �۸�����
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
	//	ɾ��ָ����:
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
	ResetLastError(); //--- ���ô������ 
	if(CopyBuffer(ind_handle,0,0,amount,buffer)<0) //--- ��0����ָ�껺������ֵ��䲿��Buffer ���� 
	{ 
		PrintFormat("Failed to copy data from the FraSMA indicator, error code %d",GetLastError());//--- �������ʧ�ܣ���ʾ������� 
		return(false); //--- �˳����� - ����ʾ����Ϊ�ǲ������ָ�� 
	}
	
	return(true); 
}
//+------------------------------------------------------------------+
