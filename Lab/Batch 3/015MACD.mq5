#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 015;
input ENUM_TIMEFRAMES Timeframe = PERIOD_MN1;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
enum intOptionsA{
   A1 = 1, //Default
   A2 = 2, //Long-Only
};

input intOptionsA Type = A1;

int TpPoints = -1; //TpPoints
input int SlPoints = 3000;
//0 or 3000
input int time_exit = 50; //Time Exit
//50 or 80
int A = 0; //Start Time
int Z = 23; //End Time
int E = 18; //Expiration Time

//+------------------------------------------------------------------+

string today;
string yesterday;
string today2;
string yesterday2;
datetime Start;
datetime Stop;
datetime Expiration;
string Trade_Start = string(A)+":05:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time
string Trade_Expiration = string(E)+":00:00"; //Expiration Time

string text;
int buyPosition;
int sellPosition;
datetime buyOpen;
datetime sellOpen;
int buyDuration;
int sellDuration;

MqlRates Price[];
double Main[];
double Signal[];
int MACDHandler;
int bar1;
int bar2;
int newbar;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   ArraySetAsSeries(Price, true);
   ArraySetAsSeries(Main, true);
   ArraySetAsSeries(Signal, true);
   //MACDHandler = iMACD(_Symbol, Timeframe, 12, 26, 9, PRICE_CLOSE);
   MACDHandler = iCustom(_Symbol, Timeframe, "Examples/MACD.ex5");
   bar1 = 0;
   bar2 = 0;
   Comment("ID: ", Magic);
}

//+------------------------------------------------------------------+

void OnTick(){
   //newbar = iBars(_Symbol, _Period);

   today = TimeToString(TimeCurrent(), TIME_DATE);
   today2 = TimeToString(TimeCurrent(), TIME_DATE);
   
   if(today!=yesterday)
   {      
      Start = StringToTime(today+" "+Trade_Start);
      Stop = StringToTime(today+" "+Trade_Stop);
      Expiration = StringToTime(today+" "+Trade_Expiration);
      newbar = iBars(_Symbol, PERIOD_MN1);
      timeUpdate();
      yesterday = today;
   }
   
   if(bar1!=newbar){
      //Entry
      if(TimeCurrent()>Start){
         CopyRates(_Symbol, Timeframe, 0, 3, Price);
         CopyBuffer(MACDHandler, 0, 0, 3, Main);
         CopyBuffer(MACDHandler, 1, 0, 3, Signal);
         
         
         if(Main[2]<Signal[2] && Main[1]>Signal[1]){
            closePosition(POSITION_TYPE_SELL);
            checkPositions();
            if(buyPosition==0 && sellPosition==0)
            executeBuy();
         }
         if(Main[2]>Signal[2] && Main[1]<Signal[1]){
            closePosition(POSITION_TYPE_BUY);
            checkPositions();
            if(sellPosition==0 && buyPosition==0 && Type!=2)
            executeSell();
         }
         bar1=newbar;
      }
   }
   
   //Exit
   if(today2!=yesterday2){
      if(TimeCurrent()>Stop){
         if(time_exit!=-1)
         timeExit(time_exit);
         processPosition(0);
         
         checkPositions();
         yesterday2=today2;
      }
   }
}

//+------------------------------------------------------------------+

void positionSize(double slpoints)
{
   if(FixedLot == 0)
   {
      string symbol = _Symbol;
      string Curr1 = StringSubstr(symbol, 0, 3);
      string Curr2 = StringSubstr(symbol, 3, 3);
      double balance;
      if (Curr2 == "USD")
      {
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = balance*risk/slpoints*100;
      }
      else if (Curr2=="JPY")
      {
         double Ask2 = NormalizeDouble(SymbolInfoDouble("USD"+Curr2, SYMBOL_ASK), _Digits);
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = balance*risk/slpoints*Ask2/100*100;
      }
      else 
      {
         //USDCHF etc
         double Ask2 = NormalizeDouble(SymbolInfoDouble("USD"+Curr2, SYMBOL_ASK), _Digits);
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = balance*risk/slpoints*Ask2*100;
         //NZDUSD etc
         if(Lot==0)
         {
            double Bid2 = NormalizeDouble(SymbolInfoDouble(Curr2+"USD", SYMBOL_BID), _Digits);
            balance = AccountInfoDouble(ACCOUNT_BALANCE);
            Lot = balance*risk/slpoints/Bid2*100;
         }
      }
      Lot = MathFloor(Lot)/100;
      
      if (Lot<0.01)
      {
         Lot = 0.01;
      }
      else if(MathIsValidNumber(Lot) == false)
      {
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = NormalizeDouble(balance*risk/slpoints, 2);
      }
      Lot = NormalizeDouble(Lot, 2);
   }
   else
   {
      Lot = FixedLot;
   }
}

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

void executeBuyStop(double entry){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(Ask>entry) return;
   
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellStop(double entry){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid<entry) return;
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeBuy(){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   positionSize(SlPoints);
   if(SlPoints==0)
   trade.Buy(Lot, _Symbol, Ask, NULL, NULL, text);
   else
   trade.Buy(Lot, _Symbol, Ask, Ask-SlPoints*_Point, NULL, text);
}

void executeSell(){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   positionSize(SlPoints);
   if(SlPoints==0)
   trade.Sell(Lot, _Symbol, Bid, NULL, NULL, text);
   else
   trade.Sell(Lot, _Symbol, Bid, Bid+SlPoints*_Point, NULL, text);
}

void timeUpdate(){
   bool buyflag = false;
   bool sellflag = false;
   
   //Count Duration
   for(int i =0; i<PositionsTotal(); i++){
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if(PositionSelectByTicket(ticket)){
         if(PositionGetInteger(POSITION_MAGIC) == Magic && symbol == _Symbol){
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
               buyOpen = datetime(PositionGetInteger(POSITION_TIME));
               buyDuration = iBarShift(_Symbol, PERIOD_D1, buyOpen, false) +1 ;
               buyflag = true;
            }
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
               sellOpen = datetime(PositionGetInteger(POSITION_TIME)); 
               sellDuration = iBarShift(_Symbol, PERIOD_D1, sellOpen, false) +1;
               sellflag = true;
            }
         }
      }
   }
   
   //Reset Duration
   if(buyflag == false){
      buyDuration = 0;
   }
   if(sellflag == false){
      sellDuration = 0;
   }
   Comment("ID: ", Magic, "\nBuy Duration: ", buyDuration, "\nSell Duration: ", sellDuration);
}

void timeExit(int n){
   //Close Positon
   n+=1;
   if(buyDuration>=n){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellDuration>=n){
      closePosition(POSITION_TYPE_SELL);
   }
}

void processPosition(int n){
   if(TpPoints==-1) return;
   
   if(buyDuration>n  && inProfit(POSITION_TYPE_BUY)){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellDuration>n && inProfit(POSITION_TYPE_SELL)){
      closePosition(POSITION_TYPE_SELL);
   }
}

bool inProfit(ENUM_POSITION_TYPE type)
{
   bool x = false;
   double profitMargin;
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         //Calculate Profit
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
         profitMargin = PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN);
         else
         profitMargin = PositionGetDouble(POSITION_PRICE_OPEN)-PositionGetDouble(POSITION_PRICE_CURRENT);
         
         //Is Profit > TpPoints 
         if(PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol && PositionGetInteger(POSITION_TYPE)==type && profitMargin>TpPoints*_Point)
         {
            x =true;
         }
      }
   }
   return x;
}

