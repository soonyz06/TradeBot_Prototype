#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 005;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input double FixedLot = 0;
input double risk = 0.01; //Risk
double Lot;
//input double SlPoints = 500;
input int A = 8; //Start Time
input int Z = 20; //End Time
int input Exit = 5;

//+------------------------------------------------------------------+

string today;
string yesterday;
datetime Start;
datetime Stop;
datetime now;
string Trade_Start = string(A)+":00:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time

double PivotPoint;
double S1;
double S2;
double S3;
double R1;
double R2;
double R3;

double bar;
double newbar;
string text;
int buyPosition;
int sellPosition;
int done1 = 0;
int done2 = 0;
int n1=0;
int n2=0;
int days;
int newdays;
double Max;
double Min;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   Comment("ID: ", Magic);
   //ObjectCreate(0, "PP", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "S1", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "S2", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "R1", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "R2", OBJ_HLINE, 0, _Period, 0);
   //ObjectSetInteger(0, "PP", OBJPROP_COLOR, clrWheat);
   ObjectSetInteger(0, "S1", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "S2", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "R1", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "R2", OBJPROP_COLOR, clrWhite);
   //ObjectCreate(0, "High", OBJ_HLINE, 0, _Period, 0);
   //ObjectCreate(0, "Low", OBJ_HLINE, 0, _Period, 0);
   //ObjectSetInteger(0, "High", OBJPROP_COLOR, clrWhite);
   //ObjectSetInteger(0, "Low", OBJPROP_COLOR, clrWhite);
   days = iBars(_Symbol, PERIOD_D1);
}

//+------------------------------------------------------------------+




void OnTick(){
   session();
   newbar = iBars(_Symbol, _Period);
   if(TimeCurrent()>Start && TimeCurrent()<Stop){
      checkPositions();
      
      if(buyPosition==0 && done1==0){
         executeBuyLimit(S2);
         done1 = 1;
      }
      if(sellPosition==0 && buyPosition==0 && done2==0){
         executeSellLimit(R2);
         done2=1;
      }
   }
   
   if(TimeCurrent()>Stop){
      if(days!=newdays){
         //checkPositions();
         days=newdays;
         //Comment("ID: ", Magic, "\n\nBuy Position Duration: ", n1, "\nSell Position Duration: ", n2);
         closeAllPositions();
      }
      //closeAllPositions();
   }
   
   //checkPositions();
   if(buyPosition > 0 ){
      //processPosition(POSITION_TYPE_BUY);
   }
   if(sellPosition > 0 ){
      //processPosition(POSITION_TYPE_SELL);
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
   
   //Extra
   if(buyPosition==0){
      n1=0;
   }
   if(sellPosition==0){
      n2=0;
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

void session(){
   //Time
   now = TimeCurrent();
   today = TimeToString(TimeCurrent(), TIME_DATE);
   if(today!=yesterday)
   {
      //closeAllPositions();
      yesterday = today;
      Start = StringToTime(today+" "+Trade_Start);
      Stop = StringToTime(today+" "+Trade_Stop);
      done1 = 0;
      done2 = 0;
      newdays = iBars(_Symbol, PERIOD_D1);
      
      //Pivot Points
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, PERIOD_D1, 0, 3, Price);
      
      //Precondition
      PivotPoint = NormalizeDouble((Price[1].high+Price[1].low+Price[1].close)/3, _Digits);
      S1 = NormalizeDouble((PivotPoint*2)-Price[1].high, _Digits);
      S2 = NormalizeDouble(PivotPoint - (Price[1].high-Price[1].low), _Digits);
      S3 = NormalizeDouble(PivotPoint - (Price[1].high-Price[1].low)*2, _Digits);
      R1 = NormalizeDouble((PivotPoint*2)-Price[1].low, _Digits);
      R2 = NormalizeDouble(PivotPoint + (Price[1].high-Price[1].low), _Digits);
      R3 = NormalizeDouble(PivotPoint + (Price[1].high-Price[1].low)*2, _Digits);
      
      ///ObjectMove(0, "PP", 0, _Period, PivotPoint);
      ObjectMove(0, "S1", 0, _Period, S1);
      ObjectMove(0, "S2", 0, _Period, S2);
      ObjectMove(0, "R1", 0, _Period, R1);
      ObjectMove(0, "R2", 0, _Period, R2);
      
      
      //range(20, Timeframe);
      //ObjectMove(0, "High", 9, _Period, Max);
      //ObjectMove(0, "Low", 9, _Period, Min);
   }
}

void executeBuyStop(double entry){
   //positionSize(SlPoints);
   //trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Stop, text);
}

void executeSellStop(double entry){
   //positionSize(SlPoints);
   //trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Stop, text);
}

void executeBuyLimit(double entry){
   double Sl=entry-S3;
   positionSize(Sl/_Point);
   trade.BuyLimit(Lot, entry, _Symbol, entry-200*_Point, S1, ORDER_TIME_SPECIFIED, Stop, text);
}

void executeSellLimit(double entry){
   double Sl = R3-entry;
   positionSize(Sl/_Point);
   trade.SellLimit(Lot, entry, _Symbol, entry+200*_Point, R1, ORDER_TIME_SPECIFIED, Stop, text);
}

void processPosition(ENUM_POSITION_TYPE type){
   if(PositionsTotal()==0) return;
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double E = 0;
   double n = 0;
   double tp = 0;
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol && PositionGetInteger(POSITION_TYPE) == type)
         {
            E += PositionGetDouble(POSITION_PRICE_OPEN);
            n +=1;
         }
      }
   }
   double level = NormalizeDouble(E/n, _Digits);
   //ObjectMove(0, "Level", 0, _Period, level);
   
   if(type == POSITION_TYPE_BUY){
      tp = level+200*_Point;
      ObjectMove(0, "Tp1", 0, _Period, tp);
      
      if(Bid>=tp){
         closePosition(POSITION_TYPE_BUY);
         closeOrder(ORDER_TYPE_BUY_LIMIT);
         ObjectMove(0, "Tp1", 0, _Period, 0);
      }
   }
   else if(type == POSITION_TYPE_SELL){
      tp = level-200*_Point;      
      ObjectMove(0, "Tp2", 0, _Period, tp);
      
      if(Ask<=tp){
         closePosition(POSITION_TYPE_SELL);
         closeOrder(ORDER_TYPE_SELL_LIMIT);
         ObjectMove(0, "Tp2", 0, _Period, 0);
      }
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
               trade.PositionModify(ticket, sl, NULL);
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

void timeExit(int exit){
   if(PositionsTotal()==0) return;
   for(int i =0; i<PositionsTotal(); i++){
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket)){
         if (PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetString(POSITION_SYMBOL)== _Symbol){
            //Position Open
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
               n1+=1;
               
               if(n1==exit){
                  trade.PositionClose(ticket);
                  n1 = 0;
               }
            }
            else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
               n2+=1;
               
               
               if(n2==exit){
                  trade.PositionClose(ticket);
                  n2 = 0;
               }
            }
         }
      }
   }
}

void closeAllPositions()
   {
      for (int i=PositionsTotal()-1; i>=0; i--)
      {  
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket))
         {
            string symbol = PositionGetSymbol(i);
            if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol)
            {
               trade.PositionClose(ticket);
            }
         }
      }
   }


//At end of day if in profit onyl close?