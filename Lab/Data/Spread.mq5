#include<Trade\Trade.mqh>
CTrade trade;

input int Magic = 69;

void OnInit(){
   trade.SetExpertMagicNumber(Magic);
}


void OnTick(){
   //Spread
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   Comment("Spread: ", int((Ask-Bid)/_Point));
}