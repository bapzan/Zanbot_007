// Dicas = Problema de conexão com o servidor? A conexão caiu? O book de ofertas tá funcionando? O ativo tá em leilão? Quantos mili segundos tá demorando pra me conectar com o servidor?
// Quantos milisegundos tá demorando pra eu emitir uma ordem? Eu to com problema de latência? 

#include <Trade\Trade.mqh>
CTrade Trade;





//+------------------------------------------------------------------+
//| Parâmetros de entrada                                            |
//+------------------------------------------------------------------+

input string          título1=" ";                // Parâmetro dos contratos
input double          contratos=1;              // Número de contratos

input string          título3=" ";                // Parâmetro das médias
input int             ma_fast_period=8;           // Periodo da média móvel RÁPIDA
input ENUM_MA_METHOD  ma_fast_method=MODE_SMA;    // Método da média móvel RÁPIDA
input int             ma_slow_period=21;          // Periodo da média móvel LENTA
input ENUM_MA_METHOD  ma_slow_method=MODE_SMA;    // Método da média móvel LENTA
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Tempo do gráfico

input string          título2="Lixaiada";         // Parâmetro do horário
input int             hAbertura=9;                // Hora de Abertura
input int             mAbertura=15;               // Minuto de Abertura
input int             hFechamento=17;             // Hora de Fechamento
input int             mFechamento=20;             // Minuto de Fechamento 
 ulong           magicNum = 123456;          // Magic Number
 ulong           desvPts = 50;               // Desvio em pontos

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE FECHAMENTO DE POSIÇÃO                       |
//+------------------------------------------------------------------+

input int             hFecharPosicao=17;          // Horário de Fechar posições
input int             mFecharPosicao=40;          // Minuto de Fechar posições

//+------------------------------------------------------------------+
//| VARIÁVEIS DE HORÁRIO                                             |
//+------------------------------------------------------------------+

MqlDateTime           horarioAtual;

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE MONITORAMENTO                               |
//+------------------------------------------------------------------+

int      gl_Tick=0;              // Contar o número de negócios  
int      gl_Order=0;             // Compra, venda ou não faz nada
string   gl_TendenciaMA="INDEF"; // Guarda status da posição das médias

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE GESTÃO DE CUSTÓDIA                          |
//+------------------------------------------------------------------+

bool     gl_OpenPosition=false;  // Tenho posição aberta (1)
long     gl_PositionType=-1;     // Estou comprado ou vendido (2)
double   gl_Contratos=0;         // Qual a posição de custódia no servidor (3)
bool     gl_DobraMao=false;      // Indica virada de mão

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE GESTÃO DE ELEMENTOS GRÁFICOS                |
//+------------------------------------------------------------------+

bool     gl_InitHandle1=false;   // Handle da média móvel rápida, inicialização
bool     gl_InitHandle2=false;   // Handle da média móvel lenta, inicialização

bool     gl_InitChart1=false;    // Média móvel rápida foi colocada no gráfico
bool     gl_InitChart2=false;    // Média móvel lenta foi colocada no gráfico

//+------------------------------------------------------------------+
//| HANDLES                                                          |
//+------------------------------------------------------------------+

int      iMA_fast_handle=INVALID_HANDLE;          // 2 handles, pois temos 2 médias
int      iMA_slow_handle=INVALID_HANDLE;

//+------------------------------------------------------------------+
//| BUFFERS                                                          |
//+------------------------------------------------------------------+

double   iMA_fast_buffer[];      // iMA_fast_buffer[0] iMA_fast_buffer[1] Vai armazenar os valores das médias nos candles
double   iMA_slow_buffer[];      // 

//+------------------------------------------------------------------+
//| IMPEDE DE COMPRAR NA MESMA BARRA, SÓ NA PRÓXIMA                  |
//+------------------------------------------------------------------+
   
bool  NovaBarra()
      {
       static datetime horaAntiga = 0;      
       datetime horaAtual = (int) SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);    // Para saber a hora de abertura da ultima barra
       
       if(horaAntiga == 0)
         {
          horaAntiga = horaAtual;     //
          return false;
         }
         
       else if(horaAntiga != horaAtual)
         {
          horaAntiga = horaAtual;
          return true;
         }
       else
         {
          return false;
         }
      }

//+------------------------------------------------------------------+
//| HORÁRIO DE FUNCIONAMENTO DO EA                                   |
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

//+------------------------------------------------------------------+
//| HORÁRIO DE FECHAMENTO DO EA                                      |
//+------------------------------------------------------------------+ 

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
   
//+------------------------------------------------------------------+
//| DECLARAÇÃO DE FECHAMENTO DE POSIÇÃO                              |
//+------------------------------------------------------------------+ 

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
                //+------------------------------------------------------------------+
               //|                                                                  |
              //| EXPERT ONINIT                                                    |
             //|                                                                  |
            //+------------------------------------------------------------------+

int OnInit()
  {
  
//+------------------------------------------------------------------+
//| CHART INITIALIZATION                                             |
//+------------------------------------------------------------------+  

   ResetLastError();
   Comment(" ");     // Comentário que aparece no topo do gráfico

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE MONITORAMENTO                               |
//+------------------------------------------------------------------+

   gl_Tick=0;              // Contar o número de negócios  
   gl_Order=0;             // Compra, venda ou não faz nada
   gl_TendenciaMA="INDEF"; // Guarda status da posição das médias

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE GESTÃO DE CUSTÓDIA                          |
//+------------------------------------------------------------------+

   gl_OpenPosition=false;  // Tenho posição aberta (1)
   gl_PositionType=-1;     // Estou comprado ou vendido (2)
   gl_Contratos=0;         // Qual a posição de custódia no servidor (3)
   gl_DobraMao=false;      // Indica virada de mão

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE GESTÃO DE ELEMENTOS GRÁFICOS                |
//+------------------------------------------------------------------+

   gl_InitHandle1=false;   // Handle da média móvel rápida, inicialização
   gl_InitHandle2=false;   // Handle da média móvel lenta, inicialização

   gl_InitChart1=false;    // Média móvel rápida foi colocada no gráfico
   gl_InitChart2=false;    // Média móvel lenta foi colocada no gráfico

//+------------------------------------------------------------------+
//| VALIDACOES DO TIPO DE CONTA DO USUÁRIO                           |
//+------------------------------------------------------------------+

   //if(AccountInfoInteger(ACCOUNT_TRADE_MODE)!=0)        // Solicitar o tipo de conta logado - Excluir isso caso queira conta real
   //  {
   //   Print("⬛ Robô programado para operar somente em conta demo.");
   //   return(INIT_FAILED);
   //  }
     
    if(AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=0)      // Modo NETTING para comprar um e vender um compensando. Ficando zerado. Para não ficar no modo heading (comprado e vendido independente).
     {
      Print("⬛ Robô programado para operar somente em tipo NETTING.");
      return(INIT_FAILED);
     }

//+------------------------------------------------------------------+
//| ANÁLISE DE VARIÁVEIS DE CONTRATOS                                |
//+------------------------------------------------------------------+

   if(contratos<=0)
   {
   Print("⬛ O número de contratos não pode ser zero ou menor que zero.");
      return(INIT_FAILED);
   }

   //if(contratos>5)
   //{
   //Print("⬛ O número de contratos não pode ser maior que 5.");
   //   return(INIT_FAILED);
   //}   
      
   
//+------------------------------------------------------------------+
//| ANÁLISE DE VARIÁVEIS DE HORÁRIO                                  |
//+------------------------------------------------------------------+
   
   if(hAbertura<0 || hAbertura>23)
     {
      Print("⬛ O horário de abertura não pode ser menor ou igual a zero e não pode ser maior que 23.");
      return(INIT_FAILED);
     }
   
   if(mAbertura<0 || mAbertura>59)
     {
      Print("⬛ O minuto de abertura não pode ser igual a zero e não pode ser maior que 59.");
      return(INIT_FAILED);
     }
   
   if(hFechamento<0 || hFechamento>23)
     {
      Print("⬛ O horário de fechamento não pode ser menor ou igual a zero e não pode ser maior que 23.");
      return(INIT_FAILED);
     }
       
   if(mFechamento<0 || mFechamento>59)
     {
      Print("⬛ O minuto de abertura não pode ser igual a zero e não pode ser maior que 59.");
      return(INIT_FAILED);
     }
   
   if(hFechamento<hAbertura)
     {
      Print("⬛ O horário de fechamento não pode ser menor que o horário de abertura.");
      return(INIT_FAILED);
     }
   
   if(mFechamento>=mFecharPosicao)
     {
      Print("⬛ O horário de fechamento não pode ser maior que o horário fechamento de posição.");
      return(INIT_FAILED);
     }
//+------------------------------------------------------------------+
//| ANÁLISE DE VARIÁVEIS DAS MÉDIAS                                  |
//+------------------------------------------------------------------+   
 
  if(ma_fast_period<=0)
      {
       Print("⬛ O período da média rápida não pode ser menor o igual a zero.");
       return(INIT_FAILED);
      }
   
   if(ma_slow_period<=0)
      {
       Print("⬛ O período da média lenta não pode ser menor ou igual a zero.");
       return(INIT_FAILED); 
      }
   if(ma_slow_period<ma_fast_period)
      {
       Print("⬛ O período da média lenta não pode ser menor que a média rápida");
       return(INIT_FAILED);
      }

//+------------------------------------------------------------------+
//| ANÁLISE DOS ATIVOS PERMITIDOS                                    |
//+------------------------------------------------------------------+  

    //if(StringSubstr(_Symbol, 0,3)!="WIN" &&   // Lista dos ativos permitidos, se colocar o robo em qualquer um que não seja esses, vai falhar, pode excluir esse comando para permitir todos
    //   StringSubstr(_Symbol, 0,3)!="IND" &&
    //   StringSubstr(_Symbol, 0,3)!="WDO" &&
    //   StringSubstr(_Symbol, 0,3)!="DOL")
    // {
    //  Print("⬛ Ativo não permitido.");
    //  return(INIT_FAILED);
    // }
     
    //if(StringSubstr(_Symbol, 0,4)=="WIN$" ||   // Lista dos ativos permitidos, se colocar o robo em qualquer um que não seja esses, vai falhar, pode excluir esse comando para permitir todos
    //   StringSubstr(_Symbol, 0,4)=="WIN@" ||
    //   StringSubstr(_Symbol, 0,4)=="WDO$" ||
    //   StringSubstr(_Symbol, 0,4)=="WDO@" ||
    //   StringSubstr(_Symbol, 0,4)=="IND$" ||
    //   StringSubstr(_Symbol, 0,4)=="IND@" ||
    //   StringSubstr(_Symbol, 0,4)=="DOL$" ||
    //   StringSubstr(_Symbol, 0,4)=="DOL@")
    // {
    //  Print("⬛ Não é permitido o uso de séries históricas, use o contrato oficial.");
    //  return(INIT_FAILED);
    // }
     
          
     
//+------------------------------------------------------------------+
//| HANDLES                                                          |
//+------------------------------------------------------------------+ 

   iMA_fast_handle=iMA(_Symbol,TimeFrame,ma_fast_period,0,ma_fast_method, PRICE_CLOSE);
   
   if(iMA_fast_handle==INVALID_HANDLE)
      {
       Print("⬛ Erro de criação do handle da média móvel rápida: ", GetLastError());
       return(INIT_FAILED);
      }
   else
      {
       gl_InitHandle1=true;
      }
   
   iMA_slow_handle=iMA(_Symbol, TimeFrame,ma_slow_period,0,ma_slow_method, PRICE_CLOSE);
   
   if(iMA_slow_handle==INVALID_HANDLE)
      {
       Print("⬛ Erro de criação do handle da média móvel lenta: ", GetLastError());
       return(INIT_FAILED);
      }
   else
      {
       gl_InitHandle2=true;
      }

//+------------------------------------------------------------------+
//| ARRAYSETASSERIES                                                 |
//+------------------------------------------------------------------+ 
   
   if(!ArraySetAsSeries(iMA_fast_buffer,true))    // Troca o 0 que a média rápida reconhece para o ultimo candle, ao invéz do primeiro da série histórica
     {
      Print("⬛ Erro na utilização do ArraySetAsSeries para iMA_fast_buffer: ", GetLastError());
      return(INIT_FAILED);
     }

   if(!ArraySetAsSeries(iMA_slow_buffer,true))    // Troca o 0 que a média lenta reconhece para o ultimo candle, ao invéz do primeiro da série histórica
     {
      Print("⬛ Erro na utilização do ArraySetAsSeries para iMA_slow_buffer: ", GetLastError());
      return(INIT_FAILED);
     }

//+------------------------------------------------------------------+
//| CHART INDICATOR ADD                                              |
//+------------------------------------------------------------------+ 

   if(!ChartIndicatorAdd(ChartID(), 0, iMA_fast_handle))     // 0 significa que é no gráfico, 1 pra indicador em baixo, 2 pra outro indicador em baixo
     {
      Print("⬛ Erro na plotagem do indicador iMA_fast_handle no gráfico: ", GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      gl_InitChart1=true;
     }
     

   if(!ChartIndicatorAdd(ChartID(), 0, iMA_slow_handle))
     {
      Print("⬛ Erro na plotagem do indicador iMA_slow_handle no gráfico: ", GetLastError());
      return(INIT_FAILED);
     }
   else
     {
      gl_InitChart2=true;
     }

//+------------------------------------------------------------------+
//| INICIALIZAÇÃO REALIZADA COM SUCESSO                              |
//+------------------------------------------------------------------+

   Print("⬜ Inicialização realizada com sucesso");
   return(INIT_SUCCEEDED);
   
}   // Chave final da Oninit
                //+------------------------------------------------------------------+
               //                                                                   |
              //| EEXPERT ONDEINIT                                                 |
             //                                                                   |
            //+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {
//+------------------------------------------------------------------+
//| CHART INITIALIZATION                                             |
//+------------------------------------------------------------------+  

   ResetLastError();
   Comment("TESTE DE COMENTÁRIO");     // Comentário que aparece no topo do gráfico

//+------------------------------------------------------------------+
//| INDICATOR RELEASE                                                |
//+------------------------------------------------------------------+ 

   if(gl_InitHandle1 && !IndicatorRelease(iMA_fast_handle))
      Print("⬛ Erro no release do iMA_fast_handle: ", GetLastError());  // Removi os indicadores (handles)
      
   if(gl_InitHandle2 && !IndicatorRelease(iMA_slow_handle))
      Print("⬛ Erro no release do iMA_slow_handle: ", GetLastError());
      
//+------------------------------------------------------------------+
//| ARRAYFREE                                                        |
//+------------------------------------------------------------------+ 

   ArrayFree(iMA_fast_buffer);                                          // Limpei os buffers
   ArrayFree(iMA_slow_buffer);

//+------------------------------------------------------------------+
//| DELETE CHART INDICATOR                                           |
//+------------------------------------------------------------------+ 

   string iMA_fast_chart=ChartIndicatorName(0, 0, 0);                   // Nomeando
   if(gl_InitChart1 && !ChartIndicatorDelete(0, 0, iMA_fast_chart))      // Removendo a média rápida
      Print("⬛ Erro na remoção da iMA_fast_chart: ", GetLastError());

   string iMA_slow_chart=ChartIndicatorName(0, 0, 0);                   // Nomeando
   if(gl_InitChart2 && !ChartIndicatorDelete(0, 0, iMA_slow_chart))      // Removendo a média lenta
     Print("⬛ Erro na remoção da iMA_slow_chart: ", GetLastError());
      
      
//+------------------------------------------------------------------+
//| DEINICIALIZAÇÃO REALIZADA COM SUCESSO                            |
//+------------------------------------------------------------------+ 

   Print("⬜ Deinicialização executada");
   
} // Chave final da OnDeinit
                //+------------------------------------------------------------------+
               //|                                                                  |
              //| EXPERT ON TICK                                                   |
             //|                                                                  |
            //+------------------------------------------------------------------+

void OnTick()
  {
  
//+------------------------------------------------------------------+
//| CHART INITIALIZATION                                             |
//+------------------------------------------------------------------+  
   
   ResetLastError();    // Zeramos variáveis de controle

//+------------------------------------------------------------------+
//| TRADE.SET                                                        |
//+------------------------------------------------------------------+

   Trade.SetDeviationInPoints(50);
   Trade.SetExpertMagicNumber(123456);

//+------------------------------------------------------------------+
//| HORÁRIOS DE FUNCIONAMENTO                                        |
//+------------------------------------------------------------------+ 
 
//   if(HoraNegociacao())
//     {
//      Comment("Dentro do horário de negociação");
//     }
//   else
//     {
//      Comment("Fora do horário de negociação");
//     }
//     
//     
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
     
//+------------------------------------------------------------------+
//| INICIALIZA COYBUFFER                                             |
//+------------------------------------------------------------------+   
  
   if(CopyBuffer(iMA_fast_handle, 0, 0, 3, iMA_fast_buffer)!=3)      // iMa_fast_buffer[0] iMa_fast_buffer[1] iMa_fast_buffer[2]CopyBuffer atualiza os valores das médias, copia 2 candles e joga pra dentro do buffer
     {
      Print("⬛ Erro ao atualizar os valores do indicador da média móvel rápida: ", GetLastError());
      return;
     }
     
   if(CopyBuffer(iMA_slow_handle, 0, 0, 3, iMA_slow_buffer)!=3)      // iMa_slow_buffer[0] iMa_slow_buffer[1] iMa_slow_buffer[2] CopyBuffer atualiza os valores das médias, copia 2 candles e joga pra dentro do buffe
     {
      Print("⬛ Erro ao atualizar os valores do indicador da média móvel lenta: ", GetLastError());
      return;
     }

//+------------------------------------------------------------------+
//| SINCRONIZA O HORÁRIO DO SERVIDOR                                 |
//+------------------------------------------------------------------+ 

//   MqlDateTime dt;      // Vai colocar dentro da variável DT uma estrutura (dt.hora, dt.minuto, dt.segundo...)
//   TimeCurrent(dt);     // Popula a variável DT com os dados atuais (Estrutura)
//   
   
//+------------------------------------------------------------------+
//| SABER A HORA ATUAL DA ULTIMA COTAÇÃO                             |
//+------------------------------------------------------------------+
     
   TimeToStruct(TimeCurrent(), horarioAtual);

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE MONITORAMENTO                               |
//+------------------------------------------------------------------+ 

   gl_Tick++;              // Contar o número de negócios
   gl_Order=0;             // Compra, venda ou não faz nada
   
//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS DE GESTÃO DE CUSTÓDIA                          |
//+------------------------------------------------------------------+ 

   gl_OpenPosition=false;  // Tenho posição aberta? (1)
   gl_PositionType=-1;     // Estou comprado ou vendido? (2)
   gl_Contratos=0;         // Qual a posição de custódia no servidor? (3)
   gl_DobraMao=false;      // Indica virada de mão

//+------------------------------------------------------------------+
//| ATUALIZA POSIÇÃO                                                 |
//+------------------------------------------------------------------+ 

   gl_OpenPosition=PositionSelect(_Symbol);
   
   if(gl_OpenPosition==true)
     {
      gl_PositionType=PositionGetInteger(POSITION_TYPE);    // Comprado ou vendido
      gl_Contratos=PositionGetDouble(POSITION_VOLUME);      // Quantos contratos custódia
      //Print("⬜ Robô posicionado: ", gl_Contratos);
     }   
   else // glOpenPosition==false
     {
      gl_PositionType=WRONG_VALUE;  // (-1)
      //Print("⬜ Robô não posicionado: ", gl_Contratos, " na posição de ", gl_PositionType);
     }

//+------------------------------------------------------------------+
//| COMPRA                                                           |
//+------------------------------------------------------------------+

   if((iMA_fast_buffer[0]>iMA_slow_buffer[0]) &&
      (iMA_fast_buffer[1]<iMA_slow_buffer[1]))
     {
      gl_Order=1;               // Pode comprar
      gl_TendenciaMA="ALTA";    // Guarda status da posição das médias
      Print("⬜ Médias cruzadas, compra acionada."); 
     }

//+------------------------------------------------------------------+
//| HOLD COMPRA                                                      |
//+------------------------------------------------------------------+

   if(gl_OpenPosition==true &&
      gl_PositionType==POSITION_TYPE_BUY &&
      gl_Order==1)
     {
      gl_Order=0;               // Restrição de compra caso já esteja comprado
      Print("⬜ Acionado compra com o robô já comprado, desconsiderando.");
     }

//+------------------------------------------------------------------+
//| VENDA                                                            |
//+------------------------------------------------------------------+

   if((iMA_fast_buffer[0]<iMA_slow_buffer[0]) &&
      (iMA_fast_buffer[1]>iMA_slow_buffer[1]))
     {
      gl_Order=-1;              // Pode vender
      gl_TendenciaMA="BAIXA";   // Guarda status da posição das médias
      Print("⬜ Médias cruzadas, venda acionada.");
     }

//+------------------------------------------------------------------+
//| HOLD VENDA                                                       |
//+------------------------------------------------------------------+

   if(gl_OpenPosition==true && 
      gl_PositionType==POSITION_TYPE_SELL &&
      gl_Order==-1)
     {
      gl_Order=0;    // Restrição de venda caso já esteja vendido
      Print("⬜ Acionado venda com o robô já vendido, desconsiderando.");
     }

//+------------------------------------------------------------------+
//| VIRADA DE MÃO                                                    |
//+------------------------------------------------------------------+

   if(gl_OpenPosition)     // Se eu estiver posicionado
      if((gl_PositionType==POSITION_TYPE_BUY && gl_Order==-1) ||     // Se a minha posição for de compra e o requisito seja vender ou (||)
         (gl_PositionType==POSITION_TYPE_SELL && gl_Order==1))       // (continuação) se a minha posição for de venda e meu requisito for comprar 
        {
         gl_DobraMao=true;                                           // Então eu vou dobrar a mão
         Print("⬜ Acionado virada de mão.");
        }
        
//+------------------------------------------------------------------+
//| SINCRONIZA O HORÁRIO DO SERVIDOR                                 |
//+------------------------------------------------------------------+ 

   MqlDateTime dt;
   TimeCurrent(dt);
   
//+------------------------------------------------------------------+
//| ATUALIZA VARIÁVEIS DE HORÁRIO                                    |
//+------------------------------------------------------------------+ 

   
   int loc_horarioAtual=dt.hour*60+dt.min;                   // Horário atual em minutos
   int loc_horarioAbertura=hAbertura*60+mAbertura;           // Horário de abertura em minutos
   int loc_horarioFechamento=hFechamento*60+mFechamento;     // Horário de fechamento em minutos
   int loc_horarioFechPosi=hFecharPosicao*60+mFecharPosicao; // Horário de fechamento de posição em minutos
   
   if(loc_horarioAtual<loc_horarioAbertura)
     {
      Comment("[MERCADO FECHADO | ABERTURA] ", dt.hour, ":", dt.min, ":", dt.sec);
     }
   if(loc_horarioAtual>loc_horarioFechamento)
     {
      Comment("[MERCADO FECHADO | FECHAMENTO] ", dt.hour, ":", dt.min, ":", dt.sec);
     }
 

//+------------------------------------------------------------------+
//| COMENTÁRIO GRÁFICO                                               |
//+------------------------------------------------------------------+

   Comment("[EM EXECUÇÃO] NEGÓCIOS: ", gl_Tick," | DIREÇÃO: ", gl_TendenciaMA," | CUSTODIA: ", gl_Contratos, "\n", "RELÓGIO: ", dt.hour, ":", dt.min, ":", dt.sec);
   
//+------------------------------------------------------------------+
//| ORDER PLACEMENT                                                  |
//+------------------------------------------------------------------+   

   if(gl_Order!=0)   // gl_order = 1 compra, 0 não faz nada, -1 vende.
     {
      //+------------------------------------------------------------------+
      //| ATUALIZA O PREÇO                                                 |
      //+------------------------------------------------------------------+
      
      MqlTick price_info;
      ZeroMemory(price_info);
      
      if(!SymbolInfoTick(_Symbol, price_info))     // Jogo para a price_info os valores atualizados do ativo
        {
         Print("⬛ Falha na atualização do preço: ", GetLastError());
         return;
        }
     
      //+------------------------------------------------------------------+
      //| PREPARA ENVIO DA ORDEM                                           |
      //+------------------------------------------------------------------+
      
      double loc_NumeroContratos = contratos;
      
      if(gl_DobraMao==true)
        {
         loc_NumeroContratos=contratos*2;
         Print("⬜ Dobrando número de contratos para a operação.");
        }
        
      if(gl_Order==1)
        {
         Trade.Buy(loc_NumeroContratos, _Symbol);
         Print("⬜ Executada ordem de compra");
        }
        
      if(gl_Order==-1)
        {
         Trade.Sell(loc_NumeroContratos, _Symbol);
         Print("⬜ Executada ordem de venda");
        }           
     }

 

} // Chave final da Oninit

//+------------------------------------------------------------------+
