//+------------------------------------------------------------------+
//|                                       RegimeDetectionSystem.mqh  |
//|                          Sistema de Detección de Regímenes v1.0  |
//+------------------------------------------------------------------+
#ifndef REGIME_DETECTION_SYSTEM_MQH
#define REGIME_DETECTION_SYSTEM_MQH

#property copyright "Regime Detection System v1.0"
#property version   "1.00"

// Forward declarations
class EpisodicMemorySystem;
class MetaLearningSystem;

//+------------------------------------------------------------------+
//| Enumeración de tipos de régimen                                 |
//+------------------------------------------------------------------+
#ifndef __ENUM_MARKET_REGIME_DEFINED__
#define __ENUM_MARKET_REGIME_DEFINED__
enum ENUM_MARKET_REGIME
{
    REGIME_TRENDING_UP,      // Tendencia alcista fuerte
    REGIME_TRENDING_DOWN,    // Tendencia bajista fuerte
    REGIME_RANGING,          // Mercado lateral
    REGIME_VOLATILE,         // Alta volatilidad sin dirección
    REGIME_BREAKOUT,         // Rompimientos frecuentes
    REGIME_CRISIS,           // Condiciones de crisis/pánico
    REGIME_LOW_LIQUIDITY,    // Baja liquidez (Asia, etc)
    REGIME_TRANSITION        // Transición entre regímenes
};
#endif // __ENUM_MARKET_REGIME_DEFINED__

#ifndef ENUM_MARKET_REGIME_DEFINED
#define ENUM_MARKET_REGIME_DEFINED
#endif

//+------------------------------------------------------------------+
//| Estructura de métricas de régimen                               |
//+------------------------------------------------------------------+
struct RegimeMetrics
{
    double trendStrength;        // -1 a 1 (bajista a alcista)
    double volatility;           // 0 a N (normalizada ATR)
    double momentumConsistency;  // 0 a 1 (qué tan consistente es la dirección)
    double volumeProfile;        // 0 a N (volumen vs promedio)
    double priceEfficiency;      // 0 a 1 (movimiento direccional vs ruido)
    double fearGreedIndex;       // 0 a 1
    datetime lastUpdate;
    
    // NUEVAS métricas
    double volatilityExpansion;  // Ratio de expansión/contracción
    double momentumAcceleration; // Aceleración del momentum
    double volumeAnomaly;        // Detección de anomalías de volumen
    double marketNoise;          // Nivel de ruido del mercado
    double microstructureQuality;// Calidad de microestructura
    double correlationChange;    // Cambio en correlaciones
    double fractalComplexity;    // Dimensión fractal
    int currentSession;          // Sesión de trading actual
    double sessionTransition;    // Score de transición de sesión

    double avg_volatility;
    double trend_strength;
    double correlation_change;
    double consensus_quality;
    datetime last_update;
    bool    regime_changed;      // true si ha cambiado el régimen
    double  emotional_stability; // 0 a 1, 1 = estable
};

//+------------------------------------------------------------------+
//| Estructura de parámetros por régimen                            |
//+------------------------------------------------------------------+
struct RegimeParameters
{
    // Parámetros de riesgo
    double riskPercent;
    double maxOrdersPerCycle;
    double partialClosePercent;
    
    // Parámetros de entrada
    double minConsensusStrength;
    double minTotalConviction;
    bool requireStrongConsensus;
    
    // Parámetros SR
    double srSensitivityMultiplier;
    int minAccumulationBars;
    
    // Parámetros de filtro
    bool allowCounterTrend;
    bool requireVolumeConfirmation;
    double maxEmotionalThreshold;
    
    // Pesos de agentes para este régimen
    double agentWeights[5];
};

//+------------------------------------------------------------------+
//| Estructura de historial de régimen                              |
//+------------------------------------------------------------------+
struct RegimeHistory
{
    ENUM_MARKET_REGIME regime;
    datetime startTime;
    datetime endTime;
    int tradesExecuted;
    double totalProfit;
    double maxDrawdown;
    double winRate;
    RegimeMetrics avgMetrics;
    RegimeParameters optimalParams;
};

//+------------------------------------------------------------------+
//| Clase principal de detección de regímenes                       |
//+------------------------------------------------------------------+
class RegimeDetectionSystem
{
private:
    // Estado actual
    ENUM_MARKET_REGIME m_currentRegime;
    ENUM_MARKET_REGIME m_previousRegime;
    RegimeMetrics m_currentMetrics;
    datetime m_regimeStartTime;
    int m_barsInRegime;
    
    // Historial
    RegimeHistory m_history[];
    int m_historyCount;
    
    // Parámetros optimizados por régimen
    RegimeParameters m_parameters[8]; // Para cada ENUM_MARKET_REGIME
    
    // Referencias
    EpisodicMemorySystem* m_episodicMemory;
    MetaLearningSystem* m_metaLearning;
    
    // Configuración
    int m_lookbackPeriod;
    double m_transitionThreshold;
    
public:
    // Constructor
    RegimeDetectionSystem()
    {
        m_currentRegime = REGIME_RANGING;
        m_previousRegime = REGIME_RANGING;
        m_regimeStartTime = 0;
        m_barsInRegime = 0;
        m_historyCount = 0;
        m_lookbackPeriod = 100;
        m_transitionThreshold = 0.7;
        
        ArrayResize(m_history, 1000);
        InitializeDefaultParameters();
    }
    
    // Inicialización
    bool Initialize(EpisodicMemorySystem* episodic, MetaLearningSystem* meta)
    {
        m_episodicMemory = episodic;
        m_metaLearning = meta;
        
        // Cargar historial de regímenes
        LoadRegimeHistory();
        
        // Detectar régimen inicial
        UpdateRegimeDetection();
        
        Print("RegimeDetectionSystem: Inicializado");
        Print("Régimen inicial detectado: ", EnumToString(m_currentRegime));
        
        return true;
    }
    
    // Actualizar detección de régimen
    void UpdateRegimeDetection()
    {
        // Calcular métricas actuales
        CalculateCurrentMetrics();
        
        // Determinar régimen basado en métricas
        ENUM_MARKET_REGIME detectedRegime = ClassifyRegime(m_currentMetrics);
        
        // Verificar si hay cambio de régimen
        if(detectedRegime != m_currentRegime)
        {
            double confidence = CalculateRegimeConfidence(detectedRegime);
            
            if(confidence > m_transitionThreshold)
            {
                // Cambio de régimen confirmado
                OnRegimeChange(m_currentRegime, detectedRegime);
                m_previousRegime = m_currentRegime;
                m_currentRegime = detectedRegime;
                m_regimeStartTime = TimeCurrent();
                m_barsInRegime = 0;
            }
        }
        else
        {
            m_barsInRegime++;
        }
    }
    
    // Obtener régimen actual
    ENUM_MARKET_REGIME GetCurrentRegime() const { return m_currentRegime; }
    
    // Obtener parámetros para el régimen actual
    RegimeParameters GetCurrentParameters() const
    {
        return m_parameters[m_currentRegime];
    }
    
    // Obtener peso de agente para régimen actual
    double GetAgentWeight(int agentIndex) const
    {
        if(agentIndex >= 0 && agentIndex < 5)
            return m_parameters[m_currentRegime].agentWeights[agentIndex];
        return 1.0;
    }
    
    // Obtener estadísticas del régimen
    bool GetRegimeStatistics(ENUM_MARKET_REGIME regime, double &winRate, 
                           double &avgProfit, int &sampleSize)
    {
        winRate = 0.0;
        avgProfit = 0.0;
        sampleSize = 0;
        
        for(int i = 0; i < m_historyCount; i++)
        {
            if(m_history[i].regime == regime)
            {
                sampleSize++;
                winRate += m_history[i].winRate;
                avgProfit += m_history[i].totalProfit;
            }
        }
        
        if(sampleSize > 0)
        {
            winRate /= sampleSize;
            avgProfit /= sampleSize;
            return true;
        }
        
        return false;
    }
    
    // NUEVO MÉTODO: Registrar resultado de trade
    void RegisterTradeResult(ulong ticket, double profit, bool isWin, 
                           datetime openTime, datetime closeTime)
    {
        // Actualizar estadísticas del régimen actual
        if(m_barsInRegime > 0)
        {
            // Buscar o crear entrada para el régimen actual
            bool found = false;
            for(int i = 0; i < m_historyCount; i++)
            {
                if(m_history[i].regime == m_currentRegime && 
                   m_history[i].endTime == 0) // Régimen activo
                {
                    m_history[i].tradesExecuted++;
                    m_history[i].totalProfit += profit;
                    
                    if(isWin)
                    {
                        double currentWinRate = m_history[i].winRate;
                        int totalTrades = m_history[i].tradesExecuted;
                        m_history[i].winRate = (currentWinRate * (totalTrades - 1) + 1.0) / totalTrades;
                    }
                    else
                    {
                        double currentWinRate = m_history[i].winRate;
                        int totalTrades = m_history[i].tradesExecuted;
                        m_history[i].winRate = (currentWinRate * (totalTrades - 1)) / totalTrades;
                    }
                    
                    if(profit < 0 && profit < m_history[i].maxDrawdown)
                        m_history[i].maxDrawdown = profit;
                    
                    found = true;
                    break;
                }
            }
            
            if(!found)
            {
                // Crear nueva entrada
                if(m_historyCount < ArraySize(m_history))
                {
                    m_history[m_historyCount].regime = m_currentRegime;
                    m_history[m_historyCount].startTime = m_regimeStartTime;
                    m_history[m_historyCount].endTime = 0; // Aún activo
                    m_history[m_historyCount].tradesExecuted = 1;
                    m_history[m_historyCount].totalProfit = profit;
                    m_history[m_historyCount].winRate = isWin ? 1.0 : 0.0;
                    m_history[m_historyCount].maxDrawdown = profit < 0 ? profit : 0;
                    m_history[m_historyCount].avgMetrics = m_currentMetrics;
                    m_historyCount++;
                }
            }
        }
        
        // NUEVO: Ajustar parámetros si el rendimiento es malo
        OptimizeCurrentRegimeParameters();
        
        Print("RDS: Resultado registrado para régimen ", EnumToString(m_currentRegime));
    }
    
private:
    //+------------------------------------------------------------------+
    //| MEJORADO: CalculateCurrentMetrics con Análisis Profundo        |
    //| RAZÓN: Detectar regímenes con mayor precisión                   |
    //+------------------------------------------------------------------+
    void CalculateCurrentMetrics()
    {
        // Arrays de datos
        double close[], high[], low[], open[];
        long volume[];
        
        ArraySetAsSeries(close, true);
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        ArraySetAsSeries(open, true);
        ArraySetAsSeries(volume, true);
        
        // NUEVO: Copiar más datos para análisis profundo
        int deepLookback = m_lookbackPeriod * 2;
        int copied = CopyClose(_Symbol, PERIOD_CURRENT, 0, deepLookback, close);
        CopyHigh(_Symbol, PERIOD_CURRENT, 0, deepLookback, high);
        CopyLow(_Symbol, PERIOD_CURRENT, 0, deepLookback, low);
        CopyOpen(_Symbol, PERIOD_CURRENT, 0, deepLookback, open);
        CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, deepLookback, volume);
        
        if(copied < deepLookback) return;
        
        // 1. MEJORADO: Calcular fuerza de tendencia con múltiples timeframes
        double trendStrength = 0.0;
        
        // Tendencia corto plazo (20 períodos)
        double shortTrend = CalculateAdaptiveTrendStrength(close, 20);
        
        // Tendencia medio plazo (50 períodos)
        double mediumTrend = CalculateAdaptiveTrendStrength(close, 50);
        
        // Tendencia largo plazo (100 períodos)
        double longTrend = CalculateAdaptiveTrendStrength(close, 100);
        
        // NUEVO: Análisis de convergencia de tendencias (continuo)
// Convergencia continua [-1..+1] basada en signos de tendencias multi-TF
double trendConvergence = 0.0;
int sameSign = 0;
sameSign += (shortTrend  > 0) ? 1 : ((shortTrend  < 0) ? -1 : 0);
sameSign += (mediumTrend > 0) ? 1 : ((mediumTrend < 0) ? -1 : 0);
sameSign += (longTrend   > 0) ? 1 : ((longTrend   < 0) ? -1 : 0);
trendConvergence = sameSign / 3.0;

// Combinar tendencias con pesos con pesos
        trendStrength = shortTrend * 0.5 + mediumTrend * 0.3 + longTrend * 0.2;
        
        // NUEVO: Ajustar por convergencia
        trendStrength *= (1.0 + MathAbs(trendConvergence) * 0.3);
        
        m_currentMetrics.trendStrength = MathTanh(trendStrength); // Normalizar a [-1, 1]
        
        // 2. MEJORADO: Calcular volatilidad con análisis multidimensional
        double currentATR = CalculateATR(high, low, close, 14);
        
        // NUEVO: Volatilidad histórica adaptativa
        double historicalVol = CalculateHistoricalVolatility(close, 20);
        double realizedVol = CalculateRealizedVolatility(high, low, close, 20);
        
        // NUEVO: Ratio de expansión/contracción de volatilidad
        double volExpansion = 0.0;
        double atrShort = CalculateATR(high, low, close, 5);
        double atrLong = CalculateATR(high, low, close, 20);
        
        if(atrLong > 0)
            volExpansion = atrShort / atrLong;
        
        // Combinar métricas de volatilidad
        m_currentMetrics.volatility = (currentATR / close[0]) * 100; // Como porcentaje del precio
        
        // NUEVO: Guardar ratio de expansión para análisis
        m_currentMetrics.volatilityExpansion = volExpansion;
        
        // 3. NUEVO: Calcular consistencia del momentum mejorada
        double momentumConsistency = CalculateMomentumConsistency(close, 20);
        
        // NUEVO: Análisis de aceleración del momentum
        double momentumAcceleration = CalculateMomentumAcceleration(close, 10);
        
        m_currentMetrics.momentumConsistency = momentumConsistency;
        m_currentMetrics.momentumAcceleration = momentumAcceleration;
        
        // 4. MEJORADO: Perfil de volumen con análisis de distribución
        double volumeProfile = CalculateVolumeProfile(volume, close, 20);
        
        // NUEVO: Detectar anomalías de volumen
        double volumeAnomaly = DetectVolumeAnomalies(volume, 50);
        
        m_currentMetrics.volumeProfile = volumeProfile;
        m_currentMetrics.volumeAnomaly = volumeAnomaly;
        
        // 5. MEJORADO: Eficiencia del precio con Kaufman adaptativo
        double priceEfficiency = CalculateAdaptivePriceEfficiency(close, 20);
        
        // NUEVO: Análisis de ruido de mercado
        double marketNoise = CalculateMarketNoise(high, low, close, 14);
        
        m_currentMetrics.priceEfficiency = priceEfficiency;
        m_currentMetrics.marketNoise = marketNoise;
        
        // 6. NUEVO: Análisis de microestructura
        double bidAskSpread = CalculateAverageSpread();
        double marketDepth = EstimateMarketDepth(volume, high, low);
        
        m_currentMetrics.microstructureQuality = (1.0 - bidAskSpread) * marketDepth;
        
        // 7. NUEVO: Fear/Greed mejorado con múltiples inputs
        double fearGreedIndex = CalculateEnhancedFearGreed(close, high, low, volume);
        
        m_currentMetrics.fearGreedIndex = fearGreedIndex;
        
        // 8. NUEVO: Análisis de correlaciones entre activos
        double correlationChange = CalculateCorrelationChange();
        
        m_currentMetrics.correlationChange = correlationChange;
        
        // 9. NUEVO: Detección de patrones fractales
        double fractalDimension = CalculateFractalDimension(close, 50);
        m_currentMetrics.fractalComplexity = fractalDimension;
        
        // 10. NUEVO: Análisis de sesiones de trading
        int currentSession = GetCurrentTradingSession();
        double sessionTransition = CalculateSessionTransitionScore();
        
        m_currentMetrics.currentSession = currentSession;
        m_currentMetrics.sessionTransition = sessionTransition;
        
        // Actualizar timestamp
        m_currentMetrics.lastUpdate = TimeCurrent();
        
        
        {
    // --- Rate limiting y log solo si cambia o cada 60s
    static datetime lastLogTime = 0;
    static double lastTrend   = EMPTY_VALUE;
    static double lastEff     = EMPTY_VALUE;
    static double lastNoise   = EMPTY_VALUE;
    static double lastVolPct  = EMPTY_VALUE;
    static double lastExpand  = EMPTY_VALUE;
    static double lastFG      = EMPTY_VALUE;
    static double lastConv    = EMPTY_VALUE;

    bool changed =
       (lastTrend   == EMPTY_VALUE) ||
       (MathAbs(m_currentMetrics.trendStrength - lastTrend)   > 0.005) ||
       (MathAbs(priceEfficiency                - lastEff)     > 0.005) ||
       (MathAbs(marketNoise                    - lastNoise)   > 0.005) ||
       (MathAbs(m_currentMetrics.volatility    - lastVolPct)  > 0.01 ) ||
       (MathAbs(volExpansion                   - lastExpand)  > 0.01 ) ||
       (MathAbs(fearGreedIndex                 - lastFG)      > 0.005) ||
       (MathAbs(trendConvergence               - lastConv)    > 0.05 ) ||
       (m_currentMetrics.regime_changed);

    if(changed || (TimeCurrent() - lastLogTime) >= 60)
    {
        lastLogTime = TimeCurrent();
        lastTrend  = m_currentMetrics.trendStrength;
        lastEff    = priceEfficiency;
        lastNoise  = marketNoise;
        lastVolPct = m_currentMetrics.volatility;
        lastExpand = volExpansion;
        lastFG     = fearGreedIndex;
        lastConv   = trendConvergence;

        string convLabel = (trendConvergence >  0.5) ? "alineadas alcistas" :
                           (trendConvergence < -0.5) ? "alineadas bajistas" :
                                                        "mixtas";

        static datetime __lastRegimePrintBar = 0;
datetime __bt = iTime(_Symbol, PERIOD_CURRENT, 0);
if(__bt != __lastRegimePrintBar)
{
    __lastRegimePrintBar = __bt;
Print("=== Métricas de Régimen ===");
        Print("Tendencia: ", DoubleToString(m_currentMetrics.trendStrength, 3),
              "  Convergencia: ", DoubleToString(trendConvergence, 2), " (", convLabel, ")");
        Print("Volatilidad: ", DoubleToString(m_currentMetrics.volatility, 2), "%  Expansión: ",
              DoubleToString(volExpansion, 2));
        Print("Eficiencia: ", DoubleToString(priceEfficiency, 3), "  Ruido: ",
              DoubleToString(marketNoise, 3));
        Print("Fear/Greed: ", DoubleToString(fearGreedIndex, 3));

        // Reset del flag de cambio de régimen tras loguear
        }
m_currentMetrics.regime_changed = false;
    }
}
    }
    
    // NUEVAS FUNCIONES AUXILIARES:
    
    //+------------------------------------------------------------------+
    //| Calcular fuerza de tendencia adaptativa                         |
    //+------------------------------------------------------------------+
    double CalculateAdaptiveTrendStrength(const double &prices[], int period)
    {
        if(period >= ArraySize(prices)) return 0.0;
        
        // Regresión lineal
        double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
        
        for(int i = 0; i < period; i++)
        {
            sumX += i;
            sumY += prices[i];
            sumXY += i * prices[i];
            sumX2 += i * i;
        }
        
        double slope = (period * sumXY - sumX * sumY) / (period * sumX2 - sumX * sumX);
        
        // Normalizar slope por ATR
        double atr = 0;
        for(int i = 1; i < period; i++)
        {
            atr += MathAbs(prices[i] - prices[i-1]);
        }
        atr /= (period - 1);
        
        if(atr > 0)
            return -slope / atr; // Negativo porque series está invertida
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular volatilidad histórica                                  |
    //+------------------------------------------------------------------+
    double CalculateHistoricalVolatility(const double &prices[], int period)
    {
        if(period >= ArraySize(prices)) return 0.0;
        
        double returns[];
        ArrayResize(returns, period - 1);
        
        // Calcular retornos logarítmicos
        for(int i = 0; i < period - 1; i++)
        {
            if(prices[i+1] > 0 && prices[i] > 0)
                returns[i] = MathLog(prices[i] / prices[i+1]);
            else
                returns[i] = 0;
        }
        
        // Calcular desviación estándar
        double mean = 0;
        for(int i = 0; i < period - 1; i++)
            mean += returns[i];
        mean /= (period - 1);
        
        double variance = 0;
        for(int i = 0; i < period - 1; i++)
            variance += MathPow(returns[i] - mean, 2);
        variance /= (period - 1);
        
        // Anualizar (asumiendo 252 días de trading)
        return MathSqrt(variance * 252);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular volatilidad realizada                                  |
    //+------------------------------------------------------------------+
    double CalculateRealizedVolatility(const double &high[], const double &low[], 
                                     const double &close[], int period)
    {
        if(period >= ArraySize(high)) return 0.0;
        
        double sum = 0.0;
        for(int i = 0; i < period; i++)
        {
            // Parkinson volatility estimator
            if(high[i] > low[i])
                sum += MathPow(MathLog(high[i] / low[i]), 2);
        }
        
        return MathSqrt(sum / (4 * period * MathLog(2)));
    }
    
    //+------------------------------------------------------------------+
    //| Calcular ATR personalizado                                      |
    //+------------------------------------------------------------------+
    double CalculateATR(const double &high[], const double &low[], 
                       const double &close[], int period)
    {
        if(period >= ArraySize(high)) return 0.0;
        
        double atr = 0.0;
        for(int i = 1; i < period; i++)
        {
            double tr = MathMax(high[i] - low[i], 
                       MathMax(MathAbs(high[i] - close[i-1]), 
                              MathAbs(low[i] - close[i-1])));
            atr += tr;
        }
        
        return atr / (period - 1);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular consistencia del momentum                              |
    //+------------------------------------------------------------------+
    double CalculateMomentumConsistency(const double &prices[], int period)
    {
        int upMoves = 0, downMoves = 0;
        double totalMove = 0, consistentMove = 0;
        
        for(int i = 1; i < period && i < ArraySize(prices); i++)
        {
            double move = prices[i-1] - prices[i];
            totalMove += MathAbs(move);
            
            if(move > 0)
            {
                upMoves++;
                if(i > 1 && prices[i] - prices[i+1] > 0)
                    consistentMove += MathAbs(move);
            }
            else
            {
                downMoves++;
                if(i > 1 && prices[i] - prices[i+1] < 0)
                    consistentMove += MathAbs(move);
            }
        }
        
        double directionality = MathAbs(upMoves - downMoves) / (double)period;
        double consistency = (totalMove > 0) ? consistentMove / totalMove : 0;
        
        return directionality * 0.5 + consistency * 0.5;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular aceleración del momentum                               |
    //+------------------------------------------------------------------+
    double CalculateMomentumAcceleration(const double &prices[], int period)
    {
        if(period >= ArraySize(prices)) return 0.0;
        
        // Calcular momentum en dos mitades del período
        double momentum1 = 0, momentum2 = 0;
        int halfPeriod = period / 2;
        
        // Primera mitad (más antigua)
        for(int i = halfPeriod; i < period; i++)
        {
            momentum1 += (prices[i-1] - prices[i]);
        }
        momentum1 /= halfPeriod;
        
        // Segunda mitad (más reciente)
        for(int i = 0; i < halfPeriod; i++)
        {
            momentum2 += (prices[i] - prices[i+1]);
        }
        momentum2 /= halfPeriod;
        
        // Aceleración = cambio en momentum
        return momentum2 - momentum1;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular perfil de volumen                                      |
    //+------------------------------------------------------------------+
    double CalculateVolumeProfile(const long &volumes[], 
                                                         const double &prices[], 
                                                         int period)
    {
        if(period >= ArraySize(volumes)) return 1.0;
        
        // Volumen ponderado por precio
        double vwap = 0, totalVolume = 0;
        
        for(int i = 0; i < period; i++)
        {
            vwap += prices[i] * (double)volumes[i];
            totalVolume += (double)volumes[i];
        }
        
        if(totalVolume > 0)
            vwap /= totalVolume;
        
        // Distribución de volumen respecto a VWAP
        double aboveVWAP = 0, belowVWAP = 0;
        
        for(int i = 0; i < period; i++)
        {
            if(prices[i] > vwap)
                aboveVWAP += (double)volumes[i];
            else
                belowVWAP += (double)volumes[i];
        }
        
        // Ratio de distribución (1 = equilibrado, >1 = más volumen arriba)
        if(belowVWAP > 0)
            return aboveVWAP / belowVWAP;
        
        return 1.0;
    }
    
    //+------------------------------------------------------------------+
    //| Detectar anomalías de volumen                                   |
    //+------------------------------------------------------------------+
    double DetectVolumeAnomalies(const long &volumes[], int period)
    {
        if(period >= ArraySize(volumes)) return 0.0;
        
        // Calcular media y desviación estándar
        double mean = 0, stdDev = 0;
        
        for(int i = 0; i < period; i++)
            mean += (double)volumes[i];
        mean /= period;
        
        for(int i = 0; i < period; i++)
            stdDev += MathPow((double)volumes[i] - mean, 2);
        stdDev = MathSqrt(stdDev / period);
        
        // Contar anomalías (volumen > 2 desviaciones estándar)
        int anomalies = 0;
        for(int i = 0; i < 10 && i < period; i++) // Últimas 10 barras
        {
            if((double)volumes[i] > mean + 2 * stdDev)
                anomalies++;
        }
        
        return (double)anomalies / 10.0; // Normalizado 0-1
    }
    
    //+------------------------------------------------------------------+
    //| Calcular eficiencia de precio adaptativa                        |
    //+------------------------------------------------------------------+
    double CalculateAdaptivePriceEfficiency(const double &prices[], int period)
    {
        if(period >= ArraySize(prices)) return 0.0;
        
        // Kaufman Efficiency Ratio
        double direction = MathAbs(prices[0] - prices[period-1]);
        double volatility = 0;
        
        for(int i = 1; i < period; i++)
            volatility += MathAbs(prices[i-1] - prices[i]);
        
        if(volatility > 0)
            return direction / volatility;
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular ruido de mercado                                       |
    //+------------------------------------------------------------------+
    double CalculateMarketNoise(const double &high[], const double &low[], 
                               const double &close[], int period)
    {
        if(period >= ArraySize(high)) return 0.0;
        
        double signal = 0, noise = 0;
        
        for(int i = 0; i < period - 1; i++)
        {
            // Señal = movimiento de cierre a cierre
            signal += MathAbs(close[i] - close[i+1]);
            
            // Ruido = rango intrabar
            noise += (high[i] - low[i]);
        }
        
        if(noise > 0)
            return 1.0 - (signal / noise); // Más ruido = valor más alto
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular spread promedio                                        |
    //+------------------------------------------------------------------+
    double CalculateAverageSpread()
    {
        // Obtener spread actual
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        
        if(point > 0)
            return (ask - bid) / point;
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Estimar profundidad de mercado                                  |
    //+------------------------------------------------------------------+
    double EstimateMarketDepth(const long &volumes[], const double &high[], 
                              const double &low[])
    {
        // Estimación basada en volumen y rango
        double avgVolume = 0;
        double avgRange = 0;
        
        int period = MathMin(20, ArraySize(volumes));
        
        for(int i = 0; i < period; i++)
        {
            avgVolume += (double)volumes[i];
            avgRange += (high[i] - low[i]);
        }
        
        avgVolume /= period;
        avgRange /= period;
        
        // Mayor volumen con menor rango = mayor profundidad
        if(avgRange > 0)
            return MathLog(avgVolume + 1) / avgRange;
        
        return 1.0;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular Fear/Greed mejorado                                    |
    //+------------------------------------------------------------------+
    double CalculateEnhancedFearGreed(const double &close[], 
                                                             const double &high[], 
                                                             const double &low[], 
                                                             const long &volume[])
    {
        double fearGreed = 0.5; // Neutral
        
        // 1. RSI
        double rsi = CalculateRSI(close, 14);
        if(rsi > 70) fearGreed += 0.15; // Greed
        else if(rsi < 30) fearGreed -= 0.15; // Fear
        
        // 2. Volatilidad vs promedio
        double currentVol = (high[0] - low[0]) / close[0];
        double avgVol = 0;
        for(int i = 1; i < 20; i++)
        {
            avgVol += (high[i] - low[i]) / close[i];
        }
        avgVol /= 19;
        
        if(currentVol > avgVol * 1.5) fearGreed -= 0.1; // Fear
        else if(currentVol < avgVol * 0.7) fearGreed += 0.1; // Greed
        
        // 3. Momentum
        double momentum = (close[0] - close[10]) / close[10];
        fearGreed += momentum * 2; // Ajustar por momentum
        
        // 4. Volumen
        double currentVol2 = (double)volume[0];
        double avgVol2 = 0;
        for(int i = 1; i < 20; i++)
            avgVol2 += (double)volume[i];
        avgVol2 /= 19;
        
        if(currentVol2 > avgVol2 * 2 && momentum < 0) fearGreed -= 0.2; // Panic selling
        else if(currentVol2 > avgVol2 * 2 && momentum > 0) fearGreed += 0.2; // FOMO buying
        
        return MathMax(0.0, MathMin(1.0, fearGreed));
    }
    
    //+------------------------------------------------------------------+
    //| Calcular RSI                                                    |
    //+------------------------------------------------------------------+
    double CalculateRSI(const double &prices[], int period)
    {
        if(period >= ArraySize(prices)) return 50.0;
        
        double gains = 0, losses = 0;
        
        for(int i = 1; i < period; i++)
        {
            double change = prices[i-1] - prices[i];
            if(change > 0)
                gains += change;
            else
                losses += MathAbs(change);
        }
        
        if(losses == 0) return 100.0;
        
        double rs = gains / losses;
        return 100.0 - (100.0 / (1.0 + rs));
    }
    
    //+------------------------------------------------------------------+
    //| Calcular cambio de correlación                                  |
    //+------------------------------------------------------------------+
    double CalculateCorrelationChange()
    {
        // Por ahora retornar valor neutral
        // En implementación completa, comparar correlaciones con otros pares
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular dimensión fractal                                      |
    //+------------------------------------------------------------------+
    double CalculateFractalDimension(const double &prices[], int period)
    {
        // Implementación simplificada del método de conteo de cajas
        double maxPrice = prices[0], minPrice = prices[0];
        
        for(int i = 1; i < period && i < ArraySize(prices); i++)
        {
            if(prices[i] > maxPrice) maxPrice = prices[i];
            if(prices[i] < minPrice) minPrice = prices[i];
        }
        
        double range = maxPrice - minPrice;
        if(range <= 0) return 1.0;
        
        // Contar "cajas" necesarias para cubrir la serie
        int boxes = 0;
        double boxSize = range / 10; // 10 niveles
        
        for(int i = 0; i < period - 1; i++)
        {
            int box1 = (int)((prices[i] - minPrice) / boxSize);
            int box2 = (int)((prices[i+1] - minPrice) / boxSize);
            if(box1 != box2) boxes++;
        }
        
        // Dimensión fractal aproximada
        return 1.0 + (MathLog(boxes) / MathLog(period));
    }
    
    //+------------------------------------------------------------------+
    //| Obtener sesión de trading actual                                |
    //+------------------------------------------------------------------+
    int GetCurrentTradingSession()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        int hour = dt.hour;
        
        if(hour >= 0 && hour < 8)
            return 0;  // Asian
        else if(hour >= 8 && hour < 13)
            return 1;  // London
        else if(hour >= 13 && hour < 17)
            return 2;  // New York
        else
            return 3;  // Overlap/Closed
    }
    
    //+------------------------------------------------------------------+
    //| Calcular score de transición de sesión                          |
    //+------------------------------------------------------------------+
    double CalculateSessionTransitionScore()
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        int hour = dt.hour;
        int minute = dt.min;
        
        // Detectar proximidad a cambio de sesión
        double score = 0.0;
        
        // Transiciones principales
        if((hour == 7 && minute > 30) || (hour == 8 && minute < 30))
            score = 1.0 - MathAbs(hour * 60 + minute - 480) / 30.0; // London open
        else if((hour == 12 && minute > 30) || (hour == 13 && minute < 30))
            score = 1.0 - MathAbs(hour * 60 + minute - 780) / 30.0; // NY open
        else if((hour == 16 && minute > 30) || (hour == 17 && minute < 30))
            score = 1.0 - MathAbs(hour * 60 + minute - 1020) / 30.0; // London close
        
        return MathMax(0.0, score);
    }
    
    // Clasificar régimen basado en métricas
    ENUM_MARKET_REGIME ClassifyRegime(const RegimeMetrics &metrics)
    {
        
    // Fast-path NCN: ADX + pendiente + eficiencia + expansión (no rompe firmas)
    double __adx = 0.0; 
    int __adx_handle = iADX(_Symbol, PERIOD_CURRENT, 14);
    if(__adx_handle != INVALID_HANDLE){
        double __adx_buf[1];
        if(CopyBuffer(__adx_handle,0,0,1,__adx_buf)>0) __adx = __adx_buf[0];
        IndicatorRelease(__adx_handle);
    }
    // Pendiente y error estándar (50)
    MqlRates __lr[50];
    double __slope=0.0, __se=0.0;
    if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, __lr) == 50){
        int __n=50; double sx=0, sy=0, sxx=0, sxy=0;
        for(int i=0;i<__n;i++){ double x=i, y=__lr[i].close; sx+=x; sy+=y; sxx+=x*x; sxy+=x*y; }
        double denom = __n*sxx - sx*sx;
        if(denom!=0){
            __slope = (__n*sxy - sx*sy)/denom;
            double se=0.0;
            for(int i=0;i<__n;i++){ double x=i, y=__lr[i].close; double yhat=((sy - __slope*sx)/__n) + __slope*x; double e=y-yhat; se+=e*e; }
            se = MathSqrt(se/(__n-2));
            __se = (sxx>0.0 ? se/MathSqrt(sxx) : 0.0);
        }
    }
    // Efficiency Ratio (20)
    MqlRates __er[21];
    double __eff = 0.0;
    if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 21, __er) == 21){
        double change = MathAbs(__er[0].close - __er[20].close);
        double sum = 0.0; for(int i=0;i<20;i++) sum += MathAbs(__er[i].close - __er[i+1].close);
        __eff = (sum>0.0 ? change/sum : 0.0);
    }
    // Expansion ratio (range/ATR)
    double __exp = 1.0;
    {
        MqlRates __ex[20]; if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 20, __ex) == 20){
            double hi=__ex[0].high, lo=__ex[0].low;
            for(int i=1;i<20;i++){ if(__ex[i].high>hi)hi=__ex[i].high; if(__ex[i].low<lo)lo=__ex[i].low; }
            int __atr_h=iATR(_Symbol, PERIOD_CURRENT, 14);
            if(__atr_h!=INVALID_HANDLE){
                double __a[20]; int c=CopyBuffer(__atr_h,0,0,20,__a); IndicatorRelease(__atr_h);
                if(c>0){
                    int n=c<20?c:20; double atrm=0.0; for(int i=0;i<n;i++) atrm+=__a[i]; atrm/= (double)n;
                    double range = hi - lo; if(atrm>0.0) __exp = range/atrm;
                }
            }
        }
    }
    if(__adx>25.0 && MathAbs(__slope) > 2.0*__se) return (__slope>0 ? REGIME_TRENDING_UP : REGIME_TRENDING_DOWN);
    if(__adx<20.0 && __eff < 0.30) return REGIME_RANGING;
    if(__exp>2.0) return REGIME_VOLATILE;
// Reglas de clasificación basadas en métricas
        
        // Crisis: Alta volatilidad + Alto miedo
        if(metrics.volatility > 2.0 && metrics.fearGreedIndex > 0.8)
            return REGIME_CRISIS;
        
        // Trending Up: Tendencia fuerte + Consistencia + Eficiencia
        if(metrics.trendStrength > 0.5 && 
           metrics.momentumConsistency > 0.7 && 
           metrics.priceEfficiency > 0.6)
            return REGIME_TRENDING_UP;
        
        // Trending Down
        if(metrics.trendStrength < -0.5 && 
           metrics.momentumConsistency > 0.7 && 
           metrics.priceEfficiency > 0.6)
            return REGIME_TRENDING_DOWN;
        
        // Volatile: Alta volatilidad + Baja eficiencia
        if(metrics.volatility > 1.5 && metrics.priceEfficiency < 0.3)
            return REGIME_VOLATILE;
        
        // Breakout: Volumen alto + Cambio de volatilidad
        if(metrics.volumeProfile > 1.5 && metrics.volatility > 1.2)
            return REGIME_BREAKOUT;
        
        // Low Liquidity: Bajo volumen
        if(metrics.volumeProfile < 0.5)
            return REGIME_LOW_LIQUIDITY;
        
        // Ranging: Por defecto
        return REGIME_RANGING;
    }
    
    // Calcular confianza en el régimen detectado
    double CalculateRegimeConfidence(ENUM_MARKET_REGIME regime)
    {
        // Buscar en episodios históricos qué tan bien coincide
        if(m_episodicMemory != NULL)
        {
            // Implementación pendiente con EpisodicMemory
            return 0.8;
        }
        
        return 0.75; // Confianza por defecto
    }
    
    // Manejar cambio de régimen
    void OnRegimeChange(ENUM_MARKET_REGIME oldRegime, ENUM_MARKET_REGIME newRegime)
    {
        Print("=== CAMBIO DE RÉGIMEN DETECTADO ===");
        Print("De: ", EnumToString(oldRegime), " → A: ", EnumToString(newRegime));
        Print("Duración del régimen anterior: ", m_barsInRegime, " barras");
        m_currentMetrics.regime_changed = true;
        
        // Guardar estadísticas del régimen que termina
        if(m_barsInRegime > 10) // Solo si duró lo suficiente
        {
            SaveRegimeHistory(oldRegime);
        }
        
        // Notificar a otros sistemas
        if(m_metaLearning != NULL)
        {
            // Por ahora solo imprimir mensaje ya que DetectRegimeChange no existe
            Print("Cambio de régimen notificado");
        }
        
        // Ajustar parámetros para el nuevo régimen
        OptimizeParametersForRegime(newRegime);
    }
    
    // Guardar historial del régimen
    void SaveRegimeHistory(ENUM_MARKET_REGIME regime)
    {
        if(m_historyCount >= ArraySize(m_history))
        {
            ArrayResize(m_history, m_historyCount + 100);
        }
        
        m_history[m_historyCount].regime = regime;
        m_history[m_historyCount].startTime = m_regimeStartTime;
        m_history[m_historyCount].endTime = TimeCurrent();
        m_history[m_historyCount].avgMetrics = m_currentMetrics;
        
        // Obtener estadísticas de MetaLearning
        if(m_metaLearning != NULL)
        {
            // Implementación pendiente
        }
        
        m_historyCount++;
        
        // Guardar a archivo
        SaveRegimeHistoryToFile();
    }
    
    // Optimizar parámetros para el régimen
    void OptimizeParametersForRegime(ENUM_MARKET_REGIME regime)
    {
        // Si tenemos historial, usar parámetros que funcionaron antes
        bool foundHistorical = false;
        
        for(int i = m_historyCount - 1; i >= 0; i--)
        {
            if(m_history[i].regime == regime && m_history[i].winRate > 0.6)
            {
                m_parameters[regime] = m_history[i].optimalParams;
                foundHistorical = true;
                Print("Usando parámetros históricos exitosos para ", EnumToString(regime));
                break;
            }
        }
        
        if(!foundHistorical)
        {
            // Usar parámetros por defecto para el régimen
            SetDefaultParametersForRegime(regime);
        }
    }
    
    // Inicializar parámetros por defecto
    void InitializeDefaultParameters()
    {
        for(int i = 0; i < 8; i++)
        {
            SetDefaultParametersForRegime((ENUM_MARKET_REGIME)i);
        }
    }
    
    // Establecer parámetros por defecto para un régimen
    void SetDefaultParametersForRegime(ENUM_MARKET_REGIME regime)
    {
        RegimeParameters params;
        
        switch(regime)
        {
            case REGIME_TRENDING_UP:
                params.riskPercent = 3.0;  // Más agresivo en tendencias
                params.maxOrdersPerCycle = 5;
                params.minConsensusStrength = 0.3;
                params.allowCounterTrend = false;
                params.agentWeights[0] = 0.8;  // SR menos importante
                params.agentWeights[1] = 1.0;  // Accumulation normal
                params.agentWeights[2] = 1.2;  // Pattern más importante
                params.agentWeights[3] = 1.5;  // Breakout muy importante
                params.agentWeights[4] = 1.3;  // Institutional importante
                break;
                
            case REGIME_TRENDING_DOWN:
                params.riskPercent = 2.5;
                params.maxOrdersPerCycle = 3;
                params.minConsensusStrength = 0.4;
                params.allowCounterTrend = false;
                params.agentWeights[0] = 1.5;  // SR muy importante
                params.agentWeights[1] = 1.2;
                params.agentWeights[2] = 1.0;
                params.agentWeights[3] = 0.8;  // Breakout menos importante
                params.agentWeights[4] = 1.3;
                break;
                
            case REGIME_RANGING:
                params.riskPercent = 2.0;
                params.maxOrdersPerCycle = 2;
                params.minConsensusStrength = 0.5;
                params.allowCounterTrend = true;
                params.agentWeights[0] = 2.0;  // SR crítico en ranging
                params.agentWeights[1] = 1.5;  // Accumulation importante
                params.agentWeights[2] = 0.8;
                params.agentWeights[3] = 0.5;  // Breakout poco confiable
                params.agentWeights[4] = 1.0;
                break;
                
            case REGIME_VOLATILE:
                params.riskPercent = 1.0;      // Muy conservador
                params.maxOrdersPerCycle = 1;
                params.minConsensusStrength = 0.7;  // Requiere consenso fuerte
                params.requireStrongConsensus = true;
                params.maxEmotionalThreshold = 0.5;  // Bajo umbral emocional
                params.agentWeights[0] = 1.0;
                params.agentWeights[1] = 0.8;
                params.agentWeights[2] = 0.8;
                params.agentWeights[3] = 0.5;
                params.agentWeights[4] = 1.5;  // Institutional para estabilidad
                break;
                
            case REGIME_CRISIS:
                params.riskPercent = 0.5;      // Mínimo riesgo
                params.maxOrdersPerCycle = 1;
                params.minConsensusStrength = 0.8;
                params.requireStrongConsensus = true;
                params.maxEmotionalThreshold = 0.3;
                // Todos los agentes con peso bajo
                for(int j = 0; j < 5; j++)
                    params.agentWeights[j] = 0.5;
                break;
                
            default:
                // Parámetros estándar
                params.riskPercent = 2.0;
                params.maxOrdersPerCycle = 3;
                params.minConsensusStrength = 0.4;
                for(int j = 0; j < 5; j++)
                    params.agentWeights[j] = 1.0;
                break;
        }
        
        // Parámetros comunes
        params.partialClosePercent = 0.2;
        params.srSensitivityMultiplier = 0.7;
        params.minAccumulationBars = (regime == REGIME_VOLATILE) ? 2 : 2;  // Reducido de 10:7 a 2:2 para permitir trades
        params.requireVolumeConfirmation = (regime == REGIME_LOW_LIQUIDITY);
        
        m_parameters[regime] = params;
    }
    
    // NUEVO: Optimizar parámetros basado en rendimiento
    void OptimizeCurrentRegimeParameters()
    {
        // Buscar estadísticas actuales
        double currentWinRate = 0.0;
        int trades = 0;
        
        for(int i = 0; i < m_historyCount; i++)
        {
            if(m_history[i].regime == m_currentRegime && m_history[i].endTime == 0)
            {
                currentWinRate = m_history[i].winRate;
                trades = m_history[i].tradesExecuted;
                break;
            }
        }
        
        // Si tenemos suficientes datos y mal rendimiento
        if(trades >= 5 && currentWinRate < 0.4)
        {
            // Hacer más conservador
            m_parameters[m_currentRegime].riskPercent *= 0.9;
            m_parameters[m_currentRegime].minConsensusStrength *= 1.1;
            m_parameters[m_currentRegime].maxOrdersPerCycle = 
                MathMax(1, m_parameters[m_currentRegime].maxOrdersPerCycle - 1);
            
            Print("RDS: Parámetros ajustados - Régimen con bajo rendimiento");
        }
        else if(trades >= 5 && currentWinRate > 0.7)
        {
            // Permitir ser más agresivo
            m_parameters[m_currentRegime].riskPercent *= 1.05;
            m_parameters[m_currentRegime].riskPercent = 
                MathMin(m_parameters[m_currentRegime].riskPercent, 5.0);
            
            Print("RDS: Parámetros ajustados - Régimen con alto rendimiento");
        }
    }
    
    // Guardar/Cargar historial
    void SaveRegimeHistoryToFile()
    {
        string filename = "RegimeHistory_" + _Symbol + ".dat";
        int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);
        
        if(handle != INVALID_HANDLE)
        {
            FileWriteInteger(handle, m_historyCount);
            
            for(int i = 0; i < m_historyCount; i++)
            {
                FileWriteInteger(handle, m_history[i].regime);
                FileWriteLong(handle, m_history[i].startTime);
                FileWriteLong(handle, m_history[i].endTime);
                FileWriteInteger(handle, m_history[i].tradesExecuted);
                FileWriteDouble(handle, m_history[i].totalProfit);
                FileWriteDouble(handle, m_history[i].maxDrawdown);
                FileWriteDouble(handle, m_history[i].winRate);
                //  /* patched */  guardar más campos según necesidad
            }
            
            FileClose(handle);
        }
    }
    
    void LoadRegimeHistory()
    {
        string filename = "RegimeHistory_" + _Symbol + ".dat";
        
        if(FileIsExist(filename))
        {
            int handle = FileOpen(filename, FILE_READ|FILE_BIN);
            
            if(handle != INVALID_HANDLE)
            {
                m_historyCount = FileReadInteger(handle);
                ArrayResize(m_history, m_historyCount + 100);
                
                for(int i = 0; i < m_historyCount; i++)
                {
                    m_history[i].regime = (ENUM_MARKET_REGIME)FileReadInteger(handle);
                    m_history[i].startTime = (datetime)FileReadLong(handle);
                    m_history[i].endTime = (datetime)FileReadLong(handle);
                    m_history[i].tradesExecuted = FileReadInteger(handle);
                    m_history[i].totalProfit = FileReadDouble(handle);
                    m_history[i].maxDrawdown = FileReadDouble(handle);
                    m_history[i].winRate = FileReadDouble(handle);
                }
                
                FileClose(handle);
                Print("RegimeHistory: Cargados ", m_historyCount, " registros históricos");
            }
        }
    }
};
#endif // REGIME_DETECTION_SYSTEM_MQH