//+------------------------------------------------------------------+
//|                                                WildersDMI_v3.mq4 |
//|                        Copyright © 2007-09, TrendLaboratory Ltd. |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007-09, TrendLaboratory Ltd."
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"

#property indicator_separate_window
#property indicator_buffers   4
#property indicator_color1    LightBlue
#property indicator_width1    2 
#property indicator_color2    Lime
#property indicator_color3    Tomato
#property indicator_color4    Orange
#property indicator_width4    2 
#property indicator_level1    20
//---- input parameters
extern int       MA_Length    =  1; // Period of additional smoothing 
extern int       DMI_Length   = 14; // Period of DMI
extern int       ADX_Length   = 14; // Period of ADX
extern int       ADXR_Length  = 14; // Period of ADXR
extern int       ADXMode      =  1; // ADX Mode: 0-off,1-ADX,2-DX 
extern int       ADXRMode     =  1; // ADXR Mode: 0-off,1-on
extern int       VisualMode   =  1;
//---- buffers
double ADX[];
double PDI[];
double MDI[];
double ADXR[];
double sPDI[];
double sMDI[];
double STR[];
double DX[];

int len;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- indicators
   IndicatorBuffers(8);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ADX);
   
   SetIndexBuffer(1,PDI);
   SetIndexBuffer(2,MDI);
      if(VisualMode == 0)
      {
      SetIndexStyle(1,DRAW_LINE,STYLE_DOT);
      SetIndexStyle(2,DRAW_LINE,STYLE_DOT);
      }
      else
      {
      SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
      SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2);
      }
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,ADXR);
   SetIndexBuffer(4,sPDI);
   SetIndexBuffer(5,sMDI);
   SetIndexBuffer(6,STR);
   SetIndexBuffer(7,DX);
   //---- name for DataWindow and indicator subwindow label
   string short_name="WildersDMI_v3("+MA_Length+","+DMI_Length+","+ADX_Length+","+ADXR_Length+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0,"ADX");
      if(VisualMode == 0)
      {
      SetIndexLabel(1,"+DI");
      SetIndexLabel(2,"-DI");
      }
      else
      {
      SetIndexLabel(1,"(+DI)-(-DI)");
      SetIndexLabel(2,"(-DI)-(+DI)");
      }
   SetIndexLabel(3,"ADXR");
//----
   len = DMI_Length + MA_Length + ADX_Length + ADXR_Length + 1;
   SetIndexDrawBegin(0,len);
   SetIndexDrawBegin(1,len);
   SetIndexDrawBegin(2,len);
   SetIndexDrawBegin(3,len); 
   
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int    i,shift,limit,counted_bars=IndicatorCounted();
   double alfa1 = 1.0/DMI_Length;
   double alfa2 = 1.0/ADX_Length;
   double Bulls, Bears, TR = 0;
//---- 
   if (counted_bars < 0) return(-1);
      
   if(counted_bars<1)
      for(i=1;i<=len;i++) 
      {
      PDI[Bars-i]=0.0;
      MDI[Bars-i]=0.0;
      ADX[Bars-i]=0.0;
      sPDI[Bars-i]=0.0;
      sMDI[Bars-i]=0.0;
      DX[Bars-i]=0.0;
      STR[Bars-i]=0.0;
      ADXR[Bars-i]=0.0;
      }
      
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
   
   for(shift=limit;shift>=0;shift--)
   {
   double AvgHigh  = iMA(NULL,0,MA_Length,0,1,PRICE_HIGH,shift);
   double AvgHigh1 = iMA(NULL,0,MA_Length,0,1,PRICE_HIGH,shift+1);
   double AvgLow   = iMA(NULL,0,MA_Length,0,1,PRICE_LOW,shift);
   double AvgLow1  = iMA(NULL,0,MA_Length,0,1,PRICE_LOW,shift+1);
   double AvgClose1= iMA(NULL,0,MA_Length,0,1,PRICE_CLOSE,shift+1);
     
   if (AvgHigh >= AvgHigh1) Bulls = 0.5*(MathAbs(AvgHigh-AvgHigh1)+(AvgHigh-AvgHigh1));
   else Bulls = 0;
   if (AvgLow  <= AvgLow1 ) Bears = 0.5*(MathAbs(AvgLow1-AvgLow)+(AvgLow1-AvgLow));
   else Bears = 0;
   
   if (Bulls > Bears) Bears = 0;
   else 
   if (Bulls < Bears) Bulls = 0;
   else
   if (Bulls == Bears) {Bulls = 0;Bears = 0;}
   
   TR = MathMax(AvgHigh-AvgLow,AvgHigh-AvgClose1); 
   TR = MathMax(TR,AvgClose1 - AvgLow);
    
      if(shift <= Bars - MA_Length - 1 && shift >= Bars - DMI_Length - MA_Length) 
      {
      sPDI[shift] += Bulls;
      sMDI[shift] += Bears; 
      STR[shift]  += TR; 
         if(shift == Bars - DMI_Length - MA_Length)
         {
         sPDI[shift] = Bulls/DMI_Length;   
         sMDI[shift] = Bears/DMI_Length;
         STR[shift]  = TR/DMI_Length;
         }
      }
      else
      if(shift < Bars - DMI_Length - MA_Length) 
      {
      sPDI[shift] = sPDI[shift+1] + alfa1 * (Bulls - sPDI[shift+1]);
      sMDI[shift] = sMDI[shift+1] + alfa1 * (Bears - sMDI[shift+1]);
      STR[shift]  = STR[shift+1]  + alfa1 * (TR - STR[shift+1]); 
               
         if(STR[shift] != 0)
         {
         double pDI = 100*sPDI[shift]/STR[shift];
         double mDI = 100*sMDI[shift]/STR[shift];
         }
         else
         {
         pDI = 0;
         mDI = 0;
         }
      
         if(ADXMode > 0)
         {
         if((pDI + mDI) != 0) 
         DX[shift] = 100*MathAbs(pDI - mDI)/(pDI + mDI); 
         else DX[shift] = 0;
   
         if(ADXMode == 1 && shift < Bars - DMI_Length - MA_Length - ADX_Length)
         ADX[shift] = ADX[shift+1] + alfa2 * (DX[shift] - ADX[shift+1]); 
         else
         if(ADXMode == 2)
         ADX[shift] = DX[shift];
         
         if(ADXRMode > 0 && shift < Bars - len) ADXR[shift] = 0.5*(ADX[shift] + ADX[shift+ADXR_Length]);
         }
         
         if(VisualMode == 1)
         {
            if(pDI > mDI) {PDI[shift] = pDI - mDI; MDI[shift] = 0;} 
            else
            {MDI[shift] = mDI - pDI; PDI[shift] = 0;} 
         } 
         else
         {PDI[shift] = pDI; MDI[shift] = mDI;}
      }         
   }
   
//----
   return(0);
}
//+------------------------------------------------------------------+