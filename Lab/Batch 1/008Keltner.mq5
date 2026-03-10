#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 008;
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15;
enum intOptionsA{
   A1 = 1, //EURUSD
   A2 = 2, //Others
};

input intOptionsA Market = A1;
input double FixedLot = 0; 
input double risk = 0.01; //Risk
double Lot;
int E = 1; //Entry ATR
input int s = 5; //SL ATR
input int t = 5; //TSL ATR
input int b = 0; //BE ATR
//-1, 0, 2  
//input int e = 5; //TBE ATR
string today;
string yesterday;
datetime Start;
datetime Stop;
datetime now;
input int A = 8; //Start Time
input int Z = 20; //End Time
string Trade_Start = string(A)+":00:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time

//eurusd 552 / 31
//usdjpy 251
//gbpjpy 352
//+------------------------------------------------------------------+

double bar;
double newbar;
string text;
int buyPosition;
int sellPosition;
int done1 = 0;
int done2 = 0;
double ATR[];
double MA[];
double Upper[];
double Lower[];
double Middle[];
double RSI[];
int ATRHandler;
int MAHandler;
int KNHandler;
int RSIHandler;
double entry1;
double entry2;
double tsl;
double even;
double bsl;
int tslflag;
double dp;
int dpt[6];
int dpw[6];
double dpm[6];
double profit;

//+------------------------------------------------------------------+

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   text = "S"+string(Magic);
   bar = 0;
   yesterday = "0";
   Comment("ID: ", Magic);
   ATRHandler = iATR(_Symbol, Timeframe, 20);
   KNHandler = iCustom(_Symbol, Timeframe, "Examples\Keltner_Band.ex5");
   MAHandler = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
   //RSIHandler = iRSI(_Symbol, Timeframe, 20, PRICE_CLOSE);
   ObjectCreate(0, "Entry", OBJ_HLINE, 0, 0, 0);
   ObjectSetInteger(0, "Entry", OBJPROP_COLOR, clrPink);
   ObjectCreate(0, "TSL", OBJ_HLINE, 0, 0, 0);
   ObjectSetInteger(0, "TSL", OBJPROP_COLOR, clrLimeGreen);
   tslflag = 0;
}

//+------------------------------------------------------------------+

void OnDeinit(const int reason){
   displayData();
}

//+------------------------------------------------------------------+

void OnTick(){
   newbar = iBars(_Symbol, Timeframe);
   session();
   if(bar!=newbar){
      //Price
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, Timeframe, 0, 3, Price);
      
      ArraySetAsSeries(Upper, true);
      CopyBuffer(KNHandler, 0, 0, 3, Upper);
      ArraySetAsSeries(Lower, true);
      CopyBuffer(KNHandler, 1, 0, 3, Lower);
      ArraySetAsSeries(Middle, true);
      CopyBuffer(KNHandler, 2, 0, 3, Middle);
      
      ArraySetAsSeries(ATR, true);
      CopyBuffer(ATRHandler, 0, 0, 3, ATR);
      ArraySetAsSeries(MA, true);
      CopyBuffer(MAHandler, 0, 0, 3, MA);
      //ArraySetAsSeries(RSI, true);
      //CopyBuffer(RSIHandler, 0, 0, 3, RSI);
      
      //Entry
      if(TimeCurrent()>Start && TimeCurrent()<Stop){
         checkPositions();
         if(Price[2].close<Lower[2] && Price[1].close<MA[1]){ //swap
            ObjectMove(0, "Entry", 0, _Period, Price[2].close-(ATR[1]));
            if(Price[1].close<Price[2].close-(ATR[1]*E)){
               executeSell();                                 //swap
            } 
         }
         if(Price[2].close>Upper[2] && Price[1].close>MA[1]){
            ObjectMove(0, "Entry", 0, _Period, Price[2].close+(ATR[1]));
            if(Price[1].close>Price[2].close+(ATR[1]*E)){
               executeBuy();
            }
         }
      }
      
      //Exit      
      //Opposite entry as Exit
      if(Price[2].close<Lower[2] && Price[1].close<Price[2].close-(ATR[1]*E) && Price[1].close>tsl){
         //closePosition(POSITION_TYPE_BUY);
      }
      if(Price[2].close>Upper[2] && Price[1].close>Price[2].close+(ATR[1]*E) && Price[1].close<tsl){
         //closePosition(POSITION_TYPE_SELL);
      }
      
      //Close inside belt as Exit
      if(Price[1].close<Upper[1] && Price[1].close>tsl && buyPosition>0){
         checkProfit();
         dataM();
         
         closePosition(POSITION_TYPE_BUY);
         data(dpw);
         dp = 0;
      }
      if(Price[1].close>Lower[1] && Price[1].close<tsl && sellPosition>0){
         checkProfit();
         dataM();
         
         closePosition(POSITION_TYPE_SELL);
         data(dpw);
         dp = 0;
      }
     
      //Breakeven
      if(Price[1].close<tsl && bsl!=0){
         positionModify(POSITION_TYPE_SELL, bsl, NULL);
      }
      
      if(Price[1].close>tsl && bsl!=0){
         positionModify(POSITION_TYPE_BUY, bsl, NULL);
      }

      //Aesthetic 
      //Comment(dpw[0], dpt[0], "\n",dpw[1], dpt[1], "\n",dpw[2], dpt[2], "\n",dpw[3], dpt[3], "\n",dpw[4], dpt[4], "\n", dpw[5], dpt[5], "\n");
      if(buyPosition == 0 && sellPosition == 0){
         ObjectMove(0, "Entry", 0, _Period, 0);
         ObjectMove(0, "TSL", 0, _Period, 0);
      }
      
      if(Price[1].close<MA[1]){
         Comment("ID: ", Magic, "\nTrend: Bearish");
      }
      else if(Price[1].close>MA[1]){
         Comment("ID: ", Magic, "\nTrend: Bullish");
      }
      

      bar=newbar;
      
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


void session(){
   //Time
   now = TimeCurrent();
   today = TimeToString(TimeCurrent(), TIME_DATE);
   if(today!=yesterday)
   {
      yesterday = today;
      Start = StringToTime(today+" "+Trade_Start);
      Stop = StringToTime(today+" "+Trade_Stop);                    
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
               if(NormalizeDouble(PositionGetDouble(POSITION_SL), 5)!=NormalizeDouble(sl, 5)){
                  trade.PositionModify(ticket, sl, tp);
                  //Print(PositionGetDouble(POSITION_SL), sl);
               }
               else{
                  bsl = 0;
               }
            }
         }
      }
   }
}

void executeBuy(){
   if(buyPosition>0) return;
   dp = ATR[1]/_Point;
   
   if((dp<60 || dp>90)&& Market==1) return; //90 more recent, overall 120
   
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   positionSize((ATR[1]*s)/_Point);
   trade.Buy(Lot, _Symbol, Ask, NormalizeDouble(Ask-ATR[1]*s, _Digits), NULL, text);
   entry1 = Ask;
   tsl = Ask+ATR[1]*t;
   //even = Ask+ATR[1]*e;
   bsl = Ask-ATR[1]*b;
   ObjectMove(0, "TSL", 0, _Period, tsl);
   dp = ATR[1]/_Point;
   data(dpt);
}

void executeSell(){
   if(sellPosition>0) return;
   dp = ATR[1]/_Point;
   
   if((dp<60 || dp>90)&& Market==1) return;
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   positionSize((ATR[1]*s)/_Point);
   trade.Sell(Lot, _Symbol, Bid, NormalizeDouble(Bid+ATR[1]*s, _Digits), NULL, text);
   entry2 = Bid;
   tsl = Bid-ATR[1]*t;
   //even = Bid-ATR[1]*e;
   bsl = Bid+ATR[1]*b;
   ObjectMove(0, "TSL", 0, _Period, tsl);
   dp = ATR[1]/_Point;
   data(dpt);
}

void data(int & dps[]){
   if(dp==0) return;
   
   if(Market==1){
      if(dp<65){ //60-65
         dps[0]+=1;
      }
      else if (dp<70){ //65-70
         dps[1]+=1;
      }
      else if(dp<75){ //70-75
         dps[2]+=1;
      }
      else if(dp<80){ //75-80
         dps[3]+=1;
      }
      else if(dp<85){ //80-85
         dps[4]+=1;
      }
      else if(dp>85){ //85-90
         dps[5]+=1;
      }
   }
   else{
      if(dp<60){ //40-60
         dps[0]+=1;
      }
      else if (dp<80){ //60-80
         dps[1]+=1;
      }
      else if(dp<100){ //80-100
         dps[2]+=1;
      }
      else if(dp<120){ //100-120
         dps[3]+=1;
      }
      else if(dp<140){ //120-140
         dps[4]+=1;
      }
      else if(dp>140){ //>140
         dps[5]+=1;
      }
   }
   
}

void dataM(){
   if(dp==0) return;
   
   if(Market == 1){
         checkProfit();
         if(dp<65){ 
            dpm[0]+=profit;
         }
         else if (dp<70){ 
            dpm[1]+=profit;
         }
         else if(dp<75){ 
            dpm[2]+=profit;
         }
         else if(dp<80){ 
            dpm[3]+=profit;
         }
         else if(dp<85){ 
            dpm[4]+=profit;
         }
         else if(dp>85){ 
            dpm[5]+=profit;
         }  
      }
   else{
         checkProfit();
         if(dp<60){ 
            dpm[0]+=profit;
         }
         else if (dp<80){  //60-100 recent
            dpm[1]+=profit;
         }
         else if(dp<100){ 
            dpm[2]+=profit;
         }
         else if(dp<120){ 
            dpm[3]+=profit;
         }
         else if(dp<140){  //120-140 kill?
            dpm[4]+=profit;
         }
         else if(dp>140){ 
            dpm[5]+=profit;
         }        
   
   }
}

void displayData(){
   double output;
   for (int i = 0; i<6 ; i++){
      if(dpt[i]==0){
         Print("No Trades\n");
      }
      else{
         output = NormalizeDouble(dpw[i]*100/dpt[i], 1);
         Print("Revenue: ", NormalizeDouble(dpm[i], 1), " $");
         Print("WR: ", output, " %");
         Print("Weight: ", NormalizeDouble(output*dpm[i], 1));
         Print("Trades: ", dpt[i],"\n");
      }
      
   }
   
   //Print(dpw[0], dpt[0], "\n",dpw[1], dpt[1], "\n",dpw[2], dpt[2], "\n",dpw[3], dpt[3], "\n",dpw[4], dpt[4], "\n");
}

bool checkProfit()
{
   bool B;
      
   B = false;
   profit = 0;
   for(int i =0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      string symbol = PositionGetSymbol(i);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetInteger(POSITION_MAGIC)==Magic && symbol == _Symbol)
         {
            if(PositionGetDouble(POSITION_PROFIT)>0){
               B = true;
               profit = NormalizeDouble(PositionGetDouble(POSITION_PROFIT), 2);
            }
         }
      }
   }
   
   return B;
}