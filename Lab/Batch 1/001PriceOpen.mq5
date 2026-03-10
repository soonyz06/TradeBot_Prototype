#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 001;
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15;
input double FixedLot = 0;
input double risk = 0.01; //Risk
double Lot;
input int SlPoints = 200;
input int distance = 200; //Distance
input int trail = 5; // Trail
//input int Exit = 40; // Time Exit
//int input Bars = 20;

string today;
string yesterday;
datetime Start;
datetime Stop;
datetime Expiration;
datetime now;
input int A = 8; //Start Time
input int Z = 20; //End Time
int E = 20; //Expiration
string Trade_Start = string(A)+":00:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time
string expire = string(E)+":00:00";

double bar;
double newbar;
string text;
int buyPosition;
int sellPosition;
double Max;
double Min;
double Max2 = 0;
double Min2 = 0;
double open;
int done1;
int done2;
int days;
int newdays;
int n1 = 0;
int n2 = 0;




//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   ObjectCreate(0, "High", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "Low", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "High", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "Low", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Open", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Open", OBJPROP_COLOR, clrYellow);
   Comment("ID: ", Magic);
   days = iBars(_Symbol, PERIOD_D1);
}

//+------------------------------------------------------------------+

void OnTick(){
   //Time
   session();
   
   if(TimeCurrent()>Start && TimeCurrent()<Stop){
      newbar = iBars(_Symbol, Timeframe);
      //At new bar
      if(bar!=newbar){
         bar=newbar;
         //Trade
         checkPositions();
         if(buyPosition==0 && done1 == 0){
            executeBuyStop(open+distance*_Point);
         }
         if(sellPosition==0 && done2 == 0){
            executeSellStop(open-distance*_Point);
         }
         if(buyPosition == 1){
            done1 = 1;
         }
         if(sellPosition == 1){
            done2 = 1;
         }
      }
   }
   
   //Trail
   //processPosition(trail);
      
   if(TimeCurrent()>Stop){
      if(days!=newdays){
         checkPositions();
         //timeExit(trail);
         days=newdays;
         //Comment("ID: ", Magic, "\n\nBuy Position Duration: ", n1, "\nSell Position Duration: ", n2);
      }
      closeAllPositions();
   }
   
}

//+------------------------------------------------------------------+
void positionSize(int slpoints)
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
   //n
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
            if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP || OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT)
            {
               buyPosition+=1;
            }
            else if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP || OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT)
            {
               sellPosition+=1;
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


//+------------------------------------------------------------------+

void session(){
   //Time
   now = TimeCurrent();
   today = TimeToString(TimeCurrent(), TIME_DATE);
   if(today!=yesterday)
   {
      yesterday = today;
      Start = StringToTime(today+" "+Trade_Start);
      Stop = StringToTime(today+" "+Trade_Stop);
      Expiration = StringToTime(today+" "+expire);
      done1 = 0;
      done2 = 0;
      //Entry
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, PERIOD_D1, 0, 2, Price);
      open = Price[1].close;
      ObjectMove(0, "Open", 0, _Period, open);
      newdays = iBars(_Symbol, PERIOD_D1);
                    
   }
}

void executeBuyStop(double entry){
   //double Sl = NormalizeDouble((SlPoints*_Point)+(ATR[1]), _Digits);
   //positionSize(round(Sl/_Point));
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellStop(double entry){
   //double Sl = NormalizeDouble((SlPoints*_Point)+(ATR[1]), _Digits);
   //positionSize(round(Sl/_Point));
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeBuyLimit(double entry){
   //double Sl = NormalizeDouble((SlPoints*_Point)+(ATR[1]), _Digits);
   //positionSize(round(Sl/_Point));
   positionSize(SlPoints);
   trade.BuyLimit(Lot, entry, _Symbol, entry-SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void executeSellLimit(double entry){
   //double Sl = NormalizeDouble((SlPoints*_Point)+(ATR[1]), _Digits);
   //positionSize(round(Sl/_Point));
   positionSize(SlPoints);
   trade.SellLimit(Lot, entry, _Symbol, entry+SlPoints*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void processPosition(int bars){
   if(PositionsTotal()==0) return;
   for(int i =0; i<PositionsTotal(); i++){
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket)){
         if (PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetString(POSITION_SYMBOL)== _Symbol){
            //Position Open
            double High[];
            CopyHigh(_Symbol, Timeframe, 0, bars, High);
            double Low[];
            CopyLow(_Symbol, Timeframe, 0, bars, Low);
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
               double Trail = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)];
               double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
            
               if(PositionGetDouble(POSITION_SL)!=Trail && Ask>PositionGetDouble(POSITION_PRICE_OPEN)+200*_Point){
                  //trade.PositionModify(ticket, Trail, NULL);
                  positionModify(POSITION_TYPE_BUY, Trail);
               }
            }
            else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
               double Trail = High[ArrayMaximum(High, 0, WHOLE_ARRAY)];
               double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
               
               if(PositionGetDouble(POSITION_SL)!=Trail && Bid<PositionGetDouble(POSITION_PRICE_OPEN)-200*_Point){
                  //trade.PositionModify(ticket, Trail, NULL);
                  positionModify(POSITION_TYPE_SELL, Trail);
               }
            }
         }
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