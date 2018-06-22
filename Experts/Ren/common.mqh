enum TREND_SIGNAL
{
	TREND_HARD_DOWN  =0,           // strong down trend
	TREND_DOWN       =1,           // down trend
	TREND_SOFT_DOWN  =2,           // weak down trend
	TREND_FLAT       =3,           // no trend
	TREND_SOFT_UP    =4,           // weak up trend
	TREND_UP         =5,           // up trend
	TREND_HARD_UP    =6            // strong up trend
};

enum MY_ORDER_TYPE
{
	MY_ORDER_NULL 			= 0,
	MY_ORDER_BUY  			= 1,
	MY_ORDER_SELL		  	= 2,
	MY_ORDER_OPEN_BUY  	= 3,
	MY_ORDER_OPEN_SELL 	= 4,
	MY_ORDER_CLOSE_BUY 	= 5,
	MY_ORDER_CLOSE_SELL	= 6
};