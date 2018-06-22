#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>

#include "common.mqh"

class MyTrade
{
protected:
	CPositionInfo  m_position;                   // 订单对象
	CTrade         m_trade;                      // 交易对象
	CSymbolInfo    m_symbol;                     // 交易品种信息对象
	CAccountInfo   m_account;					// 账户信息对象
	ulong    	magicNumber;
	double   	lots;				//开仓数
	double   	takeProfit;			//止盈点数
	double   	stopLoss;			//止损点数
	double		m_trailing_stop;	//止损	
	double 		m_take_profit;		//盈利
	double 		m_adjusted_point;
	double 		minDesposit;		//最低存款
	int			maxOrder;			//最大开仓数
	int 		periodCnt;
	int			lastTradePeriod;
public:
	MyTrade();
	~MyTrade();
	bool Init(ulong magic_number, double inpLots, double take_rofit, double stop_loss);
	bool InitCheckParameters(const int digits_adjust);
	void OrderOpen(MY_ORDER_TYPE type);
   	void OrderClose(MY_ORDER_TYPE type);
   	bool IsTradeTime(void);
   	bool RefreshRates();
};

MyTrade::MyTrade() : minDesposit(1000),
					 maxOrder(10),
					 periodCnt(0),
					 lastTradePeriod(0)
{
	
}

MyTrade::~MyTrade()
{
	
}

bool MyTrade::Init(ulong magic_number, double inpLots, double take_profit, double stop_loss)
{
	magicNumber = magic_number;
	lots = inpLots;
	takeProfit = take_profit;
	stopLoss = stop_loss;
	
	//--- initialize common information
	m_symbol.Name(Symbol());                  // symbol
	m_trade.SetExpertMagicNumber(magic_number); // magic
	m_trade.SetMarginMode();
	m_trade.SetTypeFillingBySymbol(Symbol());
	//--- tuning for 3 or 5 digits
	int digits_adjust=1;
	if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
		digits_adjust=10;
	m_adjusted_point=m_symbol.Point()*digits_adjust;
	//--- set default deviation for trading in adjusted points
	m_trailing_stop    =stopLoss*m_adjusted_point;
	m_take_profit     =takeProfit*m_adjusted_point;
	//--- set default deviation for trading in adjusted points
	m_trade.SetDeviationInPoints(3*digits_adjust);
	//---
	if(!InitCheckParameters(digits_adjust))
		return(false);
	//--- succeed
	return(true);
}

bool MyTrade::InitCheckParameters(const int digits_adjust)
{
	//--- initial data checks
	if(takeProfit > 0)
	{
		if(takeProfit*digits_adjust<m_symbol.StopsLevel())
		{
			printf("Take Profit must be greater than %d",m_symbol.StopsLevel());
			return(false);
		}
	}
	if(stopLoss > 0)
	{
		if(stopLoss*digits_adjust<m_symbol.StopsLevel())
		{
			printf("Trailing Stop must be greater than %d",m_symbol.StopsLevel());
			return(false);
		}
	}
	
	//--- check for right lots amount
	if(lots<m_symbol.LotsMin() || lots>m_symbol.LotsMax())
	{
		printf("Lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
		return(false);
	}
	if(MathAbs(lots/m_symbol.LotsStep()-MathRound(lots/m_symbol.LotsStep()))>1.0E-10)
	{
		printf("Lots amount is not corresponding with lot step %f",m_symbol.LotsStep());
		return(false);
	}

	//--- succeed
	return(true);
}

void MyTrade::OrderOpen(MY_ORDER_TYPE type)
{
	double ask;
	double bid;
	double tp;
	double sl;
	double price;
	int total = PositionsTotal();
	if(m_account.FreeMargin() < minDesposit) //余额不足
	{
		Print("deposit = ", DoubleToString(m_account.FreeMargin(),2));
		return;
	}

	if(total < maxOrder && lastTradePeriod != periodCnt)
	{
		lastTradePeriod = periodCnt;
		ask = m_symbol.Ask();
		bid = m_symbol.Bid();
		if(type == MY_ORDER_OPEN_BUY || type == MY_ORDER_BUY)
		{
			price = m_symbol.Ask();
			if(m_trailing_stop == 0.0)
			{
				sl = 0.0;
			}
			else
			{
				sl = m_symbol.Bid()-m_trailing_stop;
			}
			if(m_take_profit == 0.0)
			{
				tp = 0.0;
			}
			else
			{
				tp = m_symbol.Ask()+m_take_profit;
			}
			
			if(!m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,sl,tp))
			{
				Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
					", description of result: ",m_trade.ResultRetcodeDescription(),
					", ticket of deal: ",m_trade.ResultDeal());
			}
		}
		else if(type == MY_ORDER_OPEN_SELL || type == MY_ORDER_SELL)
		{
			price = m_symbol.Bid();
			if(m_trailing_stop == 0.0)
			{
				sl = 0.0;
			}
			else
			{
				sl = m_symbol.Bid()+m_trailing_stop;
			}
			if(m_take_profit == 0.0)
			{
				tp = 0.0;
			}
			else
			{
				tp = m_symbol.Ask()-m_take_profit;
			}
			if(!m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,lots,price,sl,tp))
			{
				Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
					", description of result: ",m_trade.ResultRetcodeDescription(),
					", ticket of deal: ",m_trade.ResultDeal());
			}
		}
	}
}

void MyTrade::OrderClose(MY_ORDER_TYPE type)
{
	int total = PositionsTotal();
	int i;

	for(i = total-1; i >= 0; i--)
	{
		if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
		{
			if(m_position.Symbol()==m_symbol.Name() && m_position.Magic() == MagicNumber)
			{
				if(m_position.PositionType() == POSITION_TYPE_BUY)
				{
					if(type == MY_ORDER_CLOSE_BUY || type == MY_ORDER_SELL)
					{
						m_trade.PositionClose(m_position.Ticket());
					}
				}
				
				if(m_position.PositionType() == POSITION_TYPE_SELL)
				{
					if(type == MY_ORDER_CLOSE_SELL || type == MY_ORDER_BUY)
					{
						m_trade.PositionClose(m_position.Ticket());
					}
				}
			}
		}
	}
}

bool MyTrade::IsTradeTime(void)
{
	ENUM_TIMEFRAMES period = Period();
	int seconds;
	int cnt = 0;
	static int day = 0;
	MqlDateTime time;

	TimeToStruct(TimeCurrent(),time);
	seconds = time.hour*3600 + time.min*60 + time.sec;
	
	if(day != time.day)
	{
		day = time.day;
		periodCnt = 0;
	}
	if(period == PERIOD_M5)
	{
		cnt = seconds/(60*5);
	}
	else if(period == PERIOD_M15)
	{
		cnt = seconds/(60*15);
	}
	else if(period == PERIOD_M30)
	{
		cnt = seconds/(60*30);
	}
	else if(period == PERIOD_H1)
	{
		cnt = seconds/(60*60);
	}
	else if(period == PERIOD_H2)
	{
		cnt = seconds/(60*60*2);
	}
	else if(period == PERIOD_H3)
	{
		cnt = seconds/(60*60*3);
	}
	else if(period == PERIOD_H4)
	{
		cnt = seconds/(60*60*4);
	}
	else 
	{
		return false;
	}
	if(periodCnt != cnt)
	{
		periodCnt = cnt;
	}

	return true;
}

bool MyTrade::RefreshRates()
{
	//--- refresh rates
	if(!m_symbol.RefreshRates())
		return(false);
	//--- protection against the return value of "zero"
	if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
		return(false);
	//---
	return(true);
}