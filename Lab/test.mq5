#include <Trade\Trade.mqh>
CTrade trade;

// This is the strategy's parameters.
int period = 50;
int deviation = 2;
int stoploss = 100;
int takeprofit = 200;
// This is the strategy's logic.
void OnTick() {
    // Calculate the simple moving average of the price data.
    double SMA = MovingAverage(Symbol(), period);
    // Calculate the Bollinger bands of the price data.
    double UpperBand = SMA + deviation * StandardDeviation(Symbol(), period);
    double LowerBand = SMA - deviation * StandardDeviation(Symbol(), period);
    // If the price is above the upper Bollinger band, go long.
    if (Close > UpperBand) {
        Buy(Symbol(), MarketOrder, 100000, stoploss, takeprofit);
    }
    // If the price is below the lower Bollinger band, go short.
    if (Close < LowerBand) {
        Sell(Symbol(), MarketOrder, 100000, stoploss, takeprofit);
    }
}