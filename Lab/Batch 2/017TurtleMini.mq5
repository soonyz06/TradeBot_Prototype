#include<Trade\Trade.mqh>
CTrade trade;
//GBPJPY

enum intOptionsA{
   A1 = 1, //1 Hour Turtle
   A2 = 2, //4 Hour Turtle
   A3 = 3, //Custom
};

input ulong Magic = 017;
input intOptionsA Strategy = A1;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
input string Custom =""; //  

input ENUM_TIMEFRAMES p; //Timeframe
input int t = 4500; //TpPoints
input int s = 750; //SlPoints
input int b = 3000; //Break-even
input int e = 150; //Time Exit
input int l = 70; //Bars Lookback
int ret = 69; //Retracement

ENUM_TIMEFRAMES Timeframe;
int TpPoints;
int SlPoints;
int break_even;
int time_exit;
int lookback;
      
int A = 0; //Start Time


//+------------------------------------------------------------------+

string today;
string yesterday;
string today2;
string yesterday2;
datetime Start;
datetime Stop;
datetime Expiration;
string Trade_Start = string(A)+":05:00"; //Start Time


string text;
int buyPosition;
int sellPosition;
int buyTrade;
int sellTrade;
int buyDuration;
int sellDuration;
datetime buyOpen;
datetime sellOpen;
int bar1;
int bar2;
int newbar;

MqlRates Price[];
double High[];
double Low[];
double Highest;
double Lowest;
double Ask;
double Bid;
double oldHigh;
double oldLow;
double ATR[];
int ATRHandler;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   newbar=0;
   ArraySetAsSeries(Price, true);
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Low, true);   
   
   if(Strategy==1){
      Timeframe = PERIOD_H1;
      TpPoints = 4500; 
      SlPoints = 800;
      break_even = 3000;
      time_exit = 150; 
      lookback = 70; 
   }
   else if(Strategy==2){
      Timeframe = PERIOD_H4;
      TpPoints = 3000; 
      //SlPoints = 750;
      break_even = -1;
      time_exit = 22; 
      lookback = 145; 
      ATRHandler = iATR(_Symbol, PERIOD_H4, 4);
   }
   else{
      Timeframe = p;
      TpPoints = t; 
      SlPoints = s;
      break_even = b;
      time_exit = e; 
      lookback = l; 
   }
   
   ObjectCreate(0, "Max", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Max", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Min", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Min", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Trail", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Trail", OBJPROP_COLOR, clrYellow);
   Comment("ID: ", Magic);
   oldHigh = 0;
   oldLow = 0;
}

//+------------------------------------------------------------------+

void OnTick(){
   //newbar = iBars(_Symbol, _Period);

   today = TimeToString(TimeCurrent(), TIME_DATE);
   today2 = TimeToString(TimeCurrent(), TIME_DATE);
   
   if(today!=yesterday)
   {      
      Start = StringToTime(today+" "+Trade_Start);
      
      yesterday=today;
   }
   
   newbar = iBars(_Symbol, Timeframe);
   
   if(bar1!=newbar){
      //Entry
      CopyRates(_Symbol, Timeframe, 0, 3, Price);
      range(lookback);
      checkPositions();
      timeUpdate();
         
      if(Strategy==2){         
         CopyBuffer(ATRHandler, 0, 0, 3, ATR);
         SlPoints = int((ATR[1]*0.65)/_Point);
         //trail(trail_exit);
      }
         
      if(buyPosition==0 && sellTrade==0)
      executeBuyStop(Highest);
      if(sellPosition==0 && buyTrade==0)
      executeSellStop(Lowest);
        
      checkPositions();
      timeUpdate();
      timeExit(time_exit);
      processPosition(0);
      breakEven(break_even);
      bar1=newbar;
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
   buyTrade = 0;
   sellTrade = 0;
   
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
               buyTrade +=1;
            }
            else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
            {
               sellPosition+=1;
               sellTrade+=1;
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

void closeOrder(ENUM_ORDER_TYPE type)
{
   for (int i=OrdersTotal()-1; i>=0; i--)
   {  
      ulong ticket = OrderGetTicket(i);
      if (OrderSelect(ticket))
      {
         string symbol = OrderGetString(ORDER_SYMBOL);
         if (OrderGetInteger(ORDER_MAGIC)==Magic && symbol == _Symbol && OrderGetInteger(ORDER_TYPE)==type)
         {
            trade.OrderDelete(ticket);
         }
      }
   }
}

void executeBuyStop(double entry){
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(Ask>entry) return;
   if(entry-Ask<ret*_Point) return;
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, NULL, 0, text);
}

void executeSellStop(double entry){
   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid<entry) return;
   if(Bid-entry<ret*_Point) return;
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, NULL, 0, text);
}

void range(int bars){
   CopyHigh(_Symbol, Timeframe, 1, bars, High);
   CopyLow(_Symbol, Timeframe, 1, bars, Low);
   Highest = NormalizeDouble(High[ArrayMaximum(High, 0, WHOLE_ARRAY)], _Digits);
   Lowest = NormalizeDouble(Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)], _Digits);
   
   if(Highest!=oldHigh){
      closeOrder(ORDER_TYPE_BUY_STOP);
   }
   if(Lowest!=oldLow){
      closeOrder(ORDER_TYPE_SELL_STOP);
   }
   
   ObjectMove(0, "Max", 0, 0, Highest);
   ObjectMove(0, "Min", 0, 0, Lowest);
   
   oldHigh = Highest;
   oldLow = Lowest;
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
               buyDuration = iBarShift(_Symbol, Timeframe, buyOpen, false);
               buyflag = true;
            }
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
               sellOpen = datetime(PositionGetInteger(POSITION_TIME)); 
               sellDuration = iBarShift(_Symbol, Timeframe, sellOpen, false);
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

void breakEven(int points){
   if(points<0) return;
   
   double profitMargin;
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               profitMargin = PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN);
            }
            else{
                profitMargin = PositionGetDouble(POSITION_PRICE_OPEN)-PositionGetDouble(POSITION_PRICE_CURRENT);
            }
            
            if(profitMargin>points*_Point)
            trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP));
         }
      }
   }
}

void trail(int bars){
   if(bars==-1) return;
   
   double trail_high[];
   double trail_low[];
   double trail_highest;
   double trail_lowest;
   double tsl;
   ArraySetAsSeries(trail_high, true);
   ArraySetAsSeries(trail_low, true);
   
   CopyHigh(_Symbol, Timeframe, 2, bars, trail_high);
   CopyLow(_Symbol, Timeframe, 2, bars, trail_low);
   trail_highest = NormalizeDouble(trail_high[ArrayMaximum(trail_high, 0, WHOLE_ARRAY)], _Digits);
   trail_lowest = NormalizeDouble(trail_low[ArrayMinimum(trail_low, 0, WHOLE_ARRAY)], _Digits);
   
   if(buyTrade>0){
      tsl = trail_lowest;
      ObjectMove(0, "Trail", 0, _Period, tsl);
      positionModify(POSITION_TYPE_BUY, tsl);
      
      //if(Price[1].close<tsl)
      //closePosition(POSITION_TYPE_BUY);
   }
   if(sellTrade>0){
      tsl = trail_highest;
      ObjectMove(0, "Trail", 0, _Period, tsl);   
      positionModify(POSITION_TYPE_SELL, tsl);
      
      //if(Price[1].close>tsl)
      //closePosition(POSITION_TYPE_SELL);
   }
   
   if(buyTrade == 0 && sellTrade==0){
      ObjectMove(0, "Trail", 0, _Period, 0);
   }
}

void positionModify(ENUM_POSITION_TYPE type, double sl){
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
               if(type == POSITION_TYPE_BUY && sl>PositionGetDouble(POSITION_SL))
               trade.PositionModify(ticket, sl, PositionGetDouble(POSITION_TP));
               
               if(type == POSITION_TYPE_SELL && sl<PositionGetDouble(POSITION_SL))
               trade.PositionModify(ticket, sl, PositionGetDouble(POSITION_TP));
            }
         }
      }
   }
}