#include <Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 1200;
string yesterday;
string today;
string Day;
double DO;
double high;
double low;
int MaHandler;
int x;
double High[5]; 
double Low[5];    
double Imb[5];
double Score[3][5]; 

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
   yesterday = "0";
   MaHandler = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE);
   ObjectCreate(0, "DO", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "High", OBJ_HLINE, 0, _Period, 0);
   ObjectCreate(0, "Low", OBJ_HLINE, 0, _Period, 0);
   ObjectSetInteger(0, "DO", OBJPROP_COLOR, clrWheat);
   ObjectSetInteger(0, "High", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "Low", OBJPROP_COLOR, clrWhite);  
   ArrayInitialize(Score, 0); 
}

void OnTick(){
   today = TimeToString(TimeCurrent(), TIME_DATE);
   if(yesterday!=today){
      MqlDateTime Today;
      TimeCurrent(Today);
      Day = EnumToString((ENUM_DAY_OF_WEEK)Today.day_of_week);
      //Comment(Day);
      
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, PERIOD_D1, 0, 3, Price);
      
      double MA[];
      ArraySetAsSeries(MA, true);
      CopyBuffer(MaHandler, 0, 0, 1, MA);
      
      
           
      if(Day == "TUESDAY"){
         ArrayInitialize(High, 0);
         ArrayInitialize(Low, 0);
         ArrayInitialize(Imb, 0);
         High[0] = Price[1].high;
         Low[0] = Price[1].low;
         Imb[0] = Price[1].high-Price[1].low;
      }
      else if(Day=="WEDNESDAY"){
         High[1] = Price[1].high;
         Low[1] = Price[1].low;
         Imb[1] = Price[1].high-Price[1].low;
      }
      else if(Day=="THURSDAY"){
         High[2] = Price[1].high;
         Low[2] = Price[1].low;
         Imb[2] = Price[1].high-Price[1].low;
      }
      else if(Day=="FRIDAY"){
         High[3] = Price[1].high;
         Low[3] = Price[1].low;
         Imb[3] = Price[1].high-Price[1].low;
      }
      else if(Day == "MONDAY"){
         High[4] = Price[1].high;
         Low[4] = Price[1].low;
         Imb[4] = Price[1].high-Price[1].low;
         Score[0][ArrayMaximum(High, 0, WHOLE_ARRAY)] += 1;
         Score[1][ArrayMinimum(Low, 0, WHOLE_ARRAY)] += 1;
         Score[2][ArrayMaximum(Imb, 0, WHOLE_ARRAY)] += 1;
      }
      
      Comment(Day, "\n                   High     Low     Movement\nMonday       :", 
      Score[0][0], "     ", Score[1][0], "     ", Score[2][0], "     ", "\nTuesday     : ",
      Score[0][1], "     ", Score[1][1], "     ", Score[2][1], "     ", "\nWednesday: ", 
      Score[0][2], "     ", Score[1][2], "     ", Score[2][2], "     ", "\nThursday    : ",
      Score[0][3], "     ", Score[1][3], "     ", Score[2][3], "     ", "\nFriday         : ", 
      Score[0][4], "     ", Score[1][4], "     ", Score[2][4]);
      yesterday = today;
   }
}

void OnDeinit(const int reason){
   Print(Day, "\n                   High     Low     Movement\nMonday       :", 
      Score[0][0], "     ", Score[1][0], "     ", Score[2][0], "     ", "\nTuesday     : ",
      Score[0][1], "     ", Score[1][1], "     ", Score[2][1], "     ", "\nWednesday: ", 
      Score[0][2], "     ", Score[1][2], "     ", Score[2][2], "     ", "\nThursday    : ",
      Score[0][3], "     ", Score[1][3], "     ", Score[2][3], "     ", "\nFriday         : ", 
      Score[0][4], "     ", Score[1][4], "     ", Score[2][4]);
}