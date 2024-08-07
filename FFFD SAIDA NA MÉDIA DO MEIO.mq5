#include <Trade\Trade.mqh>
CTrade Trade;


input string          título1=" ";                // #########HORÁRIOS############
input double          _volume=1.00;               // Número de lotes
input int             PeriodoBanda = 20;          // Periodo da Bollinger
input double          DesvioBanda = 2.00;         // Desvio da banda
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Tempo do gráfico


input string          título2=" ";                // #########HORÁRIOS############
input int             hAbertura=9;                // Hora de Abertura
input int             mAbertura=15;               // Minuto de Abertura
input int             hFechamento=17;             // Hora de Fechamento
input int             mFechamento=20;             // Minuto de Fechamento 
input int             hFecharPosicao=17;          // Horário de Fechar posições
input int             mFecharPosicao=40;          // Minuto de Fechar posições


// Magic Number
ulong           magicNum = 123456;          
// Desvio em pontos
ulong           desvPts = 50;               
// Pega o horário corrente
MqlDateTime           horarioAtual;
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


// Armazena valores da Bollinger
int handle_Bollinger;

// Armazena array da Bollinger
double array_upBand[];
double array_middleBand[];
double array_lowBand[];


// Armazena valores dos preços
MqlRates rates[];

int OnInit()
  {
   // Oculta a grade no gráfico
   ChartSetInteger(0, CHART_SHOW_GRID, false);     
   
   // Atribuindo os dados do indicador no handle
   handle_Bollinger = iBands(Symbol(), TimeFrame, PeriodoBanda, 0, DesvioBanda, PRICE_CLOSE);

   Print("⬜ Incialização realizada com sucesso!");
   return(INIT_SUCCEEDED);
  }


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
   
   // Torna o primeiro candle a ser contado para o último
   ArraySetAsSeries( array_upBand, true);
   ArraySetAsSeries( array_middleBand, true);
   ArraySetAsSeries( array_lowBand, true);
   ArraySetAsSeries( rates, true);

   // Simbolo, Periodo, começar posição 0, copia 3 posições, copia para o rates (no caso, esses são os preços)
   CopyRates(Symbol(), Period(), 0, 5, rates);

   // Handle do indicador, quantos buffers, começa a copiar da posição 0, copia 3 posições, copia para o array  
   CopyBuffer(handle_Bollinger, 1, 0, 5, array_upBand);
   CopyBuffer(handle_Bollinger, 0, 0, 5, array_middleBand);
   CopyBuffer(handle_Bollinger, 2, 0, 5, array_lowBand);


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
   // Se preço de fechamento do candle2 menor q lwo band E fechamento cadle1 maior que low band, então...
   if(rates[2].close < array_lowBand[2] && rates[1].close > array_lowBand[1])
     {
         // Então, habilita compra
         order=1;
     }
    //Caso comprado, segura compra e não deixa abrir mais posições
    if(OpenPosition==true && PositionType==POSITION_TYPE_BUY && order==1)
      {
          // Restrição de compra caso já esteja comprado
          order=0;               
          Print("⬜ Acionado compra com o robô já comprado, desconsiderando.");
      }           

   // Se preço de fechamento do candle2 maior q upBand2 E fechamento cadle1 menor que upband2, então...
   if(rates[2].close > array_upBand[2] && rates[1].close < array_upBand[1])
     {
         // Então, habilita venda.
         order=-1;
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
     
     
   // Se tiver com posição aberta
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
   // Se a estratégia apontar algo...
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
      // Se o sinal for de compra, então vamos comprar
      if(order==1 && HoraNegociacao())
        {
           // Compra a mercado, com 0 SL, 0 TP
           Trade.Buy(NumeroContratos, _Symbol, 0.00, 0.00, 0.00, "[COMPRA]");
           Print("⬜ Executada ordem de compra");
        }
      // Se o sinal for de venda, então vamos vender
      if(order==-1 && HoraNegociacao())
        {
           // Venda a mercado, com 0 SL, 0 TP
           Trade.Sell(NumeroContratos, _Symbol, 0.00, 0.00, 0.00, "[VENDA]");
           Print("⬜ Executada ordem de venda");
        }
     }
} // CHAVE FINAL DA ONTICK

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


















               
// NÃO ESTOU USANDO ESSA FUNÇÃO
/*
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
*/
  
  
//+------------------------------------------------------------------+
