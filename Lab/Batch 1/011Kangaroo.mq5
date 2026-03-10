#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 011;
input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
input int tsl = 100; //TSL Points
input int SlPoints = 0;
input int time_exit = 10; //Time Exit
int A = 0; //Start Time
input int Z = 20; //End Time
int E = Z; //Expiration Time

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

MqlRates Price[];
double ATR[];
int ATRHandler;


//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   ArraySetAsSeries(Price, true);
   ArraySetAsSeries(ATR, true);
   ATRHandler = iATR(_Symbol, Timeframe, 10);
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
         CopyRates(_Symbol, Timeframe, 0, 5, Price);
         //CopyBuffer(ATRHandler, 0, 0, 3, ATR);
         checkPositions();
         
         kangarooEntry();
         yesterday = today;
      }
   }
   
   //Exit
   if(today2!=yesterday2){
      if(TimeCurrent()>Stop){
         checkPositions();
         timeExit(time_exit); //both fixed
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
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(Ask>entry) return;
   
   if(SlPoints==0){
    int x = int((entry-Price[2].low)/_Point);
    positionSize(x);
    trade.BuyStop(Lot, entry, _Symbol, Price[2].low, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
   }
   else{
      positionSize(SlPoints);
      trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
   }
}

void executeSellStop(double entry){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid<entry) return;
   
   if(SlPoints==0){
      int x = int((Price[2].high-entry)/_Point);
      positionSize(x);
      trade.SellStop(Lot, entry, _Symbol, Price[2].high, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
   }
   else{
      positionSize(SlPoints);
      trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
   }
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

void executeBuy(){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   trade.Buy(FixedLot, _Symbol, Ask, Price[2].low, NULL);
}

void executeSell(){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   trade.Sell(FixedLot, _Symbol, Bid, Price[2].high, NULL);
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

void processPosition(int n){
   if(buyTime>n  && inProfit(POSITION_TYPE_BUY)){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellTime>n && inProfit(POSITION_TYPE_SELL)){
      closePosition(POSITION_TYPE_SELL);
   }
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

void kangarooEntry(){
   //ObjectCreate(0, "Tail", OBJ_HLINE, 0, 0, 0);

   double change = (MathAbs(Price[1].close-Price[2].close))*100/Price[2].close;
   
   if(Price[2].low<Price[1].close && Price[2].low<Price[3].close && change<0.5){ //close fixed
      if(buyPosition ==0 && sellPosition==0){
         executeBuyStop(Price[2].high); //bar 2/1
      }
      closePosition(POSITION_TYPE_SELL);
      //ObjectCreate(0, "Tail", OBJ_HLINE, 0, 0, Price[2].low);
   }
   
   if(Price[2].high>Price[1].close && Price[2].high>Price[3].close && change<0.5){ //research change
      if(buyPosition==0 && sellPosition==0){
         executeSellStop(Price[2].low);
      }
      closePosition(POSITION_TYPE_BUY); 
      //ObjectCreate(0, "Tail", OBJ_HLINE, 0, 0, Price[2].high);
   }
}