#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 000;
input ENUM_TIMEFRAMES Timeframe = PERIOD_MN1;
input double FixedLot = 0;
double Lot = FixedLot;

enum intOptionsA{
   A1 = 1, //Gold
   A2 = 1, //Stocks
   A3 = 2, //Currencies
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

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   Comment("ID: ", Magic);
}

//+------------------------------------------------------------------+




void OnTick(){
   newbar = iBars(_Symbol, Timeframe);
   if(bar!=newbar){
      //Price
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, Timeframe, 0, 3, Price);
      
      checkPositions();
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

void positionModify(ENUM_POSITION_TYPE type, double sl, double tp){
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
               trade.PositionModify(ticket, sl, tp);
            }
         }
      }
   }
}

void executeBuy(){
   if(buyPosition>0) return;
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   trade.Buy(Lot, _Symbol, Ask, NULL, NULL, text);
}

void executeSell(){
   if(sellPosition>0) return;
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   trade.Sell(Lot, _Symbol, Bid, NULL, NULL, text);
}
