//+------------------------------------------------------------------+
//|                                      EpisodicMemorySystem.mqh    |
//|                          Sistema de Memoria Episódica v1.0       |
//+------------------------------------------------------------------+
#ifndef EPISODIC_MEMORY_SYSTEM_MQH
#define EPISODIC_MEMORY_SYSTEM_MQH

#property copyright "Episodic Memory System v1.0"
#property version   "1.00"
#include <MetaLearningSystem.mqh>
#include <VotingStatistics.mqh>
#include <SupportResistance.mqh>
#include <PatternMemory.mqh>


//+------------------------------------------------------------------+
//| ENUM y estructuras añadidas para EM_TouchContext                |
//+------------------------------------------------------------------+
#ifndef __TOUCH_CONTEXT__
#define __TOUCH_CONTEXT__

// Tipo de toque sobre un nivel SR
enum ENUM_TOUCH_TYPE
  {
   TOUCH_UNKNOWN = 0,
   TOUCH_FIRST   = 1,   // Primer toque
   TOUCH_RETEST  = 2    // Retesteo posterior
  };

// Información de un nivel SR relacionada al toque
#ifndef __SR_LEVEL_INFO__
struct SRLevelInfo
  {
   datetime firstTouch;        // Momento del primer toque
   datetime lastTouch;         // Momento del último toque
   int      touches;           // Número de toques detectados
   double   movementStrength;  // Fuerza del movimiento tras el toque
   // Campos adicionales necesarios para compatibilidad
   double   price;             // Precio del nivel
   ENUM_SR_TYPE type;          // Tipo de nivel (soporte/resistencia)
   double   strength;          // Fuerza del nivel
   ENUM_SR_STATE state;        // Estado del nivel
   ENUM_SR_QUALITY quality;    // Calidad del nivel
  };
#endif // __SR_LEVEL_INFO__
  

// Estructura de contexto de toque que utiliza EpisodicMemorySystem
struct EM_TouchContext
  {
   bool            valid;          // Validez del contexto
   double          price;          // Precio del toque
   datetime        time;           // Hora del toque
   ENUM_TOUCH_TYPE touchType;      // Tipo de toque (primer toque, retesteo, etc)
   double          quality;        // Calidad del toque según heurística SR
   double          strength;       // Fuerza de rechazo medida
   double          levelStrength;  // Fuerza del nivel SR
   int             touchNumber;    // Contador de toques del nivel
   double          atr;            // Volatilidad (ATR) en puntos
   SRLevelInfo     level;          // Datos del nivel implicado
  };
  
  

#endif //__TOUCH_CONTEXT__


//+------------------------------------------------------------------+
//| DEFINICIÓN DE ESTRUCTURAS NECESARIAS                            |
//+------------------------------------------------------------------+
#ifndef __ACCUMULATION_CONTEXT__
#define __ACCUMULATION_CONTEXT__
struct AccumulationContext
{
    double   range;         // Price range of the accumulation (points)
    int      barCount;      // Number of bars in the accumulation zone
    datetime startTime;     // When the accumulation began
    double   centerPrice;   // Center price of accumulation
    double   highPrice;     // High of accumulation zone
    double   lowPrice;      // Low of accumulation zone
    bool     valid;         // If accumulation is valid
    datetime endTime;       // When accumulation ended
    bool     volumeConfirmation; // Volume pattern confirmed
};

#endif // __ACCUMULATION_CONTEXT__

//+------------------------------------------------------------------+
//| ConsensusMemory y NeuralConsensusResult                         |
//+------------------------------------------------------------------+
#ifndef CONSENSUS_MEMORY_STRUCT_DEFINED
#define CONSENSUS_MEMORY_STRUCT_DEFINED
struct ConsensusMemory
{
    ulong consensus_id;
    ulong associated_ticket;
    datetime timestamp;
    double consensus_strength;
    int agent_count;
    ENUM_VOTE_DIRECTION direction;
    bool was_successful;
    double emotional_score;
    double profit_result;
    int negotiation_rounds;
    string dominant_agent;
    double agreement_level;
};
#endif

#ifndef NEURAL_CONSENSUS_RESULT_STRUCT_DEFINED
#define NEURAL_CONSENSUS_RESULT_STRUCT_DEFINED
struct NeuralConsensusResult
{
    ulong consensus_id;
    ENUM_VOTE_DIRECTION final_direction;
    double total_conviction;
    double consensus_strength;
    bool strong_consensus;
    string leading_agent;
    bool veto_used;
    string consensus_reasoning;
};
#endif

//+------------------------------------------------------------------+
//| Estructura de episodio completo                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CompleteTradeRecord: Complete trade record structure            |
//+------------------------------------------------------------------+
struct CompleteTradeRecord
{
    ulong consensus_id;
    ulong order_ticket;
    datetime consensus_time;
    int consensus_direction;
    double consensus_strength;
    double total_conviction;
    string leading_agent;

    string participating_agents[5];
    double agent_votes[5];
    double agent_confidences[5];

    bool veto_used;
    double initial_volatility;
    double initial_momentum;
    double initial_fear;
    double initial_greed;
    int session_type;
    double sr_level_strength;

    datetime order_open_time;
    double order_open_price;
    double order_lot_size;
    double order_sl;
    double order_tp;
    int order_position_in_cycle;

    datetime order_close_time;
    double order_close_price;
    double order_profit;
    double order_profit_points;
    double order_profit_currency;
    bool order_success;
    int order_duration_bars;
    double max_profit_reached;
    double max_drawdown_reached;

    double max_favorable_excursion;
    double max_adverse_excursion;
    int bars_duration;
    bool was_successful;

    double agent_performance_impact[5];
    bool consensus_quality_confirmed;
    double learning_value;
};




//=== Guarded MarketPattern definition =====================================
#ifndef __MARKET_PATTERN__
#define __MARKET_PATTERN__
struct MarketPattern
{
    datetime    timestamp;
    double      volatility;
    double      momentum;
    double      volume_ratio;
    int         session_type;
    double      rsi;
    double      atr_ratio;
    double      price_position;
    int         touches;
    double      strength;
    int         pattern_type;
    int         result;
    double      profit_factor;
    int         bars_duration;
    bool        is_profitable;
    double      consensus_strength;
    double      emotional_context;
    double      agent_agreement;
    int         dissenting_agents;
    double      fear_level;
    double      greed_level;
    ulong       consensus_id;
    ulong       order_ticket;
};
#endif // __MARKET_PATTERN__
struct TradingEpisode
{
    // Contexto inicial
    ulong episodeId;
    datetime startTime;
    ENUM_MARKET_REGIME marketRegime;
    MarketPattern initialPattern;
    EM_TouchContext srTouch;
    AccumulationContext accumulation;
    
    // Decisión tomada
    ConsensusMemory consensus;
    NeuralConsensusResult neuralResult;
    
    // Resultado
    CompleteTradeRecord tradeRecord;
    bool wasSuccessful;
    double profitLoss;
    double maxFavorableExcursion;
    double maxAdverseExcursion;
    
    // Métricas de similitud para búsqueda rápida
    double patternFingerprint[10];  // Vector de características para matching rápido
    
    // Enlaces a episodios similares
    ulong similarEpisodes[5];
    double similarities[5];
};

//+------------------------------------------------------------------+
//| Resultado de predicción basada en historia                      |
//+------------------------------------------------------------------+
struct HistoricalPrediction
{
    double successProbability;      // 0-1
    double expectedProfit;          // En puntos
    double expectedDrawdown;        // En puntos
    double confidence;              // 0-1 basado en número de muestras
    int samplesUsed;                // Episodios similares encontrados
    string warning;                 // Advertencias si las hay
    bool shouldTrade;               // Recomendación final
    
    // Desglose por similitud
    double avgSimilarity;
    double minSimilarity;
    double maxSimilarity;
};

//+------------------------------------------------------------------+
//| Clase principal de memoria episódica                            |
//+------------------------------------------------------------------+
class EpisodicMemorySystem
{
private:
    // Almacenamiento de episodios
    TradingEpisode m_episodes[];
    int m_episodeCount;
    int m_maxEpisodes;
    
    // Índices para búsqueda rápida
    ulong m_regimeIndex[][1000];    // [regime][episodeIds]
    int m_regimeIndexCount[8];       // Contador por régimen
    
    // Referencias
    RegimeDetectionSystem* m_regimeDetector;
    MetaLearningSystem* m_metaLearning;
    
    // Configuración
    double m_minSimilarityThreshold;
    int m_minSamplesForPrediction;
    double m_warningThreshold;       // Si success rate < esto, warning
    
    // Cache de búsquedas recientes
    struct SearchCache
    {
        string key;
        TradingEpisode results[20];
        int resultCount;
        datetime timestamp;
    };
    SearchCache m_searchCache[10];
    int m_cacheIndex;
    
    // Archivos de persistencia
    string m_episodesFile;
    string m_indexFile;
    
public:
    // Constructor
    EpisodicMemorySystem()
    {
        m_episodeCount = 0;
        m_maxEpisodes = 10000;
        m_minSimilarityThreshold = 0.7;
        m_minSamplesForPrediction = 3;
        m_warningThreshold = 0.4;
        m_cacheIndex = 0;
        
        ArrayResize(m_episodes, 1000);
        // Allocate regime index rows
        ArrayResize(m_regimeIndex, 8);
for(int i = 0; i < 8; i++)
            m_regimeIndexCount[i] = 0;
            
        // Nombres de archivos
        m_episodesFile = "EpisodicMemory_" + Symbol() + ".dat";
        m_indexFile = "EpisodicIndex_" + Symbol() + ".dat";
    }
    
    // Inicialización
    bool Initialize(RegimeDetectionSystem* regime, MetaLearningSystem* meta)
    {
        m_regimeDetector = regime;
        m_metaLearning = meta;
        
        // Cargar episodios históricos
        LoadEpisodes();
        
        // Construir índices
        RebuildIndices();
        
        Print("EpisodicMemorySystem: Inicializado con ", m_episodeCount, " episodios");
        
        return true;
    }
    
    // Crear nuevo episodio al iniciar trade
    ulong StartNewEpisode(EM_TouchContext &touch, AccumulationContext &accum,
                         ConsensusMemory &consensus, NeuralConsensusResult &neural)
    {
        if(m_episodeCount >= m_maxEpisodes)
        {
            CompactEpisodes(); // Eliminar episodios antiguos
        }
        
        TradingEpisode newEpisode;
        newEpisode.episodeId = (ulong)TimeCurrent() + m_episodeCount;
        newEpisode.startTime = TimeCurrent();
        
        // Obtener régimen actual
        if(m_regimeDetector != NULL)
            newEpisode.marketRegime = m_regimeDetector.GetCurrentRegime();
        else
            newEpisode.marketRegime = REGIME_RANGING;
        
        // Copiar contexto
        newEpisode.srTouch = touch;
        newEpisode.accumulation = accum;
        newEpisode.consensus = consensus;
        newEpisode.neuralResult = neural;
        
        // Inicializar pattern
        newEpisode.initialPattern.timestamp = TimeCurrent();
        newEpisode.initialPattern.volatility = touch.atr / _Point;
        newEpisode.initialPattern.momentum = 0;
        newEpisode.initialPattern.volume_ratio = 1.0;
        newEpisode.initialPattern.session_type = GetSessionType();
        newEpisode.initialPattern.rsi = 50.0;
        newEpisode.initialPattern.atr_ratio = 1.0;
        newEpisode.initialPattern.price_position = 0.5;
        newEpisode.initialPattern.touches = touch.touchNumber;
        newEpisode.initialPattern.strength = touch.levelStrength;
        newEpisode.initialPattern.pattern_type = 0;
        newEpisode.initialPattern.result = 0;
        newEpisode.initialPattern.profit_factor = 0;
        newEpisode.initialPattern.bars_duration = 0;
        newEpisode.initialPattern.is_profitable = false;
        newEpisode.initialPattern.consensus_strength = consensus.consensus_strength;
        newEpisode.initialPattern.emotional_context = consensus.emotional_score;
        newEpisode.initialPattern.agent_agreement = consensus.agreement_level;
        newEpisode.initialPattern.dissenting_agents = 5 - consensus.agent_count;
        newEpisode.initialPattern.fear_level = consensus.emotional_score; // Usar emotional_score como proxy
        newEpisode.initialPattern.greed_level = 1.0 - consensus.emotional_score;
        newEpisode.initialPattern.consensus_id = consensus.consensus_id;
        newEpisode.initialPattern.order_ticket = 0;
        
        // Calcular fingerprint para búsquedas rápidas
        CalculateFingerprint(newEpisode);
        
        // Agregar a la colección
        if(m_episodeCount >= ArraySize(m_episodes))
            ArrayResize(m_episodes, m_episodeCount + 100);
        
        m_episodes[m_episodeCount] = newEpisode;
        
        // Actualizar índice por régimen
        AddToRegimeIndex(newEpisode.marketRegime, newEpisode.episodeId);
        
        m_episodeCount++;
        
        return newEpisode.episodeId;
    }
    
    // Completar episodio con resultado
    bool CompleteEpisode(ulong episodeId, CompleteTradeRecord &record, bool success)
    {
        int idx = FindEpisodeById(episodeId);
        if(idx < 0) return false;
        
        m_episodes[idx].tradeRecord = record;
        m_episodes[idx].wasSuccessful = success;
        m_episodes[idx].profitLoss = record.order_profit_points;
        m_episodes[idx].maxFavorableExcursion = record.max_favorable_excursion;
        m_episodes[idx].maxAdverseExcursion = record.max_adverse_excursion;
        
        // Actualizar episodios similares
        UpdateSimilarEpisodes(idx);
        
        // Guardar a archivo
        SaveEpisode(m_episodes[idx]);
        
        return true;
    }
    
    // Buscar episodios similares al contexto actual
    int FindSimilarEpisodes(EM_TouchContext &touch, AccumulationContext &accum, 
                           ENUM_MARKET_REGIME regime, TradingEpisode &results[], int maxResults = 10)
    {
        ArrayResize(results, 0);
        
        // Verificar cache primero
        string cacheKey = GenerateCacheKey(touch, accum, regime);
        int cacheIdx = CheckCache(cacheKey);
        if(cacheIdx >= 0)
        {
            ArrayResize(results, m_searchCache[cacheIdx].resultCount);
            for(int i = 0; i < m_searchCache[cacheIdx].resultCount; i++)
                results[i] = m_searchCache[cacheIdx].results[i];
            return m_searchCache[cacheIdx].resultCount;
        }
        
        // Crear episodio temporal para comparación
        TradingEpisode current;
        current.srTouch = touch;
        current.accumulation = accum;
        current.marketRegime = regime;
        CalculateFingerprint(current);
        
        // Buscar primero en el mismo régimen
        TradingEpisode candidates[];
        int candidateCount = GetEpisodesByRegime(regime, candidates);
        
        // Si no hay suficientes, ampliar búsqueda
        if(candidateCount < m_minSamplesForPrediction * 2)
        {
            candidateCount = GetAllEpisodes(candidates);
        }
        
        // Calcular similitudes
        struct SimilarityScore
        {
            int index;
            double similarity;
        };
        SimilarityScore scores[];
        ArrayResize(scores, candidateCount);
        
        for(int i = 0; i < candidateCount; i++)
        {
            scores[i].index = i;
            scores[i].similarity = CalculateSimilarity(current, candidates[i]);
        }
        
        // Ordenar por similitud (bubble sort simple)
        for(int i = 0; i < candidateCount - 1; i++)
        {
            for(int j = i + 1; j < candidateCount; j++)
            {
                if(scores[j].similarity > scores[i].similarity)
                {
                    SimilarityScore temp = scores[i];
                    scores[i] = scores[j];
                    scores[j] = temp;
                }
            }
        }
        
        // Retornar los más similares que superen el umbral
        int resultCount = 0;
        for(int i = 0; i < candidateCount && resultCount < maxResults; i++)
        {
            if(scores[i].similarity >= m_minSimilarityThreshold)
            {
                ArrayResize(results, resultCount + 1);
                results[resultCount] = candidates[scores[i].index];
                resultCount++;
            }
        }
        
        // Guardar en cache
        UpdateCache(cacheKey, results);
        
        return resultCount;
    }
    
    // Predecir resultado basado en episodios similares
    HistoricalPrediction PredictOutcome(TradingEpisode &similar[], int count)
    {
        HistoricalPrediction prediction;
        prediction.successProbability = 0.0;
        prediction.expectedProfit = 0.0;
        prediction.expectedDrawdown = 0.0;
        prediction.confidence = 0.0;
        prediction.samplesUsed = count;
        prediction.warning = "";
        prediction.shouldTrade = false;
        prediction.avgSimilarity = 0.0;
        prediction.minSimilarity = 1.0;
        prediction.maxSimilarity = 0.0;
        
        if(count == 0)
        {
            prediction.warning = "No hay episodios similares";
            return prediction;
        }
        
        // Analizar resultados históricos
        int successCount = 0;
        double totalProfit = 0.0;
        double totalDrawdown = 0.0;
        double totalSimilarity = 0.0;
        
        for(int i = 0; i < count; i++)
        {
            if(similar[i].wasSuccessful)
                successCount++;
            
            totalProfit += similar[i].profitLoss;
            totalDrawdown += similar[i].maxAdverseExcursion;
            
            // Actualizar min/max similitud
            double sim = similar[i].similarities[0];
            totalSimilarity += sim;
            if(sim < prediction.minSimilarity) prediction.minSimilarity = sim;
            if(sim > prediction.maxSimilarity) prediction.maxSimilarity = sim;
        }
        
        // Calcular métricas
        prediction.successProbability = (double)successCount / count;
        prediction.expectedProfit = totalProfit / count;
        prediction.expectedDrawdown = totalDrawdown / count;
        prediction.avgSimilarity = totalSimilarity / count;
        
        // Calcular confianza basada en número de muestras y similitud
        prediction.confidence = MathMin(1.0, (double)count / 10.0) * prediction.avgSimilarity;
        
        // Generar advertencias
        if(prediction.successProbability < m_warningThreshold)
        {
            prediction.warning = StringFormat("ADVERTENCIA: Solo %d%% de éxito histórico", 
                                            (int)(prediction.successProbability * 100));
        }
        
        if(prediction.expectedProfit < 0)
        {
            if(prediction.warning != "")
                prediction.warning += " | ";
            prediction.warning += StringFormat("Expectativa negativa: %.1f puntos", 
                                             prediction.expectedProfit);
        }
        
        // Decisión final
        prediction.shouldTrade = (prediction.successProbability >= 0.5 && 
                                 prediction.expectedProfit > 0 &&
                                 prediction.confidence >= 0.5);
        
        // Override si hay advertencias graves
        if(prediction.successProbability < 0.3 || prediction.expectedProfit < -50)
        {
            prediction.shouldTrade = false;
            if(prediction.warning == "")
                prediction.warning = "Condiciones históricas desfavorables";
        }
        
        return prediction;
    }
    
    // Obtener estadísticas por régimen
    void GetRegimeStatistics(ENUM_MARKET_REGIME regime, double &winRate, 
                           double &avgProfit, int &totalTrades)
    {
        winRate = 0.0;
        avgProfit = 0.0;
        totalTrades = 0;
        
        int wins = 0;
        double totalPL = 0.0;
        
        for(int i = 0; i < m_episodeCount; i++)
        {
            if(m_episodes[i].marketRegime == regime && m_episodes[i].profitLoss != 0)
            {
                totalTrades++;
                totalPL += m_episodes[i].profitLoss;
                
                if(m_episodes[i].wasSuccessful)
                    wins++;
            }
        }
        
        if(totalTrades > 0)
        {
            winRate = (double)wins / totalTrades;
            avgProfit = totalPL / totalTrades;
        }
    }
    
private:
    // Calcular fingerprint para búsqueda rápida
    void CalculateFingerprint(TradingEpisode &episode)
    {
        // Crear vector de características normalizadas
        episode.patternFingerprint[0] = episode.srTouch.levelStrength / 10.0;
        episode.patternFingerprint[1] = (double)episode.srTouch.quality / 5.0;
        episode.patternFingerprint[2] = episode.accumulation.range / (100 * _Point);
        episode.patternFingerprint[3] = episode.accumulation.barCount / 20.0;
        episode.patternFingerprint[4] = episode.consensus.consensus_strength;
        episode.patternFingerprint[5] = episode.consensus.emotional_score;
        episode.patternFingerprint[6] = (double)episode.marketRegime / 8.0;
        episode.patternFingerprint[7] = episode.initialPattern.volatility;
        episode.patternFingerprint[8] = episode.initialPattern.momentum / 100.0;
        episode.patternFingerprint[9] = MathMin(1.0, episode.initialPattern.volume_ratio);
        
        // Normalizar entre 0 y 1
        for(int i = 0; i < 10; i++)
        {
            episode.patternFingerprint[i] = MathMax(0.0, MathMin(1.0, episode.patternFingerprint[i]));
        }
    }
    
    // Calcular similitud entre episodios
    double CalculateSimilarity(TradingEpisode &e1, TradingEpisode &e2)
    {
        // Similitud basada en distancia euclidiana del fingerprint
        double distance = 0.0;
        for(int i = 0; i < 10; i++)
        {
            distance += MathPow(e1.patternFingerprint[i] - e2.patternFingerprint[i], 2);
        }
        distance = MathSqrt(distance);
        
        // Convertir distancia a similitud (0-1)
        double similarity = 1.0 / (1.0 + distance);
        
        // Bonus si es el mismo régimen
        if(e1.marketRegime == e2.marketRegime)
            similarity *= 1.2;
        
        // Bonus si es la misma dirección
        if(e1.consensus.direction == e2.consensus.direction)
            similarity *= 1.1;
        
        return MathMin(1.0, similarity);
    }
    
    // Buscar episodio por ID
    int FindEpisodeById(ulong id)
    {
        for(int i = 0; i < m_episodeCount; i++)
        {
            if(m_episodes[i].episodeId == id)
                return i;
        }
        return -1;
    }
    
    // Obtener episodios por régimen
    int GetEpisodesByRegime(ENUM_MARKET_REGIME regime, TradingEpisode &results[])
    {
        ArrayResize(results, 0);
        int count = 0;
        
        for(int i = 0; i < m_episodeCount; i++)
        {
            if(m_episodes[i].marketRegime == regime)
            {
                ArrayResize(results, count + 1);
                results[count] = m_episodes[i];
                count++;
            }
        }
        
        return count;
    }
    
    // Obtener todos los episodios
    int GetAllEpisodes(TradingEpisode &results[])
    {
        ArrayResize(results, m_episodeCount);
        
        for(int i = 0; i < m_episodeCount; i++)
        {
            results[i] = m_episodes[i];
        }
        
        return m_episodeCount;
    }
    
    // Gestión de índices
    void AddToRegimeIndex(ENUM_MARKET_REGIME regime, ulong episodeId)
    {
        int idx = m_regimeIndexCount[regime];
        if(idx < 1000)
        {
            m_regimeIndex[regime][idx] = episodeId;
            m_regimeIndexCount[regime]++;
        }
    }
    
    void RebuildIndices()
    {
        // Limpiar índices
        for(int i = 0; i < 8; i++)
            m_regimeIndexCount[i] = 0;
        
        // Reconstruir
        for(int i = 0; i < m_episodeCount; i++)
        {
            AddToRegimeIndex(m_episodes[i].marketRegime, m_episodes[i].episodeId);
        }
    }
    
    // Actualizar episodios similares
    void UpdateSimilarEpisodes(int episodeIdx)
    {
        // Buscar los 5 más similares
        double maxSims[5] = {0, 0, 0, 0, 0};
        ulong simIds[5] = {0, 0, 0, 0, 0};
        
        for(int i = 0; i < m_episodeCount; i++)
        {
            if(i == episodeIdx) continue;
            
            double sim = CalculateSimilarity(m_episodes[episodeIdx], m_episodes[i]);
            
            // Insertar en top 5 si es mayor
            for(int j = 0; j < 5; j++)
            {
                if(sim > maxSims[j])
                {
                    // Desplazar hacia abajo
                    for(int k = 4; k > j; k--)
                    {
                        maxSims[k] = maxSims[k-1];
                        simIds[k] = simIds[k-1];
                    }
                    
                    maxSims[j] = sim;
                    simIds[j] = m_episodes[i].episodeId;
                    break;
                }
            }
        }
        
        // Actualizar en el episodio
        for(int i = 0; i < 5; i++)
        {
            m_episodes[episodeIdx].similarEpisodes[i] = simIds[i];
            m_episodes[episodeIdx].similarities[i] = maxSims[i];
        }
    }
    
    // Gestión de cache
    string GenerateCacheKey(EM_TouchContext &touch, AccumulationContext &accum, 
                          ENUM_MARKET_REGIME regime)
    {
        return StringFormat("%d_%d_%d_%d", 
                          (int)(touch.levelStrength * 10),
                          accum.barCount,
                          regime,
                          (int)(touch.quality * 100));
    }
    
    int CheckCache(string key)
    {
        for(int i = 0; i < 10; i++)
        {
            if(m_searchCache[i].key == key && 
               TimeCurrent() - m_searchCache[i].timestamp < 300) // 5 minutos
            {
                return i;
            }
        }
        return -1;
    }
    
    void UpdateCache(string key, TradingEpisode &results[])
    {
        m_searchCache[m_cacheIndex].key = key;
        m_searchCache[m_cacheIndex].timestamp = TimeCurrent();
        m_searchCache[m_cacheIndex].resultCount = ArraySize(results);
        
        for(int i = 0; i < ArraySize(results) && i < 20; i++)
        {
            m_searchCache[m_cacheIndex].results[i] = results[i];
        }
        
        m_cacheIndex = (m_cacheIndex + 1) % 10;
    }
    
    // Compactar episodios cuando se alcanza el límite
    void CompactEpisodes()
    {
        // Eliminar el 20% más antiguo
        int toRemove = m_episodeCount / 5;
        
        for(int i = 0; i < m_episodeCount - toRemove; i++)
        {
            m_episodes[i] = m_episodes[i + toRemove];
        }
        
        m_episodeCount -= toRemove;
        
        // Reconstruir índices
        RebuildIndices();
        
        Print("EpisodicMemory: Compactado. Episodios restantes: ", m_episodeCount);
    }
    
    // Obtener tipo de sesión actual
    int GetSessionType()
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
    
    // ==== IMPLEMENTACIÓN COMPLETA DE GUARDADO/CARGA DE ARCHIVOS ====
    
    // Guardar episodio individual
    void SaveEpisode(TradingEpisode &episode)
    {
        // Guardar a archivo temporal primero
        string tempFile = m_episodesFile + ".tmp";
        int handle = FileOpen(tempFile, FILE_WRITE|FILE_BIN|FILE_ANSI);
        
        if(handle != INVALID_HANDLE)
        {
            // Escribir episodio
            WriteEpisodeToFile(handle, episode);
            FileClose(handle);
            
            // Agregar al archivo principal
            AppendEpisodeToMainFile(episode);
        }
    }
    
    // Escribir episodio a archivo
    void WriteEpisodeToFile(int handle, TradingEpisode &episode)
    {
        // ID y tiempos
        FileWriteLong(handle, episode.episodeId);
        FileWriteLong(handle, episode.startTime);
        FileWriteInteger(handle, episode.marketRegime);
        
        // Pattern inicial
        WriteMarketPattern(handle, episode.initialPattern);
        
        // Touch context
        WriteTouchContext(handle, episode.srTouch);
        
        // Accumulation context
        WriteAccumulationContext(handle, episode.accumulation);
        
        // Consensus memory
        WriteConsensusMemory(handle, episode.consensus);
        
        // Neural result
        WriteNeuralResult(handle, episode.neuralResult);
        
        // Trade record
        WriteTradeRecord(handle, episode.tradeRecord);
        
        // Resultados
        FileWriteInteger(handle, episode.wasSuccessful ? 1 : 0);
        FileWriteDouble(handle, episode.profitLoss);
        FileWriteDouble(handle, episode.maxFavorableExcursion);
        FileWriteDouble(handle, episode.maxAdverseExcursion);
        
        // Fingerprint
        for(int i = 0; i < 10; i++)
            FileWriteDouble(handle, episode.patternFingerprint[i]);
        
        // Episodios similares
        for(int i = 0; i < 5; i++)
        {
            FileWriteLong(handle, episode.similarEpisodes[i]);
            FileWriteDouble(handle, episode.similarities[i]);
        }
    }
    
    // Funciones auxiliares de escritura
    void WriteMarketPattern(int handle, MarketPattern &pattern)
    {
        FileWriteLong(handle, pattern.timestamp);
        FileWriteDouble(handle, pattern.volatility);
        FileWriteDouble(handle, pattern.momentum);
        FileWriteDouble(handle, pattern.volume_ratio);
        FileWriteInteger(handle, pattern.session_type);
        FileWriteDouble(handle, pattern.rsi);
        FileWriteDouble(handle, pattern.atr_ratio);
        FileWriteDouble(handle, pattern.price_position);
        FileWriteInteger(handle, pattern.touches);
        FileWriteDouble(handle, pattern.strength);
        FileWriteInteger(handle, pattern.pattern_type);
        FileWriteDouble(handle, pattern.result);
        FileWriteDouble(handle, pattern.profit_factor);
        FileWriteInteger(handle, pattern.bars_duration);
        FileWriteInteger(handle, pattern.is_profitable ? 1 : 0);
        FileWriteDouble(handle, pattern.consensus_strength);
        FileWriteDouble(handle, pattern.emotional_context);
        FileWriteDouble(handle, pattern.agent_agreement);
        FileWriteInteger(handle, pattern.dissenting_agents);
        FileWriteDouble(handle, pattern.fear_level);
        FileWriteDouble(handle, pattern.greed_level);
        FileWriteLong(handle, pattern.consensus_id);
        FileWriteLong(handle, pattern.order_ticket);
    }
    
    void WriteTouchContext(int handle, EM_TouchContext &touch)
    {
        FileWriteInteger(handle, touch.valid ? 1 : 0);
        FileWriteDouble(handle, touch.price);
        FileWriteLong(handle, touch.time);
        FileWriteInteger(handle, touch.touchType);
        FileWriteDouble(handle, touch.quality);
        FileWriteDouble(handle, touch.strength);
        FileWriteDouble(handle, touch.levelStrength);
        FileWriteInteger(handle, touch.touchNumber);
        FileWriteDouble(handle, touch.atr);
        
        // Escribir SRLevel
        FileWriteDouble(handle, touch.level.price);
        FileWriteInteger(handle, touch.level.type);
        FileWriteLong(handle, touch.level.firstTouch);
        FileWriteLong(handle, touch.level.lastTouch);
        FileWriteInteger(handle, touch.level.touches);
        FileWriteDouble(handle, touch.level.strength);
        FileWriteInteger(handle, touch.level.state);
        FileWriteDouble(handle, touch.level.movementStrength);
        FileWriteInteger(handle, touch.level.quality);
    }
    
    void WriteAccumulationContext(int handle, AccumulationContext &accum)
    {
        FileWriteDouble(handle, accum.range);
        FileWriteInteger(handle, accum.barCount);
        FileWriteLong(handle, accum.startTime);
        FileWriteDouble(handle, accum.centerPrice);
        FileWriteDouble(handle, accum.highPrice);
        FileWriteDouble(handle, accum.lowPrice);
        FileWriteInteger(handle, accum.valid ? 1 : 0);
        FileWriteLong(handle, accum.endTime);
        FileWriteInteger(handle, accum.volumeConfirmation ? 1 : 0);
    }
    
    void WriteConsensusMemory(int handle, ConsensusMemory &consensus)
    {
        FileWriteLong(handle, consensus.consensus_id);
        FileWriteLong(handle, consensus.associated_ticket);
        FileWriteLong(handle, consensus.timestamp);
        FileWriteDouble(handle, consensus.consensus_strength);
        FileWriteInteger(handle, consensus.agent_count);
        FileWriteInteger(handle, consensus.direction);
        FileWriteInteger(handle, consensus.was_successful ? 1 : 0);
        FileWriteDouble(handle, consensus.emotional_score);
        FileWriteDouble(handle, consensus.profit_result);
        FileWriteInteger(handle, consensus.negotiation_rounds);
        FileWriteString(handle, consensus.dominant_agent);
        FileWriteDouble(handle, consensus.agreement_level);
        FileWriteDouble(handle, consensus.profit_result);  // Usar profit_result en lugar de profit_points
        FileWriteInteger(handle, 0);  // duration_bars - campo no existe, usar 0
        FileWriteDouble(handle, 0.0); // max_favorable_excursion - campo no existe
        FileWriteDouble(handle, 0.0); // max_adverse_excursion - campo no existe

        // Arrays - campos no existen en ConsensusMemory, usar valores por defecto
        for(int i = 0; i < 5; i++)
        {
            FileWriteString(handle, "");  // participating_agents
            FileWriteDouble(handle, 0.0); // agent_confidences
            FileWriteInteger(handle, 0);  // agent_votes
        }
    }
    
    void WriteNeuralResult(int handle, NeuralConsensusResult &neural)
    {
        FileWriteInteger(handle, neural.final_direction);
        FileWriteDouble(handle, neural.consensus_strength);
        FileWriteDouble(handle, neural.total_conviction);
        FileWriteDouble(handle, 0.0); // negotiation_rounds - campo no existe
        FileWriteString(handle, neural.consensus_reasoning);
        FileWriteInteger(handle, neural.strong_consensus ? 1 : 0);
        FileWriteInteger(handle, 0);  // dissenting_agents - campo no existe
        FileWriteString(handle, neural.leading_agent);
        FileWriteDouble(handle, 0.0); // leadership_strength - campo no existe
        FileWriteInteger(handle, neural.veto_used ? 1 : 0);
        FileWriteLong(handle, neural.consensus_id);

        // Market emotion - campos no existen, usar 0.0
        FileWriteDouble(handle, 0.0); // fear
        FileWriteDouble(handle, 0.0); // greed
        FileWriteDouble(handle, 0.0); // uncertainty
        FileWriteDouble(handle, 0.0); // excitement
    }
    
    void WriteTradeRecord(int handle, CompleteTradeRecord &record)
    {
        FileWriteLong(handle, record.consensus_id);
        FileWriteLong(handle, record.order_ticket);
        FileWriteLong(handle, record.consensus_time);
        FileWriteInteger(handle, record.consensus_direction);
        FileWriteDouble(handle, record.consensus_strength);
        FileWriteDouble(handle, record.total_conviction);
        FileWriteString(handle, record.leading_agent);
        
        for(int i = 0; i < 5; i++)
        {
            FileWriteString(handle, record.participating_agents[i]);
            FileWriteDouble(handle, record.agent_votes[i]);
            FileWriteDouble(handle, record.agent_confidences[i]);
        }
        
        FileWriteInteger(handle, record.veto_used ? 1 : 0);
        FileWriteDouble(handle, record.initial_volatility);
        FileWriteDouble(handle, record.initial_momentum);
        FileWriteDouble(handle, record.initial_fear);
        FileWriteDouble(handle, record.initial_greed);
        FileWriteInteger(handle, record.session_type);
        FileWriteDouble(handle, record.sr_level_strength);
        
        FileWriteLong(handle, record.order_open_time);
        FileWriteDouble(handle, record.order_open_price);
        FileWriteDouble(handle, record.order_lot_size);
        FileWriteDouble(handle, record.order_sl);
        FileWriteDouble(handle, record.order_tp);
        FileWriteInteger(handle, record.order_position_in_cycle);
        
        FileWriteLong(handle, record.order_close_time);
        FileWriteDouble(handle, record.order_close_price);
        FileWriteDouble(handle, record.order_profit);
        FileWriteDouble(handle, record.order_profit_points);
        FileWriteInteger(handle, record.order_success ? 1 : 0);
        FileWriteInteger(handle, record.order_duration_bars);
        FileWriteDouble(handle, record.max_profit_reached);
        FileWriteDouble(handle, record.max_drawdown_reached);
        
        for(int i = 0; i < 5; i++)
            FileWriteDouble(handle, record.agent_performance_impact[i]);
        
        FileWriteInteger(handle, record.consensus_quality_confirmed ? 1 : 0);
        FileWriteDouble(handle, record.learning_value);
        FileWriteDouble(handle, record.max_favorable_excursion);
        FileWriteDouble(handle, record.max_adverse_excursion);
    }
    
    // Agregar episodio al archivo principal
    void AppendEpisodeToMainFile(TradingEpisode &episode)
    {
        int handle = FileOpen(m_episodesFile, FILE_READ|FILE_WRITE|FILE_BIN|FILE_ANSI);
        
        if(handle != INVALID_HANDLE)
        {
            // Ir al final
            FileSeek(handle, 0, SEEK_END);
            
            // Escribir episodio
            WriteEpisodeToFile(handle, episode);
            
            FileClose(handle);
        }
    }
    
    // Cargar todos los episodios
    void LoadEpisodes()
    {
        if(!FileIsExist(m_episodesFile))
        {
            Print("EpisodicMemory: No se encontraron episodios históricos");
            return;
        }
        
        int handle = FileOpen(m_episodesFile, FILE_READ|FILE_BIN|FILE_ANSI);
        
        if(handle != INVALID_HANDLE)
        {
            m_episodeCount = 0;
            
            while(!FileIsEnding(handle) && m_episodeCount < m_maxEpisodes)
            {
                TradingEpisode episode;
                
                if(ReadEpisodeFromFile(handle, episode))
                {
                    if(m_episodeCount >= ArraySize(m_episodes))
                        ArrayResize(m_episodes, m_episodeCount + 100);
                    
                    m_episodes[m_episodeCount] = episode;
                    m_episodeCount++;
                }
                else
                {
                    break; // Error de lectura
                }
            }
            
            FileClose(handle);
            
            Print("EpisodicMemory: Cargados ", m_episodeCount, " episodios históricos");
        }
    }
    
    // Leer episodio desde archivo
    bool ReadEpisodeFromFile(int handle, TradingEpisode &episode)
    {
        if(FileIsEnding(handle)) return false;
        
        // ID y tiempos
        episode.episodeId = (ulong)FileReadLong(handle);
        episode.startTime = (datetime)FileReadLong(handle);
        episode.marketRegime = (ENUM_MARKET_REGIME)FileReadInteger(handle);
        
        // Pattern inicial
        if(!ReadMarketPattern(handle, episode.initialPattern)) return false;
        
        // Touch context
        if(!ReadTouchContext(handle, episode.srTouch)) return false;
        
        // Accumulation context
        if(!ReadAccumulationContext(handle, episode.accumulation)) return false;
        
        // Consensus memory
        if(!ReadConsensusMemory(handle, episode.consensus)) return false;
        
        // Neural result
        if(!ReadNeuralResult(handle, episode.neuralResult)) return false;
        
        // Trade record
        if(!ReadTradeRecord(handle, episode.tradeRecord)) return false;
        
        // Resultados
        episode.wasSuccessful = (FileReadInteger(handle) == 1);
        episode.profitLoss = FileReadDouble(handle);
        episode.maxFavorableExcursion = FileReadDouble(handle);
        episode.maxAdverseExcursion = FileReadDouble(handle);
        
        // Fingerprint
        for(int i = 0; i < 10; i++)
            episode.patternFingerprint[i] = FileReadDouble(handle);
        
        // Episodios similares
        for(int i = 0; i < 5; i++)
        {
            episode.similarEpisodes[i] = (ulong)FileReadLong(handle);
            episode.similarities[i] = FileReadDouble(handle);
        }
        
        return true;
    }
    
    // Funciones auxiliares de lectura
    bool ReadMarketPattern(int handle, MarketPattern &pattern)
    {
        if(FileIsEnding(handle)) return false;
        
        pattern.timestamp = (datetime)FileReadLong(handle);
        pattern.volatility = FileReadDouble(handle);
        pattern.momentum = FileReadDouble(handle);
        pattern.volume_ratio = FileReadDouble(handle);
        pattern.session_type = FileReadInteger(handle);
        pattern.rsi = FileReadDouble(handle);
        pattern.atr_ratio = FileReadDouble(handle);
        pattern.price_position = FileReadDouble(handle);
        pattern.touches = FileReadInteger(handle);
        pattern.strength = FileReadDouble(handle);
        pattern.pattern_type = FileReadInteger(handle);
        pattern.result = FileReadInteger(handle);
        pattern.profit_factor = FileReadDouble(handle);
        pattern.bars_duration = FileReadInteger(handle);
        pattern.is_profitable = (FileReadInteger(handle) == 1);
        pattern.consensus_strength = FileReadDouble(handle);
        pattern.emotional_context = FileReadDouble(handle);
        pattern.agent_agreement = FileReadDouble(handle);
        pattern.dissenting_agents = FileReadInteger(handle);
        pattern.fear_level = FileReadDouble(handle);
        pattern.greed_level = FileReadDouble(handle);
        pattern.consensus_id = (ulong)FileReadLong(handle);
        pattern.order_ticket = (ulong)FileReadLong(handle);
        
        return true;
    }
    
    bool ReadTouchContext(int handle, EM_TouchContext &touch)
    {
        if(FileIsEnding(handle)) return false;
        
        touch.valid = (FileReadInteger(handle) == 1);
        touch.price = FileReadDouble(handle);
        touch.time = (datetime)FileReadLong(handle);
        touch.touchType = (ENUM_TOUCH_TYPE)FileReadInteger(handle);
        touch.quality = FileReadDouble(handle);
        touch.strength = FileReadDouble(handle);
        touch.levelStrength = FileReadDouble(handle);
        touch.touchNumber = FileReadInteger(handle);
        touch.atr = FileReadDouble(handle);
        
        // Leer SRLevel
        touch.level.price = FileReadDouble(handle);
        touch.level.type = (ENUM_SR_TYPE)FileReadInteger(handle);
        touch.level.firstTouch = (datetime)FileReadLong(handle);
        touch.level.lastTouch = (datetime)FileReadLong(handle);
        touch.level.touches = FileReadInteger(handle);
        touch.level.strength = FileReadDouble(handle);
        touch.level.state = (ENUM_SR_STATE)FileReadInteger(handle);
        touch.level.movementStrength = FileReadDouble(handle);
        touch.level.quality = (ENUM_SR_QUALITY)FileReadInteger(handle);
        
        return true;
    }
    
    bool ReadAccumulationContext(int handle, AccumulationContext &accum)
    {
        if(FileIsEnding(handle)) return false;
        
        accum.range = FileReadDouble(handle);
        accum.barCount = FileReadInteger(handle);
        accum.startTime = (datetime)FileReadLong(handle);
        accum.centerPrice = FileReadDouble(handle);
        accum.highPrice = FileReadDouble(handle);
        accum.lowPrice = FileReadDouble(handle);
        accum.valid = (FileReadInteger(handle) == 1);
        accum.endTime = (datetime)FileReadLong(handle);
        accum.volumeConfirmation = (FileReadInteger(handle) == 1);
        
        return true;
    }
    
    bool ReadConsensusMemory(int handle, ConsensusMemory &consensus)
    {
        if(FileIsEnding(handle)) return false;
        
        consensus.consensus_id = (ulong)FileReadLong(handle);
        consensus.associated_ticket = (ulong)FileReadLong(handle);
        consensus.timestamp = (datetime)FileReadLong(handle);
        consensus.consensus_strength = FileReadDouble(handle);
        consensus.agent_count = FileReadInteger(handle);
        consensus.direction = (ENUM_VOTE_DIRECTION)FileReadInteger(handle);
        consensus.was_successful = (FileReadInteger(handle) == 1);
        consensus.emotional_score = FileReadDouble(handle);
        consensus.profit_result = FileReadDouble(handle);
        consensus.negotiation_rounds = FileReadInteger(handle);
        consensus.dominant_agent = FileReadString(handle);
        consensus.agreement_level = FileReadDouble(handle);
        FileReadDouble(handle); // profit_points - descartado, campo no existe
        FileReadInteger(handle); // duration_bars - descartado
        FileReadDouble(handle); // max_favorable_excursion - descartado
        FileReadDouble(handle); // max_adverse_excursion - descartado

        // Arrays - leer pero descartar, campos no existen
        for(int i = 0; i < 5; i++)
        {
            FileReadString(handle);  // participating_agents - descartado
            FileReadDouble(handle);  // agent_confidences - descartado
            FileReadInteger(handle); // agent_votes - descartado
        }
        
        return true;
    }
    
    bool ReadNeuralResult(int handle, NeuralConsensusResult &neural)
    {
        if(FileIsEnding(handle)) return false;
        
        neural.final_direction = (ENUM_VOTE_DIRECTION)FileReadInteger(handle);
        neural.consensus_strength = FileReadDouble(handle);
        neural.total_conviction = FileReadDouble(handle);
        FileReadDouble(handle); // negotiation_rounds - descartado
        neural.consensus_reasoning = FileReadString(handle);
        neural.strong_consensus = (FileReadInteger(handle) == 1);
        FileReadInteger(handle); // dissenting_agents - descartado
        neural.leading_agent = FileReadString(handle);
        FileReadDouble(handle); // leadership_strength - descartado
        neural.veto_used = (FileReadInteger(handle) == 1);
        neural.consensus_id = (ulong)FileReadLong(handle);

        // Market emotion - leer pero descartar, campos no existen
        FileReadDouble(handle); // fear
        FileReadDouble(handle); // greed
        FileReadDouble(handle); // uncertainty
        FileReadDouble(handle); // excitement
        
        return true;
    }
    
    bool ReadTradeRecord(int handle, CompleteTradeRecord &record)
    {
        if(FileIsEnding(handle)) return false;
        
        record.consensus_id = (ulong)FileReadLong(handle);
        record.order_ticket = (ulong)FileReadLong(handle);
        record.consensus_time = (datetime)FileReadLong(handle);
        record.consensus_direction = (ENUM_VOTE_DIRECTION)FileReadInteger(handle);
        record.consensus_strength = FileReadDouble(handle);
        record.total_conviction = FileReadDouble(handle);
        record.leading_agent = FileReadString(handle);
        
        for(int i = 0; i < 5; i++)
        {
            record.participating_agents[i] = FileReadString(handle);
            record.agent_votes[i] = FileReadDouble(handle);
            record.agent_confidences[i] = FileReadDouble(handle);
        }
        
        record.veto_used = (FileReadInteger(handle) == 1);
        record.initial_volatility = FileReadDouble(handle);
        record.initial_momentum = FileReadDouble(handle);
        record.initial_fear = FileReadDouble(handle);
        record.initial_greed = FileReadDouble(handle);
        record.session_type = FileReadInteger(handle);
        record.sr_level_strength = FileReadDouble(handle);
        
        record.order_open_time = (datetime)FileReadLong(handle);
        record.order_open_price = FileReadDouble(handle);
        record.order_lot_size = FileReadDouble(handle);
        record.order_sl = FileReadDouble(handle);
        record.order_tp = FileReadDouble(handle);
        record.order_position_in_cycle = FileReadInteger(handle);
        
        record.order_close_time = (datetime)FileReadLong(handle);
        record.order_close_price = FileReadDouble(handle);
        record.order_profit = FileReadDouble(handle);
        record.order_profit_points = FileReadDouble(handle);
        record.order_success = (FileReadInteger(handle) == 1);
        record.order_duration_bars = FileReadInteger(handle);
        record.max_profit_reached = FileReadDouble(handle);
        record.max_drawdown_reached = FileReadDouble(handle);
        
        for(int i = 0; i < 5; i++)
            record.agent_performance_impact[i] = FileReadDouble(handle);
        
        record.consensus_quality_confirmed = (FileReadInteger(handle) == 1);
        record.learning_value = FileReadDouble(handle);
        record.max_favorable_excursion = FileReadDouble(handle);
        record.max_adverse_excursion = FileReadDouble(handle);
        
        return true;
    }
};
#endif // EPISODIC_MEMORY_SYSTEM_MQH