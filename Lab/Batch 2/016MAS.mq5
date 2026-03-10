#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 016;
input ENUM_TIMEFRAMES Timeframe = PERIOD_M30;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
input int TpPoints = 5000;
input int SlPoints = 750;
input int break_even = 1100; //Break Even
input int time_exit = 930; //Time Exit
int A = 0; //Start Time

//4000 800 -1
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
datetime buyOpen;
datetime sellOpen;
int buyDuration;
int sellDuration;
int bar1;
int bar2;
int newbar;

MqlRates Price[];
double MA1[];
double MA2[];
double MA3[];
int MAHandler1;
int MAHandler2;
int MAHandler3;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   bar1 = 0;
   bar2 = 0;
   ArraySetAsSeries(Price, true);
   ArraySetAsSeries(MA1, true);
   ArraySetAsSeries(MA2, true);
   ArraySetAsSeries(MA3, true);
   MAHandler1 = iMA(_Symbol, Timeframe, 40, 0, MODE_SMA, PRICE_CLOSE);
   MAHandler2 = iMA(_Symbol, Timeframe, 50, 0, MODE_SMA, PRICE_CLOSE);
   MAHandler3 = iMA(_Symbol, Timeframe, 200, 0, MODE_SMA, PRICE_CLOSE);
   Comment("ID: ", Magic);
}

//+------------------------------------------------------------------+

void OnTick(){
   //newbar = iBars(_Symbol, _Period);

   today = TimeToString(TimeCurrent(), TIME_DATE);
   
   if(today!=yesterday)
   {      
      Start = StringToTime(today+" "+Trade_Start);

      yesterday=today;
   }
   
   newbar = iBars(_Symbol, Timeframe);
   
   if(bar1!=newbar){
      //Entry
      if(TimeCurrent()>Start){
         CopyRates(_Symbol, Timeframe, 0, 3, Price);
         CopyBuffer(MAHandler1, 0, 0, 3, MA1);
         CopyBuffer(MAHandler2, 0, 0, 3, MA2);
         CopyBuffer(MAHandler3, 0, 0, 3, MA3);
         checkPositions();
         timeUpdate();
         
         if(buyPosition==0 && sellPosition==0){
            if(Price[1].close>MA3[1]){
               if(MA1[1]>MA2[1] && MA1[2]<=MA2[2]){
                  executeBuy();
               }
            }
            
            if(Price[1].close<MA3[1]){
               if(MA1[1]<MA2[1] && MA1[2]>=MA2[2]){
                  executeSell();
               }
            }
         }
      }
      bar1=newbar;
   }
   
   //Exit
   if(bar2!=newbar){
      checkPositions();
      timeUpdate();
      timeExit(time_exit); //Time Exit
      processPosition(0);  //Large TP
      breakEven(break_even); //Break Even
      bar2=newbar;
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

void executeBuy(){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   positionSize(SlPoints);
   trade.Buy(Lot, _Symbol, Ask, Ask-SlPoints*_Point, NULL, text);
}

void executeSell(){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   positionSize(SlPoints);
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
               buyDuration = iBarShift(_Symbol, Timeframe, buyOpen, false) ;
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

