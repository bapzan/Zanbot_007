
#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+   
input int             _volume = 1;                // Quantidade de lotes
input int             PeriodoRSI = 2;             // Período do IFR
input int             LinhaSobrevenda = 25;       // Linha de sobrevenda
input int             MaximaCandles = 2;          // Máxima de quantos candles para vender
input int             FechaDepoisDe = 7;          // Fechar posição depois de X candles
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

// Variável que vai armazenar os valores do indicador
int handle_RSI;
double handle_HIG1;
double handle_HIG2;
double handle_HIG;

// Variáveis de ARRAY
double array_RSI[];
double array_HIG1[];
double array_HIG2[];
MqlRates rates[];

// Variável se é candle de baixa
int CandleBaixa = 0;
// Variável se RSI está sobrevendido
int RSI_Sobrevendido = 0;

// Variável para saber quando o ativo (preço) chegou no breakeven
double precoBreakeven;
double precoStopMovel;
// Variável para ativar nosso breakeven
bool ativarBreakeven;

int OnInit()
{
   // Torna o primeiro candle a ser contado para o último
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(array_RSI, true);
   ArraySetAsSeries(array_HIG1, true);
   ArraySetAsSeries(array_HIG2, true);
   
   // Atribuindo os dados do indicador nos handles
   handle_RSI = iRSI(Symbol(), TimeFrame, PeriodoRSI, handle_RSI);
   handle_HIG1 = iHigh(Symbol(), TimeFrame, 1);
   handle_HIG2 = iHigh(Symbol(), TimeFrame, 2);
   
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
   CopyBuffer(handle_RSI, 0, 0, 5, array_RSI);
   //CopyBuffer(handle_HIG1, 0, 0, 5, array_HIG1);
   //CopyBuffer(handle_HIG2, 0, 0, 5, array_HIG2);
   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 5, rates);
   // Pega a máxima do ultimo candle e do penultimo e pega a máxima entre as duas
   handle_HIG1 = iHigh(Symbol(), TimeFrame, 1);
   handle_HIG2 = iHigh(Symbol(), TimeFrame, 2);
   double TakeProfit = MathMax( handle_HIG1, handle_HIG2);
     
   // Pega o fechamento do dia anterior
   double FechamentoAnterior = rates[1].close;
      
   // Confere se o candle anterior é de baixa
   if(rates[1].close < rates[1].open)
     {
         // Candle é de baixa
         CandleBaixa = 1;
     }
   else
     {
         // Candle não é de baixa
         CandleBaixa = 0;
     }
   
   // Se o preço do RSI estiver abaixo da linha de sobrevenda
   if(array_RSI[1] < LinhaSobrevenda)
     {
         // Então, RSI_Sobrevendido é verdade
         RSI_Sobrevendido = 1;
     }
   else
     {
         // Caso contrário, RSI não está sobrevendido
         RSI_Sobrevendido = 0;
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
   if(CandleBaixa == 1 && RSI_Sobrevendido == 1) 
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
            double priceOpen = rates[1].close;
            // Compra a mercado
            Trade.Buy(NumeroContratos, Symbol(), 0.00, 0.00, TakeProfit, "[COMPRA]");
            Print("⬜ IFR Sobrevendido, compra acionada!");
         }
     }
     
   long AberturaTrade = PositionGetInteger(POSITION_TIME);
   if(TimeCurrent() >= AberturaTrade + TimeFrame*60000*(FechaDepoisDe-1))
     {
         FechaPosicao();
         Print("Fechando todas as posições depois de 7 candles!");
     }

   if(PositionsTotal() == 1)
     {
         Comment(" Stop loss da operação: ", TakeProfit);
         // Move o stoploss para a máxima dos dois últimos candles
         moverStopLoss(TakeProfit);
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


