//+------------------------------------------------------------------+
//|                                         knoxville_divergence.mq4 |
//|                                                     Paúl Herrera |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Avanti Servicios Financieros, C.A."
#property link      "https://avantifs.herokuapp.com"
#property version   "2.1"
#property strict
#property indicator_chart_window

//--- input parameters
input int      Periods = 30;
input bool     BullishDivergence = True;
input bool     BearishDivergence = True;

int arrowCount = 0;
double divisor = MathPow(10, Digits);


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
  }
  
 void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, OBJ_ARROW);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int limit = rates_total - prev_calculated;
   int KD, i;
   
   if(limit > 1)
     {
      for(i=1; i < limit - Periods; i++)
        {
         KD = knoxville_divergence(i);
         create_arrow(KD, i, time, high, low);
        }
     }
    else if (limit == 1)
      {
       KD = knoxville_divergence(1);
       create_arrow(KD, 1, time, high, low);
      }
    else
      {
      }
    
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//------------------------------------------------------------------------------ 1 --
//-----------------------          FUNCTIONS          -------------------------- 1 --
//------------------------------------------------------------------------------ 1 --

int knoxville_divergence(int period)         
  {
   int MinPeriod = 4, KD = 0, i, j;
   int os[210], ob[210];
   double rsi = 50;
   
   ArrayInitialize(os,999999999);
   ArrayInitialize(ob,999999999);
   
   //---- Checking if oversold/overbought.
   for (j = 0; j <= Periods; j++)
     {
       rsi = iRSI(NULL, 0, 21, PRICE_CLOSE, period + j);
       if (rsi <= 30)
         {
          os[j] = period + j;
         }
       if (rsi >= 70)
         {
          ob[j] = period + j;
         }
     }
     
   ArraySort(os);
   ArraySort(ob);

   int c = 0;
   //---- Checking for Knoxville Divergence.
   if (period>0){
   for (i = MinPeriod; i <= Periods; i++)
      {
       //---- Checking for Momentum Divergence.
       if(BullishDivergence)
         {
          if (iMomentum(NULL, 0, 20, PRICE_CLOSE, period) > iMomentum(NULL, 0, 20, PRICE_CLOSE, period + i)){
            if (iClose(NULL, 0, period) < iClose(NULL, 0, period + i)){
              if (iLow(NULL, 0, period) <= iLow(NULL,0,iLowest(NULL, 0, MODE_LOW, i, period + 1))){
                for(j=0; j < ArraySize(os); j++)
                  {
                   if (os[j] <= period + i)
                     {
                      KD = 1;
                      Print(" Bullish Divergence - Divergent periods: ", period + i, " -> ", period, 
                            ". Oversold at period: ", os[j], ". Name: arrow", arrowCount + 1);
                      return(KD);
                     }
                  }
              }
            }
          }
         }
       if(BearishDivergence)
         {
          if (iMomentum(NULL, 0, 20, PRICE_CLOSE, period) < iMomentum(NULL, 0, 20, PRICE_CLOSE, period + i)){
             if (iClose(NULL, 0, period) > iClose(NULL, 0, period + i)){
               if (iHigh(NULL, 0, period) >= iHigh(NULL,0,iHighest(NULL, 0, MODE_HIGH, i, period + 1))){
                 for(j=0; j < ArraySize(os); j++)
                   {
                    if (ob[j] <= period + i)
                      {
                       KD = -1;
                       Print(" Bearish Divergence - Divergent periods: ", period + i, " -> ", period, 
                             ". Overbought at period: ", ob[j], ". Name: arrow", arrowCount + 1);
                       return(KD);
                      }
                    }
                  }
               }
            }       
         }
      }}
    return(0);
   }
 
 
void create_arrow(int KD, int period, const datetime &time[], const double &high[],
                const double &low[])
   {
      string name;
      
      if (KD == 1)
        {
           arrowCount++;
           name = get_name();
           ObjectCreate(0,name,OBJ_ARROW,0,0,0,0,0);          // Create an arrow
           ObjectSetInteger(0,name,OBJPROP_ARROWCODE,225);    // Set the arrow code
           ObjectSetInteger(0,name,OBJPROP_TIME,time[period]);        // Set time
           ObjectSetDouble(0,name,OBJPROP_PRICE,high[period] + 2.5*iATR(NULL,0,10,period));       // Set price
           ObjectSetInteger(0,name,OBJPROP_WIDTH,3);
           ObjectSetInteger(0,name,OBJPROP_COLOR,clrForestGreen);
           ChartRedraw(0);
        }
      else if (KD == -1)
        {
           arrowCount++;
           name = get_name();
           ObjectCreate(0,name,OBJ_ARROW,0,0,0,0,0);          // Create an arrow
           ObjectSetInteger(0,name,OBJPROP_ARROWCODE,226);    // Set the arrow code
           ObjectSetInteger(0,name,OBJPROP_TIME,time[period]);        // Set time
           ObjectSetDouble(0,name,OBJPROP_PRICE,low[period] - 0.5*iATR(NULL,0,10,period));       // Set price
           ObjectSetInteger(0,name,OBJPROP_WIDTH,3);
           ChartRedraw(0); 
        }
   }
   
   
string get_name()
   {
    return(StringConcatenate("arrow", IntegerToString(arrowCount)));
   }
 
//+------------------------------------------------------------------+
