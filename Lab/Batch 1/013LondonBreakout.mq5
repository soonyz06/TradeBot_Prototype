#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 013;
input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
int SlPoints;
double Tp;
input int time_exit = 0; //Time Exit
input int A = 8; //Start Time
int E = A+1; //Expiration Time
int Z = 20; //End Time

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
int buyTime;
int sellTime;
double MP;

MqlRates Price[];
//double MA[];
//int MAHandler;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   ArraySetAsSeries(Price, true);
   //ArraySetAsSeries(MA, true);
   //MAHandler = iMA(_Symbol, Timeframe, 200, 0, MODE_SMA, PRICE_CLOSE);
   
   ObjectCreate(0, "Max", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Max", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Min", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Min", OBJPROP_COLOR, clrWhite);
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
      
      //Entry
      if(TimeCurrent()>Start){
         CopyRates(_Symbol, Timeframe, 0, 3, Price);
         //CopyBuffer(MAHandler, 0, 0, 3, MA);
         ObjectMove(0, "Max", 0, 0, Price[0].high);
         ObjectMove(0, "Min", 0, 0, Price[0].low);
         MP = NormalizeDouble((Price[0].high+Price[0].low)/2, _Digits);
         checkPositions();
         
         if(Price[0].close>MP && sellPosition==0){
            executeSellStop(MP);
         }
         if(Price[0].close<MP && buyPosition==0){
            executeBuyStop(MP);
         }
         yesterday = today;
      }
   }
   
   //Exit
   if(today2!=yesterday2){
      if(TimeCurrent()>Stop){
         checkPositions();
         timeExit(time_exit);
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
   SlPoints = int((entry-Price[0].low)/_Point);
    
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, Price[0].low, NormalizeDouble(entry+SlPoints*_Point*5, _Digits), ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellStop(double entry){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid<entry) return;
   SlPoints = int((Price[0].high-entry)/_Point);
   
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, Price[0].high, NormalizeDouble(entry-SlPoints*_Point*5, _Digits) , ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeBuyLimit(double entry){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(Ask<entry) return;
   positionSize(SlPoints);
   trade.BuyLimit(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellLimit(double entry){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid>entry) return;
   positionSize(SlPoints);
   trade.SellLimit(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void timeExit(int n){
   int buy = 0;
   int sell = 0;
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
               buy+=1;
            }
            else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
            {
               sell+=1;
            }
         }
      }
   }
   
   //Duration
    if(buy>0){
      buyTime+=1;
   }
   else{
      buyTime = 0;
   }
   
   if(sell>0){
      sellTime+=1;
   }
   else{
      sellTime = 0;
   }
   
   //Exit
   n+=1;
      
   if(buyTime>=n){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellTime>=n){
      closePosition(POSITION_TYPE_SELL);
   }
}



