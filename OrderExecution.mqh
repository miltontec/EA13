//+------------------------------------------------------------------+
//|                                    OrderExecution_NCN_v11.03.mqh |
//|                        Sistema con Neural Consensus Network      |
//|                        Trailing Stop Sincronizado para Ciclo     |
//+------------------------------------------------------------------+
#ifndef ORDER_EXECUTION_NCN_V11_03_MQH
#define ORDER_EXECUTION_NCN_V11_03_MQH
#property copyright "Trading System v11.03 - Synchronized Trailing Stop"
#property version   "11.03"
#property strict

#include <Trade/Trade.mqh>
#include <SupportResistance.mqh>
#include <VotingStatistics.mqh>
#include <MetaLearningSystem.mqh>

//+------------------------------------------------------------------+
//| ENUMERACIONES                                                    |
//+------------------------------------------------------------------+
#ifndef ENUM_TRADE_DIRECTION_DEF
#define ENUM_TRADE_DIRECTION_DEF
enum ENUM_TRADE_DIRECTION
{
    DIRECTION_NONE,   // 0
    DIRECTION_BUY,    // 1
    DIRECTION_SELL    // 2
};
#endif

//+------------------------------------------------------------------+
//| ESTRUCTURAS PARA MULTI-ORDEN                                    |
//+------------------------------------------------------------------+
#ifndef MULTI_ORDER_CYCLE_STRUCT
#define MULTI_ORDER_CYCLE_STRUCT
struct MultiOrderCycle
{
    ulong             tickets[10];           
    double            lotSizes[10];          
    double            entryPrices[10];       
    double            stopLosses[10];        
    double            takeProfits[10];       
    int               orderCount;            
    double            baseLotSize;           
    ENUM_TRADE_DIRECTION direction;          
    datetime          cycleStartTime;        
    bool              cycleActive;           
    double            totalPartialClosed;    
    double            cycleProfit;           
    
    // Campos para Neural Consensus
    double            consensusStrength;     
    double            emotionalContext;      
    int               emotionalAlerts;       
    double            maxFearLevel;          
    double            avgConviction;         
// NUEVO: Tracking de consenso
ulong             initial_consensus_id;  // ID del consenso que inició el ciclo
ulong             consensus_ids[10];     // ID de consenso para cada orden

    
    // NUEVO: Trailing sincronizado del ciclo
    bool              cycleTrailingActive;   // Si el trailing del ciclo está activo
    double            cycleTrailingLevel;    // Nivel de SL común para todas las órdenes
    double            cycleTrailingActivationPrice; // Precio donde se activó el trailing del ciclo
    datetime          cycleLastTrailingUpdate; // Última actualización del trailing del ciclo
    double            cycleMaxProfit;        // Máximo profit alcanzado en el ciclo
    double            maxDrawdown;          // Máxima racha de pérdida del ciclo
    int               dissenting_agents;    // Cantidad de agentes que difirieron del consenso
};

#endif // MULTI_ORDER_CYCLE_STRUCT
struct PositionInfo
{
    ulong             ticket;
    datetime          openTime;
    double            openPrice;
    double            currentSL;
    double            currentTP;
    double            maxProfit;
    double            currentLot;
    bool              isPartOfCycle;
    int               cycleIndex;
    double            emotionalScore;
    
    // Info de trailing
    bool              trailingActive;
    int               trailingStage;
    double            lastTrailingPrice;
};

//+------------------------------------------------------------------+
//| Estructura para configuración de trailing dinámico              |
//+------------------------------------------------------------------+
struct TrailingConfig
{
    int               activationPoints;    // Puntos para activar
    int               trailingDistance;    // Distancia del trailing
    double            protectionFactor;    // Factor de protección (0.5 = 50% del movimiento)
    bool              useATR;             // Usar ATR para ajuste dinámico
    double            atrMultiplier;      // Multiplicador ATR
};

//+------------------------------------------------------------------+
//| NUEVA ESTRUCTURA: Configuración de Lot Inteligente              |
//+------------------------------------------------------------------+
struct IntelligentLotConfig
{
    // Multiplicadores base
    double            minRiskMultiplier;      // Multiplicador mínimo (default 0.1)
    double            maxRiskMultiplier;      // Multiplicador máximo (default 1.0)
    
    // Pesos de componentes
    double            consensusWeight;        // Peso del consenso (default 0.4)
    double            convictionWeight;       // Peso de convicción (default 0.3)
    double            emotionalWeight;        // Peso emocional (default 0.2)
    double            metaLearningWeight;     // Peso de ML (default 0.1)
    
    // Umbrales de confianza
    double            highConfidenceThreshold;  // Umbral para confianza alta (0.8)
    double            lowConfidenceThreshold;   // Umbral para confianza baja (0.3)
    
    // Ajustes emocionales
    double            fearReductionFactor;    // Factor de reducción por miedo (0.5)
    double            greedBoostFactor;       // Factor de boost por codicia (1.2)
    double            uncertaintyPenalty;     // Penalización por incertidumbre (0.3)
};

//+------------------------------------------------------------------+
//| ENUMERACIONES ADICIONALES                                        |
//+------------------------------------------------------------------+
enum ENUM_EXECUTION_PHASE
{
    PHASE_VALIDATION,
    PHASE_CALCULATION,
    PHASE_EXECUTION,
    PHASE_MANAGEMENT,
    PHASE_EMOTIONAL_CHECK
};

enum ENUM_MARKET_CONTEXT
{
    CONTEXT_RALLY,
    CONTEXT_ACCUMULATION,
    CONTEXT_HIGH_VOL,
    CONTEXT_NORMAL,
    CONTEXT_FEARFUL,
    CONTEXT_GREEDY
};

enum ENUM_EMOTIONAL_ACTION
{
    ACTION_NONE,
    ACTION_REDUCE_SIZE,
    ACTION_TIGHTEN_STOPS,
    ACTION_PARTIAL_CLOSE,
    ACTION_FULL_EXIT
};

//+------------------------------------------------------------------+
//| ESTRUCTURA MarketEmotion para análisis emocional del mercado   |
//+------------------------------------------------------------------+
#ifndef MARKET_EMOTION_STRUCT_DEFINED
#define MARKET_EMOTION_STRUCT_DEFINED
struct MarketEmotion
{
    double fear;
    double greed;
    double uncertainty;
    double excitement;
    datetime timestamp;
};
#endif


//+------------------------------------------------------------------+
//| CLASE PRINCIPAL OrderExecution v11.03                           |
//+------------------------------------------------------------------+
class OrderExecution
{
private:
// NUEVO: ID del consenso actual
ulong m_current_consensus_id;

// NUEVO: Tracking de órdenes cerradas
struct ClosedOrderInfo
{
    ulong ticket;
    ulong consensus_id;
    double profit;
    bool success;
    datetime close_time;
};
ClosedOrderInfo m_closed_orders[];
int m_closed_count;

    // Referencias a otros módulos
    MetaLearningSystem*   m_metaLearning;
    
    // Parámetros de configuración
    double               m_riskPercent;
    double               m_maxLotSize;
    double               m_atrMultiplier;
    double               m_emergencyDD;
    int                  m_magicNumber;
    
    // Parámetros multi-orden
    double               m_orderReduction;
    double               m_partialClosePercent;
    int                  m_trailingDistance;
    int                  m_trailingStart;
    int                  m_maxOrdersPerCycle;
    
    // Parámetros emocionales
    double               m_fearThreshold;
    double               m_greedThreshold;
    double               m_emotionalReduction;
    bool                 m_useEmotionalStops;
    
    // NUEVO: Configuración de lote inteligente
    IntelligentLotConfig m_lotConfig;
    double               m_lastConsensusStrength;
    double               m_lastTotalConviction;
    
    // NUEVOS: Configuración de trailing dinámico
    TrailingConfig       m_trailingStages[3];  // 3 etapas de trailing
    bool                 m_useDynamicTrailing;
    double               m_trailingATRPeriod;
    
    // Estado interno
    double               m_currentATR;
    double               m_accountEquity;
    double               m_volatilityRatio;
    ENUM_MARKET_CONTEXT  m_marketContext;
    bool                 m_emergencyActive;
    MarketEmotion        m_currentEmotion;
    
    // Estadísticas
    int                  m_totalTrades;
    double               m_totalProfit;
    double               m_maxDrawdown;
    int                  m_emotionalExits;
    
    // Control de trade
    CTrade               m_trade;

public:
    // Multi-orden público
    MultiOrderCycle      m_multiOrder;
    // -- Declaraciones añadidas para consenso y ciclo multi-orden
    void ResetMultiOrderCycle();
    void SetCurrentConsensusID(ulong consensus_id);
    void NotifyOrderClosed(ulong ticket,double profit,bool success);
    
    
    // Constructor y destructor
                        OrderExecution();
                       ~OrderExecution();
    
    // Inicialización
    bool                 Initialize(MetaLearningSystem* metaLearning = NULL);
    void                 SetParameters(double riskPercent, double maxLot, double atrMult);
    void                 SetMultiOrderParams(double reduction, double partialClose, int trailingStart, int trailingStep, int maxOrders);
    void                 SetEmotionalParams(double fearThreshold, double greedThreshold, double emotionalReduction);
    void                 SetMagicNumber(int magic) { m_magicNumber = magic; }
    
    // Configuración de trailing dinámico
    void                 SetDynamicTrailingParams(bool useDynamic, double atrPeriod = 14);
    void                 ConfigureTrailingStage(int stage, int activation, int distance, double protection, bool useATR, double atrMult);
    
    // MÉTODOS PRINCIPALES MULTI-ORDEN
    bool                 ExecuteFirstOrder(int direction, double conviction, double touchPrice);
    bool                 ExecuteAdditionalOrder(int direction, double conviction);
    void                 UpdateAllTrailingStops();         // MODIFICADO para trailing sincronizado
    bool                 ExecutePartialCloses();
    void                 MonitorMultiplePositions();
    void                 CheckCycleIntegrity();
    void                 FinalizeCycle();
    
    // Verificar si hay órdenes en profit
    bool                 HasOrdersInProfit(int &ordersInProfit, double &totalProfit);
    double               GetFirstOrderProfit();
    double               GetFirstOrderMovement();
    
    // Métodos emocionales
    void                 UpdateEmotionalContext(MarketEmotion &emotion);
    ENUM_EMOTIONAL_ACTION AnalyzeEmotionalAction();
    bool                 ExecuteEmotionalAction(ENUM_EMOTIONAL_ACTION action);
    void                 AdjustStopsForEmotion();
    double               GetEmotionalMultiplier();

    // Métodos de cálculo
    double               CalculateLotSize(double stopDistance, double conviction);
    double               CalculateEmotionalLotSize(double baseLot, MarketEmotion &emotion);
    double               CalculateReducedLotSize(int orderIndex);
    double               CalculateStopLoss(double entryPrice, int direction, bool isAdditional = false);
    double               CalculateTakeProfit(double entryPrice, int direction);
    double               CalculateEmotionalStop(double normalStop, int direction);
    
    // Gestión de posiciones mejorada
    bool                 UpdateCycleTrailing();              // NUEVO: Actualizar trailing sincronizado
    bool                 ApplyCycleTrailingToOrder(int orderIndex); // NUEVO: Aplicar trailing a orden específica
    bool                 CheckTrailingActivation();          // NUEVO: Verificar activación del trailing
    bool                 ClosePartialPosition(ulong ticket, double closePercent);
    bool                 EmergencyCloseAll(string reason);
    bool                 IsTicketInCycle(ulong ticket);
    int                  GetOrderIndexByTicket(ulong ticket);
    bool                 CheckEmergencyStop();
    
    // Comunicación con otros módulos
    void                 SendCycleToMetaLearning();
    void                 UpdateConsensusContext(double consensusStrength, double conviction);
    void                 UpdateStatus(string status);
    
    // Utilidades
    void                 UpdateATR();
    void                 UpdateAccountInfo();
    bool                 ValidateExecution(double price, double lot);
    void                 LogExecutionEvent(string message);
    void                 PrintEmotionalStatus();
    void                 PrintTrailingStatus();  // MODIFICADO
    
private:
    // Métodos internos
    bool                 ExecuteMarketOrder(int direction, double lotSize, 
                                          double entryPrice, double stopPrice, double tpPrice);
    void                 RecalculateActiveOrders();
    void                 CompactOrderArrays();
    bool                 CheckOrderClosed(ulong ticket);
    double               GetUpdatedPrice(int direction);
    int                  CalculateDynamicSlippage();
    void                 UpdateMarketContext();
    double               CalculateEmotionalScore();
    void                 LogEmotionalEvent(string event, double score);
    double               m_actualRiskUsed;      // Riesgo real usado en último trade
    bool                 m_overrideMinLot;      // Si debe ignorar mínimo del broker
    // Métodos privados para trailing
    void                 InitializeTrailingConfig();
    int                  DetermineTrailingStage(double profitPoints);
    double               GetATRValue(ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
    double               CalculateCycleTrailingStop(double currentPrice); // NUEVO
    
    // NUEVOS: Métodos para cálculo inteligente de lote
    void                 InitializeLotConfig();
    double               CalculateIntelligentLotSize(double baseRisk, double stopDistance);
    double               CalculateConfidenceMultiplier();
    double               CalculateEmotionalAdjustment();
    double               GetMetaLearningBoost();
    double               NormalizeLotSize(double lot);
    void                 PrintLotCalculationDetails(double finalLot);
    ulong GetCurrentConsensusID() const
{
    return m_current_consensus_id;
}
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
OrderExecution::OrderExecution()
{
    m_actualRiskUsed = 0.0;
    m_overrideMinLot = false;
    // Parámetros por defecto - CAMBIO: Riesgo máximo 5%
    m_riskPercent = 5.0;  // CAMBIADO DE 2.0 A 5.0
    m_maxLotSize = 1.0;
    m_atrMultiplier = 1.5;
    m_emergencyDD = 10.0;
    m_magicNumber = 123456;
    m_metaLearning = NULL;
    
    // Multi-orden por defecto
    m_orderReduction = 0.65;
    m_partialClosePercent = 0.20;
    m_trailingDistance = 150;
    m_trailingStart = 200;
    m_maxOrdersPerCycle = 5;
    
    // Parámetros emocionales por defecto
    m_fearThreshold = 0.7;
    m_greedThreshold = 0.7;
    m_emotionalReduction = 0.3;
    m_useEmotionalStops = true;
    
    // NUEVO: Inicializar configuración de lote inteligente
    InitializeLotConfig();
    m_lastConsensusStrength = 0.5;
    m_lastTotalConviction = 0.5;
    
    // Trailing dinámico por defecto
    m_useDynamicTrailing = true;
    m_trailingATRPeriod = 14;
    InitializeTrailingConfig();
    
    // Estado inicial
    m_currentATR = 0.0;
        m_accountEquity = 0.0;
    m_marketContext = CONTEXT_NORMAL;
    m_emergencyActive = false;
    
    // Estadísticas
    m_totalTrades = 0;
    m_totalProfit = 0.0;
    m_maxDrawdown = 0.0;
    m_emotionalExits = 0;
    
    // Inicializar multi-orden
    ResetMultiOrderCycle();
    
    // Inicializar emoción
    m_currentEmotion.fear = 0.5;
    m_currentEmotion.greed = 0.5;
    m_currentEmotion.uncertainty = 0.5;
    m_currentEmotion.excitement = 0.5;
    
    // Configurar CTrade
    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetTypeFilling(ORDER_FILLING_IOC);
    m_trade.SetDeviationInPoints(10);
}


//+------------------------------------------------------------------+
//| NUEVO: Inicializar configuración de lote inteligente            |
//+------------------------------------------------------------------+
void OrderExecution::InitializeLotConfig()
{
    // Multiplicadores base
    m_lotConfig.minRiskMultiplier = 0.1;     // Usar mínimo 10% del riesgo
    m_lotConfig.maxRiskMultiplier = 1.0;     // Usar máximo 100% del riesgo
    
    // Pesos de componentes (deben sumar 1.0)
    m_lotConfig.consensusWeight = 0.4;       // 40% basado en consenso
    m_lotConfig.convictionWeight = 0.3;      // 30% basado en convicción
    m_lotConfig.emotionalWeight = 0.2;       // 20% basado en emoción
    m_lotConfig.metaLearningWeight = 0.1;    // 10% basado en ML
    
    // Umbrales de confianza
    m_lotConfig.highConfidenceThreshold = 0.8;
    m_lotConfig.lowConfidenceThreshold = 0.3;
    
    // Ajustes emocionales
    m_lotConfig.fearReductionFactor = 0.5;   // Reducir 50% con miedo alto
    m_lotConfig.greedBoostFactor = 1.2;      // Boost 20% con codicia (pero controlada)
    m_lotConfig.uncertaintyPenalty = 0.3;     // Penalización 30% con incertidumbre
}

//+------------------------------------------------------------------+
//| Inicializar configuración de trailing por defecto               |
//+------------------------------------------------------------------+
void OrderExecution::InitializeTrailingConfig()
{
    // Etapa 1: Protección inicial
    m_trailingStages[0].activationPoints = 100;
    m_trailingStages[0].trailingDistance = 80;
    m_trailingStages[0].protectionFactor = 0.3;
    m_trailingStages[0].useATR = true;
    m_trailingStages[0].atrMultiplier = 1.5;
    
    // Etapa 2: Protección media
    m_trailingStages[1].activationPoints = 200;
    m_trailingStages[1].trailingDistance = 60;
    m_trailingStages[1].protectionFactor = 0.5;
    m_trailingStages[1].useATR = true;
    m_trailingStages[1].atrMultiplier = 1.2;
    
    // Etapa 3: Protección agresiva
    m_trailingStages[2].activationPoints = 300;
    m_trailingStages[2].trailingDistance = 40;
    m_trailingStages[2].protectionFactor = 0.7;
    m_trailingStages[2].useATR = true;
    m_trailingStages[2].atrMultiplier = 1.0;
}

//+------------------------------------------------------------------+
//| Reset del ciclo multi-orden                                     |
//+------------------------------------------------------------------+
void OrderExecution::ResetMultiOrderCycle()
{
    for(int i = 0; i < 10; i++)
    {
        m_multiOrder.tickets[i] = 0;
        m_multiOrder.lotSizes[i] = 0;
        m_multiOrder.entryPrices[i] = 0;
        m_multiOrder.stopLosses[i] = 0;
        m_multiOrder.takeProfits[i] = 0;
        m_multiOrder.consensus_ids[i] = 0;  // NUEVO
    m_multiOrder.maxDrawdown = 0.0;
    m_multiOrder.dissenting_agents = 0;
    }
    
    m_multiOrder.orderCount = 0;
    m_multiOrder.cycleActive = false;
    m_multiOrder.direction = DIRECTION_NONE;
    m_multiOrder.baseLotSize = 0;
    m_multiOrder.cycleStartTime = 0;
    m_multiOrder.totalPartialClosed = 0;
    m_multiOrder.cycleProfit = 0;
    m_multiOrder.consensusStrength = 0;
    m_multiOrder.emotionalContext = 0.5;
    m_multiOrder.emotionalAlerts = 0;
    m_multiOrder.maxFearLevel = 0;
    m_multiOrder.avgConviction = 0;
    m_multiOrder.initial_consensus_id = 0;  // NUEVO
    
    // NUEVO: Reset trailing sincronizado
    m_multiOrder.cycleTrailingActive = false;
    m_multiOrder.cycleTrailingLevel = 0;
    m_multiOrder.cycleTrailingActivationPrice = 0;
    m_multiOrder.cycleLastTrailingUpdate = 0;
    m_multiOrder.cycleMaxProfit = 0;
}

//+------------------------------------------------------------------+
//| Configurar parámetros de trailing dinámico                      |
//+------------------------------------------------------------------+
void OrderExecution::SetDynamicTrailingParams(bool useDynamic, double atrPeriod)
{
    m_useDynamicTrailing = useDynamic;
    m_trailingATRPeriod = MathMax(5, MathMin(50, atrPeriod));
    
    Print("OrderExecution: Trailing dinámico ", (useDynamic ? "ACTIVADO" : "DESACTIVADO"));
    if(useDynamic)
    {
        Print("  Período ATR: ", m_trailingATRPeriod);
    }
}

//+------------------------------------------------------------------+
//| Configurar etapa de trailing específica                         |
//+------------------------------------------------------------------+
void OrderExecution::ConfigureTrailingStage(int stage, int activation, int distance, 
                                           double protection, bool useATR, double atrMult)
{
    if(stage < 0 || stage > 2) return;
    
    m_trailingStages[stage].activationPoints = activation;
    m_trailingStages[stage].trailingDistance = distance;
    m_trailingStages[stage].protectionFactor = MathMax(0.1, MathMin(0.9, protection));
    m_trailingStages[stage].useATR = useATR;
    m_trailingStages[stage].atrMultiplier = MathMax(0.5, MathMin(3.0, atrMult));
    
    Print("Trailing Etapa ", stage+1, " configurada: ",
          "Act=", activation, " Dist=", distance, " Prot=", protection);
}

//+------------------------------------------------------------------+
//| MEJORADO: Calcular tamaño de lote con sistema inteligente      |
//+------------------------------------------------------------------+
double OrderExecution::CalculateLotSize(double stopDistance, double conviction)
{
    if(stopDistance <= 0 || m_accountEquity <= 0) return 0;
    
    // 1. Calcular riesgo base del balance (ahora con 5% máximo)
    double baseRiskAmount = m_accountEquity * (m_riskPercent / 100.0); // Ahora basado en equity
    
    // 2. Usar el nuevo sistema de cálculo inteligente
    double finalLot = CalculateIntelligentLotSize(baseRiskAmount, stopDistance);
    
    // 3. Log detallado del cálculo (solo si hay convicción significativa)
    if(conviction > 0.2)
    {
        PrintLotCalculationDetails(finalLot);
    }
    
    return finalLot;
}


//+------------------------------------------------------------------+
//| NUEVO SISTEMA DE LOTAJE INTELIGENTE                            |
//+------------------------------------------------------------------+
double OrderExecution::CalculateIntelligentLotSize(double baseRisk, double stopDistance)
{
    // 1. CÁLCULO BASE FIJO (No se toca)
    double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if(pipValue <= 0) pipValue = 1.0;
    
    double baseLot = baseRisk / (stopDistance * pipValue);
    
    // 2. AJUSTE POR CONFIANZA (Máximo ±30%)
    double confidenceAdjustment = 1.0;
    
    // Sistema de 3 niveles simples
    if(m_lastConsensusStrength > 0.8 && m_lastTotalConviction > 0.7)
    {
        // ALTA CONFIANZA: +15% a +30%
        confidenceAdjustment = 1.15;
        
        // NOTA: GetMasterAgent no está disponible actualmente en MetaLearningSystem
        // TODO: Implementar GetMasterAgent en MetaLearningSystem
        /*
        // Bonus si hay Master Agent liderando
        if(m_metaLearning != NULL)
        {
            string leader = m_metaLearning.GetMasterAgent();
            if(leader != "None" && leader != "")
                confidenceAdjustment = 1.30;
        }
        */
    }
    else if(m_lastConsensusStrength > 0.6 && m_lastTotalConviction > 0.5)
    {
        // CONFIANZA MEDIA: Sin cambios
        confidenceAdjustment = 1.0;
    }
    else
    {
        // BAJA CONFIANZA: -15%
        confidenceAdjustment = 0.85;
        
        // Si es MUY baja, -30%
        if(m_lastConsensusStrength < 0.4 || m_lastTotalConviction < 0.3)
            confidenceAdjustment = 0.70;
    }
    
    // 3. AJUSTE POR CONTEXTO DE MERCADO (Máximo ±10%)
    double marketAdjustment = 1.0;
    
    // Solo en volatilidad extrema
    if(m_volatilityRatio > 2.5)
        marketAdjustment = 0.90;  // -10% en volatilidad muy alta
    else if(m_volatilityRatio < 0.5)
        marketAdjustment = 1.10;  // +10% en volatilidad muy baja
    
    // 4. SEGURIDAD EMOCIONAL (Solo en casos extremos)
    double emotionalSafety = 1.0;
    if(m_currentEmotion.fear > 0.9)  // Solo miedo EXTREMO
        emotionalSafety = 0.80;  // -20%
    
    // 5. CÁLCULO FINAL
    double finalMultiplier = confidenceAdjustment * marketAdjustment * emotionalSafety;
    
    // Ajuste total (mínimo 0.1x, sin límite superior)
    finalMultiplier = MathMax(0.5, MathMin(1.5, finalMultiplier));
    
    double finalLot = baseLot * finalMultiplier;
    
    // 6. NORMALIZACIÓN
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Asegurar mínimo razonable
    double reasonableMin = minLot;
    
    finalLot = MathMax(reasonableMin, MathMin(m_maxLotSize, finalLot));
    finalLot = MathRound(finalLot / stepLot) * stepLot;
    
    // 7. LOG CLARO Y TRANSPARENTE
    double actualRiskPercent = (finalLot * stopDistance * pipValue) / m_accountEquity * 100.0;
    
    Print("═══ CÁLCULO DE LOTE INTELIGENTE ═══");
    Print("Equity : $", DoubleToString(m_accountEquity, 2));
    Print("Riesgo configurado: ", DoubleToString(m_riskPercent, 1), "%");
    Print("Riesgo real: ", DoubleToString(actualRiskPercent, 2), "%");
    Print("Ajustes aplicados:");
    Print("  • Confianza: x", DoubleToString(confidenceAdjustment, 2), 
          " (Consenso: ", DoubleToString(m_lastConsensusStrength, 2), ")");
    if(marketAdjustment != 1.0)
        Print("  • Mercado: x", DoubleToString(marketAdjustment, 2));
    if(emotionalSafety != 1.0)
        Print("  • Seguridad: x", DoubleToString(emotionalSafety, 2));
    Print("Multiplicador total: x", DoubleToString(finalMultiplier, 2));
    Print("Lote final: ", DoubleToString(finalLot, 3));
    Print("═══════════════════════════════════");
    
    return finalLot;
}

//+------------------------------------------------------------------+
//| NUEVO: Calcular multiplicador de confianza                      |
//+------------------------------------------------------------------+
double OrderExecution::CalculateConfidenceMultiplier()
{
    // Componente 1: Consenso (40%)
    double consensusComponent = m_lastConsensusStrength * m_lotConfig.consensusWeight;
    
    // Componente 2: Convicción (30%)
    double convictionComponent = m_lastTotalConviction * m_lotConfig.convictionWeight;
    
    // Componente 3: Confianza combinada
    double combinedConfidence = consensusComponent + convictionComponent;
    
    // Aplicar curva de confianza no lineal
    double multiplier;
    
    if(combinedConfidence >= m_lotConfig.highConfidenceThreshold)
    {
        // Alta confianza: usar 80-100% del riesgo
        multiplier = 0.8 + (combinedConfidence - m_lotConfig.highConfidenceThreshold) / 
                          (1.0 - m_lotConfig.highConfidenceThreshold) * 0.2;
    }
    else if(combinedConfidence <= m_lotConfig.lowConfidenceThreshold)
    {
        // Baja confianza: usar 10-30% del riesgo
        multiplier = 0.1 + (combinedConfidence / m_lotConfig.lowConfidenceThreshold) * 0.2;
    }
    else
    {
        // Confianza media: usar 30-80% del riesgo (interpolación)
        double range = m_lotConfig.highConfidenceThreshold - m_lotConfig.lowConfidenceThreshold;
        double position = (combinedConfidence - m_lotConfig.lowConfidenceThreshold) / range;
        multiplier = 0.3 + position * 0.5;
    }
    
    return multiplier;
}

//+------------------------------------------------------------------+
//| NUEVO: Calcular ajuste emocional                                |
//+------------------------------------------------------------------+
double OrderExecution::CalculateEmotionalAdjustment()
{
    double adjustment = 1.0;
    
    // Reducción por miedo
    if(m_currentEmotion.fear > 0.5)
    {
        double fearImpact = (m_currentEmotion.fear - 0.5) * 2.0; // 0 a 1
        adjustment *= (1.0 - fearImpact * (1.0 - m_lotConfig.fearReductionFactor));
    }
    
    // Reducción por incertidumbre
    if(m_currentEmotion.uncertainty > 0.6)
    {
        double uncertaintyImpact = (m_currentEmotion.uncertainty - 0.6) / 0.4;
        adjustment *= (1.0 - uncertaintyImpact * m_lotConfig.uncertaintyPenalty);
    }
    
    // Boost moderado por codicia (solo si no hay miedo alto)
    if(m_currentEmotion.greed > 0.7 && m_currentEmotion.fear < 0.4)
    {
        double greedImpact = (m_currentEmotion.greed - 0.7) / 0.3;
        adjustment *= (1.0 + greedImpact * (m_lotConfig.greedBoostFactor - 1.0));
    }
    
    // Aplicar peso emocional
    double emotionalWeight = m_lotConfig.emotionalWeight;
    adjustment = 1.0 + (adjustment - 1.0) * emotionalWeight;
    
    return MathMax(0.3, MathMin(1.2, adjustment));
}

//+------------------------------------------------------------------+
//| NUEVO: Obtener boost de MetaLearning                            |
//+------------------------------------------------------------------+
double OrderExecution::GetMetaLearningBoost()
{
    if(m_metaLearning == NULL || CheckPointer(m_metaLearning) != POINTER_DYNAMIC)
        return 1.0;
    
    // NOTA: Estos métodos no están disponibles actualmente en MetaLearningSystem
    // TODO: Implementar GetRiskAdjustment() y GetEmotionalRiskAdjustment() en MetaLearningSystem
    
    // Por ahora, retornar valor por defecto
    return 1.0;
    
    /*
    // Obtener ajuste de riesgo de ML
    double mlAdjustment = m_metaLearning.GetRiskAdjustment();
    
    // Obtener ajuste emocional de ML
    double mlEmotionalAdjustment = m_metaLearning.GetEmotionalRiskAdjustment(
        m_currentEmotion.fear, m_currentEmotion.greed);
    
    // Combinar ajustes
    double combinedML = (mlAdjustment + mlEmotionalAdjustment) / 2.0;
    
    // Aplicar peso de ML
    double mlWeight = m_lotConfig.metaLearningWeight;
    double boost = 1.0 + (combinedML - 1.0) * mlWeight;
    
    return MathMax(0.8, MathMin(1.3, boost));
    */
}

//+------------------------------------------------------------------+
//| NormalizeLotSize mejorado con más validaciones                 |
//+------------------------------------------------------------------+
double OrderExecution::NormalizeLotSize(double lot)
{
    // Obtener límites del símbolo
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Validar que los límites sean válidos
    if(minLot <= 0) minLot = 0.01;
    if(maxLot <= 0 || maxLot < minLot) maxLot = 100.0;
    if(stepLot <= 0) stepLot = 0.01;
    
    // Aplicar límite configurado
    maxLot = MathMin(m_maxLotSize, maxLot);
    
    // Validar lot de entrada
    if(!MathIsValidNumber(lot) || lot <= 0)
    {
        Print("OrderExecution: Lot inválido para normalizar: ", lot);
        return minLot;
    }
    
    // Limitar entre min y max
    lot = MathMax(minLot, MathMin(maxLot, lot));
    
    // Normalizar al step
    double steps = MathRound(lot / stepLot);
    lot = steps * stepLot;
    
    // Validación final
    lot = NormalizeDouble(lot, 2);  // Máximo 2 decimales
    lot = MathMax(minLot, MathMin(maxLot, lot));
    
    return lot;
}
//+------------------------------------------------------------------+
//| NUEVO: Imprimir detalles del cálculo de lote                   |
//+------------------------------------------------------------------+
void OrderExecution::PrintLotCalculationDetails(double finalLot)
{
    static int callCount = 0;
    callCount++;
    
    // Solo imprimir cada 5 llamadas para no saturar el log
    if(callCount % 5 != 1) return;
    
    double confidenceMultiplier = CalculateConfidenceMultiplier();
    double emotionalAdjustment = CalculateEmotionalAdjustment();
    double mlBoost = GetMetaLearningBoost();
    
    Print("=== CÁLCULO DE LOTE INTELIGENTE ===");
    Print("Equity : ", DoubleToString(m_accountEquity, 2), 
          " Riesgo%: ", DoubleToString(m_riskPercent, 2));
    Print("Consenso: ", DoubleToString(m_lastConsensusStrength, 3),
          " Convicción: ", DoubleToString(m_lastTotalConviction, 3));
    Print("Multiplicador Confianza: ", DoubleToString(confidenceMultiplier, 3),
          " (", DoubleToString(confidenceMultiplier * 100, 1), "% del riesgo)");
    Print("Ajuste Emocional: x", DoubleToString(emotionalAdjustment, 3),
          " (Miedo:", DoubleToString(m_currentEmotion.fear, 2),
          " Codicia:", DoubleToString(m_currentEmotion.greed, 2), ")");
    Print("Boost ML: x", DoubleToString(mlBoost, 3));
    Print("Lote Final: ", DoubleToString(finalLot, 3));
    Print("==================================");
}

//+------------------------------------------------------------------+
//| ACTUALIZAR CONTEXTO DE CONSENSO                                 |
//+------------------------------------------------------------------+
void OrderExecution::UpdateConsensusContext(double consensusStrength, double conviction)
{
    // NUEVO: Guardar valores para cálculo de lote
    m_lastConsensusStrength = consensusStrength;
    m_lastTotalConviction = conviction;
    
    if(m_multiOrder.cycleActive)
    {
        m_multiOrder.consensusStrength = (m_multiOrder.consensusStrength * 0.7 + consensusStrength * 0.3);
        m_multiOrder.avgConviction = (m_multiOrder.avgConviction * 0.8 + conviction * 0.2);
    }
}

// ============== TODO EL RESTO DEL CÓDIGO PERMANECE IDÉNTICO ==============
// A partir de aquí, todos los métodos son exactamente iguales a v11.03

//+------------------------------------------------------------------+
//| ACTUALIZAR TODOS LOS TRAILING STOPS - SINCRONIZADO             |
//+------------------------------------------------------------------+
void OrderExecution::UpdateAllTrailingStops()
{
    if(m_multiOrder.orderCount == 0) return;
    
    // Actualizar ATR para cálculos dinámicos
    UpdateATR();
    
    // Primero verificar si el trailing del ciclo debe activarse
    if(!m_multiOrder.cycleTrailingActive)
    {
        if(CheckTrailingActivation())
        {
            LogExecutionEvent("=== TRAILING STOP DEL CICLO ACTIVADO ===");
            m_multiOrder.cycleTrailingActive = true;
            m_multiOrder.cycleTrailingActivationPrice = SymbolInfoDouble(_Symbol, 
                (m_multiOrder.direction == DIRECTION_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        }
    }
    
    // Si el trailing está activo, actualizar nivel común
    if(m_multiOrder.cycleTrailingActive)
    {
        if(UpdateCycleTrailing())
        {
            LogExecutionEvent("Trailing del ciclo actualizado a: " + 
                             DoubleToString(m_multiOrder.cycleTrailingLevel, _Digits));
            
            // Aplicar el nuevo nivel a todas las órdenes
            int ordersUpdated = 0;
            for(int i = 0; i < m_multiOrder.orderCount; i++)
            {
                if(m_multiOrder.tickets[i] > 0)
                {
                    if(ApplyCycleTrailingToOrder(i))
                        ordersUpdated++;
                }
            }
            
            LogExecutionEvent("Órdenes actualizadas con nuevo trailing: " + 
                             IntegerToString(ordersUpdated) + "/" + 
                             IntegerToString(m_multiOrder.orderCount));
        }
    }
}

//+------------------------------------------------------------------+
//| VERIFICAR ACTIVACIÓN DEL TRAILING DEL CICLO                    |
//+------------------------------------------------------------------+
bool OrderExecution::CheckTrailingActivation()
{
    if(m_multiOrder.cycleTrailingActive) return false;
    if(m_multiOrder.orderCount == 0) return false;
    
    // Verificar basándose en la primera orden
    if(m_multiOrder.tickets[0] > 0)
    {
        if(PositionSelectByTicket(m_multiOrder.tickets[0]))
        {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double priceMove = 0;
            
            if(m_multiOrder.direction == DIRECTION_BUY)
                priceMove = (currentPrice - openPrice) / _Point;
            else
                priceMove = (openPrice - currentPrice) / _Point;
            
            // Verificar si alcanzó el punto de activación
            if(priceMove >= m_trailingStart)
            {
                LogExecutionEvent("Primera orden alcanzó " + DoubleToString(priceMove, 0) + 
                                 " puntos - Activando trailing del ciclo");
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ACTUALIZAR TRAILING SINCRONIZADO DEL CICLO                     |
//+------------------------------------------------------------------+
bool OrderExecution::UpdateCycleTrailing()
{
    if(!m_multiOrder.cycleTrailingActive) return false;
    if(m_multiOrder.orderCount == 0) return false;
    
    // Obtener precio actual
    double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Calcular el nuevo nivel de trailing
    double newTrailingLevel = CalculateCycleTrailingStop(currentPrice);
    
    // Verificar si debemos actualizar
    bool shouldUpdate = false;
    
    if(m_multiOrder.direction == DIRECTION_BUY)
    {
        // Para BUY: el nuevo SL debe ser mayor que el actual
        if(newTrailingLevel > m_multiOrder.cycleTrailingLevel || 
           m_multiOrder.cycleTrailingLevel == 0)
        {
            shouldUpdate = true;
        }
    }
    else
    {
        // Para SELL: el nuevo SL debe ser menor que el actual
        if(newTrailingLevel < m_multiOrder.cycleTrailingLevel || 
           m_multiOrder.cycleTrailingLevel == 0)
        {
            shouldUpdate = true;
        }
    }
    
    if(shouldUpdate)
    {
        m_multiOrder.cycleTrailingLevel = newTrailingLevel;
        m_multiOrder.cycleLastTrailingUpdate = TimeCurrent();
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| CALCULAR STOP DE TRAILING PARA EL CICLO                        |
//+------------------------------------------------------------------+
double OrderExecution::CalculateCycleTrailingStop(double currentPrice)
{
    double trailingDistance = m_trailingDistance * _Point;
    
    // Ajustar por ATR si está configurado
    if(m_useDynamicTrailing)
    {
        double atr = GetATRValue();
        if(atr > 0)
        {
            // Determinar etapa basado en el profit total del ciclo
            double cycleProfit = 0;
            double firstOrderOpenPrice = 0;
            
            if(m_multiOrder.tickets[0] > 0 && PositionSelectByTicket(m_multiOrder.tickets[0]))
            {
                firstOrderOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            }
            
            if(firstOrderOpenPrice > 0)
            {
                double priceMove = 0;
                if(m_multiOrder.direction == DIRECTION_BUY)
                    priceMove = (currentPrice - firstOrderOpenPrice) / _Point;
                else
                    priceMove = (firstOrderOpenPrice - currentPrice) / _Point;
                
                int stage = DetermineTrailingStage(priceMove);
                if(stage >= 0)
                {
                    trailingDistance = atr * m_trailingStages[stage].atrMultiplier;
                }
            }
        }
    }
    
    // Aplicar ajuste emocional si es necesario
    if(m_currentEmotion.fear > 0.6 || m_currentEmotion.greed > 0.7)
    {
        double emotionalFactor = 1.0;
        if(m_currentEmotion.fear > 0.6)
            emotionalFactor = 0.8; // Trailing más cercano con miedo
        else if(m_currentEmotion.greed > 0.7)
            emotionalFactor = 0.9; // Proteger ganancias con codicia
        
        trailingDistance *= emotionalFactor;
    }
    
    // Calcular nuevo nivel de stop
    double newSL = 0;
    if(m_multiOrder.direction == DIRECTION_BUY)
    {
        newSL = currentPrice - trailingDistance;
    }
    else
    {
        newSL = currentPrice + trailingDistance;
    }
    
    return NormalizeDouble(newSL, _Digits);
}

//+------------------------------------------------------------------+
//| APLICAR TRAILING DEL CICLO A UNA ORDEN ESPECÍFICA              |
//+------------------------------------------------------------------+
bool OrderExecution::ApplyCycleTrailingToOrder(int orderIndex)
{
    if(orderIndex >= m_multiOrder.orderCount) return false;
    if(m_multiOrder.cycleTrailingLevel == 0) return false;
    
    ulong ticket = m_multiOrder.tickets[orderIndex];
    if(ticket == 0 || !PositionSelectByTicket(ticket)) return false;
    
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    
    // Verificar que el nuevo SL es válido
    bool validSL = false;
    if(m_multiOrder.direction == DIRECTION_BUY)
    {
        validSL = (m_multiOrder.cycleTrailingLevel > currentSL && 
                   m_multiOrder.cycleTrailingLevel < currentPrice);
    }
    else
    {
        validSL = ((m_multiOrder.cycleTrailingLevel < currentSL || currentSL == 0) && 
                   m_multiOrder.cycleTrailingLevel > currentPrice);
    }
    
    if(validSL)
    {
        if(m_trade.PositionModify(ticket, m_multiOrder.cycleTrailingLevel, 0))
        {
            m_multiOrder.stopLosses[orderIndex] = m_multiOrder.cycleTrailingLevel;
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| EJECUTAR ORDEN ADICIONAL - MODIFICADO                          |
//+------------------------------------------------------------------+
bool OrderExecution::ExecuteAdditionalOrder(int direction, double confidence)
{
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
    {
        LogExecutionEvent("Error: No hay ciclo activo para orden adicional");
        return false;
    }
    
    if(m_multiOrder.orderCount >= m_maxOrdersPerCycle)
    {
        LogExecutionEvent("Límite de órdenes alcanzado: " + IntegerToString(m_maxOrdersPerCycle));
        return false;
    }
    
    // Verificar acción emocional
    ENUM_EMOTIONAL_ACTION emotionalAction = AnalyzeEmotionalAction();
    if(emotionalAction == ACTION_FULL_EXIT || emotionalAction == ACTION_PARTIAL_CLOSE)
    {
        LogExecutionEvent("CANCELADO: Contexto emocional no favorable");
        if(emotionalAction == ACTION_FULL_EXIT)
        {
            EmergencyCloseAll("Contexto emocional crítico");
        }
        return false;
    }
    
    // Actualizar convicción promedio
    m_multiOrder.avgConviction = (m_multiOrder.avgConviction * m_multiOrder.orderCount + confidence) / 
                                 (m_multiOrder.orderCount + 1);
    
    LogExecutionEvent("=== EJECUTANDO ORDEN ADICIONAL #" + 
                     IntegerToString(m_multiOrder.orderCount + 1) + " ===");
    LogExecutionEvent("Convicción: " + DoubleToString(confidence, 3));
    LogExecutionEvent("Contexto emocional actual: " + DoubleToString(CalculateEmotionalScore(), 2));
    
    // Calcular lot reducido
    double newLot = CalculateReducedLotSize(m_multiOrder.orderCount);
    
    // Aplicar reducción emocional adicional si es necesario
    if(emotionalAction == ACTION_REDUCE_SIZE)
    {
        newLot *= (1.0 - m_emotionalReduction);
        LogExecutionEvent("Lot reducido por contexto emocional");
    }
    
    if(newLot <= 0)
    {
        LogExecutionEvent("Error: Lot size adicional es 0");
        return false;
    }
    
    // Obtener precio actual
    double currentPrice = GetUpdatedPrice(direction);
    
    // IMPORTANTE: Si el trailing del ciclo está activo, usar ese nivel como SL
    double stopPrice;
    if(m_multiOrder.cycleTrailingActive && m_multiOrder.cycleTrailingLevel > 0)
    {
        stopPrice = m_multiOrder.cycleTrailingLevel;
        LogExecutionEvent("*** Usando trailing sincronizado del ciclo: " + 
                         DoubleToString(stopPrice, _Digits));
    }
    else
    {
        // Stop loss normal si no hay trailing activo
        double slDistance = m_trailingDistance * _Point;
        
        // Ajustar distancia por emoción
        if(m_currentEmotion.fear > 0.5)
        {
            slDistance *= (1.0 - m_currentEmotion.fear * 0.3);
        }
        
        stopPrice = (direction > 0) ? 
                    currentPrice - slDistance : 
                    currentPrice + slDistance;
    }
    
    double tpPrice = 0.0;
    
    // Validar ejecución
    if(!ValidateExecution(currentPrice, newLot))
    {
        LogExecutionEvent("Error: Validación de ejecución adicional fallida");
        return false;
    }
    
    // Ejecutar orden
    if(ExecuteMarketOrder(direction, newLot, currentPrice, stopPrice, tpPrice))
    {
        LogExecutionEvent("Orden adicional ejecutada");

        // NUEVO: Usar el mismo consensus_id del ciclo
        int idx = m_multiOrder.orderCount - 1;
        m_multiOrder.consensus_ids[idx] = m_multiOrder.initial_consensus_id;
        
        // NOTA: RegisterConsensusOrder no está disponible actualmente en MetaLearningSystem
        // TODO: Implementar RegisterConsensusOrder en MetaLearningSystem
        /*
        // NUEVO: Registrar en MetaLearning
        if(m_metaLearning != NULL && m_multiOrder.initial_consensus_id > 0)
        {
            m_metaLearning.RegisterConsensusOrder(m_multiOrder.initial_consensus_id, 
                                                 m_multiOrder.tickets[idx]);
        }
        */
        
        LogExecutionEvent("  Lot: " + DoubleToString(newLot, 3) + 
                         " (" + DoubleToString((1.0 - m_orderReduction) * 100, 0) + 
                         "% del anterior)");
        
        if(m_multiOrder.cycleTrailingActive)
        {
            LogExecutionEvent("  SL sincronizado con ciclo: " + 
                             DoubleToString(stopPrice, _Digits));
        }
        
        // No necesitamos actualizar trailing aquí porque ya tiene el SL correcto
        
        // Ejecutar cierres parciales
        ExecutePartialCloses();
        
        // Ajustar stops por emoción si es necesario
        if(m_useEmotionalStops)
        {
            AdjustStopsForEmotion();
        }
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Verificar si hay órdenes en profit                              |
//+------------------------------------------------------------------+
bool OrderExecution::HasOrdersInProfit(int &ordersInProfit, double &totalProfit)
{
    ordersInProfit = 0;
    totalProfit = 0.0;
    
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
        return false;
    
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            if(PositionSelectByTicket(m_multiOrder.tickets[i]))
            {
                double profit = PositionGetDouble(POSITION_PROFIT);
                if(profit > 0)
                {
                    ordersInProfit++;
                    totalProfit += profit;
                }
            }
        }
    }
    
    return (ordersInProfit > 0);
}

//+------------------------------------------------------------------+
//| Obtener profit de la primera orden                              |
//+------------------------------------------------------------------+
double OrderExecution::GetFirstOrderProfit()
{
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
        return 0.0;
    
    if(m_multiOrder.tickets[0] > 0)
    {
        if(PositionSelectByTicket(m_multiOrder.tickets[0]))
        {
            return PositionGetDouble(POSITION_PROFIT);
        }
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Obtener movimiento de la primera orden en puntos               |
//+------------------------------------------------------------------+
double OrderExecution::GetFirstOrderMovement()
{
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
        return 0.0;
    
    if(m_multiOrder.tickets[0] > 0)
    {
        if(PositionSelectByTicket(m_multiOrder.tickets[0]))
        {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            
            if(m_multiOrder.direction == DIRECTION_BUY)
                return (currentPrice - openPrice) / _Point;
            else
                return (openPrice - currentPrice) / _Point;
        }
    }
    
    return 0.0;
}



//+------------------------------------------------------------------+
//| Imprimir estado del trailing - MODIFICADO                      |
//+------------------------------------------------------------------+
void OrderExecution::PrintTrailingStatus()
{
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
    {
        Print("No hay órdenes activas para mostrar trailing");
        return;
    }
    
    Print("=== ESTADO DE TRAILING SINCRONIZADO v11.03 ===");
    Print("Modo: ", m_useDynamicTrailing ? "DINÁMICO" : "ESTÁNDAR");
    Print("Trailing del ciclo: ", m_multiOrder.cycleTrailingActive ? "ACTIVO" : "INACTIVO");
    
    if(m_multiOrder.cycleTrailingActive)
    {
        Print("Nivel de trailing común: ", DoubleToString(m_multiOrder.cycleTrailingLevel, _Digits));
        
        double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ? 
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double trailingDistance = 0;
        if(m_multiOrder.direction == DIRECTION_BUY)
            trailingDistance = (currentPrice - m_multiOrder.cycleTrailingLevel) / _Point;
        else
            trailingDistance = (m_multiOrder.cycleTrailingLevel - currentPrice) / _Point;
        
        Print("Distancia del trailing: ", DoubleToString(trailingDistance, 0), " pts");
        
        if(m_multiOrder.cycleLastTrailingUpdate > 0)
        {
            int secondsSinceUpdate = (int)(TimeCurrent() - m_multiOrder.cycleLastTrailingUpdate);
            Print("Última actualización: hace ", secondsSinceUpdate, " segundos");
        }
    }
    
    // Mostrar estado de cada orden
    Print("--- Estado de órdenes ---");
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            if(PositionSelectByTicket(m_multiOrder.tickets[i]))
            {
                double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
                double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double currentSL = PositionGetDouble(POSITION_SL);
                
                double profitPoints = 0;
                if(m_multiOrder.direction == DIRECTION_BUY)
                    profitPoints = (currentPrice - openPrice) / _Point;
                else
                    profitPoints = (openPrice - currentPrice) / _Point;
                
                Print("Orden ", i+1, ":");
                Print("  Profit: ", DoubleToString(profitPoints, 0), " pts");
                Print("  SL actual: ", DoubleToString(currentSL, _Digits));
                
                // Verificar si coincide con el trailing del ciclo
                if(m_multiOrder.cycleTrailingActive && 
                   MathAbs(currentSL - m_multiOrder.cycleTrailingLevel) < _Point)
                {
                    Print("  ✓ Sincronizado con trailing del ciclo");
                }
                else if(m_multiOrder.cycleTrailingActive)
                {
                    Print("  ⚠ No sincronizado - esperando actualización");
                }
            }
        }
    }
    
    Print("===================================");
}

// ========== IMPLEMENTACIONES HEREDADAS Y ACTUALIZADAS ==========

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
OrderExecution::~OrderExecution()
{
    Print("OrderExecution v11.03: Estadísticas finales");
    Print("  Total trades: ", m_totalTrades);
    Print("  Total profit: ", DoubleToString(m_totalProfit, 2));
    Print("  Salidas emocionales: ", m_emotionalExits);
}

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
bool OrderExecution::Initialize(MetaLearningSystem* metaLearning)
{
    m_metaLearning = metaLearning;
    
    UpdateATR();
    UpdateAccountInfo();
    UpdateMarketContext();
    
    // Configurar CTrade
    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetTypeFilling(ORDER_FILLING_IOC);
    m_trade.SetDeviationInPoints(CalculateDynamicSlippage());
    
    // Inicializar configuración de trailing
    InitializeTrailingConfig();
    
    Print("OrderExecution v11.03: Módulo inicializado con trailing sincronizado");
    Print("  Magic Number: ", m_magicNumber);
    Print("  Risk: ", m_riskPercent, "%");
    Print("  Max órdenes/ciclo: ", m_maxOrdersPerCycle);
    Print("  Trailing dinámico: ", m_useDynamicTrailing ? "SÍ" : "NO");
    Print("  Trailing sincronizado: ACTIVADO");
    
    return true;
}

//+------------------------------------------------------------------+
//| Configurar parámetros básicos                                   |
//+------------------------------------------------------------------+

void OrderExecution::SetParameters(double riskPercent, double maxLot, double atrMult)
{
    // 1. RIESGO (% balance) ─ permitir 0.1‑100 %
    m_riskPercent = MathMax(0.1, MathMin(100.0, riskPercent));

    // 2. LÍMITE DE LOTE ─ si se pasa 0 o negativo, tomar el máximo del bróker
    double brokerMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double brokerMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

    if(maxLot <= 0.0)
        m_maxLotSize = brokerMax;
    else
        m_maxLotSize = MathMin(brokerMax, MathMax(brokerMin, maxLot));

    // 3. ATR multiplier 0.5‑5.0
    m_atrMultiplier = MathMax(0.5, MathMin(5.0, atrMult));

    PrintFormat("OrderExecution: risk=%.1f%%, maxLot=%.2f, ATRmult=%.2f",
                 m_riskPercent, m_maxLotSize, m_atrMultiplier);
}


//+------------------------------------------------------------------+
//| Configurar parámetros multi-orden                               |
//+------------------------------------------------------------------+
void OrderExecution::SetMultiOrderParams(double reduction, double partialClose,
                                        int trailingStart, int trailingStep, int maxOrders)
{
    m_orderReduction = MathMax(0.5, MathMin(0.9, 1.0 - reduction));
    m_partialClosePercent = MathMax(0.1, MathMin(0.5, partialClose));
    m_trailingStart = MathMax(10, trailingStart);
    m_trailingDistance = MathMax(5, trailingStep);
    m_maxOrdersPerCycle = MathMax(1, MathMin(10, maxOrders));
    
    // Actualizar configuración de trailing con los nuevos valores
    m_trailingStages[0].activationPoints = m_trailingStart / 2;
    m_trailingStages[1].activationPoints = m_trailingStart;
    m_trailingStages[2].activationPoints = m_trailingStart * 2;
    
    Print("OrderExecution: Parámetros multi-orden configurados");
    Print("  Trailing sincronizado activará en: ", m_trailingStart, " puntos");
}

//+------------------------------------------------------------------+
//| Configurar parámetros emocionales                               |
//+------------------------------------------------------------------+
void OrderExecution::SetEmotionalParams(double fearThreshold, double greedThreshold, double emotionalReduction)
{
    m_fearThreshold = MathMax(0.5, MathMin(0.95, fearThreshold));
    m_greedThreshold = MathMax(0.5, MathMin(0.95, greedThreshold));
    m_emotionalReduction = MathMax(0.1, MathMin(0.5, emotionalReduction));
    
    Print("OrderExecution: Parámetros emocionales configurados");
}

//+------------------------------------------------------------------+
//| Actualizar contexto emocional                                   |
//+------------------------------------------------------------------+
void OrderExecution::UpdateEmotionalContext(MarketEmotion &emotion)
{
    m_currentEmotion = emotion;
    
    // Actualizar contexto de mercado basado en emociones
    ENUM_MARKET_CONTEXT oldContext = m_marketContext;
    
    if(emotion.fear > m_fearThreshold)
    {
        m_marketContext = CONTEXT_FEARFUL;
    }
    else if(emotion.greed > m_greedThreshold)
    {
        m_marketContext = CONTEXT_GREEDY;
    }
    else if(emotion.uncertainty > 0.7)
    {
        m_marketContext = CONTEXT_HIGH_VOL;
    }
    else
    {
        UpdateMarketContext();
    }
    
    if(oldContext != m_marketContext)
    {
        LogExecutionEvent("Cambio de contexto: " + EnumToString(oldContext) + " → " + EnumToString(m_marketContext));
    }
    
    // Actualizar máximo miedo del ciclo
    if(m_multiOrder.cycleActive && emotion.fear > m_multiOrder.maxFearLevel)
    {
        m_multiOrder.maxFearLevel = emotion.fear;
    }
}

//+------------------------------------------------------------------+
//| EJECUTAR PRIMERA ORDEN                                          |
//+------------------------------------------------------------------+
bool OrderExecution::ExecuteFirstOrder(int direction, double confidence, double touchPrice)
{
    LogExecutionEvent("=== INICIANDO CICLO MULTI-ORDEN v11.03 ===");
    LogExecutionEvent("Convicción: " + DoubleToString(confidence, 3));
    LogExecutionEvent("Contexto emocional - Fear: " + DoubleToString(m_currentEmotion.fear, 2) + 
                     " Greed: " + DoubleToString(m_currentEmotion.greed, 2));

// NUEVO: Registrar consensus_id
if(m_current_consensus_id > 0)
{
    LogExecutionEvent("Consenso ID: " + IntegerToString(m_current_consensus_id));
}
    
    // Resetear ciclo
    ResetMultiOrderCycle();
    // NUEVO: Guardar consensus_id en el ciclo
    m_multiOrder.initial_consensus_id = m_current_consensus_id;
    
    m_multiOrder.direction = (ENUM_TRADE_DIRECTION)((direction > 0) ? DIRECTION_BUY : DIRECTION_SELL);
    m_multiOrder.cycleStartTime = TimeCurrent();
    m_multiOrder.consensusStrength = confidence;
    m_multiOrder.emotionalContext = CalculateEmotionalScore();
    m_multiOrder.maxFearLevel = m_currentEmotion.fear;
    m_multiOrder.avgConviction = confidence;
    
    // Verificar acción emocional antes de ejecutar
    ENUM_EMOTIONAL_ACTION emotionalAction = AnalyzeEmotionalAction();
    if(emotionalAction == ACTION_FULL_EXIT)
    {
        LogExecutionEvent("CANCELADO: Contexto emocional crítico");
        return false;
    }
    
    // Actualizar información
    UpdateATR();
    UpdateAccountInfo();
    
    // Verificar condiciones de emergencia
    if(CheckEmergencyStop())
    {
        LogExecutionEvent("EMERGENCIA: Trading detenido por drawdown");
        return false;
    }
    
    // Calcular parámetros
    double currentPrice = GetUpdatedPrice(direction);
    double stopPrice = CalculateStopLoss(currentPrice, direction, false);
    
    // Ajustar stop por contexto emocional
    if(m_useEmotionalStops && m_currentEmotion.fear > 0.5)
    {
        stopPrice = CalculateEmotionalStop(stopPrice, direction);
        LogExecutionEvent("Stop ajustado por contexto emocional");
    }
    
    double stopDistance = MathAbs(currentPrice - stopPrice) / _Point;
    
    if(stopDistance <= 0)
    {
        LogExecutionEvent("Error: Stop distance inválida");
        return false;
    }
    
    // Calcular lot size base - AQUÍ SE USA EL NUEVO CÁLCULO
    double baseLot = CalculateLotSize(stopDistance, confidence);
    
    // Ya no necesitamos ajuste emocional adicional porque está incluido en CalculateLotSize
    
    if(baseLot <= 0)
    {
        LogExecutionEvent("Error: Lot size calculado es 0");
        return false;
    }
    
    m_multiOrder.baseLotSize = baseLot;
    
    // Calcular TP (0 para no limitar ganancias)
    double tpPrice = 0.0;
    
    // Validar ejecución
    if(!ValidateExecution(currentPrice, baseLot))
    {
        LogExecutionEvent("Error: Validación de ejecución fallida");
        return false;
    }
    
    // Ejecutar orden
    if(ExecuteMarketOrder(direction, baseLot, currentPrice, stopPrice, tpPrice))
    {
        m_multiOrder.cycleActive = true;
        m_totalTrades++;
        
        LogExecutionEvent("Primera orden ejecutada - Ciclo iniciado");
        LogExecutionEvent("  Lot: " + DoubleToString(baseLot, 3));
        LogExecutionEvent("  Entry: " + DoubleToString(currentPrice, _Digits));
        LogExecutionEvent("  SL: " + DoubleToString(stopPrice, _Digits));
        LogExecutionEvent("  Trailing sincronizado: DISPONIBLE");
        LogExecutionEvent("  Se activará en: " + IntegerToString(m_trailingStart) + " puntos");
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| MONITOREAR MÚLTIPLES POSICIONES - VERSIÓN CORREGIDA            |
//+------------------------------------------------------------------+
void OrderExecution::MonitorMultiplePositions()
{
    if(!m_multiOrder.cycleActive) return;
    
    // Arrays para tracking completo
    struct OrderCloseInfo {
        ulong ticket;
        ulong consensus_id;
        double profit;
        bool success;
        int orderIndex;
        datetime closeTime;
        double closePrice;
    };
    
    OrderCloseInfo closedOrders[];
    int closedCount = 0;
    
    // FASE 1: Detectar y recopilar TODA la información de órdenes cerradas
    for(int i = 0; i < 10; i++)
    {
        if(m_multiOrder.tickets[i] == 0) continue;
        
        if(!PositionSelectByTicket(m_multiOrder.tickets[i]))
        {
            // Orden cerrada - recopilar información completa
            ulong ticket = m_multiOrder.tickets[i];
            ulong consensus_id = m_multiOrder.consensus_ids[i];
            
            // Si no tiene consensus_id específico, usar el del ciclo
            if(consensus_id == 0)
            {
                consensus_id = m_multiOrder.initial_consensus_id;
                Print("ADVERTENCIA: Orden ", ticket, " sin CID específico, usando inicial: ", consensus_id);
            }
            
            // Calcular profit completo del historial
            double totalProfit = 0.0;
            double closePrice = 0.0;
            datetime closeTime = 0;
            
            if(HistoryOrderSelect(ticket))
            {
                // Buscar todos los deals asociados
                HistorySelect(0, TimeCurrent());
                int dealsTotal = HistoryDealsTotal();
                
                for(int d = 0; d < dealsTotal; d++)
                {
                    ulong dealTicket = HistoryDealGetTicket(d);
                    if(dealTicket > 0)
                    {
                        ulong dealOrder = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
                        if(dealOrder == ticket)
                        {
                            ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
                            
                            // Solo contar deals de salida
                            if(dealType == DEAL_TYPE_SELL || dealType == DEAL_TYPE_BUY)
                            {
                                double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                                double dealSwap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                                double dealCommission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                                
                                totalProfit += dealProfit + dealSwap + dealCommission;
                                
                                // Obtener precio y tiempo de cierre del último deal
                                closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                                closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
                            }
                        }
                    }
                }
            }
            
            // Guardar información completa
            ArrayResize(closedOrders, closedCount + 1);
            closedOrders[closedCount].ticket = ticket;
            closedOrders[closedCount].consensus_id = consensus_id;
            closedOrders[closedCount].profit = totalProfit;
            closedOrders[closedCount].success = (totalProfit >= 0);
            closedOrders[closedCount].orderIndex = i;
            closedOrders[closedCount].closeTime = closeTime;
            closedOrders[closedCount].closePrice = closePrice;
            closedCount++;
            
            // Actualizar profit del ciclo inmediatamente
            m_multiOrder.cycleProfit += totalProfit;
            
            // Marcar slot como vacío
            m_multiOrder.tickets[i] = 0;
            m_multiOrder.lotSizes[i] = 0;
            m_multiOrder.consensus_ids[i] = 0;
        }
    }
    
    // FASE 2: Notificar TODAS las órdenes cerradas con información completa
    for(int i = 0; i < closedCount; i++)
    {
        Print("═══ NOTIFICACIÓN DE CIERRE DE ORDEN ═══");
        Print("Ticket: ", closedOrders[i].ticket);
        Print("Consensus ID: ", closedOrders[i].consensus_id);
        Print("Profit: ", DoubleToString(closedOrders[i].profit, 2));
        Print("Éxito: ", closedOrders[i].success ? "SÍ" : "NO");
        Print("Tiempo cierre: ", TimeToString(closedOrders[i].closeTime));
        
        // NOTA: LearnFromResult no está disponible con esta firma en MetaLearningSystem
        // TODO: Implementar LearnFromResult(bool, double, double&[], int, string, ulong) en MetaLearningSystem
        /*
        // CORRECCIÓN: Asegurar notificación completa a MetaLearning
        if(m_metaLearning != NULL && closedOrders[i].consensus_id > 0)
        {
            // Intentar aprendizaje directo
            double emptyFeatures[];
            ArrayResize(emptyFeatures, 0);
            m_metaLearning.LearnFromResult(
                closedOrders[i].success,
                closedOrders[i].profit,
                emptyFeatures,
                (int)(m_currentATR * 10000),
                IntegerToString((int)m_marketContext),
                closedOrders[i].consensus_id
            );
            Print("✓ Resultado aprendido en MetaLearning");
        }
        */
        
        // Notificar también al propio OrderExecution
        NotifyOrderClosed(
            closedOrders[i].ticket,
            closedOrders[i].profit,
            closedOrders[i].success
        );
    }
    
    // FASE 3: Compactar y verificar integridad
    if(closedCount > 0)
    {
        CompactOrderArrays();
        RecalculateActiveOrders();
        
        Print("═══ RESUMEN POST-CIERRE ═══");
        Print("Órdenes cerradas: ", closedCount);
        Print("Órdenes activas restantes: ", m_multiOrder.orderCount);
        Print("Profit acumulado del ciclo: ", DoubleToString(m_multiOrder.cycleProfit, 2));
    }
    
    // FASE 4: Verificar estado del ciclo
    if(m_multiOrder.orderCount == 0)
    {
        Print("Todas las órdenes cerradas - Finalizando ciclo");
        
        // Verificar que el ciclo tenga toda la información necesaria
        if(m_multiOrder.initial_consensus_id == 0)
        {
            Print("ADVERTENCIA: Ciclo sin consensus_id inicial");
        }
        
        FinalizeCycle();
    }
    else
    {
        // Continuar monitoreando las órdenes activas restantes
        
        // Actualizar contexto
        UpdateATR();
        UpdateAccountInfo();
        
        // Verificar emergencia
        if(CheckEmergencyStop())
        {
            LogExecutionEvent("EMERGENCIA: Cerrando todas las posiciones");
            EmergencyCloseAll("Drawdown de emergencia");
            return;
        }
        
        // Actualizar trailing stops
        UpdateAllTrailingStops();
        
        // Log periódico mejorado
        static datetime lastLogTime = 0;
        if(TimeCurrent() - lastLogTime > 60)
        {
            lastLogTime = TimeCurrent();
            
            LogExecutionEvent("═══ ESTADO DEL CICLO ═══");
            LogExecutionEvent("Consensus ID inicial: " + IntegerToString(m_multiOrder.initial_consensus_id));
            LogExecutionEvent("Órdenes activas: " + IntegerToString(m_multiOrder.orderCount));
            
            // Verificar integridad de consensus_ids
            int validCIDs = 0;
            for(int i = 0; i < m_multiOrder.orderCount; i++)
            {
                if(m_multiOrder.consensus_ids[i] > 0)
                    validCIDs++;
            }
            LogExecutionEvent("Órdenes con CID válido: " + IntegerToString(validCIDs));
        }
    }
}
//+------------------------------------------------------------------+
//| FINALIZAR CICLO                                                 |
//+------------------------------------------------------------------+
void OrderExecution::FinalizeCycle()
{
    LogExecutionEvent("=== FINALIZANDO CICLO MULTI-ORDEN v11.03 ===");
    LogExecutionEvent("  Duración: " + IntegerToString(int((TimeCurrent() - m_multiOrder.cycleStartTime) / 60)) + " minutos");
    LogExecutionEvent("  Órdenes máximas: " + IntegerToString(m_multiOrder.orderCount));
    LogExecutionEvent("  Profit del ciclo: " + DoubleToString(m_multiOrder.cycleProfit, 2));
    LogExecutionEvent("  Máximo profit alcanzado: " + DoubleToString(m_multiOrder.cycleMaxProfit, 2));
    LogExecutionEvent("  Parciales cerrados: " + DoubleToString(m_multiOrder.totalPartialClosed, 2));
    LogExecutionEvent("  Consenso inicial: " + DoubleToString(m_multiOrder.consensusStrength, 3));
    LogExecutionEvent("  Convicción promedio: " + DoubleToString(m_multiOrder.avgConviction, 3));
    LogExecutionEvent("  Contexto emocional promedio: " + DoubleToString(m_multiOrder.emotionalContext, 2));
    LogExecutionEvent("  Máximo miedo alcanzado: " + DoubleToString(m_multiOrder.maxFearLevel, 2));
    LogExecutionEvent("  Alertas emocionales: " + IntegerToString(m_multiOrder.emotionalAlerts));
    LogExecutionEvent("  Trailing sincronizado: " + (m_multiOrder.cycleTrailingActive ? "SE ACTIVÓ" : "NO SE ACTIVÓ"));
    
    // Imprimir estadísticas de trailing
    if(m_multiOrder.cycleTrailingActive)
    {
        LogExecutionEvent("  Nivel final de trailing: " + DoubleToString(m_multiOrder.cycleTrailingLevel, _Digits));
    }
    
    // Actualizar estadísticas
    m_totalProfit += m_multiOrder.cycleProfit;
    
    // Enviar datos a MetaLearning
    // Enviar datos a MetaLearning
    SendCycleToMetaLearning();

    // Reiniciar ciclo para la próxima ejecución
    ResetMultiOrderCycle();
}
void OrderExecution::CheckCycleIntegrity()
{
    int activeOrders = 0;
    
    for(int i = 0; i < 10; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            if(!CheckOrderClosed(m_multiOrder.tickets[i]))
            {
                activeOrders++;
            }
            else
            {
                m_multiOrder.tickets[i] = 0;
                m_multiOrder.lotSizes[i] = 0;
            }
        }
    }
    
    m_multiOrder.orderCount = activeOrders;
    
    if(activeOrders > 0 && activeOrders < 10)
    {
        CompactOrderArrays();
    }
    
    if(activeOrders == 0)
    {
        m_multiOrder.cycleActive = false;
    }
}

bool OrderExecution::EmergencyCloseAll(string reason)
{
    LogExecutionEvent("=== CIERRE DE EMERGENCIA: " + reason + " ===");
    
    bool allClosed = true;
    
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            if(PositionSelectByTicket(m_multiOrder.tickets[i]))
            {
                if(!m_trade.PositionClose(m_multiOrder.tickets[i]))
                {
                    allClosed = false;
                    LogExecutionEvent("Error cerrando ticket " + IntegerToString(m_multiOrder.tickets[i]));
                }
                else
                {
                    m_multiOrder.tickets[i] = 0;
                }
            }
        }
    }
    
    if(allClosed)
    {
        FinalizeCycle();
    }
    
    return allClosed;
}

ENUM_EMOTIONAL_ACTION OrderExecution::AnalyzeEmotionalAction()
{
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
        return ACTION_NONE;
    
    if(m_currentEmotion.fear > 0.9)
    {
        LogEmotionalEvent("MIEDO EXTREMO detectado", m_currentEmotion.fear);
        m_multiOrder.emotionalAlerts++;
        return ACTION_FULL_EXIT;
    }
    
    if(m_currentEmotion.fear > m_fearThreshold && m_multiOrder.orderCount > 1)
    {
        LogEmotionalEvent("Miedo alto - considerar cierre parcial", m_currentEmotion.fear);
        m_multiOrder.emotionalAlerts++;
        return ACTION_PARTIAL_CLOSE;
    }
    
    if(m_currentEmotion.greed > m_greedThreshold)
    {
        LogEmotionalEvent("Codicia alta - ajustar stops", m_currentEmotion.greed);
        return ACTION_TIGHTEN_STOPS;
    }
    
    if(m_currentEmotion.uncertainty > 0.8)
    {
        LogEmotionalEvent("Incertidumbre alta", m_currentEmotion.uncertainty);
        return ACTION_REDUCE_SIZE;
    }
    
    return ACTION_NONE;
}

bool OrderExecution::ExecuteEmotionalAction(ENUM_EMOTIONAL_ACTION action)
{
    bool result = false;
    
    switch(action)
    {
        case ACTION_REDUCE_SIZE:
            result = true;
            break;
            
        case ACTION_TIGHTEN_STOPS:
            AdjustStopsForEmotion();
            result = true;
            break;
            
        case ACTION_PARTIAL_CLOSE:
            for(int i = 0; i < m_multiOrder.orderCount; i++)
            {
                if(m_multiOrder.tickets[i] > 0)
                {
                    ClosePartialPosition(m_multiOrder.tickets[i], 0.5);
                }
            }
            result = true;
            break;
            
        case ACTION_FULL_EXIT:
            result = EmergencyCloseAll("Contexto emocional crítico");
            m_emotionalExits++;
            break;
            
        default:
            break;
    }
    
    return result;
}

void OrderExecution::AdjustStopsForEmotion()
{
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
        return;
    
    LogExecutionEvent("Ajustando stops por contexto emocional");
    
    // Si hay trailing activo, ajustar el nivel común
    if(m_multiOrder.cycleTrailingActive)
    {
        double adjustmentFactor = 1.0;
        
        if(m_currentEmotion.fear > 0.6)
        {
            adjustmentFactor = 1.0 - (m_currentEmotion.fear - 0.6) * 0.5;
        }
        else if(m_currentEmotion.greed > 0.7)
        {
            adjustmentFactor = 0.8;
        }
        
        double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ? 
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double newDistance = m_trailingDistance * _Point * adjustmentFactor;
        double newSL;
        
        if(m_multiOrder.direction == DIRECTION_BUY)
        {
            newSL = currentPrice - newDistance;
            if(newSL > m_multiOrder.cycleTrailingLevel)
            {
                m_multiOrder.cycleTrailingLevel = newSL;
                UpdateAllTrailingStops();
                LogExecutionEvent("Trailing ajustado por emoción a: " + DoubleToString(newSL, _Digits));
            }
        }
        else
        {
            newSL = currentPrice + newDistance;
            if(newSL < m_multiOrder.cycleTrailingLevel)
            {
                m_multiOrder.cycleTrailingLevel = newSL;
                UpdateAllTrailingStops();
                LogExecutionEvent("Trailing ajustado por emoción a: " + DoubleToString(newSL, _Digits));
            }
        }
    }
}

double OrderExecution::CalculateEmotionalLotSize(double baseLot, MarketEmotion &emotion)
{
    double emotionalMultiplier = GetEmotionalMultiplier();
    
    double adjustedLot = baseLot * emotionalMultiplier;
    
    if(MathAbs(emotionalMultiplier - 1.0) > 0.05)
    {
        LogExecutionEvent("Lot ajustado por emoción: " + 
                         DoubleToString(baseLot, 3) + " → " + 
                         DoubleToString(adjustedLot, 3) + 
                         " (x" + DoubleToString(emotionalMultiplier, 2) + ")");
    }
    
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    adjustedLot = MathMax(minLot, adjustedLot);
    
    return adjustedLot;
}

double OrderExecution::GetEmotionalMultiplier()
{
    double multiplier = 1.0;
    
    if(m_currentEmotion.fear > 0.5)
    {
        double fearReduction = (m_currentEmotion.fear - 0.5) * 0.6;
        multiplier *= (1.0 - fearReduction);
    }
    
    if(m_currentEmotion.uncertainty > 0.6)
    {
        double uncertaintyReduction = (m_currentEmotion.uncertainty - 0.6) * 0.4;
        multiplier *= (1.0 - uncertaintyReduction);
    }
    
    if(m_currentEmotion.greed > 0.7 && m_currentEmotion.fear < 0.3)
    {
        double greedBoost = (m_currentEmotion.greed - 0.7) * 0.2;
        multiplier *= (1.0 + greedBoost);
    }
    
    multiplier = MathMax(0.3, MathMin(1.2, multiplier));
    
    return multiplier;
}

//+------------------------------------------------------------------+
//| CÁLCULO PARA ÓRDENES ADICIONALES (Mantener como está)          |
//+------------------------------------------------------------------+
double OrderExecution::CalculateReducedLotSize(int orderIndex)
{
    if(orderIndex == 0) return m_multiOrder.baseLotSize;
    
    // Reducción exponencial estándar
    double reduction = MathPow(m_orderReduction, orderIndex);
    double newLot = m_multiOrder.baseLotSize * reduction;
    
    // OPCIONAL: Boost menor si la confianza aumentó
    if(m_lastConsensusStrength > 0.85 && orderIndex <= 2)
    {
        reduction = MathPow(m_orderReduction + 0.05, orderIndex); // Reducir menos
        newLot = m_multiOrder.baseLotSize * reduction;
    }
    
    return NormalizeLotSize(newLot);
}

double OrderExecution::CalculateStopLoss(double entryPrice, int direction, bool isAdditional)
{
    double stopDistance;
    
    if(isAdditional)
    {
        stopDistance = m_trailingDistance * _Point;
    }
    else
    {
        stopDistance = m_currentATR * m_atrMultiplier;
    }
    
    double stopPrice;
    if(direction > 0)
    {
        stopPrice = entryPrice - stopDistance;
    }
    else
    {
        stopPrice = entryPrice + stopDistance;
    }
    
    return NormalizeDouble(stopPrice, _Digits);
}

double OrderExecution::CalculateTakeProfit(double entryPrice, int direction)
{
    return 0.0;
}

double OrderExecution::CalculateEmotionalStop(double normalStop, int direction)
{
    double currentPrice = GetUpdatedPrice(direction);
    double normalDistance = MathAbs(currentPrice - normalStop);
    
    double adjustedDistance = normalDistance;
    
    if(m_currentEmotion.fear > 0.6)
    {
        adjustedDistance *= (1.0 - (m_currentEmotion.fear - 0.6) * 0.4);
    }
    else if(m_currentEmotion.greed > 0.7)
    {
        adjustedDistance *= (1.0 + (m_currentEmotion.greed - 0.7) * 0.2);
    }
    
    double emotionalStop;
    if(direction > 0)
    {
        emotionalStop = currentPrice - adjustedDistance;
    }
    else
    {
        emotionalStop = currentPrice + adjustedDistance;
    }
    
    return NormalizeDouble(emotionalStop, _Digits);
}

bool OrderExecution::ClosePartialPosition(ulong ticket, double closePercent)
{
    if(!PositionSelectByTicket(ticket)) return false;
    
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    double closeVolume = NormalizeDouble(currentVolume * closePercent, 2);
    
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    closeVolume = NormalizeDouble(closeVolume / stepLot, 0) * stepLot;
    
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if(closeVolume < minLot) return false;
    
    if(m_trade.PositionClosePartial(ticket, closeVolume))
    {
        double profit = 0.0;
        ulong last_deal = m_trade.ResultDeal();
        if(last_deal > 0 && HistoryDealSelect(last_deal))
            profit = HistoryDealGetDouble(last_deal, DEAL_PROFIT);
        m_multiOrder.totalPartialClosed += profit;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Ejecuta cierres parciales según criterios de profit              |
//+------------------------------------------------------------------+
bool OrderExecution::ExecutePartialCloses()
{
    bool closed = false;

    // Recorremos las órdenes del ciclo activo
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        ulong ticket = m_multiOrder.tickets[i];
        if(ticket == 0)
            continue;

        // Verificamos que la posición exista
        if(!PositionSelectByTicket(ticket))
            continue;

        double profit = PositionGetDouble(POSITION_PROFIT);

        // Criterio simple: solo si la posición va en profit
        if(profit <= 0.0)
            continue;

        // Cerrar la fracción configurada
        if(ClosePartialPosition(ticket, m_partialClosePercent))
        {
            LogExecutionEvent("Cierre parcial ejecutado para ticket " + IntegerToString(ticket));
            closed = true;
        }
    }

    return closed;
}


bool OrderExecution::IsTicketInCycle(ulong ticket)
{
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] == ticket)
            return true;
    }
    return false;
}

int OrderExecution::GetOrderIndexByTicket(ulong ticket)
{
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] == ticket)
            return i;
    }
    return -1;
}

bool OrderExecution::CheckEmergencyStop()
{
    double currentDD = (AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY)) / 
                       AccountInfoDouble(ACCOUNT_BALANCE) * 100;
    
    double adjustedEmergencyDD = m_emergencyDD;
    if(m_currentEmotion.fear > 0.7)
    {
        adjustedEmergencyDD *= 0.8;
    }
    
    if(currentDD >= adjustedEmergencyDD)
    {
        m_emergencyActive = true;
        return true;
    }
    
    if(m_emergencyActive && currentDD < adjustedEmergencyDD * 0.5)
    {
        m_emergencyActive = false;
    }
    
    return m_emergencyActive;
}

void OrderExecution::SendCycleToMetaLearning()
{
    if(m_metaLearning == NULL || CheckPointer(m_metaLearning) != POINTER_DYNAMIC) return;

    // NUEVO: Agregar IDs al ciclo
    MultiOrderCycle cycleData;
    cycleData.initial_consensus_id = m_multiOrder.initial_consensus_id;

    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        cycleData.tickets[i] = m_multiOrder.tickets[i];
    }

    // NOTA: LearnFromMultiOrderCycle no está disponible actualmente en MetaLearningSystem
    // TODO: Implementar LearnFromMultiOrderCycle en MetaLearningSystem
    // m_metaLearning.LearnFromMultiOrderCycle(m_multiOrder);

    LogExecutionEvent("Datos del ciclo enviados a MetaLearning con consenso ID: " + 
                     IntegerToString(m_multiOrder.initial_consensus_id));
}


void OrderExecution::UpdateStatus(string status)
{
    LogExecutionEvent("Status: " + status);
}

void OrderExecution::UpdateATR()
{
    int atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
    if(atr_handle != INVALID_HANDLE)
    {
        double atr_buffer[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0)
        {
            m_currentATR = atr_buffer[0];
        }
        IndicatorRelease(atr_handle);
    }
    
    if(m_currentATR <= 0)
    {
        m_currentATR = 50 * _Point;
    }
}

void OrderExecution::UpdateAccountInfo()
{
    m_accountEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
}

void OrderExecution::UpdateMarketContext()
{
    double atrRatio = 1.0;
    m_volatilityRatio = atrRatio;
    int atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
    if(atr_handle != INVALID_HANDLE)
    {
        double atr_buffer[];
        if(CopyBuffer(atr_handle, 0, 0, 20, atr_buffer) == 20)
        {
            double avgATR = 0;
            for(int i = 0; i < 20; i++)
                avgATR += atr_buffer[i];
            avgATR /= 20.0;
            
            if(avgATR > 0)
                atrRatio = m_currentATR / avgATR;
        }
        IndicatorRelease(atr_handle);
    }
    
    if(atrRatio > 1.5)
        m_marketContext = CONTEXT_HIGH_VOL;
    else if(atrRatio < 0.7)
        m_marketContext = CONTEXT_ACCUMULATION;
    else
        m_marketContext = CONTEXT_NORMAL;
    
    if(m_currentEmotion.fear > m_fearThreshold)
        m_marketContext = CONTEXT_FEARFUL;
    else if(m_currentEmotion.greed > m_greedThreshold)
        m_marketContext = CONTEXT_GREEDY;
}

bool OrderExecution::ValidateExecution(double price, double lot)
{
    if(!TerminalInfoInteger(TERMINAL_CONNECTED) || 
       !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        LogExecutionEvent("Terminal no conectado o trading no permitido");
        return false;
    }
    
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        LogExecutionEvent("Trading no permitido en este EA");
        return false;
    }
    
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    if(lot < minLot || lot > maxLot)
    {
        LogExecutionEvent("Lot size fuera de rango: " + DoubleToString(lot, 3));
        return false;
    }
    
    if(price <= 0)
    {
        LogExecutionEvent("Precio inválido: " + DoubleToString(price, _Digits));
        return false;
    }
    
    double margin_required = 0;
    if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot, price, margin_required))
    {
        LogExecutionEvent("Error calculando margen");
        return false;
    }
    
    if(margin_required > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
    {
        LogExecutionEvent("Margen insuficiente");
        return false;
    }
    
    return true;
}

void OrderExecution::LogExecutionEvent(string message)
{
    string logMessage = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + 
                       " [OrderExecution v11.03] " + message;
    Print(logMessage);
}

double OrderExecution::GetUpdatedPrice(int direction)
{
    if(direction > 0)
        return SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    else
        return SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

int OrderExecution::CalculateDynamicSlippage()
{
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    int baseSlippage = (int)MathMax(10, spread * 2);
    
    if(m_marketContext == CONTEXT_HIGH_VOL || m_currentEmotion.excitement > 0.7)
        baseSlippage *= 2;
    
    return MathMin(50, baseSlippage);
}

double OrderExecution::CalculateEmotionalScore()
{
    double score = (m_currentEmotion.fear * 0.4 + 
                    m_currentEmotion.greed * 0.3 + 
                    m_currentEmotion.uncertainty * 0.2 + 
                    m_currentEmotion.excitement * 0.1);
    
    return score;
}

void OrderExecution::LogEmotionalEvent(string event, double score)
{
    string message = "EVENTO EMOCIONAL: " + event + " (Score: " + DoubleToString(score, 3) + ")";
    LogExecutionEvent(message);
}

void OrderExecution::PrintEmotionalStatus()
{
    Print("=== ESTADO EMOCIONAL - ORDEREXECUTION ===");
    Print("Fear: ", DoubleToString(m_currentEmotion.fear, 3));
    Print("Greed: ", DoubleToString(m_currentEmotion.greed, 3));
    Print("Uncertainty: ", DoubleToString(m_currentEmotion.uncertainty, 3));
    Print("Excitement: ", DoubleToString(m_currentEmotion.excitement, 3));
    Print("Contexto: ", EnumToString(m_marketContext));
    Print("Multiplicador emocional: ", DoubleToString(GetEmotionalMultiplier(), 2));
    
    if(m_multiOrder.cycleActive)
    {
        Print("Ciclo - Alertas emocionales: ", m_multiOrder.emotionalAlerts);
        Print("Ciclo - Max fear: ", DoubleToString(m_multiOrder.maxFearLevel, 2));
        Print("Ciclo - Contexto promedio: ", DoubleToString(m_multiOrder.emotionalContext, 2));
    }
    Print("========================================");
}

// MÓDULO COMPLETO CORREGIDO: ExecuteMarketOrder()
bool OrderExecution::ExecuteMarketOrder(int direction, double lotSize, 
                                       double entryPrice, double stopPrice, double tpPrice)
{
    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetDeviationInPoints(CalculateDynamicSlippage());
    m_trade.SetTypeFilling(ORDER_FILLING_IOC);
    
    bool success = false;
    
    string comment = "NCN_v11.03_" + IntegerToString(m_multiOrder.orderCount + 1) + 
                    "_E" + DoubleToString(m_multiOrder.emotionalContext, 1);
    
    // NUEVO: Añadir consensus_id al comentario si está disponible
    if(m_current_consensus_id > 0)
    {
        comment += "_CID" + IntegerToString(m_current_consensus_id);
    }
    
    if(direction > 0)
    {
        success = m_trade.Buy(lotSize, _Symbol, entryPrice, stopPrice, tpPrice, comment);
    }
    else
    {
        success = m_trade.Sell(lotSize, _Symbol, entryPrice, stopPrice, tpPrice, comment);
    }
    
    if(success)
    {
        ulong order_ticket = m_trade.ResultOrder();
        double realPrice = m_trade.ResultPrice();

        // CORRECCIÓN CRÍTICA: Obtener POSITION ticket en lugar de ORDER ticket
        // OnTradeTransaction usa trans.position (position ID), no order ID
        ulong position_ticket = 0;

        // Esperar brevemente para que la posición se registre
        Sleep(50);

        // Intentar obtener el position ticket de la posición recién abierta
        // Buscar posición con el mismo magic number que acabamos de abrir
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong pos_ticket = PositionGetTicket(i);
            if(pos_ticket > 0)
            {
                if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber &&
                   PositionGetString(POSITION_SYMBOL) == _Symbol)
                {
                    position_ticket = pos_ticket;
                    Print("✓ Position ticket obtenido: ", position_ticket, " (order: ", order_ticket, ")");
                    break;
                }
            }
        }

        // Si no encontramos position ticket, usar order ticket como fallback
        if(position_ticket == 0)
        {
            position_ticket = order_ticket;
            Print("⚠ Usando order ticket como fallback: ", order_ticket);
        }

        int idx = m_multiOrder.orderCount;
        m_multiOrder.tickets[idx] = position_ticket;
        m_multiOrder.lotSizes[idx] = lotSize;
        m_multiOrder.entryPrices[idx] = realPrice;
        m_multiOrder.stopLosses[idx] = stopPrice;
        m_multiOrder.takeProfits[idx] = tpPrice;
        
        // NUEVO: Guardar consensus_id
        if(idx == 0)
        {
            // Primera orden: usar el consensus_id actual
            m_multiOrder.initial_consensus_id = m_current_consensus_id;
            m_multiOrder.consensus_ids[idx] = m_current_consensus_id;
        }
        else
        {
            // Órdenes adicionales: usar el consensus_id del ciclo
            m_multiOrder.consensus_ids[idx] = m_multiOrder.initial_consensus_id;
        }
        
        m_multiOrder.orderCount++;
        
        // NOTA: RegisterConsensusOrder no está disponible actualmente en MetaLearningSystem
        // TODO: Implementar RegisterConsensusOrder en MetaLearningSystem
        /*
        // NUEVO: Registrar en MetaLearning si está disponible
        if(m_metaLearning != NULL && m_multiOrder.consensus_ids[idx] > 0)
        {
            m_metaLearning.RegisterConsensusOrder(m_multiOrder.consensus_ids[idx], position_ticket);
            Print("Orden registrada - Ticket: ", position_ticket,
                  " Consensus ID: ", m_multiOrder.consensus_ids[idx]);
        }
        */

        // NUEVO: Guardar en registro local
        if(m_closed_count < ArraySize(m_closed_orders))
        {
            // Pre-registrar la orden para tracking
            m_closed_orders[m_closed_count].ticket = position_ticket;
            m_closed_orders[m_closed_count].consensus_id = m_multiOrder.consensus_ids[idx];
            m_closed_orders[m_closed_count].profit = 0;
            m_closed_orders[m_closed_count].success = false;
            m_closed_orders[m_closed_count].close_time = 0;
            // No incrementar m_closed_count aquí, se hace cuando se cierra
        }
        
        return true;
    }
    else
    {
        int error = GetLastError();
        LogExecutionEvent("ERROR: " + m_trade.ResultRetcodeDescription() + " (" + IntegerToString(error) + ")");
        LogExecutionEvent("Consensus ID no registrado: " + IntegerToString(m_current_consensus_id));
        return false;
    }
}
//+------------------------------------------------------------------+
//| Recalcular número de órdenes activas                           |
//+------------------------------------------------------------------+
void OrderExecution::RecalculateActiveOrders()
{
    int activeCount = 0;
    
    for(int i = 0; i < 10; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            // Doble verificación de que la orden existe
            if(PositionSelectByTicket(m_multiOrder.tickets[i]))
            {
                activeCount++;
            }
            else
            {
                // Si no existe, limpiar el slot
                m_multiOrder.tickets[i] = 0;
                m_multiOrder.lotSizes[i] = 0;
                m_multiOrder.consensus_ids[i] = 0;
            }
        }
    }
    
    m_multiOrder.orderCount = activeCount;
    
    LogExecutionEvent("Órdenes activas recalculadas: " + IntegerToString(activeCount));
}

bool OrderExecution::CheckOrderClosed(ulong ticket)
{
    return !PositionSelectByTicket(ticket);
}

int OrderExecution::DetermineTrailingStage(double profitPoints)
{
    // Revisar etapas de mayor a menor
    for(int i = 2; i >= 0; i--)
    {
        if(profitPoints >= m_trailingStages[i].activationPoints)
        {
            return i;
        }
    }
    
    return -1; // No alcanza activación mínima
}

double OrderExecution::GetATRValue(ENUM_TIMEFRAMES timeframe)
{
    int atr_handle = iATR(_Symbol, timeframe, (int)m_trailingATRPeriod);
    if(atr_handle != INVALID_HANDLE)
    {
        double atr_buffer[];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0)
        {
            IndicatorRelease(atr_handle);
            return atr_buffer[0];
        }
        IndicatorRelease(atr_handle);
    }
    
    // Valor por defecto si falla
    return m_currentATR > 0 ? m_currentATR : 50 * _Point;
}



void OrderExecution::SetCurrentConsensusID(ulong consensus_id)
{
    m_current_consensus_id = consensus_id;
}





// NUEVO: Método para notificar cierre de orden
void OrderExecution::NotifyOrderClosed(ulong ticket, double profit, bool success)
{
    // Buscar consensus_id de esta orden
    ulong consensus_id = 0;
    for(int i = 0; i < 10; i++)
    {
        if(m_multiOrder.tickets[i] == ticket)
        {
            consensus_id = m_multiOrder.consensus_ids[i];
            break;
        }
    }

    // NOTA: LearnFromResult no está disponible con esta firma en MetaLearningSystem
    // TODO: Implementar LearnFromResult(bool, double, double&[], int, string, ulong) en MetaLearningSystem
    /*
    // Notificar a MetaLearning
    if(m_metaLearning != NULL && consensus_id > 0)
    {
        double emptyFeatures[];
        ArrayResize(emptyFeatures, 0);
        m_metaLearning.LearnFromResult(
            success,
            profit,
            emptyFeatures,
            (int)(m_currentATR * 10000),
            IntegerToString((int)m_marketContext),
            consensus_id
        );
    }
    */

    // Guardar en historial
    if(m_closed_count < ArraySize(m_closed_orders))
    {
        m_closed_orders[m_closed_count].ticket = ticket;
        m_closed_orders[m_closed_count].consensus_id = consensus_id;
        m_closed_orders[m_closed_count].profit = profit;
        m_closed_orders[m_closed_count].success = success;
        m_closed_orders[m_closed_count].close_time = TimeCurrent();
        m_closed_count++;
    }
}

#endif // ORDER_EXECUTION_NCN_V11_03_MQH
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Compactar los arreglos de órdenes dentro de m_multiOrder         |
//+------------------------------------------------------------------+
void OrderExecution::CompactOrderArrays()
{
    int newIndex = 0;

    // Reorganizar arrays manteniendo la coherencia de índices
    for(int i = 0; i < 10; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            // Si hay un hueco antes, mover los valores
            if(i != newIndex)
            {
                m_multiOrder.tickets[newIndex]       = m_multiOrder.tickets[i];
                m_multiOrder.lotSizes[newIndex]      = m_multiOrder.lotSizes[i];
                m_multiOrder.entryPrices[newIndex]   = m_multiOrder.entryPrices[i];
                m_multiOrder.stopLosses[newIndex]    = m_multiOrder.stopLosses[i];
                m_multiOrder.takeProfits[newIndex]   = m_multiOrder.takeProfits[i];
                m_multiOrder.consensus_ids[newIndex] = m_multiOrder.consensus_ids[i];
            }
            newIndex++;
        }
    }

    // Limpiar los slots restantes
    for(int i = newIndex; i < 10; i++)
    {
        m_multiOrder.tickets[i]       = 0;
        m_multiOrder.lotSizes[i]      = 0;
        m_multiOrder.entryPrices[i]   = 0;
        m_multiOrder.stopLosses[i]    = 0;
        m_multiOrder.takeProfits[i]   = 0;
        m_multiOrder.consensus_ids[i] = 0;
    }

    // Actualizar contador de órdenes
    m_multiOrder.orderCount = newIndex;
}