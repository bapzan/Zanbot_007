// SETUP 123, FAZER COM QUE O 123 SEJA BOM! HIGH DO TERCEIRO CANDLE ABAIXO DO PRIMEIRO E HIGH DO SEGUNDO ABAIXO DO PRIMEIRO

#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+   
input int             _volume = 100;              // Quantidade de lotes
input int             MediaRapida = 20;           // Período da Média Rápida
input int             MediaLenta = 200;           // Período da Média Lenta
input int             MediaATR = 50;
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Tempo do gráfico

input string          título2=" ";                // #########HORÁRIOS############
input int             hAbertura=9;                // Hora de Abertura
input int             mAbertura=15;               // Minuto de Abertura
input int             hFechamento=17;             // Hora de Fechamento
input int             mFechamento=20;             // Minuto de Fechamento 
input int             hFecharPosicao=17;          // Horário de Fechar posições
input int             mFecharPosicao=40;          // Minuto de Fechar posições

// Magic Number
ulong magicNum = 123456;          
// Desvio em pontos
ulong desvPts = 50;               
// Pega o horário corrente
MqlDateTime horarioAtual;
// 0 Não faz nada, 1 comprar, -1 vender
int order=0;
// Estou comprado ou vendido (2)
long PositionType=-1;     
// Indica virada de mão
bool DobraMao=false;     
// Tem posição aberta?
bool OpenPosition=false;
// Armazena tempo dentro das variáveis
datetime candleNovo;
datetime candleAtual;

double High1;
double High2;
double High3;
double High4;
double High5;
double High6;
double High7;
double High8;
double High9;
double High10;
double High11;
double High12;
double High13;
double High14;
double High15;
double High16;
double High17;
double High18;
double High19;
double High20;

double Low1;
double Low2;
double Low3;
double Low4;
double Low5;
double Low6;
double Low7;
double Low8;
double Low9;
double Low10;
double Low11;
double Low12;
double Low13;
double Low14;
double Low15;
double Low16;
double Low17;
double Low18;
double Low19;
double Low20;

// Variável que vai armazenar os valores do indicador
int handle_fast;
int handle_slow;
int handle_ATR;

// Variáveis de ARRAY
double array_fast[];
double array_slow[];
double array_ATR[];
MqlRates rates[];

// Variável se é candle de baixa
int CandleBaixaAlta = 0;

// Variável para saber quando o ativo (preço) chegou no breakeven
double precoBreakeven;
double precoStopMovel;
// Variável para ativar nosso breakeven
bool ativarBreakeven;

int OnInit()
{
   // Torna o primeiro candle a ser contado para o último
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(array_fast, true);
   ArraySetAsSeries(array_slow, true);
   // Atribuindo os dados do indicador nos handles
   handle_fast  = iMA(Symbol(), TimeFrame, MediaRapida, 0, MODE_EMA, handle_fast);
   handle_slow  = iMA(Symbol(), TimeFrame, MediaLenta, 0, MODE_EMA, handle_slow);
   handle_ATR  = iATR(Symbol(), TimeFrame, MediaATR);
   
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
     
     
   // Handle do indicador, quantos buffers, começa a copiar da posição 0, copia 3 posições, copia para o array  
   CopyBuffer(handle_fast, 0, 0, 5, array_fast);
   CopyBuffer(handle_slow, 0, 0, 5, array_slow);
   CopyBuffer(handle_ATR, 0, 0, 5, array_ATR);
   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 5, rates);
 
   High1  = iHigh(Symbol(), TimeFrame, 1);
   High2  = iHigh(Symbol(), TimeFrame, 2);
   High3  = iHigh(Symbol(), TimeFrame, 3);
   double High1_2  = MathMax( High1,  High2);
   
   double Highest123 = MathMax(High1_2, High3);
   
   
   
   Low1   = iLow(Symbol(), TimeFrame, 1);
   Low2   = iLow(Symbol(), TimeFrame, 2);
   Low3   = iLow(Symbol(), TimeFrame, 3);
   double Low1_2     = MathMin( Low1,  Low2);
   
   double Lowest123 = MathMin(Low1_2, Low3);
   
   
   
   

   // Pega o fechamento do dia anterior
   double FechamentoAnterior = rates[1].close;
   
   // Confere se o candle anterior é de baixa
   if(rates[1].close > rates[1].open)
     {
         // Candle é de alta
         CandleBaixaAlta = 1;
     }
   else
     {
         CandleBaixaAlta = 0;
     }
     
   
   if(rates[1].close < rates[1].open)
     {
         // Candle não é de baixa
         CandleBaixaAlta = -1;
     }
   else
     {
         CandleBaixaAlta = 0;
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
   
if(order == 0)
  {

   // Se a max penultimo > max atual && min penultimo < min atual && preço atual acima de todas as médias
   if(rates[1].close > array_fast[1] && rates[1].close > array_slow[1]
      && rates[2].low < rates[3].low && rates[1].low > rates[2].low
      && array_fast[1] > array_slow[1]
      && array_fast[1] > array_fast[2] && array_slow[1] > array_slow[2]
      && (rates[1].high - rates[1].low) <= array_ATR[1])
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
   if(rates[1].close < array_fast[1] && rates[1].close < array_slow[1]
      && rates[2].high > rates[3].high && rates[1].high < rates[2].high
      && array_fast[1] < array_slow[1]
      && array_fast[1] < array_fast[2] && array_slow[1] < array_slow[2]
      && (rates[1].high - rates[1].low) <= array_ATR[1])
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
  }
else
  {
   order = 0;
  }
     
   // Se ordens totais forem maior que 0
   if(OrdersTotal() > 0)
     {
         // Deletar ordens pendentes
         deletarOrdensPendentes();
         Print("⬜ Deletando ordens pendentes");
     }
 
   if(order != 0)
     {
       // Variável para o numero de contratos dobrado
       double NumeroContratos = _volume;  
       // Se o sinal for de compra e estiver no horário de negociação...
       if(order == 1 && HoraNegociacao())
         {
            // Preco de abertura da ordem    
            double priceOpen = rates[1].high;
            // Preço de stoploss
            double Sl = rates[2].low;
            //if(Highest123 == rates[1].high)
            //  {
            //      Sl = rates[1].low - (5 * _Point);
            //  }
            // Takeprofit
            double TakeProfit = priceOpen + (Highest123 - rates[2].low );
            // Compra stop
            Trade.BuyStop(NumeroContratos, priceOpen, Symbol(), Sl, TakeProfit, 0, 0, "[COMPRA]");
            Print("⬜ 123 de compra!");
         }
         
       if(order == -1 && HoraNegociacao())
         {
            // Preco de abertura da ordem    
            double priceOpen = rates[1].low ;
            // Preço de stoploss
            double Sl = rates[2].high;
            //if(Lowest123 == (rates[1].low))
            //  {
            //      Sl = rates[1].high + (5 * _Point);
            //  }
            // Takeprofit
            double TakeProfit = priceOpen + (Lowest123 - rates[2].high);
            // Venda Stop
            Trade.SellStop(NumeroContratos, priceOpen, Symbol(),  Sl, TakeProfit, 0, 0, "[VENDA]");
            Print("⬜ 123 de venda!");
         }
     }



}  // CHAVE FINAL DA ONTICK  

//+------------------------------------------------------------------+


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
void moverStopLoss(double TakeProfit)
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
                     // Variável novo Stop Loss
                     double novoSl;
                     // Se o tipo da posição for posição de compra
                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                                 // Então, o novo stoploss vai ser o próprio Highest                            
                                 novoSl = NormalizeDouble(TakeProfit, _Digits);
                                 
                                 // Modificar o novo stoploss para o ticket
                                 Trade.PositionModify(ticket, 0.00, novoSl);
                                 Print("⬜ Trailing stop na máxima dos dois candles prévios ativado!");
                             
                       }
                }
          }
    }
   


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


