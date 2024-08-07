#include <Trade\Trade.mqh>
CTrade Trade;

input double   _volume=1.00;         // Número de lotes
input double   _stoploss=150.00;     // Stoploss
input double   _takeprofit=50.00;    // TakeProfit

input int   RSISobrecomprado=70;  // Linha de sobrecompra RSI
input int   RSISobrevendido=30;   // Linha de sobrevenda RSI
input int   PeriodoMediaRSI=9;    // Periodo do RSI
input ENUM_TIMEFRAMES Timeframe_RSI = PERIOD_CURRENT; // Tempo do gráfico
// Armazena valores do RSI
int handle_rsi;

// Armazena array do RSI
double array_rsi[];

// Armazena tempo dentro das variáveis
datetime candleNovo;
datetime candleAtual;

// Armazena valores dos preços
MqlRates rates[];



int OnInit()
{
   // Oculta a grade no gráfico
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   
   if(PeriodoMediaRSI < 1)
     {
         Print("⬛ Periodo do RSI não pode ser menor que 1", GetLastError());
         return (INIT_FAILED);
     }
        
   // Atribuindo os dados do indicador no handle
   handle_rsi = iRSI(Symbol(), Timeframe_RSI, PeriodoMediaRSI, PRICE_CLOSE);

   Print("⬜ Incialização realizada com sucesso!");
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   // Torna o primeiro candle a ser contado para o último
   ArraySetAsSeries( array_rsi, true);
   ArraySetAsSeries(rates, true);
   // Handle do indicador, quantos buffers, começa a copiar da posição 0, copia 3 posições, copia para o array  
   CopyBuffer(handle_rsi, 0, 0, 5, array_rsi);
   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 5, rates);


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
     
     
   // Se o RSI do penultimo candle for menor que LINHA DE SOBREVENDA e o RSI do último candle for maior que LINHA DE SOBREVENDA e o último candle tem que ter o fechamento acima da abertura (candle de alta), então...
   if(array_rsi[2]<RSISobrevendido && array_rsi[1]>RSISobrevendido && rates[1].close > rates[1].open)
     {
         // Se posições abertas for igual a 0 && Ordens forem iguais a 0
         if(PositionsTotal() == 0 && OrdersTotal() == 0)
           {
               // Compra a mercado, com 0 SL, 0 TP
               Trade.Buy(_volume, Symbol(), 0.00, 0.00, 0.00, "[COMPRA]");
               // Adiciona o stop loss e take profit usandoa função void addTakeStop
               addTakeStop(_stoploss, _takeprofit);
           }

     }
   
   // Se o RSI do penultimo candle for maior que LINHA DE SOBRECOMPRA e o RSI do último candle for menor que LINHA DE SOBRECOMPRA, então...
   if(array_rsi[2] > RSISobrecomprado && array_rsi[1] < RSISobrecomprado && rates[1].close < rates[1].open)
     {
         // Se posições abertas for igual a 0 && Ordens forem iguais a 0
         if(PositionsTotal() == 0 && OrdersTotal() == 0)
           {
               // Venda a mercado, com 0 SL, 0 TP
               Trade.Sell(_volume, Symbol(), 0.00, 0.00, 0.00, "[VENDA]");
               // Adiciona o stop loss e take profit usandoa função void addTakeStop
               addTakeStop(_stoploss, _takeprofit);
           }
     }
}  // Chave final OnTick

void addTakeStop(double preco_sl, double preco_tp)
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
                     // Pega o preço de entrada da posição
                     double precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
                     // Pega o preço do stoploss da posição
                     double stopLoss = PositionGetDouble(POSITION_SL);
                     // Pega o preço de takeprofit da posição
                     double takeProfit = PositionGetDouble(POSITION_TP);
                     
                     // Vai conter o novo Stop Loss
                     double novoSl;
                     // Vai conter o novo Take Profit
                     double novoTP;
                     
                     // Se o tipo da posição for posição de compra
                     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       {
                           //                             
                           novoSl = NormalizeDouble(precoEntrada - (preco_sl *_Point), _Digits);
                           //
                           novoTP = NormalizeDouble(precoEntrada + (preco_tp *_Point), _Digits);
                           // Modificar o novo stoploss para o ticket
                           Trade.PositionModify(ticket, novoSl, novoTP);
                       }
                     else if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                       {
                           
                           novoSl = NormalizeDouble(precoEntrada + (preco_sl *_Point), _Digits);
                           
                           novoTP = NormalizeDouble(precoEntrada - (preco_tp *_Point), _Digits);
                           
                           Trade.PositionModify(ticket, novoSl, novoTP);
                       }
                }
          }
    }

