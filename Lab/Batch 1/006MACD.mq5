#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 006;
input ENUM_TIMEFRAMES Timeframe = PERIOD_MN1;
input double FixedLot = 0;
input double risk = 0.01; //Risk
double Lot = FixedLot;
int A = 0; //Start Time
input int Z = 20; //End Time
int E = 18; //Expiration Time

enum intOptionsA{
   A1 = 1, //Gold
   A2 = 1, //Stocks
   A3 = 2, //Currencies
};

input intOptionsA Market = A1;

string today;
string yesterday;
string today2;
string yesterday2;
datetime Start;
datetime Stop;
datetime Expiration;
string Trade_Start = string(A)+":30:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time
string Trade_Expiration = string(E)+":00:00"; //Expiration Time




//+------------------------------------------------------------------+

double bar;
double newbar;
string text;
int buyPosition;
int sellPosition;
int done1 = 0;
int done2 = 0;
double MACD[];
double SIGNAL[];
int MACDHandler;
double RSI[];
int RSIHandler;
double main;
double signal;
string x;
MqlRates Price[];

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   Comment("ID: ", Magic);
   MACDHandler = iCustom(_Symbol, Timeframe, "Examples/MACD.ex5");
   RSIHandler = iRSI(_Symbol, Timeframe, 14, PRICE_CLOSE);
   ArraySetAsSeries(MACD, true);
   ArraySetAsSeries(SIGNAL, true);
   ArraySetAsSeries(RSI, true);
   ArraySetAsSeries(Price, true);
}

//+------------------------------------------------------------------+




void OnTick(){
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
         CopyBuffer(MACDHandler, 0, 0, 3, MACD);
         main = NormalizeDouble(MACD[1], 3);
         CopyBuffer(MACDHandler, 1, 0, 3, SIGNAL);
         signal = NormalizeDouble(SIGNAL[1], 3);
         CopyBuffer(RSIHandler, 0, 0, 3, RSI);
         
         checkPositions();
         
         if(main>signal){
            if(buyPosition==0 && RSI[0]>50){// && MACD[2]<SIGNAL[2]){ //55????
               executeBuy();
            }
            if(sellPosition>0){
               if(Market !=1)
               closePosition(POSITION_TYPE_SELL);
               //positionModify(POSITION_TYPE_SELL, Price[1].high, NULL);
            }
         }
         if(main<signal){
            if(sellPosition==0 && RSI[0]<50){// && MACD[2]>SIGNAL[2]){
               if(Market!=1)
               executeSell();
            }
            if(buyPosition>0){
               closePosition(POSITION_TYPE_BUY);
               //positionModify(POSITION_TYPE_BUY, Price[1].low, NULL);
            }
         }
         
         //Comment
         if(RSI[0]>=50){
            x = "Bullish";
         }
         else{
            x = "Bearish";
         }
         Comment("ID: ", Magic, "\nMomentum: ", x);
            
         yesterday = today;
      }
   }
   
  


}



//+------------------------------------------------------------------+



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

void positionModify(ENUM_POSITION_TYPE type, double sl, double tp){
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
               trade.PositionModify(ticket, sl, tp);
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


void executeBuy(){
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   trade.Buy(Lot, _Symbol, Ask, NULL, NULL, text);
}

void executeSell(){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   trade.Sell(Lot, _Symbol, Bid, NULL, NULL, text);
}
