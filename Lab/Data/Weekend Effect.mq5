#include<Trade\Trade.mqh>
CTrade trade;

input ulong Magic = 000;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int A = 8; //Start Time
input int Z = 20; //End Time

//+------------------------------------------------------------------+

string today;
string yesterday;
datetime Start;
datetime Stop;
datetime now;
string Trade_Start = string(A)+":00:00"; //Start Time
string Trade_Stop = string(Z)+":00:00"; //End Time

double bar;
double newbar;
int done1 = 0;
int done2 = 0;

//Variables
string Day;
double High[5]; 
double Low[5];    
double Imb[5];
double Score[3][5]; 
int N=0;
int n = 0;
int a1 = 0;
int b1 = 0;
int C3[5];
int W41=0;
int W42=0;

string Wtext1;
string Rtext2;
string Ctext3;
string Wtext4;
//+------------------------------------------------------------------+

void OnInit(){
   bar=0;
}

//+------------------------------------------------------------------+




void OnTick(){
   session();
   newbar = iBars(_Symbol, _Period);
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
      done1 = 0;
      done2 = 0;
      
      WeekRecap();
      Correlation();
      WeekTrend(500);
      N+=1;
      n = int(N/5);
      
      
      
      Comment("Today: ", Day, "\n", Ctext3);
   }
}




//+------------------------------------------------------------------+




void OnDeinit(const int reason){
   Print(Rtext2, Ctext3, Wtext4);
      
      
}




//+------------------------------------------------------------------+



//1
void WeekendEffect(){
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, PERIOD_D1, 0, 3, Price);
      
      MqlDateTime Today;
      TimeCurrent(Today);
      Day = EnumToString((ENUM_DAY_OF_WEEK)Today.day_of_week);
      
      if(Day=="TUESDAY"){
         if(Price[2].close>Price[2].open && Price[1].close>Price[1].open){
            a1+=1;
         }
         else if(Price[2].close<Price[2].open && Price[1].close<Price[1].open){
            b1+=1;
         }
      }
      
      if(n>0)      
      Wtext1 = ("\nWeekend Effect\nTotal Number of Weeks: "+ string(n)+ 
      "\nBuy Continuations: "+ string(a1)+
      "\nSell Continuations: "+ string(b1)+
      "\nPercentage of Continuation: "+ string((a1+b1)*100/n)+ "%\n");
}

//2
void WeekRecap(){
      MqlRates Price[];
      ArraySetAsSeries(Price, true);
      CopyRates(_Symbol, PERIOD_D1, 0, 3, Price);
      
      MqlDateTime Today;
      TimeCurrent(Today);
      Day = EnumToString((ENUM_DAY_OF_WEEK)Today.day_of_week);
      
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
      
      
      if(n>0)
      Rtext2 =
      "\nWeek Summary"+
           "\n              High     Low     Movement                    \nMonday      : "+ 
      string(int(Score[0][0]/n*100))+ "%     "+ string(int(Score[1][0]/n*100))+ "%     "+ string(int(Score[2][0]/n*100))+ "%     "+ "\nTuesday     : "+
      string(int(Score[0][1]/n*100))+ "%     "+ string(int(Score[1][1]/n*100))+ "%     "+ string(int(Score[2][1]/n*100))+ "%     "+ "\nWednesday   : "+ 
      string(int(Score[0][2]/n*100))+ "%     "+ string(int(Score[1][2]/n*100))+ "%     "+ string(int(Score[2][2]/n*100))+ "%     "+ "\nThursday    : "+
      string(int(Score[0][3]/n*100))+ "%     "+ string(int(Score[1][3]/n*100))+ "%     "+ string(int(Score[2][3]/n*100))+ "%     "+ "\nFriday      : "+ 
      string(int(Score[0][4]/n*100))+ "%     "+ string(int(Score[1][4]/n*100))+ "%     "+ string(int(Score[2][4]/n*100))+"%\n";
}

//3
void Correlation(){
   MqlRates Price[];
   ArraySetAsSeries(Price, true);
   CopyRates(_Symbol, PERIOD_D1, 0, 5, Price);
   
   MqlDateTime Today;
   TimeCurrent(Today);
   Day = EnumToString((ENUM_DAY_OF_WEEK)Today.day_of_week);
   
   if((Price[2].close>Price[2].open && Price[1].close>Price[1].open) || (Price[2].close<Price[2].open && Price[1].close<Price[1].open)){
      if(Day=="WEDNESDAY"){
         C3[0]+=1;
      }
      else if(Day=="THURSDAY"){
         C3[1]+=1;
      }
      else if(Day=="FRIDAY"){
         C3[2]+=1;
      }
      else if(Day=="MONDAY"){
         C3[3]+=1;
      }
      else if(Day=="TUESDAY"){
         C3[4]+=1;
      }
   }

   if(n>0)
   Ctext3 = "\nCorrelatins"+
            "\nMonday-Tuesday: "+string(int(C3[0])*100/n)+
            "%\nTuesday-Wednesday: "+string(int(C3[1])*100/n)+
            "%\nWednesday-Thursday: "+string(int(C3[2])*100/n)+
            "%\nThursday-Friday: "+string(int(C3[3])*100/n)+
            "%\nFriday-Monday: " +string(int(C3[4])*100/n)+
            "%\n";
}

//4
void WeekTrend(int distance){
   MqlRates Price[];
   ArraySetAsSeries(Price, true);
   CopyRates(_Symbol, PERIOD_D1, 0, 6, Price);
   
   MqlDateTime Today;
   TimeCurrent(Today);
   Day = EnumToString((ENUM_DAY_OF_WEEK)Today.day_of_week);
   
   if(Day == "MONDAY"){
      if(Price[5].close>Price[5].open && Price[1].close>Price[5].open+distance*_Point){
         W41+=1;
      }
      if(Price[5].close<Price[5].open && Price[1].close<Price[5].open-distance*_Point){
         W42+=1;
      }
   }
   
   if(n>0)
   Wtext4 = "\nWeeklong Trend"+
            "\nBuy Position: "+string(int(W41*100/n))+
            "%\nSell Position: "+string(int(W42*100/n))+
            "%\n";

}