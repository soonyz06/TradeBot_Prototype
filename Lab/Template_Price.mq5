#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 000;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input double FixedLot = 0;
input double risk = 0.01; //Risk
double Lot;
input double SlPoints = 200;
input int A = 8; //Start Time
input int Z = 20; //End Time

//+------------------------------------------------------------------+

string today;
string yesterday;
datetime Start;
datetime Stop;
datetime now;
string Trade_Start = string(A)+":00:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time

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
   session();
   newbar = iBars(_Symbol, _Period);
   if(TimeCurrent()>Start && TimeCurrent()<Stop){
   
      checkPositions();
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
         Lot = balance*risk/slpoints;
      }
      else if (Curr2=="JPY")
      {
         double Ask2 = NormalizeDouble(SymbolInfoDouble("USD"+Curr2, SYMBOL_ASK), _Digits);
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = balance*risk/slpoints*Ask2/100;
      }
      else 
      {
         //USDCHF etc
         double Ask2 = NormalizeDouble(SymbolInfoDouble("USD"+Curr2, SYMBOL_ASK), _Digits);
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = balance*risk/slpoints*Ask2;
         //NZDUSD etc
         if(Lot==0)
         {
            double Bid2 = NormalizeDouble(SymbolInfoDouble(Curr2+"USD", SYMBOL_BID), _Digits);
            balance = AccountInfoDouble(ACCOUNT_BALANCE);
            Lot = balance*risk/slpoints/Bid2;
         }
      }
      if (Lot<0.01)
      {
         Lot = 0.01;
      }
      else if(MathIsValidNumber(Lot) == false)
      {
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         Lot = NormalizeDouble(balance*risk/slpoints, 1);
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

void session(){
   //Time
   now = TimeCurrent();
   today = TimeToString(TimeCurrent(), TIME_DATE);
   if(today!=yesterday)
   {
      yesterday = today;
      Start = StringToTime(today+" "+Trade_Start);
      Stop = StringToTime(today+" "+Trade_Stop);
      done1 = 0;
      done2 = 0;
   }
}

void executeBuyStop(double entry){
   if(buyPosition>0) return;
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Stop, text);
}

void executeSellStop(double entry){
   if(sellPosition>0) return;
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Stop, text);
}

void executeBuyLimit(double entry){
   if(buyPosition>0) return;
   positionSize(SlPoints);
   trade.BuyLimit(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Stop, text);
}

void executeSellLimit(double entry){
   if(sellPosition>0) return;
   positionSize(SlPoints);
   trade.SellLimit(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Stop, text);
}

