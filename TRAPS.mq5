
#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+   
input int             _volume = 100;              // Quantidade de lotes
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Tempo do gráfico


input string          título2=" ";                // #########HORÁRIOS############
input int             hAbertura=10;               // Hora de Abertura
input int             mAbertura=10;               // Minuto de Abertura
input int             hFechamento=10;             // Hora de Fechamento
input int             mFechamento=30;             // Minuto de Fechamento 
input int             hFecharPosicao=17;          // Horário de Fechar posições
input int             mFecharPosicao=40;          // Minuto de Fechar posições

// Magic Number
ulong magicNum = 123456;          
// Desvio em pontos
ulong desvPts = 50;               
// Pega o horário corrente
MqlDateTime horarioAtual;
// 0 Não faz nada, 1 comprar, -1 vender
int   order=0;
// Estou comprado ou vendido (2)
long     PositionType=-1;     
// Indica virada de mão
bool     DobraMao=false;     
// Tem posição aberta?
bool     OpenPosition=false;
// Armazena tempo dentro das variáveis
datetime candleNovo;
datetime candleAtual;

MqlRates rates[];

// Variável para saber quando o ativo (preço) chegou no breakeven
double precoBreakeven;
double precoStopMovel;
// Variável para ativar nosso breakeven
bool ativarBreakeven;

int OnInit()
{
   // Torna o primeiro candle a ser contado para o último
   ArraySetAsSeries(rates, true);


   // Oculta a grade no gráfico
   ChartSetInteger(0, CHART_SHOW_GRID, false);  
      
   Print("⬜ Incialização realizada com sucesso!");
   return(INIT_SUCCEEDED);
} // Final da OnInit


void OnTick()
  {

   Trade.SetDeviationInPoints(50);
   Trade.SetExpertMagicNumber(123456);
   
   // Utilizandoa  função hora de negociação
   if(HoraNegociacao())
     {
      Comment("Dentro do horário de negociação");
     }
   else
     {
      Comment("Fora do horário de negociação");
     }
     
     
   // Utilizando a função hora de fechamento de posições 
   if(HoraFechamento())
     {
      Comment("Horário de fechamento de posições");
      FechaPosicao();
     }
   else if(HoraNegociacao())
          {
           Comment("Dentro do horário de negociação");
          }
   else
     {
      Comment("Fora do horário de negociação");
     }
     
   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 3, rates);
   
   double maximadeOntem = iHigh(Symbol(), PERIOD_D1, 1);
   double minimadeOntem = iLow(Symbol(), PERIOD_D1, 1);
   
   if(HoraNegociacao())
     {
         ObjectCreate(Symbol(), "Máxima do dia anterior", OBJ_HLINE, 0, 0, maximadeOntem, clrBlue);
     }
   
   if(HoraNegociacao())
     {
         ObjectCreate(Symbol(), "Mínima do dia anterior", OBJ_HLINE, 0, 0, minimadeOntem, clrRed);
     }
   
//+------------------------------------------------------------------+
//| FUNÇÕES DE TRADE PADRÃO                                          |
//+------------------------------------------------------------------+ 

   // Pegando a hora de abertura do candle atual
   candleAtual = rates[0].time;
   
   // Se o candleAtual for diferente do candleNovo
   if(candleAtual != candleNovo)
     {
         // Candle novo recebe hora do candle atual
         candleNovo = rates[0].time;
     }
   // Se eles forem iguais...
   else
     {
         // Não processa mais nada daqui pra baixo
         return;
     }

   // Adiciona os lotes na variável Contratos
   double Contratos=0;
   // Variável para posição aberta
   OpenPosition=PositionSelect(_Symbol);
   // Se eu estiver posicionado
   if(OpenPosition==true)
     {
         // Comprado ou vendido
         PositionType=PositionGetInteger(POSITION_TYPE);
         // Quantos contratos custódia
         Contratos=PositionGetDouble(POSITION_VOLUME);      
     }
   else
     {
         // Não tenho posição aberta, logo, não tem tipo da posição
         PositionType=WRONG_VALUE;  // (-1)
     }
   
if(order==0)
  {
   // Se a max penultimo > max atual && min penultimo < min atual && preço atual acima de todas as médias
   if(rates[1].low < minimadeOntem)

     {
         // Ativa o sinal de compra, order = 1
         order=1;
         Print("⬜ Sinal de compra dado");
     }

   //Caso comprado, segura compra e não deixa abrir mais posições
   if(OpenPosition==true && PositionType==POSITION_TYPE_BUY && order==1)
     {
          // Restrição de compra caso já esteja comprado
          order=0;               
          Print("⬜ Acionado compra com o robô já comprado, desconsiderando.");
     }
     
   // Impede de abrir nova ordem de compra
   if(OrdersTotal() > 0 && order==1 && rates[0].time != rates[1].time)
     {
         // Então, ordem passa a ser 0
         deletarOrdensPendentes();
         order=0;
         Print("⬜ Novo candle, sem novos sinais");
     }
     
   // Se o preço de abertura de 1 candle atrás for menor que a MM do mesmo && preço close maior que a MM de 1 candle && MM 2 < MM 1 (MM caindo)
   if(rates[1].high > maximadeOntem)
     {
          // Ativa o sinal de venda (-1)
          order=-1;
          Print("⬜ Sinal de venda dado");
     }

   //Caso vendido, segura venda e não deixa abrir mais posições
   if(OpenPosition==true && PositionType==POSITION_TYPE_SELL && order==-1)
    {
        // Restrição de venda caso vendido
        order=0;              
        Print("⬜ Acionado venda com o robô já vendido, desconsiderando.");
    }
    
   // Impede de abrir nova ordem de venda
   if(OrdersTotal() > 0 && order==-1 && rates[0].time != rates[1].time)
     {
         // Então, ordem passa a ser 0
         order=0;
         Print("⬜ Novo candle, sem novos sinais");
     }     
  }
  else
    {
        // Caso nenhuma regra for atendida...
        order=0;
    }  

   static datetime bar_time=0;
   datetime this_bar_time=iTime(Symbol(),TimeFrame,0);
   if(bar_time!=this_bar_time)
     {
      bar_time=this_bar_time;
      // Se ordens totais forem maior que 0
      if(OrdersTotal() > 0)
        {
            // Deletar ordens pendentes
            deletarOrdensPendentes();
            Print("⬜ Deletando ordens pendentes");
        }
     }
 
   if(order != 0)
     {
       // Variável para o numero de contratos dobrado
       double NumeroContratos = _volume;  
       // Se o sinal for de compra e estiver no horário de negociação...
       if(order == 1 && HoraNegociacao())
         {
            // Preco de abertura da ordem    
            double priceOpen = rates[1].high + 0.01;
            // Stoploss na mínima do candle
            double _sl = rates[1].low - 0.01;
            // Take profit 2x o sl
            double _tp = priceOpen + 2*(priceOpen - _sl);
            // Compra stop 30 pontos acima da máxima do penultimo candle.
            Trade.BuyStop(NumeroContratos, priceOpen, Symbol(), _sl, _tp, 0, 0, "[COMPRA]");
            Print("⬜ Compra posicionada!");
         }
         
       // Se o sinal for de venda e estiver no horário de negociação...
       if(order == -1 && HoraNegociacao())
         {
            // Preco de abertura da ordem    
            double priceOpen = rates[1].low - 0.01;
            // Stoploss na máxima do candle
            double _sl = rates[1].high + 0.01;
            // Takeprofit 2x o sl
            double _tp = priceOpen + 2*(priceOpen - _sl);
            // Venda com stop 30 pontos acima da máxima do penultimo candle.
            Trade.SellStop(NumeroContratos, priceOpen, Symbol(), _sl, _tp, 0, 0, "[VENDA]");
            Print("⬜ Venda posicionada!");
         }
     }     

}  // CHAVE FINAL DA ONTICK  








// Função para deletar ordens pendentes
void deletarOrdensPendentes()
   {
   // i = ordens totais   
   for(int i = OrdersTotal() - 1; i >= 0; i--) 
   
           {
                 // Se ticket de i for maior que 0
                 if(OrderGetTicket(i) > 0) 
   
                 {
                     // Se pega o simbolo da ordem e confere se é o mesmo da ordem atual
                     if (OrderGetString(ORDER_SYMBOL)==Symbol())
   
                     {                      
                         // Função para deletar a ordem do ticket i
                         Trade.OrderDelete(OrderGetTicket(i));  
                     }
                 }
           }
      }
           
// Função para mover breakeven
void moverBreakeven()
   {
      // int=0 -> estamos começandoa a contar do zero, Positionstotal -1 pois estamos contando do 0 ao 9 = 10 unidades
      for(int i = PositionsTotal()-1; i>=0; i--)
        {
            // Pega o simbolo da posição
            string symbol = PositionGetSymbol(i);
            // Se symbol for == ao simbolo do gráfico...
            if(symbol == Symbol())
              {
                  // Variável ticket recebe o ticket da posição
                  ulong ticket = PositionGetInteger(POSITION_TICKET);
                  // precoEntrada recebe o preço de abertura da ordem
                  double precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
                  // Modifica a posicao do trade, pega o ticket da posição, adiciona o novo stop loss e novo takeprofit
                  Trade.PositionModify(ticket, precoEntrada, 0);
              }
        }
   }





// Função para trailing stop
void moverStopLoss(double sarValue)
    {
        for(int i = PositionsTotal()-1 ; i>=0 ; i--)
          {
              //Na posição X quero saber qual ativo
              string symbol = PositionGetSymbol(i);
              // Verifica se o Symbol é o ativo que tá no gráfico
              if(symbol == Symbol())
                {
                     // Pega o ticket da posição
                     ulong ticket = PositionGetInteger(POSITION_TICKET);
                     // Pega o preço de entrada
                     double precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
                     // Pega o preço do stoploss
                     double stopLoss = PositionGetDouble(POSITION_SL);
                     // Pega o preço de takeprofit
                     double takeProfit = PositionGetDouble(POSITION_TP);
                     
                     // Variável novo Stop Loss
                     double novoSl;
                     // Se o tipo da posição for posição de compra
                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                           // Se o valor do SAR for maior que o SL
                           if(sarValue > stopLoss)
                             {
                                 // Então, o novo stoploss vai ser o próprio SAR                            
                                 novoSl = NormalizeDouble(sarValue, _Digits);
                                 
                                 // Modificar o novo stoploss para o ticket
                                 Trade.PositionModify(ticket, novoSl, 0.00);
                                 Print("⬜ SARS Parabolic acima do SL, trailing stop ativado!");
                             }
                       }
                }
          }
}
   

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| FUNÇÕES GLOBAIS                                                  |
//+------------------------------------------------------------------+ 

bool  HoraNegociacao()
     {
      if(horarioAtual.hour >= hAbertura && horarioAtual.hour <= hFechamento)
         {
          if(horarioAtual.hour == hAbertura)
            {
             if(horarioAtual.min >= mAbertura)
               {
                return true;
               }
             else
               {
                return false;
               }
            }
          if(horarioAtual.hour == hFechamento)
            {
             if(horarioAtual.min <= mFechamento)
               {
                return true;
               }
             else
               {
                return false;
               }
            }
          return true;
         }
       return false;
     }

bool   HoraFechamento()
       {
        TimeToStruct(TimeCurrent(), horarioAtual);
        if(horarioAtual.hour >= hFecharPosicao)
          {
           if(horarioAtual.hour == hFecharPosicao)
             {
              if(horarioAtual.min >= mFecharPosicao)
                {
                 return true;
                }
              else
                {
                 return false;
                }
             }
           return true;
          }
         return false;
       }

void  FechaPosicao()
      {
       for(int i = PositionsTotal()-1; i>=0; i--)
         {
          string symbol = PositionGetSymbol(i);
          ulong  magic = PositionGetInteger(POSITION_MAGIC);
          if(symbol == _Symbol && magic == magicNum)
            {
             ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
             if(Trade.PositionClose(PositionTicket, desvPts))
               {
                Print("⬜ Posição fechada - sem falha. ResultRetcode: ", Trade.ResultRetcode(), ", RetCodedescription: ", Trade.ResultRetcodeDescription());
               }
            }
         }
      }

 
  
   //int CandlesAtras = 5;
   //// Variável inteira armazena valor do highest( simbolo do ativo, timeframe, modo (exemplo: Maior minima), quantidade de candles analisados, começar a contagem de qual candle
   //int HighestCandles   = iHighest( Symbol(), TimeFrame, MODE_HIGH, CandlesAtras, 0);                                //52 Week's Highest Candle
   //int LowestCandles   = iLowest( Symbol(), TimeFrame, MODE_LOW, CandlesAtras, 0);                                  //52 Week's Lowest Candle
   //// Armazena o maior preço, high( simbolo, time frame, de qual candle? do highest)
   //double HighCandles = iHigh(Symbol(), TimeFrame, iHighest( _Symbol, TimeFrame, MODE_HIGH, CandlesAtras, 0));     //52 Week's Highest Price
   //double LowCandles = iLow(Symbol(), TimeFrame, iLowest( _Symbol, TimeFrame, MODE_LOW, CandlesAtras, 0));        //52 Week's Lowest Price
   
   //Print("Máxima dos últimos ",CandlesAtras," candles: ", HighCandles, "\nMínima dos últimos ",CandlesAtras," candles: ", LowCandles);
