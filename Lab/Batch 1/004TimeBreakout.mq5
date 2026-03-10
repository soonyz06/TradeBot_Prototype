#include<Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+

///Variables
input ulong Magic = 004;
input double FixedLot = 0; 
input double risk = 0.005; //Risk
input int A = 4; //Range Start 
input int B = 8; //Trade Start
input int D = 20; //Trade End
int E = 20; //Expiration
input int x = 500; //SlPoints
//input int T = 1; //Trade-Limiter
int input Exit = 35; //Timed Exit
int o = 0;

string Dorm_Start = string(A)+":00:00";
string Dorm_Stop = string(B)+":00:00";
string Trade_Start = string(B)+":00:00";
string Trade_Stop = string(D)+":00:00";
string Expiration_ = string(E)+":00:00";
double Lot;
double SlPoints;
int Position;
double Max;
double Min;
int n1=0;
int n2=0;
//+------------------------------------------------------------------+

string day;
int bar;
int newbar;
string yesterday;
datetime Start; 
datetime Stop;
datetime TradeStart;
datetime TradeStop;
datetime Expiration;
string text; 
int done1;
int done2;
int buyPosition;
int sellPosition;
int days;
int newdays;

///Initialise
void OnInit()
{
   trade.SetExpertMagicNumber(Magic);
   bar = 0;
   yesterday = "0";
   text = "RB"+string(Magic);
   //Line
   ObjectCreate(0, "Max", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Max", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Min", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Min", OBJPROP_COLOR, clrWhite);
   Comment("ID: ", Magic);
   days = iBars(_Symbol, PERIOD_D1);
}
//+------------------------------------------------------------------+

///Start
void OnTick()
{   
   ///Time
   datetime now = TimeCurrent();
   string today = TimeToString(now, TIME_DATE);
   if(today != yesterday){
      ///MT4 time + 5 -> Malaysia Time
      Start = StringToTime(today+" "+Dorm_Start);
      Stop = StringToTime(today+" "+Dorm_Stop);
      TradeStart = StringToTime(today+" "+Trade_Start);
      TradeStop = StringToTime(today+" "+Trade_Stop);
      Expiration = StringToTime(today+" "+Expiration_);
      done1 = 0;
      done2 = 0;
      yesterday = today;
      newdays = iBars(_Symbol, PERIOD_D1);
   } 
   
   //+------------------------------------------------------------------+
   
   ///Range
   double Top[];
   ArraySetAsSeries(Top, true);
   CopyHigh(_Symbol, PERIOD_M15, Start, Stop, Top);
   double Low[];
   ArraySetAsSeries(Low, true);
   CopyLow(_Symbol, PERIOD_M15, Start, Stop, Low);
   
   //+------------------------------------------------------------------+
   
   if (ArraySize(Top)>0 && ArraySize(Low)>0)
   {
      //Line
      Max =  Top[ArrayMaximum(Top, 0, WHOLE_ARRAY)];
      Min = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)];
      ObjectMove(0, "Max", 0, _Period, Max);
      ObjectMove(0, "Min", 0, _Period, Min);
   
      //Box
      ObjectCreate(0, "Range", OBJ_RECTANGLE, 0, Start, Max, Stop, Min);
      ObjectSetInteger(0, "Range", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, "Range", OBJPROP_FILL, true);
      ObjectSetInteger(0, "Range", OBJPROP_BACK, true);
      
      ///Live
      newbar = iBars(_Symbol, PERIOD_M15);
      if(bar!=newbar){
         if((now>TradeStart && now<TradeStop)){
            checkPositions();
            if(buyPosition==0 && done1==0){
               executeBuy(Max+10*_Point);
               done1 = 1;
            }
            if(sellPosition==0 && done2==0){
               executeSell(Min-10*_Point);
               done2 = 1;
            }
            checkPositions();
            if(buyPosition==1 && sellPosition==1){
               
            }
         }
         checkPositions();
         //processPosition(trail);
         bar = newbar;
      }
     
    //+------------------------------------------------------------------+  
    
    }
   //Close
   if(TimeCurrent()>Stop){
      if(days!=newdays){
         checkPositions();
         timeExit(Exit);
         days=newdays;
         Comment("ID: ", Magic, "\n\nBuy Position Duration: ", n1, "\nSell Position Duration: ", n2);
      }
      //closeAllPositions();
   }
   
   ObjectCreate(0, "Mid", OBJ_HLINE, 0, _Period, ((Max+Min)/2));
      
}

//+------------------------------------------------------------------+

///Functions
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

void positionSize(double slpoints)
{
   if(FixedLot == 0)
   {
      string symbol = _Symbol;
      string Curr1 = StringSubstr(symbol, 0, 3);
      string Curr2 = StringSubstr(symbol, 3, 3);
      double balance;
      //Comment(Curr1);
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

void executeBuy(double entry){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Sl;
   SlPoints  = x;
   Sl = NormalizeDouble(entry-SlPoints*_Point, _Digits);
   positionSize(SlPoints);
   trade.BuyStop(Lot, entry, _Symbol, Sl+o*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);;
}

void executeSell(double entry){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Sl;
   SlPoints = x;
   Sl = NormalizeDouble(entry-SlPoints*_Point, _Digits);
   positionSize(SlPoints);
   trade.SellStop(Lot, entry, _Symbol, Sl-o*_Point, NULL, ORDER_TIME_SPECIFIED, Expiration, text);
}

void processPosition(int bars){
   if(PositionsTotal()==0) return;
   for(int i =0; i<PositionsTotal(); i++){
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket)){
         if (PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetString(POSITION_SYMBOL)== _Symbol){
            //Position Open
            double High[];
            CopyHigh(_Symbol, _Period, 0, bars, High);
            double Low[];
            CopyLow(_Symbol, _Period, 0, bars, Low);
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
