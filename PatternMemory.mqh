//+------------------------------------------------------------------+
//|                                           PatternMemory.mqh      |
//|                        Copyright 2025, Trading Strategy Developer |
//|                        VERSIÓN MEJORADA - SEÑALES DIRECTAS       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Strategy Developer"
#property link      "https://www.domain.com"

#include <SupportResistance.mqh>
#include <AccumulationZones.mqh>

//+------------------------------------------------------------------+
//| ENUMERACIONES Y ESTRUCTURAS                                      |
//+------------------------------------------------------------------+

#ifndef TREND_DIRECTION_ENUM_DEFINED
#define TREND_DIRECTION_ENUM_DEFINED
enum ENUM_TREND_DIRECTION {
   TREND_NONE,     
   TREND_UP,       
   TREND_DOWN      
};
#endif // TREND_DIRECTION_ENUM_DEFINED

enum ENUM_MARKET_STATE {
   MARKET_RANGE,      
   MARKET_TREND,      
   MARKET_STATE_BREAKOUT    
};

enum ENUM_SR_CONTEXT {
   SR_CONTEXT_APPROACH,    
   SR_CONTEXT_TOUCH,       
   SR_CONTEXT_BOUNCE,      
   SR_CONTEXT_BREAK        
};

struct PMMarketContext {
   bool            nearSRLevel;        
   int             srLevelId;          
   ENUM_SR_TYPE    srType;             
   double          srPrice;            
   double          srStrength;         
   double          distanceToSR;       
   ENUM_SR_CONTEXT srContext;          
   
   bool            inAccumZone;        
   int             accumZoneId;        
   double          accumStrength;      
   double          accumVolatility;    
   int             accumBars;          
   bool            accumConfirmed;     
   
   bool            srAccumConfluence;  
   double          confluenceStrength; 
};

struct SimplePattern {
   datetime        time;               
   double          priceChange;        
   double          volatility;         
   double          volume;             
   ENUM_MARKET_STATE state;            
   ENUM_TREND_DIRECTION result;        
   double          strength;           
   bool            bullish;            
   
   PMMarketContext   context;            
   double          srInfluence;        
   double          accumInfluence;     
   double          confluenceBonus;    
};

struct TrendSignal {
   double          price;               
   ENUM_TREND_DIRECTION direction;      
   datetime        time;                
   double          strength;            
   bool            active;              
   int             id;                  
   int             accumZoneId;         
   double          stopLoss;            
   double          takeProfit;          
   double          probability;         
   double          confidence;          
   int             supportingPatterns;  
   
   int             srLevelId;           
   double          srAlignment;         
   double          accumAlignment;      
   double          contextBonus;        
   bool            multiTimeframeConfirm; 
   int             expectedBars;        
   double          convictionScore;     
   
   int             patternMatches;      
   int             period;              
};

//+------------------------------------------------------------------+
//| CLASE PRINCIPAL MEJORADA                                         |
//+------------------------------------------------------------------+

class CPatternMemory {
private:
   // Variables de configuración
   ENUM_TIMEFRAMES m_timeframe;
   bool            m_showVisual;
   bool            m_initialized;
   int             m_signalCount;
   string          m_prefix;
   
   // Arrays de datos
   TrendSignal     m_signals[10];
   int             m_signalsActive;
   
   // Variables de estado
   datetime        m_lastUpdate;
   PMMarketContext   m_currentContext;
   
   // Handles de indicadores
   int             m_atrHandle;
   int             m_rsiHandle;  
   int             m_macdHandle; 
   int             m_bbHandle;   
   
   // Configuración mejorada
   bool            m_aggressiveMode;
   double          m_minProbability;
   
   // NUEVO: Variable para tracking de divergencias
   ENUM_TREND_DIRECTION m_lastDivergenceDirection;
   bool            m_divergenceDetected;
   
   // Métodos privados mejorados
   ENUM_TREND_DIRECTION DetermineImmediateTrend();
   double          CalculateMarketMomentum();
   bool            CheckDivergence(ENUM_TREND_DIRECTION &divergenceDirection);
   double          GetPricePosition(); 
   
public:
   CPatternMemory();
   ~CPatternMemory();
   
   // Métodos públicos principales
   bool            Init(ENUM_TIMEFRAMES timeframe, bool showVisual = true);
   int             AnalyzeTrend(AccumulationZone &accumZones[], int accumCount, TrendSignal &signals[]);
   
   // NUEVO: Método directo para obtener dirección
   ENUM_TREND_DIRECTION GetImmediateDirection();
   double          GetDirectionConfidence();
   
   // NUEVO: Método para obtener divergencia
   bool            HasDivergence() { return m_divergenceDetected; }
   ENUM_TREND_DIRECTION GetDivergenceDirection() { return m_lastDivergenceDirection; }
   
   // Métodos de configuración
   void            SetAggressiveMode(bool aggressive) { m_aggressiveMode = aggressive; }
   void            SetMinProbability(double minProb) { m_minProbability = minProb; }
   
   // Métodos públicos existentes
   bool            IsSignalValid(int signalId);
   bool            GetSignalById(int id, TrendSignal &signal);
   void            ClearSignals();
   void            UpdateVisual();
   void            PrintCurrentAnalysis();
   PMMarketContext   GetCurrentContext() { return m_currentContext; }
   void            SetDebugMode(bool debug) { /* stub */ }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPatternMemory::CPatternMemory() {
   m_timeframe = PERIOD_CURRENT;
   m_showVisual = true;
   m_initialized = false;
   m_signalCount = 0;
   m_signalsActive = 0;
   m_lastUpdate = 0;
   m_prefix = "PATTERN_";
   
   m_atrHandle = INVALID_HANDLE;
   m_rsiHandle = INVALID_HANDLE;
   m_macdHandle = INVALID_HANDLE;
   m_bbHandle = INVALID_HANDLE;
   
   // Configuración más agresiva por defecto
   m_aggressiveMode = true;
   m_minProbability = 30.0; 
   
   // Inicializar variables de divergencia
   m_divergenceDetected = false;
   m_lastDivergenceDirection = TREND_NONE;
   
   ZeroMemory(m_currentContext);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPatternMemory::~CPatternMemory() {
   if(m_showVisual) {
      ObjectsDeleteAll(0, m_prefix);
   }
   
   // CORRECCIÓN: Liberar todos los handles
   if(m_atrHandle != INVALID_HANDLE) {
      IndicatorRelease(m_atrHandle);
      m_atrHandle = INVALID_HANDLE;
   }
   
   if(m_rsiHandle != INVALID_HANDLE) {
      IndicatorRelease(m_rsiHandle);
      m_rsiHandle = INVALID_HANDLE;
   }
   
   if(m_macdHandle != INVALID_HANDLE) {
      IndicatorRelease(m_macdHandle);
      m_macdHandle = INVALID_HANDLE;
   }
   
   if(m_bbHandle != INVALID_HANDLE) {
      IndicatorRelease(m_bbHandle);
      m_bbHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
bool CPatternMemory::Init(ENUM_TIMEFRAMES timeframe, bool showVisual = true) {
   m_timeframe = timeframe;
   m_showVisual = showVisual;
   
   // Inicializar indicadores múltiples para mejor análisis
   m_atrHandle = iATR(Symbol(), m_timeframe, 14);
   m_rsiHandle = iRSI(Symbol(), m_timeframe, 14, PRICE_CLOSE);
   m_macdHandle = iMACD(Symbol(), m_timeframe, 12, 26, 9, PRICE_CLOSE);
   m_bbHandle = iBands(Symbol(), m_timeframe, 20, 0, 2.0, PRICE_CLOSE);
   
   if(m_atrHandle == INVALID_HANDLE || m_rsiHandle == INVALID_HANDLE || 
      m_macdHandle == INVALID_HANDLE || m_bbHandle == INVALID_HANDLE) {
      Print("Error inicializando indicadores en PatternMemory");
      
      // CORRECCIÓN: Liberar handles en caso de error
      if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
      if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
      if(m_macdHandle != INVALID_HANDLE) IndicatorRelease(m_macdHandle);
      if(m_bbHandle != INVALID_HANDLE) IndicatorRelease(m_bbHandle);
      
      m_atrHandle = INVALID_HANDLE;
      m_rsiHandle = INVALID_HANDLE;
      m_macdHandle = INVALID_HANDLE;
      m_bbHandle = INVALID_HANDLE;
      
      return false;
   }
   
   m_initialized = true;
   Print("PatternMemory MEJORADO inicializado - Modo más directo y agresivo");
   return true;
}

//+------------------------------------------------------------------+
//| NUEVO: Obtener dirección inmediata del mercado                  |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CPatternMemory::GetImmediateDirection() {
   return DetermineImmediateTrend();
}

//+------------------------------------------------------------------+
//| NUEVO: Obtener confianza de la dirección                        |
//+------------------------------------------------------------------+
double CPatternMemory::GetDirectionConfidence() {
   ENUM_TREND_DIRECTION trend = DetermineImmediateTrend();
   double momentum = CalculateMarketMomentum();
   
   // Confianza basada en múltiples factores
   double confidence = 50.0; // Base
   
   // Factor 1: Momentum
   confidence += MathAbs(momentum) * 20.0;
   
   // Factor 2: RSI
   double rsi[];
   ArraySetAsSeries(rsi, true);
   if(CopyBuffer(m_rsiHandle, 0, 0, 1, rsi) > 0) {
      if((trend == TREND_UP && rsi[0] > 50) || (trend == TREND_DOWN && rsi[0] < 50)) {
         confidence += MathAbs(rsi[0] - 50) * 0.5;
      }
   }
   
   // Factor 3: Posición del precio
   double pricePos = GetPricePosition();
   if((trend == TREND_UP && pricePos < 0.3) || (trend == TREND_DOWN && pricePos > 0.7)) {
      confidence += 10.0;
   }
   
   // NUEVO: Factor 4: Si hay divergencia, reducir confianza
   if(m_divergenceDetected) {
      confidence -= 15.0;
   }
   
   return MathMin(100.0, MathMax(0.0, confidence));
}

ENUM_TREND_DIRECTION CPatternMemory::DetermineImmediateTrend() {
    struct SignalWeight {
        ENUM_TREND_DIRECTION direction;
        double weight;
        double confidence;
    };
    
    SignalWeight signals[8]; // Aumentado para incluir divergencia
    int signalCount = 0;
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), m_timeframe, 0, 20, rates) < 20) {
        return TREND_NONE;
    }
    
    // NUEVO: Verificar divergencias antes del análisis
    ENUM_TREND_DIRECTION divergenceDir = TREND_NONE;
    m_divergenceDetected = CheckDivergence(divergenceDir);
    if(m_divergenceDetected) {
        m_lastDivergenceDirection = divergenceDir;
    }
    
    // 1. Análisis de precio (peso alto)
    double priceChange5 = rates[0].close - rates[5].close;
    double priceChange10 = rates[0].close - rates[10].close;
    double avgPrice = (rates[5].close + rates[10].close) / 2;
    
    if(avgPrice > 0) {
        double percentChange = ((priceChange5 + priceChange10) / 2) / avgPrice;
        
        if(MathAbs(percentChange) > 0.0001) {
            signals[signalCount].direction = percentChange > 0 ? TREND_UP : TREND_DOWN;
            signals[signalCount].weight = 2.5; // Peso aumentado
            signals[signalCount].confidence = MathAbs(percentChange) * 10000;
            signalCount++;
        }
    }
    
    // 2. RSI (peso medio-alto)
    double rsi[];
    ArraySetAsSeries(rsi, true);
    if(CopyBuffer(m_rsiHandle, 0, 0, 3, rsi) > 0 && rsi[0] > 0) {
        // RSI extremo (umbrales más estrictos: 75/25 en lugar de 70/30)
        if(rsi[0] > 75) {
            signals[signalCount].direction = TREND_UP;
            signals[signalCount].weight = 2.0;
            signals[signalCount].confidence = (rsi[0] - 50) * 2;
            signalCount++;
        } else if(rsi[0] < 25) {
            signals[signalCount].direction = TREND_DOWN;
            signals[signalCount].weight = 2.0;
            signals[signalCount].confidence = (50 - rsi[0]) * 2;
            signalCount++;
        }
        // RSI moderado (umbrales más estrictos: 65/35 en lugar de 55/45, weight reducido)
        else if(rsi[0] > 65) {
            signals[signalCount].direction = TREND_UP;
            signals[signalCount].weight = 1.0;  // Reducido de 1.2 a 1.0
            signals[signalCount].confidence = (rsi[0] - 50) * 2;
            signalCount++;
        } else if(rsi[0] < 35) {
            signals[signalCount].direction = TREND_DOWN;
            signals[signalCount].weight = 1.0;  // Reducido de 1.2 a 1.0
            signals[signalCount].confidence = (50 - rsi[0]) * 2;
            signalCount++;
        }
    }
    
    // 3. MACD
    double macdMain[], macdSignal[];
    ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSignal, true);
    
    if(CopyBuffer(m_macdHandle, 0, 0, 3, macdMain) > 0 && 
       CopyBuffer(m_macdHandle, 1, 0, 3, macdSignal) > 0) {
        
        // Cruce de MACD
        if(macdMain[0] > macdSignal[0] && macdMain[1] <= macdSignal[1]) {
            signals[signalCount].direction = TREND_UP;
            signals[signalCount].weight = 1.8;
            signals[signalCount].confidence = 70;
            signalCount++;
        } else if(macdMain[0] < macdSignal[0] && macdMain[1] >= macdSignal[1]) {
            signals[signalCount].direction = TREND_DOWN;
            signals[signalCount].weight = 1.8;
            signals[signalCount].confidence = 70;
            signalCount++;
        }
        
        // Dirección de MACD
        if(macdMain[0] > 0 && macdMain[0] > macdMain[1]) {
            signals[signalCount].direction = TREND_UP;
            signals[signalCount].weight = 1.0;
            signals[signalCount].confidence = 50;
            signalCount++;
        } else if(macdMain[0] < 0 && macdMain[0] < macdMain[1]) {
            signals[signalCount].direction = TREND_DOWN;
            signals[signalCount].weight = 1.0;
            signals[signalCount].confidence = 50;
            signalCount++;
        }
    }
    
    // 4. Bandas de Bollinger
    double bbUpper[], bbLower[], bbMiddle[];
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMiddle, true);
    
    if(CopyBuffer(m_bbHandle, 1, 0, 1, bbUpper) > 0 &&
       CopyBuffer(m_bbHandle, 2, 0, 1, bbLower) > 0 &&
       CopyBuffer(m_bbHandle, 0, 0, 1, bbMiddle) > 0) {
        
        double bbWidth = bbUpper[0] - bbLower[0];
        double pricePos = (rates[0].close - bbLower[0]) / bbWidth;
        
        if(pricePos > 0.8) {
            signals[signalCount].direction = TREND_UP;
            signals[signalCount].weight = 1.5;
            signals[signalCount].confidence = pricePos * 100;
            signalCount++;
        } else if(pricePos < 0.2) {
            signals[signalCount].direction = TREND_DOWN;
            signals[signalCount].weight = 1.5;
            signals[signalCount].confidence = (1 - pricePos) * 100;
            signalCount++;
        }
    }
    
    // 5. NUEVO: Señal de divergencia si existe
    if(m_divergenceDetected) {
        signals[signalCount].direction = divergenceDir;
        signals[signalCount].weight = 3.0; // Peso muy alto para divergencias
        signals[signalCount].confidence = 80;
        signalCount++;
    }
    
    // 6. Contexto S/R si está disponible
    if(m_currentContext.nearSRLevel) {
        if(m_currentContext.srType == SR_SUPPORT && m_currentContext.srContext == SR_CONTEXT_BOUNCE) {
            signals[signalCount].direction = TREND_UP;
            signals[signalCount].weight = 3.5; // Peso muy alto
            signals[signalCount].confidence = m_currentContext.srStrength * 10;
            signalCount++;
        } else if(m_currentContext.srType == SR_RESISTANCE && m_currentContext.srContext == SR_CONTEXT_BOUNCE) {
            signals[signalCount].direction = TREND_DOWN;
            signals[signalCount].weight = 3.5;
            signals[signalCount].confidence = m_currentContext.srStrength * 10;
            signalCount++;
        }
    }
    
    // Calcular dirección ponderada
    double bullishScore = 0, bearishScore = 0;
    double totalWeight = 0;
    
    for(int i = 0; i < signalCount; i++) {
        double weightedConfidence = signals[i].weight * signals[i].confidence;
        totalWeight += signals[i].weight;
        
        if(signals[i].direction == TREND_UP) {
            bullishScore += weightedConfidence;
        } else if(signals[i].direction == TREND_DOWN) {
            bearishScore += weightedConfidence;
        }
    }
    
    // Normalizar scores
    if(totalWeight > 0) {
        bullishScore /= totalWeight;
        bearishScore /= totalWeight;
    }
    
    // Requerir diferencia mínima para señal clara (aumentado de 15% a 25%)
    double minDifference = MathMax(bullishScore, bearishScore) * 0.25; // 25% de diferencia
    
    if(bullishScore > bearishScore + minDifference) {
        return TREND_UP;
    } else if(bearishScore > bullishScore + minDifference) {
        return TREND_DOWN;
    } else {
        return TREND_NONE;
    }
}

//+------------------------------------------------------------------+
//| Calcular momentum del mercado                                    |
//+------------------------------------------------------------------+
double CPatternMemory::CalculateMarketMomentum() {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(Symbol(), m_timeframe, 0, 10, rates) < 10) {
      return 0.0;
   }
   
   // Momentum simple normalizado
   double momentum = (rates[9].close > 0) ? 
                  (rates[0].close - rates[9].close) / rates[9].close : 0.0;   
   // Agregar peso por volumen
   double avgVolume = 0;
   double recentVolume = 0;
   
   for(int i = 0; i < 10; i++) {
      avgVolume += (double)rates[i].tick_volume;
      if(i < 3) recentVolume += (double)rates[i].tick_volume;
   }
   
   avgVolume /= 10;
   recentVolume /= 3;
   
   if(avgVolume > 0) {
      double volumeRatio = recentVolume / avgVolume;
      momentum *= (0.5 + volumeRatio * 0.5); // Ajustar por volumen
   }
   
   return momentum;
}

//+------------------------------------------------------------------+
//| Obtener posición del precio en el rango                         |
//+------------------------------------------------------------------+
double CPatternMemory::GetPricePosition() {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(Symbol(), m_timeframe, 0, 20, rates) < 20) {
      return 0.5;
   }
   
   double highest = rates[0].high;
   double lowest = rates[0].low;
   
   for(int i = 1; i < 20; i++) {
      highest = MathMax(highest, rates[i].high);
      lowest = MathMin(lowest, rates[i].low);
   }
   
   double range = highest - lowest;
   if(range <= 0) return 0.5;
   
   return (rates[0].close - lowest) / range;
}

//+------------------------------------------------------------------+
//| Verificar divergencias                                           |
//+------------------------------------------------------------------+
bool CPatternMemory::CheckDivergence(ENUM_TREND_DIRECTION &divergenceDirection) {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(Symbol(), m_timeframe, 0, 20, rates) < 20) {
      return false;
   }
   
   double rsi[];
   ArraySetAsSeries(rsi, true);
   if(CopyBuffer(m_rsiHandle, 0, 0, 20, rsi) < 20) {
      return false;
   }
   
   // Buscar máximos y mínimos en precio y RSI
   int priceHighIndex = 0, priceLowIndex = 0;
   int rsiHighIndex = 0, rsiLowIndex = 0;
   
   for(int i = 5; i < 15; i++) {
      if(rates[i].high > rates[priceHighIndex].high) priceHighIndex = i;
      if(rates[i].low < rates[priceLowIndex].low) priceLowIndex = i;
      if(rsi[i] > rsi[rsiHighIndex]) rsiHighIndex = i;
      if(rsi[i] < rsi[rsiLowIndex]) rsiLowIndex = i;
   }
   
   // Divergencia bajista: precio hace nuevo máximo pero RSI no
   if(rates[0].high > rates[priceHighIndex].high && rsi[0] < rsi[rsiHighIndex]) {
      divergenceDirection = TREND_DOWN;
      return true;
   }
   
   // Divergencia alcista: precio hace nuevo mínimo pero RSI no
   if(rates[0].low < rates[priceLowIndex].low && rsi[0] > rsi[rsiLowIndex]) {
      divergenceDirection = TREND_UP;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Método principal de análisis mejorado                           |
//+------------------------------------------------------------------+
int CPatternMemory::AnalyzeTrend(AccumulationZone &accumZones[], int accumCount, TrendSignal &signals[]) {
   if(!m_initialized || accumCount <= 0) {
      ArrayResize(signals, 0);
      return 0;
   }
   
   // Limpiar señales viejas
   ClearSignals();
   
   // Obtener dirección inmediata
   ENUM_TREND_DIRECTION immediateDirection = DetermineImmediateTrend();
   double confidence = GetDirectionConfidence();
   
   Print("PatternMemory - Dirección inmediata: ", EnumToString(immediateDirection), 
         ", Confianza: ", DoubleToString(confidence, 1), "%");
   
   // NUEVO: Informar sobre divergencias
   if(m_divergenceDetected) {
      Print(">>> DIVERGENCIA DETECTADA: ", EnumToString(m_lastDivergenceDirection));
   }
   
   int signalsGenerated = 0;
   
   // Generar señales para cada zona de acumulación
   for(int i = 0; i < accumCount; i++) {
      if(!accumZones[i].confirmed || !accumZones[i].active) continue;
      
      TrendSignal signal;
      ZeroMemory(signal);
      
      // Configurar señal básica
      signal.direction = immediateDirection;
      signal.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      signal.time = TimeCurrent();
      signal.active = true;
      signal.id = m_signalCount++;
      signal.accumZoneId = accumZones[i].id;
      
      // Calcular fuerza basada en confianza y zona
      signal.strength = (confidence / 10.0) * 0.7 + (accumZones[i].strength * 0.3);
      
      // NUEVO: Bonus por divergencia
      if(m_divergenceDetected && signal.direction == m_lastDivergenceDirection) {
         signal.strength += 1.0;
         signal.strength = MathMin(10.0, signal.strength);
      }
      
      signal.probability = confidence;
      signal.confidence = confidence / 100.0;
      
      // Configurar stop loss básico
      double atr = 0;
      double atrBuffer[1];
      if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuffer) > 0) {
         atr = atrBuffer[0];
      }
      
      if(atr <= 0) atr = 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(signal.direction == TREND_UP) {
         signal.stopLoss = signal.price - atr * 1.5;
         signal.takeProfit = signal.price + atr * 2.5;
      } else if(signal.direction == TREND_DOWN) {
         signal.stopLoss = signal.price + atr * 1.5;
         signal.takeProfit = signal.price - atr * 2.5;
      } else {
         // Si no hay tendencia clara, usar la zona de acumulación
         if(accumZones[i].levelType == SR_SUPPORT) {
            signal.direction = TREND_UP;
            signal.stopLoss = accumZones[i].lowPrice - atr * 0.5;
            signal.takeProfit = signal.price + atr * 2.0;
         } else {
            signal.direction = TREND_DOWN;
            signal.stopLoss = accumZones[i].highPrice + atr * 0.5;
            signal.takeProfit = signal.price - atr * 2.0;
         }
         signal.strength = 5.0; // Fuerza mínima
      }
      
      // Campos adicionales
      signal.supportingPatterns = (int)(confidence / 20.0);
      signal.patternMatches = signal.supportingPatterns;
      signal.period = 24 * 60;
      signal.expectedBars = 10;
      signal.convictionScore = signal.confidence;
      
      // Si la probabilidad es muy baja pero el modo es agresivo, forzar
      if(signal.probability < m_minProbability && m_aggressiveMode) {
         signal.probability = m_minProbability + 10.0;
         signal.strength = MathMax(signal.strength, 5.0);
      }
      
      // Agregar señal
      if(m_signalsActive < 10) {
         m_signals[m_signalsActive] = signal;
         m_signalsActive++;
         signalsGenerated++;
         
         Print("Señal generada #", signal.id, ": ", EnumToString(signal.direction),
               ", Fuerza: ", DoubleToString(signal.strength, 1),
               ", Prob: ", DoubleToString(signal.probability, 1), "%");
      }
   }
   
   // Si no se generaron señales pero hay zonas, crear una por defecto
   if(signalsGenerated == 0 && accumCount > 0 && m_aggressiveMode) {
      TrendSignal defaultSignal;
      ZeroMemory(defaultSignal);
      
      // Usar la primera zona disponible
      defaultSignal.direction = (immediateDirection != TREND_NONE) ? immediateDirection : 
                               (accumZones[0].levelType == SR_SUPPORT ? TREND_UP : TREND_DOWN);
      defaultSignal.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      defaultSignal.time = TimeCurrent();
      defaultSignal.strength = 5.0;
      defaultSignal.active = true;
      defaultSignal.id = m_signalCount++;
      defaultSignal.accumZoneId = accumZones[0].id;
      defaultSignal.probability = 45.0;
      defaultSignal.confidence = 0.45;
      
      // Stop loss
      double atr = 0;
      double atrBuffer[1];
      if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuffer) > 0) {
         atr = atrBuffer[0];
      }
      if(atr <= 0) atr = 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(defaultSignal.direction == TREND_UP) {
         defaultSignal.stopLoss = defaultSignal.price - atr * 1.5;
      } else {
         defaultSignal.stopLoss = defaultSignal.price + atr * 1.5;
      }
      
      m_signals[0] = defaultSignal;
      m_signalsActive = 1;
      signalsGenerated = 1;
      
      Print("Señal DEFAULT generada: ", EnumToString(defaultSignal.direction));
   }
   
   // Copiar señales al array de salida
   ArrayResize(signals, signalsGenerated);
   for(int i = 0; i < signalsGenerated; i++) {
      signals[i] = m_signals[i];
   }
   
   return signalsGenerated;
}

//+------------------------------------------------------------------+
//| Métodos auxiliares                                               |
//+------------------------------------------------------------------+

bool CPatternMemory::IsSignalValid(int signalId) {
   for(int i = 0; i < m_signalsActive; i++) {
      if(m_signals[i].id == signalId && m_signals[i].active) {
         return (TimeCurrent() - m_signals[i].time) < 24 * 3600;
      }
   }
   return false;
}

bool CPatternMemory::GetSignalById(int id, TrendSignal &signal) {
   for(int i = 0; i < m_signalsActive; i++) {
      if(m_signals[i].id == id && m_signals[i].active) {
         signal = m_signals[i];
         return true;
      }
   }
   return false;
}

void CPatternMemory::ClearSignals() {
   for(int i = 0; i < m_signalsActive; i++) {
      m_signals[i].active = false;
   }
   m_signalsActive = 0;
}

void CPatternMemory::UpdateVisual() {
   if(!m_showVisual) return;
   
   ObjectsDeleteAll(0, m_prefix);
   
   for(int i = 0; i < m_signalsActive; i++) {
      if(!m_signals[i].active) continue;
      
      string objName = m_prefix + IntegerToString(m_signals[i].id);
      
      if(ObjectCreate(0, objName, OBJ_ARROW, 0, m_signals[i].time, m_signals[i].price)) {
         ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 
                         m_signals[i].direction == TREND_UP ? 233 : 234);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, 
                         m_signals[i].direction == TREND_UP ? clrLime : clrRed);
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);
      }
   }
}

void CPatternMemory::PrintCurrentAnalysis() {
   Print("=== ANÁLISIS PATTERN MEMORY ===");
   Print("Dirección inmediata: ", EnumToString(GetImmediateDirection()));
   Print("Confianza: ", DoubleToString(GetDirectionConfidence(), 1), "%");
   Print("Momentum: ", DoubleToString(CalculateMarketMomentum(), 3));
   Print("Posición precio: ", DoubleToString(GetPricePosition(), 2));
   Print("Divergencia detectada: ", m_divergenceDetected ? "SÍ" : "NO");
   if(m_divergenceDetected) {
      Print("Dirección divergencia: ", EnumToString(m_lastDivergenceDirection));
   }
   Print("Señales activas: ", m_signalsActive);
   Print("===============================");
}