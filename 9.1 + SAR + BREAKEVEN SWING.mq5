//+------------------------------------------------------------------+
//|                                           9.1 Larry Williams.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+   
input double _volume = 1.0;                       // Informe a quantidade de lotes
input double SAR_passo=0.02;                      // Incrementar passo do SAR 
input double SAR_maximo=0.2;                      // Nível de parada máximo
input int    MM_periodo=9;                        // Periodo da Média Móvel
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Tempo do gráfico
input ENUM_MA_METHOD    MM_metodo=MODE_EMA;       // Método da média
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


// Armazena valores do SAR parabolic
int handle_sar;
// Armazena valores da média móvel
int handle_mm;

// Armazena array do SAR parabolic
double array_sar[];
// Armazena array da média móvel
double array_mm[];
// Armazena valores dos preços
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
   ArraySetAsSeries(array_sar, true);
   ArraySetAsSeries(array_mm, true);

   // Atribuindo os dados do indicador no handle
   handle_sar = iSAR(Symbol(), TimeFrame, SAR_passo, SAR_maximo);
   handle_mm  = iMA(Symbol(), TimeFrame, MM_periodo, 0, MM_metodo, PRICE_CLOSE);
   
   // Oculta a grade no gráfico
   ChartSetInteger(0, CHART_SHOW_GRID, false);  
      
   Print("⬜ Incialização realizada com sucesso!");
   return(INIT_SUCCEEDED);
} // Final da OnInit


void OnTick()
  {
   Trade.SetDeviationInPoints(50);
   Trade.SetExpertMagicNumber(123456);
   
//   // Utilizandoa  função hora de negociação
//   if(HoraNegociacao())
//     {
//      Comment("Dentro do horário de negociação");
//     }
//   else
//     {
//      Comment("Fora do horário de negociação");
//     }
//     
//   // Utilizando a função hora de fechamento de posições 
//   if(HoraFechamento())
//     {
//      Comment("Horário de fechamento de posições");
//      FechaPosicao();
//     }
//   else if(HoraNegociacao())
//          {
//           Comment("Dentro do horário de negociação");
//          }
//   else
//     {
//      Comment("Fora do horário de negociação");
//     }
     

   // Handle do indicador, quantos buffers, começa a copiar da posição 0, copia 3 posições, copia para o array  
   CopyBuffer(handle_sar, 0, 0, 3, array_sar); 
   CopyBuffer(handle_mm, 0, 0, 3, array_mm); 
   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 3, rates);
   // Se posições abertas for igual a 0 && Ordens forem iguais a 0
   
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


   
   // Se não tiver posição aberta, não é para ativar o breakeven
   if(OpenPosition == false)
     {
         ativarBreakeven = false;
     }
     
   // Se o preço de abertura de 1 candle atrás for menor que a MM do mesmo && preço close maior que a MM de 1 candle && MM 2 < MM 1 (MM caindo)
   if(rates[1].open < array_mm[1] && rates[1].close > array_mm [1] && array_mm[2] < array_mm[1])
     {
         // Ativa o sinal de compra (1)
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
   
   // Se não tiver posição aberta, não é para ativar o breakeven

   // Se o preço de abertura de 1 candle atrás for menor que a MM do mesmo && preço close maior que a MM de 1 candle && MM 2 < MM 1 (MM caindo)
   if(rates[1].open > array_mm[1] && rates[1].close < array_mm [1] && array_mm[2] > array_mm[1])
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
     
        
if(OpenPosition == true)
  {
      // Se a minha posição for de compra e o requisito seja vender ou (||) se a minha posição for de venda e meu requisito for comprar 
      if((PositionType==POSITION_TYPE_BUY && order==-1) || (PositionType==POSITION_TYPE_SELL && order==1))       
           {
            // Virada de mão
            DobraMao=true;                                           
            Print("⬜ Acionado virada de mão.");
           }
  }
  
   if(order != 0)
     {
      // Variável para o numero de contratos dobrado
      double NumeroContratos = _volume;    
      // Se é realmente para dobrar a mão, então...
      if(DobraMao == true)
        {
           // Vai ser o numero de contratos que estamos trabalhando X2
           NumeroContratos=_volume*2;
           Print("⬜ Dobrando número de contratos para a operação.");
        }
       // Se o sinal for de compra e estiver no horário de negociação...
       if(order == 1)
         {
            // Se tiver mais que 0 ordens
            if(OrdersTotal() > 0)
              {
                  // Função para deletar ordem anterior
                  deletarOrdensPendentes();
              }
               // Somando 30 pontos na máxima no penultimo candle      
               double priceOpen = rates[1].high;
               // Stoploss 30 pontos abaixo do penultimo candle
               double  _sl = rates[1].low;
               // Compra stop 30 pontos acima da máxima do penultimo candle.
               Trade.BuyStop(NumeroContratos, priceOpen, Symbol(), _sl, 0.00, 0, 0, "[COMPRA]");
               Print("⬜ Média virou para cima, compra posicionada!");
               // Preco Breakeven recebe preco de entrada + preco de entrada - stop loss
               precoBreakeven = priceOpen + (priceOpen - _sl);
               // Preço StopMovel recebe preco de entrada + 2x preco de entrada - stop loss
               precoStopMovel = priceOpen + 2*(priceOpen - _sl);
               Comment("⬜ Preço para ativar o Stop Móvel: ", precoStopMovel, "\n⬜ Preço para ativar o BreakEven: ", precoBreakeven);
         }
       // Se o sinal for de venda e estiver no horário de negociação...
       if(order == -1)
         {
            // Se tiver mais que 0 ordens
            if(OrdersTotal() > 0)
              {
                  // Função para deletar ordem anterior
                  deletarOrdensPendentes();
              }

            // Somando 30 pontos na mínima do último candle      
            double priceOpen = rates[1].low;
            // Stoploss 30 pontos acima do último candle
            double  _sl = rates[1].high;
            // Venda com stop 30 pontos acima da máxima do penultimo candle.
            Trade.SellStop(NumeroContratos, priceOpen, Symbol(), _sl, 0.00, 0, 0, "[VENDA]");
            Print("⬜ Média virou para baixo, venda posicionada!");
            // Preco Breakeven recebe preco de entrada + preco de entrada - stop loss
            precoBreakeven = priceOpen - (priceOpen - _sl);
            // Preço StopMovel recebe preco de entrada + 2x preco de entrada - stop loss
            precoStopMovel = priceOpen - 2*(priceOpen - _sl);
            Comment("⬜ Preço para ativar o Stop Móvel: ", precoStopMovel, "\n⬜ Preço para ativar o BreakEven: ", precoBreakeven);
               
               
         }
     }     
   
   // Verificar e colocar no BreakEven
   if(rates[0].close >= precoBreakeven && OpenPosition == true && !ativarBreakeven)
     {
         // Comentário de ativar o BreakEven
         Comment("⬜ Ativou breakeven");
         // Chama a função de mover breakeven
         moverBreakeven();
         // Modifica ativarBreakeven
         ativarBreakeven = true;
     }
   
   // PROBLEMA: Sars pulando stop
   // Solução: preço indice é multiplo de 5, logo pegamos o preço e dividimos por 5
   
   // Se posições totais forem igual a 1 && preco atual for maior que preco stop movel && ativarBreakeven == true
   if(OpenPosition==true && rates[0].close >= precoStopMovel && ativarBreakeven == true)
     {

         // Comentário do novo preço do SAR
         Comment(" Sar Modificado: ", array_sar[0]);
         // Move o SARS parabolic
         moverStopLoss(array_sar[0]);
     }
}  // CHAVE FINAL DA ONTICK  
// Função para deletar ordens pendentes
void deletarOrdensPendentes()
   {
for(int i = OrdersTotal() - 1; i >= 0; i--) 

        {

              if(OrderGetTicket(i) > 0) 

              {

                  if (OrderGetString(ORDER_SYMBOL)==Symbol())

                  {                      

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

//bool  HoraNegociacao()
//     {
//      if(horarioAtual.hour >= hAbertura && horarioAtual.hour <= hFechamento)
//         {
//          if(horarioAtual.hour == hAbertura)
//            {
//             if(horarioAtual.min >= mAbertura)
//               {
//                return true;
//               }
//             else
//               {
//                return false;
//               }
//            }
//          if(horarioAtual.hour == hFechamento)
//            {
//             if(horarioAtual.min <= mFechamento)
//               {
//                return true;
//               }
//             else
//               {
//                return false;
//               }
//            }
//          return true;
//         }
//       return false;
//     }
//
//bool   HoraFechamento()
//       {
//        TimeToStruct(TimeCurrent(), horarioAtual);
//        if(horarioAtual.hour >= hFecharPosicao)
//          {
//           if(horarioAtual.hour == hFecharPosicao)
//             {
//              if(horarioAtual.min >= mFecharPosicao)
//                {
//                 return true;
//                }
//              else
//                {
//                 return false;
//                }
//             }
//           return true;
//          }
//         return false;
//       }

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


