#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 009;
input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
input double FixedLot = 0.01;
input double risk = 0.01; //Risk
double Lot;
int tsl = -1; //TslPoints
input int SlPoints = 1500;
input int time_exit = 30; //Time Exit
int confirmation = 10; //Bars Lookback
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
string Trade_Stop = string(Z)+":45:00"; //End Time
string Trade_Expiration = string(E)+":45:00"; //End Time

//double bar;
//double newbar;
string text;
int buyPosition;
int sellPosition;
datetime buyOpen;
datetime sellOpen;
int buyDuration;
int sellDuration;
double highest_high =0;
double lowest_high =0;
double lowest_low =0;
double highest_low =0;

MqlRates Price[];
      
//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   //bar = 0;
   yesterday = "";
   yesterday2 = "";
   ArraySetAsSeries(Price, true);
   Comment("ID: ", Magic, "\nBuy Duration: ", buyDuration, "\nSell Duration: ", sellDuration);
}

//+------------------------------------------------------------------+

void OnTick(){
   //newbar = iBars(_Symbol, _Period);
   
   today = TimeToString(TimeCurrent(), TIME_DATE);
   today2 = TimeToString(TimeCurrent(), TIME_DATE);
   
   if(today!=yesterday){      
      Start = StringToTime(today+" "+Trade_Start);    
      Expiration = StringToTime(today+" "+Trade_Expiration);
      Stop = StringToTime(today+" "+Trade_Stop); 
      
      //Entry (single or bi-directional)
      if(TimeCurrent()>Start){    
         CopyRates(_Symbol, Timeframe, 0, 3, Price);
         range(confirmation, 1);  //bar used for confirmation
         checkPositions();  
               
         if(Price[1].close<Price[2].low){
            //Confirmation
            if(Price[1].close<lowest_low || lowest_low==0){ //close recent better, low historically better
               if(buyPosition==0 && sellPosition==0) 
               executeBuyStop(Price[1].high);
            }
         }
         
         if(Price[1].close>Price[2].high){
            //Confirmation
            if(Price[1].close>highest_high || highest_high==0){
               if(sellPosition==0 && buyPosition==0)
               executeSellStop(Price[1].low);
            }
         }     
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

void range(int n, int x){
   if(n<=2) return;
   
   double high[];
   ArraySetAsSeries(high, true);
   CopyHigh(_Symbol, Timeframe, x+1, n, high); //2nd +1
   highest_high = high[ArrayMaximum(high, 0, WHOLE_ARRAY)];
   lowest_high = high[ArrayMinimum(high, 0, WHOLE_ARRAY)];
   
   double low[];
   ArraySetAsSeries(low, true);
   CopyLow(_Symbol, Timeframe, x+1, n, low);
   lowest_low = low[ArrayMinimum(low, 0, WHOLE_ARRAY)];
   highest_low = low[ArrayMaximum(low, 0, WHOLE_ARRAY)];
   
   //ObjectCreate(0, "highest low", OBJ_HLINE, 0, 0, highest_low);
   //ObjectCreate(0, "lowest high", OBJ_HLINE, 0, 0, lowest_high);
}

void processPosition(int n){
   if(buyDuration>n  && inProfit(POSITION_TYPE_BUY)){
      closePosition(POSITION_TYPE_BUY);
   }
   if(sellDuration>n && inProfit(POSITION_TYPE_SELL)){
      closePosition(POSITION_TYPE_SELL);
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
   trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellStop(double entry){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(Bid<entry) return;
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeBuyLimit(double entry){
   positionSize(SlPoints);
   trade.BuyLimit(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellLimit(double entry){
   positionSize(SlPoints);
   trade.SellLimit(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}


//opposite direction entry
//change sl points
//tsl mechanism after certain point
//adjust entry

//apply time exit to other system

//eur tsl -1
//gbpusd tsl 3000

//exits: close day after in profit, pure time exit, tp

