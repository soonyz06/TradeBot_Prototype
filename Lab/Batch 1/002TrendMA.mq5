#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 002;
input ENUM_TIMEFRAMES Timeframe = PERIOD_MN1;
input double FixedLot = 0.02;
//input double Risk = 0.43;
//int Lot;
input int M = 0; // Multiple Positions
enum intOptionsA{
   A1 = 1, //Gold
   A2 = 2, //Currencies
   A3 = 1, //Stocks
};

input intOptionsA Market = A1;

//+------------------------------------------------------------------+

double bar;
double newbar;
string text;
int buyPosition;
int sellPosition;
int done1 = 0;
int done2 = 0;
double MA[];
int MAHandler;


//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   Comment("ID: ", Magic);
   MAHandler = iMA(_Symbol, Timeframe, 10, 0, MODE_SMA, PRICE_CLOSE);
}

//+------------------------------------------------------------------+




void OnTick(){
   newbar = iBars(_Symbol, Timeframe);
   if(bar!=newbar){
      //Prices
      ArraySetAsSeries(MA, true);
      CopyBuffer(MAHandler, 0, 0, 3, MA);
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, Timeframe, 0, 3, Price);
      
      //Trade
      checkPositions();
      if(Price[1].close>MA[1]){
         if(sellPosition>0){
            if(Market!=1)
            closePosition(POSITION_TYPE_SELL);
         }
         if((buyPosition==0 && M==0) || (Price[2].close<MA[2] && M==1)){
            executeBuy();
         }
      }
      else if(Price[1].close<MA[1]){
         if(buyPosition>0){
            closePosition(POSITION_TYPE_BUY);
         }
         if((sellPosition==0 && M==0) || (Price[2].close>MA[2] && M==1)){
         if(Market!=1)
            executeSell();
         }
      }
      bar=newbar;
   }

}



//+------------------------------------------------------------------+

void checkPositions()
{
   buyPosition = 0;
   sellPosition = 0;
   for(int i =0; i<OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      string symbol = OrderGetString(ORDER_SYMBOL);
      if (OrderSelect(ticket))
      {
         if (OrderGetInteger(ORDER_MAGIC)==Magic && symbol == _Symbol)
         {
            if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP)
            {
               buyPosition+=1;
            }
            else if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP)
            {
               sellPosition+=1;
            }
         }
      }
   }
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol)
         {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
            {
               buyPosition+=1;
            }
            else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
            {
               sellPosition+=1;
            }
         }
      }
   }
}

void closePosition(ENUM_POSITION_TYPE type){
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol)
         {
            if(PositionGetInteger(POSITION_TYPE) == type)
            {
               trade.PositionClose(ticket);
            }
         }
      }
   }
}

void executeBuy(){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   trade.Buy(FixedLot, _Symbol, Ask, NULL, NULL, text);
}

void executeSell(){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   trade.Sell(FixedLot, _Symbol, Bid, NULL, NULL, text);
}



