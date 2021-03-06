//+------------------------------------------------------------------+
//|                                                SMA_Knoxville.mq4 |
//|               Copyright 2017, Avanti Servicios Financieros, C.A. |
//|                                   https://avantifs.herokuapp.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Avanti Servicios Financieros, C.A."
#property link      "https://avantifs.herokuapp.com"
#property version   "2.1"
#property strict

//--- input parameters
input int      SMA_Period = 1000;
input int      KnoxvilleDivergence_Periods = 30;
input int      Exit_Periods = 20;
input int      Periods_Between_Trades = 15;
input int      Emergency_StopLoss = 500;
input double   Lots = 0.01;
input bool     Buy_Signals = true;
input bool     Sell_Signals = true;
input bool     Reverse = false;

//--- global variables.
double divisor = MathPow(10, Digits);
int periodsBetweenTrades = 0;
int maxSlippage = 5;
string label_name = "label";

//--- Data structures.
struct Order
  {
   int id;
   int exitTimer;
   int ticket;
  };

Order nullOrder = {0, 0, 0};
Order orders[20];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   for(int i=0; i<ArraySize(orders) ; i++)
     {
      orders[i] = nullOrder;
     }
     
   string text = "Avanti's SMA + Knoxville EA running.";

   ObjectCreate(0,label_name,OBJ_LABEL,0,0,0);
   ObjectSetString(0,label_name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,label_name,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,label_name,OBJPROP_YDISTANCE,20);
   ObjectSetInteger(0,label_name,OBJPROP_COLOR,clrForestGreen);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectDelete(label_name);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
if(NewBar())
  {
   // If a trade is possible.
   --periodsBetweenTrades;
   if(periodsBetweenTrades <= 0)
     {
      int ticket;
      bool aboveSMA = false;
      bool belowSMA = false;
      double SMA = iMA(NULL, 0, SMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
      if(SMA != 0)
        {
         aboveSMA = iClose(NULL, 0, 1) >= SMA ? true : false;
         belowSMA = iClose(NULL, 0, 1) <= SMA ? true : false;
        }
      int divergence = knoxville_divergence(1);
      
      //Orders.
      if(aboveSMA==true && divergence==1)
        {
         int magicNumber = MathRand();
         // Buying or selling depending on the Reverse status.
         if(Reverse)
           {
            ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, maxSlippage, Bid + Emergency_StopLoss / divisor * 10, 0, NULL, magicNumber, 0, clrRed);           
           }
         else
           {
            ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, maxSlippage, Ask - Emergency_StopLoss / divisor * 10, 0, NULL, magicNumber, 0, clrGreen);
           }
         // Saving the order data in the structs array.
         if(ticket > 0)
           {
            save_order_data(magicNumber, ticket);
            periodsBetweenTrades = Periods_Between_Trades;
           }
        }
      else if(belowSMA==true && divergence==-1)
        {
         int magicNumber = MathRand();
         // Buying or selling depending on the Reverse status.
         if(Reverse)
           {
            ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, maxSlippage, Ask - Emergency_StopLoss / divisor * 10, 0, NULL, magicNumber, 0, clrGreen);
           }
         else
           {
            ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, maxSlippage, Bid + Emergency_StopLoss / divisor * 10, 0, NULL, magicNumber, 0, clrRed);           
           }
         // Saving the order data in the structs array.         
         if(ticket > 0)
           {
            save_order_data(magicNumber, ticket);
            periodsBetweenTrades = Periods_Between_Trades;
           }
        }
     }
   
   //Checks if there's an exit.
   for(int i=0; i<ArraySize(orders) ; i++)
     {
      Order order = orders[i];
      //Checks if the array's slot has a an order.
      if(order.id != 0)
        {
         //Checks the order's exit time.
         if(order.exitTimer == 0)
           {
            //Close trade.
            bool exit = OrderClose(order.ticket, Lots, Bid, 50, clrBlue);
            if(exit)
              {
               orders[i] = nullOrder;
               continue;
              }
           }
         --order.exitTimer;
         orders[i] = order;
        }
     }
   
  }


  }
//+------------------------------------------------------------------+

bool NewBar()
   {
    static datetime lastbar;
    datetime curbar = Time[0];
    if(lastbar!=curbar)
      {
       lastbar=curbar;
       return (true);
      }
    else
      {
       return(false);
      }
   }


int knoxville_divergence(int period)         
  {
   int MinPeriod = 4, KD = 0, i, j;
   int os[210], ob[210];
   double rsi = 50;
   
   ArrayInitialize(os,999999999);
   ArrayInitialize(ob,999999999);
   
   //---- Checking if oversold/overbought.
   for (j = 0; j <= KnoxvilleDivergence_Periods; j++)
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
   for (i = MinPeriod; i <= KnoxvilleDivergence_Periods; i++)
      {
       if (Sell_Signals)
         {
       //---- Checking for Momentum Divergence.
          if (iMomentum(NULL, 0, 20, PRICE_CLOSE, period) > iMomentum(NULL, 0, 20, PRICE_CLOSE, period + i)){
            if (iClose(NULL, 0, period) < iClose(NULL, 0, period + i)){
              if (iLow(NULL, 0, period) <= iLow(NULL,0,iLowest(NULL, 0, MODE_LOW, i, period + 1))){
                for(j=0; j < ArraySize(os); j++)
                  {
                   if (os[j] <= period + i)
                     {
                      KD = 1;
                      return(KD);
                     }
                  }
              }
            }
          }
         }
         
        if (Buy_Signals)
          {
          if (iMomentum(NULL, 0, 20, PRICE_CLOSE, period) < iMomentum(NULL, 0, 20, PRICE_CLOSE, period + i)){
             if (iClose(NULL, 0, period) > iClose(NULL, 0, period + i)){
               if (iHigh(NULL, 0, period) >= iHigh(NULL,0,iHighest(NULL, 0, MODE_HIGH, i, period + 1))){
                 for(j=0; j < ArraySize(os); j++)
                   {
                    if (ob[j] <= period + i)
                      {
                       KD = -1;
                       return(KD);
                      }
                   }
                 }
               }
            }       
          }
      }
    }
    return(0);
   }


void save_order_data(int magicNumber, int ticket)
  {
   for(int i=0; i<ArraySize(orders) ; i++)
     {
      //Looks for an empty space in the orders array.
      Order order = orders[i];
      if(order.id == 0)
        {
         order.id = magicNumber;
         order.exitTimer = Exit_Periods;
         order.ticket = ticket;
         orders[i] = order;
         break;
        }
     }  
  }
