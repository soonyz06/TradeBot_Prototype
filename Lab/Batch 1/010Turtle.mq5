#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 010;
input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
input int tsl = 3000; //TslPoints
input int SlPoints = 1500;
input int time_exit = 30; //Time Exit
//10 or 30
int lookback = 20; //Bars Lookback
int ret = 69; //Retracement

int A = 0; //Start Time
int Z = 20; //End Time
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

double bar;
double newbar;
string text;
int buyPosition;
int sellPosition;
int buyDuration;
int sellDuration;
datetime buyOpen;
datetime sellOpen;


MqlRates Price[];
double High[];
double Low[];
double Highest;
double Lowest;
double Ask;
double Bid;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   ArraySetAsSeries(Price, true);
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Low, true);
   
   ObjectCreate(0, "Max", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Max", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Min", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Min", OBJPROP_COLOR, clrWhite);
   Comment("ID: ", Magic, "\nBuy Duration: ", buyDuration, "\nSell Duration: ", sellDuration);
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
      
      //Entry
      if(TimeCurrent()>Start){
         CopyRates(_Symbol, Timeframe, 0, 3, Price);
         checkPositions();
         range(lookback);
         
         if(buyPosition==0)
         executeBuyStop(Highest);
         if(sellPosition==0)
         executeSellStop(Lowest);
         
         yesterday = today;
      }
   }
   
   //Exit
   if(today2!=yesterday2){
      if(TimeCurrent()>Stop){
         checkPositions();
         timeExit(time_exit);
         if(tsl!=-1)
         processPosition(0);
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
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(Ask>entry) return;
   if(entry-Ask<ret*_Point) return;
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellStop(double entry){
   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid<entry) return;
   if(Bid-entry<ret*_Point) return;
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeBuyLimit(double entry){
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(Ask<entry) return;
   positionSize(SlPoints);
   trade.BuyLimit(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellLimit(double entry){
   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid>entry) return;
   positionSize(SlPoints);
   trade.SellLimit(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void range(int bars){
   CopyHigh(_Symbol, Timeframe, 1, bars, High);
   CopyLow(_Symbol, Timeframe, 1, bars, Low);
   Highest = NormalizeDouble(High[ArrayMaximum(High, 0, WHOLE_ARRAY)], _Digits);
   Lowest = NormalizeDouble(Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)], _Digits);
   
   ObjectMove(0, "Max", 0, 0, Highest);
   ObjectMove(0, "Min", 0, 0, Lowest);
}

bool inProfit(ENUM_POSITION_TYPE type)
{
   bool x = false;
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         double profitMargin = MathAbs(PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN));
         if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol && PositionGetInteger(POSITION_TYPE)==type && profitMargin>tsl*_Point)
         {
            x =true;
         }
      }
   }
   return x;
}


void timeExit(int n){
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
   
   //Close Positon
   n+=1;
   if(buyDuration>=n){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellDuration>=n){
      closePosition(POSITION_TYPE_SELL);
   }
   Comment("ID: ", Magic, "\nBuy Duration: ", buyDuration, "\nSell Duration: ", sellDuration);
}

void processPosition(int n){
   if(buyDuration>n  && inProfit(POSITION_TYPE_BUY)){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellDuration>n && inProfit(POSITION_TYPE_SELL)){
      closePosition(POSITION_TYPE_SELL);
   }
}
