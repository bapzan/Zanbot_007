// SETUP 123, FAZER COM QUE O 123 SEJA BOM! HIGH DO TERCEIRO CANDLE ABAIXO DO PRIMEIRO E HIGH DO SEGUNDO ABAIXO DO PRIMEIRO

#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+   
input int             _volume = 100;              // Quantidade de lotes
input int             MediaATR = 50;
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Tempo do gráfico

input string          título2=" ";                // #########HORÁRIOS############
input int             hAbertura=10;                // Hora de Abertura
input int             mAbertura=10;               // Minuto de Abertura
input int             hFechamento=17;             // Hora de Fechamento
input int             mFechamento=0;             // Minuto de Fechamento 
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
datetime Expiracao;


// Variável que vai armazenar os valores do indicador
int handle_ATR;

// Variáveis de ARRAY
double array_ATR[];
MqlRates rates[];

// Variável se é candle de baixa
int CandleBaixaAlta = 0;

int OnInit()
{
   // Torna o primeiro candle a ser contado para o último
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(array_ATR, true);
   // Atribuindo os dados do indicador nos handles

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
   CopyBuffer(handle_ATR, 0, 0, 5, array_ATR);
   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 5, rates);
 
  

     
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
     
   double CandleInteiro = rates[1].high - rates[1].low;
   double umquintoCandle = CandleInteiro/5;
   double meioCandle = CandleInteiro/2;
   
   
if(order == 0)
  {

   // Se a max penultimo > max atual && min penultimo < min atual && preço atual acima de todas as médias
   if((rates[1].high - rates[1].low) >= (2*array_ATR[1])
      && rates[1].open < rates[1].close
      && rates[1].close >= (rates[1].high - umquintoCandle) && rates[1].open <= (rates[1].low + umquintoCandle))
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
     
   if((rates[1].high - rates[1].low) >= (2*array_ATR[1])
      && rates[1].open > rates[1].close
      && rates[1].open >= (rates[1].high - umquintoCandle) && rates[1].close <= (rates[1].low + umquintoCandle))
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
            // Preço de stoploss
            double Sl = rates[1].low - 0.01;
            // Takeprofit
            double TakeProfit = priceOpen + 2*(priceOpen - Sl);
            // Compra stop
            Trade.BuyStop(NumeroContratos, priceOpen, Symbol(), Sl, TakeProfit, 0, 0, "[COMPRA]");
            Print("⬜ Compra acionada!");
         }
         
       if(order == -1 && HoraNegociacao())
         {
            // Preco de abertura da ordem    
            double priceOpen = rates[1].low - 0.01;
            // Preço de stoploss
            double Sl = rates[1].high + 0.01;
            // Takeprofit
            double TakeProfit = priceOpen + 2*(priceOpen - Sl);
            // Venda Stop
            Trade.SellStop(NumeroContratos, priceOpen, Symbol(),  Sl, TakeProfit, 0, 0, "[VENDA]");
            Print("⬜ Venda acionada!");
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


