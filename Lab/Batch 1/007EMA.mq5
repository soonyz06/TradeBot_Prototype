#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 007;
input ENUM_TIMEFRAMES Timeframe = PERIOD_MN1;
input double FixedLot = 0.01;
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
double MA1[];
double MA2[];
int MAHandler1;
int MAHandler2;
double RSI[];
int RSIHandler;
double MFI[];
int MFIHandler;
double VO[];
int VOHandler;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   Comment("ID: ", Magic);
   MAHandler1 = iMA(_Symbol, Timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
   MAHandler2 = iMA(_Symbol, Timeframe, 30, 0, MODE_EMA, PRICE_CLOSE);
   RSIHandler = iRSI(_Symbol, Timeframe, 14, PRICE_CLOSE);
   //MFIHandler = iMFI(_Symbol, Timeframe, 14, VOLUME_TICK);
   VOHandler = iCustom(_Symbol, Timeframe, "Examples\Volume_Oscillator.ex5");
}

//+------------------------------------------------------------------+




void OnTick(){
   newbar = iBars(_Symbol, Timeframe);
   if(bar!=newbar){
      //Price
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, Timeframe, 0, 3, Price);
      
      //Indicators
      ArraySetAsSeries(MA1, true);
      CopyBuffer(MAHandler1, 0, 0, 3, MA1);
      ArraySetAsSeries(MA2, true);
      CopyBuffer(MAHandler2, 0, 0, 3, MA2);
      ArraySetAsSeries(RSI, true);
      CopyBuffer(RSIHandler, 0, 0, 3, RSI);
      ArraySetAsSeries(MFI, true);
      //CopyBuffer(MFIHandler, 0, 0, 3, MFI);
      ArraySetAsSeries(VO, true);
      CopyBuffer(VOHandler, 0, 0, 3, VO);
      //if(RSI[1]-MFI[1]<-20){ sell
      //if(RSI[1]-MFI[1]>20){ buy
      
      //Trade (flw MFI?)
      checkPositions();
      if(VO[0]>25){
         if(MA1[1]>MA2[1]){
            executeBuy();
         }
         if(MA1[1]<MA2[1]){
            executeSell();
         }
      }
      
      if(buyPosition>0 && Price[1].close<MA1[1]){
         closePosition(POSITION_TYPE_BUY);
      }
      if(sellPosition>0 && Price[1].close>MA1[1]){
         closePosition(POSITION_TYPE_SELL);
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
   trade.Buy(Lot, _Symbol, Ask, Ask-200*_Point, NULL, text);
}

void executeSell(){
   if(sellPosition>0) return;
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   trade.Sell(Lot, _Symbol, Bid, Bid+200*_Point, NULL, text);
}
