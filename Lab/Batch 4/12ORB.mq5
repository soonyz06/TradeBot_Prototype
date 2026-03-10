#include<Trade\Trade.mqh>
CTrade trade;

//Inputs
input ulong Magic = 102;
input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
double risk = 0.01; //Risk
input double FixedLot = 0;
//input int SlPoints = 1500;
//input int TimeExit= 10;
input int BreakEven = 300;
input int Buffer = 10;
input int Band = 1000;
input string Time=""; //
input int B = 0; //Dorm Start Time
input int A = 7; //Start Time
input int Z = 18; //End Time
int E = 18; //Expiration Time


//Variables
double Lot;
string today;
string yesterday;
datetime Dorm;
datetime Start;
datetime Stop;
datetime Expiration;
string Range_Start = string(B)+":00:00"; //Dorm Start Time
string Trade_Start = string(A)+":30:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time
string Trade_Expiration = string(E)+":00:00"; //Expiration Time
int bar1;
int bar2;
int bar3;
int newbar;
int newbar2;
string text;
MqlRates Price[];
double High[];
double Low[];
double Max;
double Min;
int buy;
int sell;



//---------------------------------------------------------------------------------------------------------



void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = string(Magic);
   bar1=0;
   bar2=0;
   yesterday="";
   ArraySetAsSeries(Price, true);
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Low, true);
   ObjectCreate(0, "Max", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Max", OBJPROP_COLOR, clrWhite);
   ObjectCreate(0, "Min", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "Min", OBJPROP_COLOR, clrWhite);
   
   Comment("ID: ", Magic);
}

void OnTick(){
   today = TimeToString(TimeCurrent(), TIME_DATE);
   if(today!=yesterday)
   {      
      Dorm = StringToTime(today+" "+Range_Start);
      Start = StringToTime(today+" "+Trade_Start);
      Stop = StringToTime(today+" "+Trade_Stop);
      Expiration = StringToTime(today+" "+Trade_Expiration);
      Comment("ID: ", Magic, "\nToday: ",today);
      yesterday=today;
   }


   newbar= iBars(_Symbol, Timeframe);
   if(bar1!=newbar){
      if(TimeCurrent()>Start){
         //High and Low
         CopyRates(_Symbol, _Period, 0, 3, Price);
         CopyHigh(_Symbol, _Period, Dorm, Start, High);
         CopyLow(_Symbol, _Period, Dorm, Start, Low);
         
         if(ArraySize(High)>0 && ArraySize(Low)>0){
            Max = High[ArrayMaximum(High, 0, WHOLE_ARRAY)];
            Min = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)];
            ObjectMove(0, "Max", 0, _Period, Max);
            ObjectMove(0, "Min", 0, _Period, Min);
            
            //Box
            ObjectCreate(0, "Range", OBJ_RECTANGLE, 0, Dorm, Max, Start, Min);
            ObjectSetInteger(0, "Range", OBJPROP_COLOR, clrCyan);
            ObjectSetInteger(0, "Range", OBJPROP_FILL, true);
            ObjectSetInteger(0, "Range", OBJPROP_BACK, true);
            
            //Orders
            ExecuteBuyStop(Max, Min);
            ExecuteSellStop(Min, Max);
            CheckPositions(buy, sell);    
            
            //Print(Price[0].high, "\n", Max, "\n", Price[0].low, "\n", Min);
            //???????  Current ask price is above entry price, so wait next bar??
            //if(buy==0)
               //ExecuteBuy(Min);
            //if(sell==0)
               //ExecuteSell(Max);
            
            CheckPositions(buy, sell);
         }
         bar1=newbar;
      }
   }
   
   if(bar2!=newbar){
      if(TimeCurrent()>Stop || Timeframe!=PERIOD_D1){
         ClosePosition(POSITION_TYPE_BUY);
         ClosePosition(POSITION_TYPE_SELL);
         CheckPositions(buy, sell);
         bar2=newbar;
      
      }
   }
   
   newbar2 = iBars(_Symbol, PERIOD_M1);
   if(bar3!=newbar2){
      ProcessPosition();
      bar3=newbar2;
   }
}



//---------------------------------------------------------------------------------------------------------



void ExecuteBuy(double sl=NULL, double tp=NULL){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(tp!=0) tp = Ask+tp*_Point;
   if(sl!=0) sl = Ask-sl*_Point;
   
   if(MathAbs(Ask-sl)/_Point > Band && Band>0) 
      trade.Buy(Lot, _Symbol, Ask, Ask-Band*_Point, tp, text);
   else
      trade.Buy(Lot, _Symbol, Ask, sl, tp, text);
}

void ExecuteSell(double sl=NULL, double tp=NULL){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(tp!=0) tp = Bid-tp*_Point;
   if(sl!=0) sl = Bid+sl*_Point;
   
   if(MathAbs(Bid-sl)/_Point > Band && Band>0) 
      trade.Sell(Lot, _Symbol, Bid, Bid-Band*_Point, tp, text);
   else
      trade.Sell(Lot, _Symbol, Bid, sl, tp, text);
}

void ExecuteBuyStop(double entry, double sl=NULL, double tp=NULL){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   //if(Ask>entry) return;
   positionSize(MathAbs(entry-sl)/_Point);
   
   if(MathAbs(entry-sl)/_Point > Band && Band>0) 
      trade.BuyStop(Lot, entry, _Symbol, entry-Band*_Point, tp, ORDER_TIME_SPECIFIED, Expiration, text);
   else 
      trade.BuyStop(Lot, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, Expiration, text);
   
}

void ExecuteSellStop(double entry, double sl=NULL, double tp=NULL){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   //if(Bid<entry) return;
   positionSize(MathAbs(entry-sl)/_Point);
   
   if(MathAbs(entry-sl)/_Point > Band && Band>0) 
      trade.SellStop(Lot, entry, _Symbol, entry+Band*_Point, tp, ORDER_TIME_SPECIFIED, Expiration, text);
   else 
      trade.SellStop(Lot, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, Expiration, text);
}

void CheckPositions(int& _buyPosition, int& _sellPosition, bool inclusive = true){  
   _buyPosition=0;
   _sellPosition=0;
   
   ulong _ticket;
   long _magic;
   string _symbol;
   long _type; //ENUM?
   
   if(inclusive == true){
      for(int i=0; i<OrdersTotal(); i++){
         _ticket = OrderGetTicket(i);
         
         if(OrderSelect(_ticket)){
            _magic = OrderGetInteger(ORDER_MAGIC);
            _symbol = OrderGetString(ORDER_SYMBOL);
            _type = OrderGetInteger(ORDER_TYPE);
            if(_magic == Magic && _symbol == _Symbol){
               if(_type == ORDER_TYPE_BUY_STOP || _type == ORDER_TYPE_BUY_LIMIT){
                  _buyPosition+=1;
               }
               else if(_type == ORDER_TYPE_SELL_STOP || _type == ORDER_TYPE_SELL_LIMIT){
                  _sellPosition+=1;
               }
            }
         }
      }
   }
   
   for(int i=0; i<PositionsTotal(); i++){
      _ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(_ticket)){
         _magic = PositionGetInteger(POSITION_MAGIC);
         _symbol = PositionGetString(POSITION_SYMBOL);
         _type = PositionGetInteger(POSITION_TYPE);
         if(_magic == Magic && _symbol == _Symbol){
            if(_type == POSITION_TYPE_BUY){
               _buyPosition+=1;
            }
            else if(_type == POSITION_TYPE_SELL){
               _sellPosition+=1;
            }
         }
      }
   }
}

void TimeUpdate(int& _buyDuration , int& _sellDuration){
   _buyDuration = 0;
   _sellDuration = 0;
   
   ulong _ticket;
   long _magic;
   string _symbol;
   long _type; 
   
   for(int i=0; i<PositionsTotal(); i++){
      _ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(_ticket)){
         _magic = PositionGetInteger(POSITION_MAGIC);
         _symbol = PositionGetString(POSITION_SYMBOL);
         _type = PositionGetInteger(POSITION_TYPE);
         if(_magic == Magic && _symbol == _Symbol){
            if(_type == POSITION_TYPE_BUY){
               _buyDuration = iBarShift(_Symbol, Timeframe, PositionGetInteger(POSITION_TIME), false);
            }
            else if(_type == POSITION_TYPE_SELL){
               _sellDuration = iBarShift(_Symbol, Timeframe, PositionGetInteger(POSITION_TIME), false);
               
            }
         }
      }
   }
   
   Comment("ID: ", Magic, "\nBuy Duration: ", _buyDuration, "\nSell Duration: ", _sellDuration);
}

void TimeExit(int n, int _buyDuration, int _sellDuration){
   if(_buyDuration>=n) ClosePosition(POSITION_TYPE_BUY);
   if(_sellDuration>=n) ClosePosition(POSITION_TYPE_SELL);
}

void ClosePosition(ENUM_POSITION_TYPE _type){
   int _closed = 0;
   int i;
   ulong _ticket;
   long _magic;
   string _symbol;
   
   for(int j =0; j<PositionsTotal(); j++)
   {
      i = j-_closed;      
      _ticket = PositionGetTicket(i);
      
      if (PositionSelectByTicket(_ticket))
      {
         _magic = PositionGetInteger(POSITION_MAGIC);
         _symbol = PositionGetString(POSITION_SYMBOL);
         if (_magic==Magic && _symbol == _Symbol)
         {
            if(PositionGetInteger(POSITION_TYPE) == _type)
            {
               trade.PositionClose(_ticket);
               _closed +=1;
            }
         }
      }
   }
}

bool InProfit(ENUM_POSITION_TYPE type){
   ulong _ticket;
   long _magic;
   string _symbol;
   double _profitMargin;
   
   for(int i=0; i<PositionsTotal(); i++){
      _ticket = PositionGetTicket(i);
      
      if (PositionSelectByTicket(_ticket))
      {
         _magic = PositionGetInteger(POSITION_MAGIC);
         _symbol = PositionGetString(POSITION_SYMBOL);
         if (_magic==Magic && _symbol == _Symbol)
         {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
            _profitMargin = PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN);
            else
            _profitMargin = PositionGetDouble(POSITION_PRICE_OPEN)-PositionGetDouble(POSITION_PRICE_CURRENT);
            
            if(type == PositionGetInteger(POSITION_TYPE) && _profitMargin>BreakEven*_Point){
               return true;
            }
         }
      }
   }
   return false;
}

void ProcessPosition(){
   if(BreakEven<0) return;
   
   if(InProfit(POSITION_TYPE_BUY)){
      BreakEven(POSITION_TYPE_BUY);
      //ClosePosition(POSITION_TYPE_BUY);
      //Print("Hello");
   }
   if(InProfit(POSITION_TYPE_SELL)){
      BreakEven(POSITION_TYPE_SELL);
      //ClosePosition(POSITION_TYPE_SELL);
      //Print("Hello");
   }
}

void BreakEven(ENUM_POSITION_TYPE type){
   ulong _ticket;
   long _magic;
   string _symbol;
   for(int i=0; i<PositionsTotal(); i++){
      _ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(_ticket))
      {
         _magic = PositionGetInteger(POSITION_MAGIC);
         _symbol = PositionGetString(POSITION_SYMBOL);
         if(_magic == Magic && _symbol == _Symbol)
         {
            //Print(MathRound(MathAbs(PositionGetDouble(POSITION_SL)-PositionGetDouble(POSITION_PRICE_OPEN))/_Point));
            if(type == PositionGetInteger(POSITION_TYPE) && MathRound(MathAbs(PositionGetDouble(POSITION_SL)-PositionGetDouble(POSITION_PRICE_OPEN))/_Point)!=Buffer){
               if(type == POSITION_TYPE_BUY)
                  trade.PositionModify(_ticket, PositionGetDouble(POSITION_PRICE_OPEN)+Buffer*_Point, PositionGetDouble(POSITION_TP));  
               else 
                  trade.PositionModify(_ticket, PositionGetDouble(POSITION_PRICE_OPEN)-Buffer*_Point, PositionGetDouble(POSITION_TP));
               return; 
            }
         }
      }  
   }
}

void positionSize(double slpoints) //old code
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


///Problem with scalping using buy-stop orders is high spreads